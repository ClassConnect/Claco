class HomeController < ApplicationController
	before_filter :authenticate_teacher!, :except => [:index, :autocomplete]

	def index
		@title = "Home Page"
		@teachers = Teacher.all

		#@testvar = "it worked!"

		# find binders where:
		# => not owned by the current teacher
		# => not deleted
		#
		#@feed = Binder.where( :owner.ne => current_teacher.id.to_s, "parents.id" => { "$ne" => "-1"}).desc(:last_update).limit(10)#, "last_update" => { "$gte" => Time.now-24.hours }  ).desc(:last_update).limit(10)

		#blacklist = []

		if signed_in?

			current_teacher.feed = Feed.new if current_teacher.feed.nil?

			@feed = []
			@subsc_feed = []

			#@feed = current_teacher.feed.main_feed
			#@subsc_feed = current_teacher.feed.subsc_feed

			# pull logs of relevant content, sort them, iterate through them, break when 10 are found
			#logs = Log.where( :ownerid.ne => current_teacher.id.to_s, :model => "binders", "data.src" => nil  ).in( method: ["create","createfile","createcontent","update","updatetags","setpub"] ).desc(:timestamp)
			logs = Log.where( :model => "binders", "data.src" => nil, :timestamp.gt => [current_teacher.feed.headtime(0).to_i,current_teacher.feed.headtime(1).to_i].min ).in( method: ["create","createfile","createcontent","update","updatetags","setpub"] ).desc(:timestamp)

			subs = (current_teacher.relationships.where(:subscribed => true).entries).map { |r| r["user_id"].to_s } 

			if logs.any?
				logs.each do |f|

					# push onto the feed if the node is not deleted
					binder = Binder.find(f.modelid.to_s)

					if binder.parents[0]!={ "id" => "-1", "title" => "" } && binder.is_pub?#(current_teacher.id.to_s==f.ownerid.to_s ? binder.is_pub? : (binder.get_access(signed_in? ? current_teacher.id.to_s : 0)))

						# eliminate redundant entries in feed
						if !( @feed.map { |g| [g[0].ownerid,g[0].method,g[0].controller,g[0].modelid,g[0].params,g[0].data] }.include? [f.ownerid,f.method,f.controller,f.modelid,f.params,f.data] ) &&
							( f.method=="setpub" ? ( f.params["enabled"]=="true" ) : true )

							# current_teacher is subscribed to the entry's owner, unlimited entries
							if (subs.include? f.ownerid.to_s) || (f.ownerid.to_s == current_teacher.id.to_s)

								# migrate individual DB calls here
								#f = 

								@feed << [f,binder] if @feed.size < MAIN_FEED_STORAGE

								@subsc_feed << [f,binder] if @subsc_feed.size < SUBSC_FEED_STORAGE
							
							else
								c = (@feed.reject { |h| h.ownerid.to_s!=f.ownerid.to_s }).size

								if c<6
									@feed << [f,binder] if @feed.size  < MAIN_FEED_STORAGE
								end
							end
						end
					end

					break if (@feed.size == MAIN_FEED_STORAGE) && (@subfeed.size == SUBSC_FEED_STORAGE)

				end
			end

			@feed = current_teacher.feed.multipush(@feed,0)

			@subsc_feed = current_teacher.feed.multipush(@subsc_feed,1)

			teacherhash = {}

			((@feed.map{ |f| f[0][:ownerid].nil? ? f[0]['ownerid'].to_s : f[0][:ownerid].to_s })|(@subsc_feed.map{ |g| g[0][:ownerid].nil? ? g[0]['ownerid'].to_s : g[0][:ownerid].to_s })).each do |h|
				teacherhash[h.to_s] = Teacher.find( h.to_s )
			end

			# the array should already be sorted
			# .sort_by { |e| -e.timestamp }								haha, BLT
			@feed = @feed.any? ? @feed.reverse.map{ |f| { 	:binder => 	f[1],#Binder.find( f[:modelid].nil? ? f['modelid'].to_s : f[:modelid].to_s ),
															:log => 	f[0],#Log.find( f[:id].nil? ? f['id'].to_s : f[:id].to_s ),
															#:owner => 	Teacher.find( f[0][:ownerid].nil? ? f[0]['ownerid'].to_s : f[0][:ownerid].to_s) } }.first(MAIN_FEED_LENGTH) : []
															:owner => 	teacherhash[f[0][:ownerid].nil? ? f[0]['ownerid'].to_s : f[0][:ownerid].to_s]} }.first(MAIN_FEED_LENGTH) : []

			@subsc_feed = @subsc_feed.any? ? @subsc_feed.reverse.map{ |f| { :binder => 	f[1],#Binder.find( f[:modelid].nil? ? f['modelid'].to_s : f[:modelid].to_s ),
																			:log => 	f[0],#Log.find( f[:id].nil? ? f['id'].to_s : f[:id].to_s ),
																			#:owner => 	Teacher.find( f[0][:ownerid].nil? ? f[0]['ownerid'].to_s : f[0][:ownerid].to_s) } }.first(MAIN_FEED_LENGTH) : []
																			:owner => 	teacherhash[f[0][:ownerid].nil? ? f[0]['ownerid'].to_s : f[0][:ownerid].to_s]} }.first(SUBSC_FEED_LENGTH) : []

			
		end

		#Binder.where( "parent.id" => { '$gt' }  )
		#Binder.all.ne( parent.id: [0,-1] )

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

end