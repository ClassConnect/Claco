class HomeController < ApplicationController
	before_filter :authenticate_teacher!, :except => [:index, :autocomplete, :tos, :privacy]

	def index
		@title = "Home Page"
		@teachers = Teacher.all

		@feed = []
		@subsfeed = []

		if signed_in?

			# pull logs of relevant content, sort them, iterate through them, break when 10 are found
			logs = Log.where( :model => "binders", "data.src" => nil  ).in( method: FEED_METHOD_WHITELIST ).desc(:timestamp)

			# pull the current teacher's subscription IDs
			subs = (current_teacher.relationships.where(:subscribed => true).entries).map { |r| r["user_id"].to_s } 

			if logs.any?
				logs.each do |f|
					begin
						binder = Binder.find(f.modelid.to_s)
					rescue
						Rails.logger.fatal "Invalid binder ID!"
						next
					end

					# push onto the feed if the node is not deleted
					if binder.parents[0]!={ "id" => "-1", "title" => "" } && binder.is_pub?
						if !( @feed.map { |g| [g[:log].ownerid,g[:log].method,g[:log].controller,g[:log].modelid,g[:log].data] }.include? [f.ownerid,f.method,f.controller,f.modelid,f.data] ) && ( f.method=="setpub" ? ( f.params["enabled"]=="true" ) : true )
							
							c = (@feed.reject { |h| h[:log].ownerid.to_s!=f.ownerid.to_s }).size

							if (subs.include? f.ownerid.to_s) || (f.ownerid.to_s == current_teacher.id.to_s)
								if c < 10
									f = { :binder => binder, :owner => Teacher.find(f.ownerid.to_s), :log => f }
									# @feed << f if @feed.size < MAIN_FEED_LENGTH
									# subsfeed will always be filled simultaneously or first, check anyway
									@subsfeed << f# if @subsfeed.size < SUBSC_FEED_LENGTH
								end
							else
								# limit occupancy of non-subscibed teachers to 6
								# if c < 6 && @feed.size < MAIN_FEED_LENGTH
								# 	@feed << { :binder => binder, :owner => Teacher.find(f.ownerid.to_s), :log => f }
								# end
							end
						end
					end
					break if @subsfeed.size == SUBSC_FEED_LENGTH
				end
			end
		end
	end

	def fetchtitle
		
		f = Nokogiri::HTML(params[:url]).at('iframe')

		if f.nil?

			title = Nokogiri::HTML(RestClient.get(params[:url])).title.strip.squeeze(' ')

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

	def privacy
		render "public/legal.html"#, :status => 200 and return
	end

	def tos
		render "public/tos.html"#, :status => 200 and return
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
					query.string "#{params[:q]}*"
				end
				#query { all } 
			end

			@teachers=@teachers.results.to_a

			if @teachers.map { |f| f.id.to_s }.include? current_teacher.id.to_s
				@teachers = @teachers.unshift @teachers.delete_at( @teachers.index { |f| f.id.to_s==current_teacher.id.to_s } )
			end
		else
			@teachers = []#Teacher.all
		end

		#debugger

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
							:data => data,
							:feedhash => Digest::MD5.hexdigest(ownerid.to_s+method.to_s+modelid.to_s+params.to_s+data.to_s))

			log.save

			return log.id.to_s

		end
	end
end