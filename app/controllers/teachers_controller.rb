class TeachersController < ApplicationController
	before_filter :authenticate_teacher!

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
		@teacher = Teacher.where(:username => params[:username]).first

        @teacher.info = Info.new

		@title = "#{ @teacher.full_name }'s Profile"

		@relationship = current_teacher.relationship_by_teacher_id(@teacher.id)

		@colleague_requests = current_teacher.relationships.where(:colleague_status => 2).entries

		#@colleagues = current_teacher.relationships.where(:colleague_status => 3).entries
		@colleagues = (current_teacher.relationships.where(:colleague_status => 3).entries).map { |c| Teacher.find(c["user_id"]) }

		#@subscriptions = current_teacher.relationships.where(:subscribed => true).entries
		@subscriptions = (current_teacher.relationships.where(:subscribed => true).entries).map { |r| Teacher.find(r["user_id"]) } 

		#Create info entry for teacher if not yet created
		#@teacher.info = Info.new if !@teacher.info

		@feed = []
		temp = []

		# pull logs of relevant content, sort them, iterate through them, break when 10 are found
		logs = Log.where( :ownerid.ne => current_teacher.id.to_s, :model => "binders", "data.src" => nil  ).in( method: ["create","createfile","createcontent","update","updatetags","setpub"] ).desc(:timestamp)

		if logs.any?
			logs.each do |f|

				# push onto the feed if the node is not deleted
				binder = Binder.find(f.modelid.to_s)

				if binder.parents[0]!={ "id" => "-1", "title" => "" } && binder.get_access(current_teacher.id.to_s) > 0

					#Rails.logger.debug "feed log: #{f.params.to_s}"

					#timestamp << f.timestamp

					#f.delete(:timestamp)

					

					#if @feed.any? && !(@feed.map { |g| g.clone.delete("timestamp") }.include? f.clone.delete("timestamp"))

					# field :ownerid
					# field :timestamp, :type => Integer
					# # method and model are potentially redundant or unneeded fields
					# # model is a lowercase string of the model name
					# field :method
					# field :controller
					# field :modelid
					# field :params, :type => Hash

					# # non-standard optional data hash
					# # :copy - this is a copy, and was copied from the binder ID specified by :copy
					# # :src - this log is part of a logset, src is the ID of the 'parent' log
					# field :data, :type => Hash, :default => {}

					if !( @feed.map { |g| [g.ownerid,g.method,g.controller,g.modelid,g.params,g.data] }.include? [f.ownerid,f.method,f.controller,f.modelid,f.params,f.data] ) &&
						( f.method=="setpub" ? ( f.params["enabled"]=="true" ) : ( true ) )

					#temp << f

					#if temp.map { |g| g.delete(:timestamp) }.uniq.size == temp.size
				
						@feed << f

					#temp <<

					#Rails.logger.debug "FEED: #{@feed.map { |h| h.delete("timestamp") }}"	

					end

					#temp = @feed.clone

					#end

				end

				#@feed.uniq!

				# exit the loop if the maximum amount has been found
				break if @feed.size == 10

				#@feed[f.method.to_s] << f
			end

		end

		# the array should already be sorted
		# .sort_by { |e| -e.timestamp }
		@feed = @feed.any? ? @feed.map{ |f| {:binder => Binder.find( f.modelid.to_s ), :owner => Teacher.find( f.ownerid.to_s ), :log => f } } : []

		#feed.map { |f| f.modelid.to_s } if feed.any?

		#Rails.logger.debug "feed: #{feed.map { |f| f.modelid.to_s }.to_s} "

		#@binder_create = Binder.where( 	:owner.ne => current_teacher.id.to_s, 
		#								"parents.id" => { "$ne" => "-1"}).in( _id: feed.map { |f| f.modelid.to_s } )

		# fetch root level directories that are owned by the teacher
		@owned_root_binders = Binder.where("parent.id" => "0", :owner => params[:id]).entries

	end

	#/editinfo
	def editinfo

		Rails.logger.debug "Reached #editinfo"

		@title = "Edit your information"

		current_teacher.info = Info.new if !current_teacher.info
	end

	#PUT /updateinfo
	def updateinfo

		#@teacher = current_teacher

		#@info = @teacher.info

		#@info = current_teacher.newinfo

		#info = params[:info]

		#TODO Make sure htmlcode is not allowed in @info.bio

		Rails.logger.debug "Reached #updateinfo"

		current_teacher.info = Info.new if !current_teacher.info

		#current_teacher.info.save

		#current_teacher.info.update_info_fields(params)

		# if params[:info][:avatar].nil?

		# 	Rails.logger.debug "No avatar chosen! <#{params[:info][:avatar].to_s}>"

		# 	current_teacher.update_attributes( :bio => params[:info][:bio],
		# 							:website => params[:info][:website] )
		# 							# new attributes
		# else

		# 	Rails.logger.debug "Got to UPDATE INFO FIELDS!!!!!"

		Rails.logger.debug "params: #{params.to_s}"

		current_teacher.info.update_attributes(	:bio 				=> params[:info][:bio],
												# new attributes
												:avatar 			=> params[:info][:avatar],
												:size 				=> params[:info][:avatar].size,
												:ext 				=> File.extname(params[:info][:avatar].original_filename),
												:data 				=> params[:info][:avatar].path,
												#:avatar_width		=> avatar[:width],
												#:avatar_height		=> avatar[:height],
												:website 			=> params[:info][:website])
		# end

		# override carrierwave uploader field
		if !params[:info][:avatar].nil?
			altparams = params.clone
			altparams[:info][:avatar] = params[:info][:avatar].original_filename
		end

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					current_teacher.id.to_s,
					altparams.nil? ? params : altparams)

		if current_teacher.info.errors.empty?
			# no errors, return to the main profile page
			redirect_to teacher_path(current_teacher)
		else
			# remain on current page, display errors
			render 'editinfo'
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

	#GET /confsub/:id <- To be changed to PUT/POST
	def confsub

		@teacher = Teacher.find(params[:id])

		@title = "You are now subscribed to #{ @teacher.full_name }"

		@relationship = current_teacher.relationship_by_teacher_id(params[:id])

		@relationship.subscribe()

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@teacher.id.to_s,
					params,
					{ :relationship => @relationship.id.to_s })

		redirect_to teacher_path(@teacher)
	end

	#GET /confunsub/:id
	def confunsub

		@teacher = Teacher.find(params[:id])

		@relationship = current_teacher.relationship_by_teacher_id(params[:id])

		@affected_relationship = @teacher.relationship_by_teacher_id(current_teacher.id)

		redirect_to teacher_path(params[:id]) if !@relationship.subscribed

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
						:affected_relationship => @affected_relationship.id.to_s })

		redirect_to teacher_path(@teacher)

	end

	#/subs
	def subs

		@title = "#{ current_teacher.full_name }'s Subscriptions"

		@subs = current_teacher.relationships.find(:subscribed => false)
		#@subs = current_teacher.relationships.find_unsubscribed

	end

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
	def confadd

		#Teacher to be added
		@teacher = Teacher.find(params[:id])

		@title = "Add #{ @teacher.full_name } as a Colleague"

		#current_teacher.add_colleague(params)

		@relationship = current_teacher.relationship_by_teacher_id(params[:id])

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

		redirect_to teacher_path(@teacher)

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

	def conversations

		@conversations = Conversation.where("members" => current_teacher.id.to_s)

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
							:timestamp => Time.now.to_i,
							:method => method.to_s,
							:model => model.to_s,
							:modelid => modelid.to_s,
							:params => params,
							:data => data)

			log.save

			return log.id.to_s

		end
	end
end
