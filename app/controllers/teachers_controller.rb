class TeachersController < ApplicationController
	before_filter :authenticate_teacher!, :except => [:show]

	#/teachers
	#Lists all teachers
	def index
		@title = "Teacher Listing"
		@teachers = Teacher.all

		#@feed = Binder.where( :owner.ne => current_teacher.id.to_s, "parents.id" => { "$ne" => "-1"}).desc(:last_update).limit(10)#, "last_update" => { "$gte" => Time.now-24.hours }  ).desc(:last_update).limit(10)

		#@feed = Log.where( :ownerid.ne => current_teacher.id.to_s).in( method: ["create","createfile","createcontent"] ).desc(:timestamp).limit(10)

		# JSON.parse utilizes the C unicode library, MUCH FASTER!!!!
		#@parsed_json = JSON.parse(File.read("app/assets/json/standards.json"))
	end

	#/teachers/:id
	#Teacher Profiles
	def show
		@teacher = Teacher.where(:username => /^#{Regexp.escape(params[:username])}$/i).first

		render "public/404.html", :status => 404 and return if @teacher.nil?

		redirect_to "/#{@teacher.username}" and return if @teacher.username != params[:username]

		@is_self = signed_in? ? current_teacher.username.downcase == params[:username].downcase : false

		if @is_self
			@children = Binder.where( :owner => current_teacher.id.to_s, :parent => { 'id'=>'0','title'=>'' } )
		else
			@children = []
			Binder.where( :owner => @teacher.id.to_s, :parent => { 'id'=>'0','title'=>'' } ).each do |b|
				@children << b if b.get_access(signed_in? ? current_teacher.id.to_s : 0) > 0
			end
		end

        @teacher.info = Info.new if @teacher.info.nil?

		@title = "#{@teacher.full_name}'s Portfolio"

		# @relationship = current_teacher.relationship_by_teacher_id(@teacher.id)

		# @colleague_requests = current_teacher.relationships.where(:colleague_status => 2).entries

		#@colleagues = current_teacher.relationships.where(:colleague_status => 3).entries
		#@colleagues = (current_teacher.relationships.where(:colleague_status => 3).entries).map { |c| Teacher.find(c["user_id"]) }

		#@subscriptions = current_teacher.relationships.where(:subscribed => true).entries
		@subscriptions = (@teacher.relationships.where(:subscribed => true).entries).map { |r| Teacher.find(r["user_id"]) } 

		@subscribers = Teacher.where("relationships.subscribed" => true, "relationships.user_id" => @teacher.id.to_s)

		#Create info entry for teacher if not yet created
		#@teacher.info = Info.new if !@teacher.info

		@subsfeed = []

		feedblacklist = {}
		duplist = {}

		@teacher_activity = false

		if signed_in?

			# pull logs of relevant content, sort them, iterate through them, break when 10 are found
			#logs = Log.where( :model => "binders", "data.src" => nil  ).in( method: FEED_METHOD_WHITELIST ).desc(:timestamp)
			#logs = Log.where( "data.src" => nil ).in( model: ['binders','teachers'] ).in( method: FEED_METHOD_WHITELIST ).desc(:timestamp)


			# pull the current teacher's subscription IDs
			subs = (current_teacher.relationships.where(:subscribed => true).entries).map { |r| r["user_id"].to_s } 


			logs = Tire.search 'logs' do |search|

				search.query do |query|
					#query.string params[:q]

					query.all

					#search.size 40
				end

				# technically these should be cascaded to avoid cross-method name conflicts
				search.filter :terms, :model => ['binders','teachers']
				search.filter :terms, :method => FEED_METHOD_WHITELIST
				search.filter :terms, :ownerid => [@teacher.id.to_s]

				search.size 60

				search.sort { by :timestamp, 'desc' }

			end
			
			logs = logs.results

			#debugger
			
			if logs.any?
				logs.each do |f|

					#debugger

					begin
						case f[:model].to_s
							when 'binders'
								model = Binder.find(f[:modelid].to_s)
							when 'teachers'
								model = Teacher.find(f[:modelid].to_s)
						end
					rescue
						Rails.logger.fatal "Invalid log model ID!"
						next
					end

					#debugger

					# push onto the feed if the node is not deleted
					case f[:model].to_s
					when 'binders'
						# the binder log entry:	should not be deleted
						# 						should not be private
						# 						should not be sourced from another log entry
						if model.parents[0]!={ "id" => "-1", "title" => "" } && model.is_pub? && !f[:data][:src]

							# the binder log entry: should not have a blacklist entry
							# 						should not be a setpub -> private
							if !(feedblacklist[f[:actionhash].to_s]) && ( f[:method] == "setpub" ? ( f[:params]["enabled"] == "true" ) : true )

								# calculate number of items contributed from this teacher
								c = (@subsfeed.flatten.reject { |h| h[:log][:ownerid].to_s!=f[:ownerid].to_s }).size

								if (subs.include? f[:ownerid].to_s) || (f[:ownerid].to_s == current_teacher.id.to_s)
									
									# occupancy of up to 10 from any teacher
									if c < 10

										# whether or not the item is included in the blacklist,
										# add the actionhash and annihilation IDs to the exclusion list
										feedblacklist[f[:actionhash].to_s] = true

										# enter all annihilation entries into blacklist hash
										f[:data][:annihilate].each { |a| feedblacklist[a.to_s] = true } if f[:data][:annihilate]

										# execute blacklist exclusion
										if !(FEED_DISPLAY_BLACKLIST.include? f[:method].to_s)# && 

											#debugger

											# create a key for an owner and an action
											similar = Digest::MD5.hexdigest(f[:ownerid].to_s + f[:method].to_s).to_s

											f = { :model => model, :owner => Teacher.find(f[:ownerid].to_s), :log => f }	

											# if there are no members in the duplist, create a new action in each tracking hash
											if !(duplist[similar]) || ((duplist[similar]['timestamp'].to_i-f[:log][:timestamp].to_i) > 30.minutes.to_i)			

												# store the index at which the similar item resides, and the current time
												duplist[similar] = { 'index' => @subsfeed.size, 'timestamp' => f[:log][:timestamp].to_i }

												# new array set for feed object type
												@subsfeed << [f]

											# there is a similar event, combine in feed array
											else	

												@subsfeed[duplist[similar]['index']] << f

												# update to the most recent time
												duplist[similar]['timestamp'] = f[:log][:timestamp].to_i

											end
										end
									end
								end
							end
						end
					when 'teachers'
						if !(feedblacklist[f[:actionhash].to_s])

							c = (@subsfeed.flatten.reject { |h| h[:log][:ownerid].to_s!=f[:ownerid].to_s }).size

							if (subs.include? f[:ownerid].to_s) || (f[:ownerid].to_s == current_teacher.id.to_s)
								
								#debugger
								if c < 10

									# whether or not the item is included in the blacklist,
									# add the actionhash and annihilation IDs to the exclusion list
									feedblacklist[f[:actionhash].to_s] = true

									f[:data][:annihilate].each { |a| feedblacklist[a.to_s] = true } if f[:data][:annihilate]

									# execute blacklist exclusion
									if !(FEED_DISPLAY_BLACKLIST.include? f[:method].to_s)# && 

										#debugger

										# create a key for an owner and an action
										similar = Digest::MD5.hexdigest(f[:ownerid].to_s + f[:method].to_s).to_s

										f = { :model => model, :owner => Teacher.find(f[:ownerid].to_s), :log => f }	

										# if there are no members in the duplist, create a new action in each tracking hash
										if !(duplist[similar]) || ((duplist[similar]['timestamp'].to_i-f[:log][:timestamp].to_i) > 30.minutes.to_i)			

											# store the index at which the similar item resides, and the current time
											duplist[similar] = { 'index' => @subsfeed.size, 'timestamp' => f[:log][:timestamp].to_i }

											# new array set for feed object type
											@subsfeed << [f]

										# there is a similar event, combine in feed array
										else	

											@subsfeed[duplist[similar]['index']] << f

											# update to the most recent time
											duplist[similar]['timestamp'] = f[:log][:timestamp].to_i

										end
									end
								end
							end
						end
					end

					break if @subsfeed.size == SUBSC_FEED_LENGTH
				end
			end
		end

		#feed.map { |f| f.modelid.to_s } if feed.any?

		#Rails.logger.debug "feed: #{feed.map { |f| f.modelid.to_s }.to_s} "

		#@binder_create = Binder.where( 	:owner.ne => current_teacher.id.to_s, 
		#								"parents.id" => { "$ne" => "-1"}).in( _id: feed.map { |f| f.modelid.to_s } )

		# fetch root level directories that are owned by the teacher
		@owned_root_binders = Binder.where("parent.id" => "0", :owner => params[:id]).reject{|b| b.get_access(signed_in? ? current_teacher.id.to_s : 0) < 1}

		rescue Errno::ECONNREFUSED

	end

	#/editinfo
	def editinfo

		@title = "Edit your information"

		current_teacher.info = Info.new if !current_teacher.info
	end

	#PUT /updateinfo
	def updateinfo

		current_teacher.info = Info.new if current_teacher.info.nil?

		current_teacher.update_attributes(params[:teacher])

		current_teacher.info.update_attributes(	:avatar			=> params[:info][:avatar],
												:website		=> Addressable::URI.heuristic_parse(params[:info][:website]).to_s,
												:grades			=> params[:grades].strip.split(/\s*,\s*/),
												:subjects		=> params[:subjects].strip.split(/\s*,\s*/),
												:bio			=> params[:info][:bio][0..189],
												:city			=> params[:info][:fulllocation].split(', ').first || "",
												:state			=> params[:info][:fulllocation].split(', ').second || "",
												:country		=> params[:info][:fulllocation].split(', ').third || "",
												:location		=> [params[:lng].to_f, params[:lat].to_f],
												:size			=> params[:info][:avatar].size)

		altparams = nil

		if !params[:info][:avatar].nil?
			altparams = params.dup
			altparams[:info][:avatar] = params[:info][:avatar].original_filename
		end

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					current_teacher.id.to_s,
					# params)
					altparams.nil? ? params : altparams)
		
		redirect_to teacher_omniauth_authorize_path(params[:buttonredirect]) and return if !params[:buttonredirect].nil?

		if current_teacher.info.errors.empty? && current_teacher.errors.empty?
			redirect_to "/#{current_teacher.username}"
		else
			# remain on current page, display errors
			@title = "Edit your information"
			render "editinfo"
		end

	end

	def updateprefs

		debugger

		emailconfig = {	"sub" => params[:sub] == "1",
						"col" => params[:col] == "1",
						"msg" => params[:msg] == "1"}

		current_teacher.update_attributes(:emailconfig => emailconfig)

		redirect_to editinfo_path

	end

	def updatepass

		@teacher = current_teacher

		if @teacher.update_attributes(params[:teacher])

			sign_in @teacher, :bypass => true

			redirect_to root_path

		else

			render "editinfo"

		end

	end

	#/tags
	def tags
		@title = "Manage your subscribed tags"

		current_teacher.tag = Tag.new if !current_teacher.tag
	end

	#PUT /updatetags
	def updatetags

		current_teacher.tag.update_tag_fields(params)

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					current_teacher.id.to_s,
					params)

		redirect_to tags_path
	end

	def sub

		@teacher = Teacher.where(:username => /^#{Regexp.escape(params[:username])}$/i).first

		# ignore duplicate requests
		return if current_teacher.subscribed_to?(@teacher.id.to_s)

		errors = []

		@title = "You are now subscribed to #{@teacher.full_name}"

		@relationship = current_teacher.relationship_by_teacher_id(@teacher.id.to_s)

		@relationship.subscribe()

		#Delay
		Teacher.delay(:queue => "email").newsub_email(current_teacher.id.to_s, @teacher.id.to_s)

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@teacher.id.to_s,
					params,
					{ :relationship => @relationship.id.to_s })

		rescue BSON::InvalidObjectId
			errors << "Invalid Request"
		rescue Mongoid::Errors::DocumentNotFound
			errors << "Invalid Request"
		ensure
			respond_to do |format|
				format.html {render :text => errors.empty? ? 1 : errors}
			end
	end

	def unsub

		errors = []

		@teacher = Teacher.where(:username => /^#{Regexp.escape(params[:username])}$/i).first

		@relationship = current_teacher.relationship_by_teacher_id(@teacher.id)

		@affected_relationship = @teacher.relationship_by_teacher_id(current_teacher.id)

		errors << "Invalid Request" if !@relationship.subscribed

		if @relationship.colleague_status == 0
			# both teachers are not colleagues

			# not subscribed to current teacher and not colleagues, so delete
			@affected_relationship.delete if @affected_relationship.subscribed == false

			# not subscribed and not colleagues, so delete
			@relationship.delete
		else
			# some colleague action is pending, merely unsubscribe from the other teacher
			@relationship.unsubscribe()
		end

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@teacher.id.to_s,
					params,
					{ 	:relationship => @relationship.id.to_s, 
						:affected_relationship => @affected_relationship.id.to_s,
						:annihilate => [Digest::MD5.hexdigest(current_teacher.id.to_s+'sub'+@teacher.id.to_s)]}) 

		rescue BSON::InvalidObjectId
			errors << "Invalid Request"
		rescue Mongoid::Errors::DocumentNotFound
			errors << "Invalid Request"
		ensure
			respond_to do |format|
				format.html {render :text => errors.empty? ? 1 : errors.first}
			end

	end

	# def omnifriend

	# 	errors = []

	# 	if !current_teacher.omnihash["facebook"].nil?

	# 		if current_teacher.omnihash["facebook"]["data"]["credentials"]["expires_at"] > Time.now.to_i

	# 			fids = JSON.parse(RestClient.get("https://graph.facebook.com/#{current_teacher.omnihash["facebook"]["data"]["uid"]}/friends?access_token=#{current_teacher.omnihash["facebook"]["data"]["credentials"]}"))["data"].collect{|f| f["id"]}

	# 			Teacher.where(:'omnihash.facebook.uid'.in => fids).each do |teacher|

	# 				current_teacher.relationship_by_teacher_id(teacher.id).subscribe

	# 			end

	# 		else

	# 			#Set redir session var and redir to oauth for new token, then redir back to this function.

	# 			errors = "Your token has expired"

	# 		end

	# 	else

	# 		errors = "You still need to authenticate your facebook account"

	# 	end

	# 	if !current_teacher.omnihash["twitter"].nil?

	# 		if current_teacher.omnihash["twitter"]["data"]["credentials"]["expires_at"] > Time.now.to_i

	# 			fids = JSON.parse(RestClient.get("https://api.twitter.com/1/friends/ids.json?user_id=#{current_teacher.omnihash["twitter"]["data"]["uid"]}&stringify_ids=true"))["ids"]

	# 			Teacher.where(:'omnihash.twitter.uid'.in => fids).each do |teacher|

	# 				current_teacher.relationship_by_teacher_id(teacher.id).subscribe

	# 			end

	# 		else

	# 			#Set redir session var and redir to oauth for new token, then redir back to this function.

	# 			errors = "Your token has expired"

	# 		end

	# 	else

	# 		errors = "You still need to authenticate your twitter account"

	# 	end

	# end

	# #/subs
	# def subs

	# 	@title = "#{ current_teacher.full_name }'s Subscriptions"

	# 	@subs = current_teacher.relationships.find(:subscribed => false)
	# 	#@subs = current_teacher.relationships.find_unsubscribed

	# end

	#Relationships Schema:
	#
	#Subscriptions:
	#When a teacher subscribes to another teacher, a new Relationship is created where .subscribed = true
	#Unsubscribing sets .subscribed = false
	#
	#If teacher1 subscribes to teacher2, and teacher2 was already subscribed to teacher1, prompt teacher1
	#if they wish to send a collegue request
	#
	#Colleagues:
	#Default status is 0 => no colleague relationship
	#Changes to 1 => pending outgoing request
	#Changes to 2 => pending incoming request
	#Changes to 3 => colleagues
	#
	#Relationship status between two colleagues will either be:
	#Both 0 or both 3, when two teachers are collegues or not colleagues, with no pending requests
	#One will be 1 and the other must be 2 when a request has been made


	#GET /confadd/:id <= To be changed to PUT/POST
	def add

		errors = []

		#Teacher to be added
		@teacher = Teacher.where(:username => /^#{Regexp.escape(params[:username])}$/i).first

		@title = "Add #{ @teacher.full_name } as a Colleague"

		#current_teacher.add_colleague(params)

		@relationship = current_teacher.relationship_by_teacher_id(@teacher.id)

		if @relationship.colleague_status == 0 #Then the colleague_status for @teacher should also be 0

			@relationship.set_colleague_status(1)

			@affected_relationship = @teacher.relationship_by_teacher_id(current_teacher.id)

			@affected_relationship.set_colleague_status(2)

		end

		#if adding colleage due to incoming request, create colleague relationshikp
		if @relationship.colleague_status == 2

			@relationship.set_colleague_status(3)

			@affected_relationship = @teacher.relationship_by_teacher_id(current_teacher.id)

			@affected_relationship.set_colleague_status(3)
		end

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@teacher.id.to_s,
					params,
					{ 	:relationship => @relationship.id.to_s, 
						:affected_relationship => @affected_relationship.id.to_s })

		rescue BSON::InvalidObjectId
			errors << "Invalid Request"
		rescue Mongoid::Errors::DocumentNotFound
			errors << "Invalid Request"
		ensure
			respond_to do |format|
				format.html {render :text => errors.empty? ? 1 : errors.first}
			end

	end

	#GET /confremove/:id <= To be changed to PUT/POST
	def confremove

		#Teacher to be removed
		@teacher = Teacher.find(params[:id])

		@title = "Remove #{ @teacher.full_name } as a Colleague"

		@relationship = current_teacher.relationship_by_teacher_id(params[:id])

		if @relationship.colleague_status == 3

			#@relationship.set_colleague_status(0)

			@affected_relationship = @teacher.relationship_by_teacher_id(current_teacher.id)

			#@affected_relationship.set_colleague_status(0)

			if @relationship.subscribed == false# and @affected_relationship.subscribed == false
				# we are not subscribed to the other teacher, so delete our relationship with them
				@relationship.delete
			else
				# weScreenshot from 2012-06-20 13:53:32 are subscribed to them, so merely unset the colleague status
				@relationship.set_colleague_status(0)
			end

			if @affected_relationship.subscribed == false
				# the other teacher is not subscribed to us, so delete their relationship with us
				@affected_relationship.delete
			else
				# they are subscribed to us, so merely unset the colleague status
				@affected_relationship.set_colleague_status(0)
			end
#			@relationship.delete if !@relationship.subscribed else @relationship.set_colleague_status(0)

#			@relationship.delete

#			@affected_relationship.delete
		end
 
		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@teacher.id.to_s,
					params,
					{ 	:relationship => @relationship.id.to_s, 
						:affected_relationship => @affected_relationship.id.to_s })

		redirect_to teacher_path(@teacher)

	end

	def showbinder

		#@text = "Success!"
		@teacher = Teacher.find(params[:id])

		@current_binder = Binder.find(params[:binder_id])
		#@current_binder << Binder.where()

		@child_binders = Binder.where("parent.id" => params[:binder_id])

		@binder_file_tree_array = Array.new
		@binder_parent_id_array = Array.new

		@current_binder.parents.each do |nodeparent|
			# this is where versioning and permission logic should be inserted
			@binder_file_tree_array << Binder.where("parent.id" => nodeparent["id"], :owner => params[:id]).entries
			@binder_parent_id_array << nodeparent["id"].to_s
		end

		
		# if @child_binders.empty?
		# 	@child_binders = Binder.new()
		# end

		#@owned_root_binders = Binder.where("parent.id" => "0", :owner => params[:id]).entries

		@retarray = Array.new


	end

	def done

		current_teacher.update_attributes(:getting_started => false)

		respond_to do |format|
			format.html {render :text => 1}
		end

	end

	def conversations

		@title = "Messages"

		@conversations = Conversation.where("members" => current_teacher.id.to_s).sort_by{|c| c.last_message.timestamp}.reverse

	end

	###############################################################################################

							#    #  ##### #     #####  ##### #####   #### 
							#    #  #     #     #    # #     #    # #    #
							#    #  #     #     #    # #     #    # # 
							######  ####  #     #####  ####  #####   ####
							#    #  #     #     #      #     #  #        #
							#    #  #     #     #      #     #   #  #    #
							#    #  ##### ##### #      ##### #    #  ####

	###############################################################################################

	module Mongo
		extend self

		def log(ownerid,method,model,modelid,params,data = {})

			log = Log.new( 	:ownerid => ownerid.to_s,
							:timestamp => Time.now.to_f,
							:method => method.to_s,
							:model => model.to_s,
							:modelid => modelid.to_s,
							:params => params,
							:data => data,
							:actionhash => Digest::MD5.hexdigest(ownerid.to_s+method.to_s+modelid.to_s))

			log.save

			return log.id.to_s

		end
	end
end
