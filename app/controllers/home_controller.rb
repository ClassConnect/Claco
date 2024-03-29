class HomeController < ApplicationController
	before_filter :authenticate_teacher!, :except => [:index, :autocomplete, :tos, :privacy, :about, :united, :team, :pioneers, :pioneersshow, :goodies, :press]

	def index

		#debugger

		@title = "Claco"
		@teachers = Teacher.all

		@feed = []
		@subsfeed = []

		# i = 0

		feedblacklist = {}
		duplist = {}

		@teacher_activity = true

		if signed_in?

			@teacher=current_teacher	

			@invcount = Invitation.where(:from => current_teacher.id.to_s).count
			@size_percent_used = (current_teacher.priv_size / current_teacher.size_cap.to_f) * 100
			@shared_binders = Binder.where(:"permissions.shared_id" => current_teacher.id.to_s).reject{|b| b.get_access(current_teacher.id.to_s) < 1}

			# pull logs of relevant content, sort them, iterate through them, break when 10 are found
			#logs = Log.where( :model => "binders", "data.src" => nil  ).in( method: FEED_METHOD_WHITELIST ).desc(:timestamp)
			#logs = Log.where( "data.src" => nil ).in( model: ['binders','teachers'] ).in( method: FEED_METHOD_WHITELIST ).desc(:timestamp)

			#debugger

			@educators = []

			reclist = []

			if current_teacher.recommend_ids.to_a.empty?
				# current_teacher.update_attributes(:recommend_ids => current_teacher.delay.recommends)
				Teacher.delay.recbuild(current_teacher.id.to_s)
				# reclist = ['502d3edd2fc61000020000bf','5049718bf5d9ab00020000a7','50451ebd7b2f1d0002000035']
			end
			reclist = current_teacher.recommend_ids[0..9].shuffle
			reclist.each_with_index do |f,index|
				begin
					teacher = Teacher.find(f.to_s)
					if Teacher.thumbready?(teacher) || (@educators.size+6 < index)
						@educators << teacher
					end
				rescue
					Rails.logger.fatal "Recommended teacher ID invalid"
					#next
				end
				break if @educators.size == 3
			end

			@feedindex = 0

			if false

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
				search.filter :terms, :ownerid => subs + [current_teacher.id.to_s]

				search.size 100

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

					# the binder log entry:		should not be deleted
					# 							should not be private
					# 							should not be sourced from another log entry
					# 							should not have a blacklist entry
					# 							should not be a setpub -> private
					#
					# the teacher log entry: 	should not have a blacklist entry
					if 	(f[:model].to_s=='binders' && 
							model.parents[0]!={ "id" => "-1", "title" => "" } && 
							model.is_pub? && 
							!f[:data][:src] && 
							!(feedblacklist[f[:actionhash].to_s]) && 
							( f[:method] == "setpub" ? ( f[:params]["enabled"] == "true" ) : true )) || 
						(f[:model].to_s=='teachers' &&
							!(feedblacklist[f[:actionhash].to_s]))

						# calculate number of items contributed from this teacher
						c = (@subsfeed.flatten.reject { |h| h[:log][:ownerid].to_s!=f[:ownerid].to_s }).size

						# must be subscribed or owned
						# occupancy of up to 10 from any teacher
						if ((subs.include? f[:ownerid].to_s) || (f[:ownerid].to_s == current_teacher.id.to_s)) && c<10

							# whether or not the item is included in the blacklist,
							# add the actionhash and annihilation IDs to the exclusion list
							feedblacklist[f[:actionhash].to_s] = true

							# enter all annihilation entries into blacklist hash
							f[:data][:annihilate].each { |a| feedblacklist[a.to_s] = true } if f[:data][:annihilate]

							# execute blacklist exclusion
							if !(FEED_DISPLAY_BLACKLIST.include? f[:method].to_s)# && 

								# create a key for an owner and an action
								similar = Digest::MD5.hexdigest(f[:ownerid].to_s + f[:method].to_s).to_s

								f = { :model => model, :owner => Teacher.find(f[:ownerid].to_s), :log => f }	

								# if there are no members in the duplist, create a new action in each tracking hash
								if !(duplist[similar]) || ((duplist[similar]['timestamp'].to_i-f[:log][:timestamp].to_i) > FEED_COLLAPSE_TIME)	

									# store the index at which the similar item resides, and the current time
									duplist[similar] = { 'index' => @subsfeed.size, 'blank_index' => 0, 'timestamp' => f[:log][:timestamp].to_i }

									# new array set for feed object type
									@subsfeed << [f]

								# there is a similar event, combine in feed array
								else	

									expire_fragment(f[:log].id.to_s) if Rails.cache.read(f[:log].id.to_s) 

									# insert into array dependent on whether or not a thumbnail exists
									if (f[:log].model.to_s=='binders' && 
											(f[:model].thumbimgids[0].nil? || 
											f[:model].thumbimgids[0].empty?)) || 
										(f[:log].model.to_s=='teachers' && 
											!Teacher.thumbready?(f[:model]))

										@subsfeed[duplist[similar]['index']] << f

									else

										@subsfeed[duplist[similar]['index']].insert(duplist[similar]['blank_index'],f)

										duplist[similar]['blank_index'] += 1

									end

									# update to the most recent time
									duplist[similar]['timestamp'] = f[:log][:timestamp].to_i

								end
								if !Rails.cache.read(f[:log].id.to_s).nil? 
									expire_fragment(f[:log].id.to_s) 
									Rails.cache.delete(f[:log].id.to_s)
								end
							end
						end
					end
					break if @subsfeed.flatten.size == SUBSC_FEED_LENGTH
				end
			end

			end

		end

		rescue Errno::ECONNREFUSED
			Rails.logger.fatal "ElasticSearch server unreachable"
		rescue Tire::Search::SearchRequestFailed
			Rails.logger.fatal "Index missing exception"

		#debugger
	end

	def inf

		#debugger

		feed = Feed.find(current_teacher.feed_ids[0])
		feedhash = feed.html(current_teacher.id.to_s,params[:logid])

		respond_to do |format|
			begin
				format.json {render :text => {'html' => feedhash['html'] , 'nextlogid' => feedhash['logid']}.to_json }
				# format.json {render :text => {'html' => 'ABCDE' , 'nextlogid' => feedhash['logid']}.to_json }
			rescue
				format.json {render :text => {'html' => "teacher does not have a feed", 'nextlogid' => ''}.to_json }
			end
		end

	end

	def educators

		@title = "Educators you may know"

		#debugger

		# fallback recommendation calculation
		if current_teacher.recommend_ids.to_a.empty?
			current_teacher.update_attribute(:recommend_ids, current_teacher.recommends)
			ActionController::Base.new.expire_fragment("recommendations/#{current_teacher.id.to_s}")
		end

		h={}
		i=0
		@recommends=[]

		current_teacher.recommend_ids.each do |f|
			h[f] = i
			i += 1
		end

		#@recommends = current_teacher.recommend_ids #Rails.cache.read("recommendations/ids/#{self.id.to_s}")

		#if @recommends.nil? || @recommends.empty?

		# precaution
		#Rails.cache.delete("recommendations/html/#{self.id.to_s}")
		#ActionController::Base.new.expire_fragment("recommendations/#{current_teacher.id.to_s}")

		# teachers = Tire.search 'teachers' do |search|

		# 	search.query do |query|
		# 		query.all
		# 	end

		# 	search.filter :terms, :stringid => current_teacher.recommend_ids

		# end
		
		# @recommends = teachers.results

		#debugger
		#url = 'localhost:9200/teachers/_mget'
		#data = '{"ids":["' + current_teacher.recommend_ids.join('","') + '"]}'
		#debugger
		#@recommends = JSON.parse(RestClient.post(url,data))['docs'].map{|f| f.first['_source']}

		#debugger

		#return if false

		# this query returns teachers in the order they were entered into the database
		#@recommends = Teacher.any_in(_id: current_teacher.recommend_ids)

		Teacher.any_in(_id: current_teacher.recommend_ids).each do |f|
			@recommends[h[f.id.to_s]]=f
		end

		#RestClient.get()

		#end

		render 'educators'

	end 

	def fetchtitle
		
		f = Nokogiri::HTML(params[:url]).at('iframe')

		if f.nil?

			title = Nokogiri::HTML(RestClient.get(URI.escape(params[:url]))).title.strip.squeeze(' ')

		else

			title = Nokogiri::HTML(RestClient.get(f['src'])).title.strip.squeeze(' ')

		end

		rescue

		ensure
			respond_to do |format|
				format.html {render :text => !title.nil? ? title[0..49] : " "}
			end
	end

	def auto
		
		smushset = []

		response = (JSON.parse(RestClient.get('http://redis.claco.com/sm/search?' + request.query_string))['results']['standard']).each { |result| smushset << { :title => result['data']['label'], :label => result['data']['value'] } }

		response.each do |result|
			smushset << { :title => result['data']['label'], :label => result['data']['value'] }
		end

		rescue

		ensure
			respond_to do |format|
				#format.json {render :text => response || ""}
				format.json {render :text => MultiJson.encode(smushset.uniq.reverse) || ""}
			end
	end

	def dj
		respond_to do |format|
			format.html {render :text => Delayed::Backend::Mongoid::Job.count}
		end
	end

	def gs
		session["gs"] = "true"

		redirect_to "/auth/#{params[:provider]}"
	end

	def about
		@title = "About"

		# expires_in 1.hour
	end

	# def explore
	# 	@title = "Explore"
	# end

	def goodies
		@title = "Goodies"
	end

	def united
		@title = "United We Teach"

		# expires_in 1.hour
	end

	def team
		@title = "Team"

		# expires_in 1.hour
	end

	def press
		@title = "Claco Press Kit"
	end

	def privacy
		@title = "Privacy Policy"

		render "public/legal.html"#, :status => 200 and return
	end

	def tos
		@title = "Terms of Service"

		render "public/tos.html"#, :status => 200 and return
	end

	def bookmarklet
		@title = "Add Web Bookmark"

		@root = current_teacher.binders.root_binders
	end

	def search

		if params[:q].present?
			#@teachers = Teacher.all.tire.search(params[:query], load: true)
			@teachers = Tire.search 'teachers' do |search|
				#query do

				# number of results returned
				search.size 30

				search.query do |query|
					#string 'fname:S*'
					#query.size 15
					if params[:q].to_s.split(' ').size>1
						query.string "#{params[:q]}"
					else
						query.string "#{params[:q]}*"
					end
				end
				#query { all } 
			end

			#debugger

			@teachers=@teachers.results.to_a

			#debugger

			if @teachers.map { |f| f.id.to_s }.include? current_teacher.id.to_s
				@teachers = @teachers.unshift @teachers.delete_at( @teachers.index { |f| f.id.to_s==current_teacher.id.to_s } )
			end
		else
			@teachers = []#Teacher.all
		end

		#@teachers = Teacher.all[0..2]

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					'',
					params)

		render "search"

	end

	def teachersearch

		# if params[:query].present?
		# 	#@teachers = Teacher.all.tire.search(params[:query], load: true)
		# 	@teachers = Tire.search 'teachers' do |search|
		# 		#query do

		# 		# number of results returned
		# 		search.size 100

		# 		search.query do |query|
		# 			#string 'fname:S*'
		# 			#query.size 15
		# 			query.string params[:query]
		# 		end
		# 		#query { all } 
		# 	end

		# 	@teachers=@teachers.results
		# else
		# 	@teachers = Teacher.all
		# end

		# #Rails.logger.debug "<<< TEACHERS RETURNED >>>"
		# #Rails.logger.debug @teachers.size.to_s

		# #retstr=""

		# #debugger

		# # @teachers.each do |t|
		# # 	retstr += t.fname + ' ' + t.lname + '<br />'
		# # end

		# respond_to do |format|
		# 	format.html {render :text => retstr}
		# end

	end

	def subscribedlog

		subs = (current_teacher.relationships.where(:subscribed => true).entries).map { |r| r["user_id"].to_s } 

		@feed = Tire.search 'logs' do |search|

			search.query do |query|
				#query.string params[:q]

				query.all

				#search.size 40
			end

			search.filter :terms, :model => ['binders','teachers']
			search.filter :terms, :method => FEED_METHOD_WHITELIST
			search.filter :terms, :ownerid => subs + [current_teacher.id.to_s]

			search.size 40

			search.sort { by :timestamp, 'desc' }

		end
		@feed = @feed.results

		retstr = ''
		
		@feed.each do |f|
			retstr += Teacher.find(f.ownerid.to_s).full_name + ' - ' + f[:method] + '<br />'# + ' ' + f.ownerid.to_s + '<br />'
		end

		respond_to do |format|
			format.html { render :text => retstr }
		end
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
