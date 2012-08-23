class HomeController < ApplicationController
	before_filter :authenticate_teacher!, :except => [:index, :autocomplete]

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

					# push onto the feed if the node is not deleted
					binder = Binder.find(f.modelid.to_s)

					if binder.parents[0]!={ "id" => "-1", "title" => "" } && binder.is_pub?
						if !( @feed.map { |g| [g[:log].ownerid,g[:log].method,g[:log].controller,g[:log].modelid,g[:log].params,g[:log].data] }.include? [f.ownerid,f.method,f.controller,f.modelid,f.params,f.data] ) && ( f.method=="setpub" ? ( f.params["enabled"]=="true" ) : true )
							if (subs.include? f.ownerid.to_s) || (f.ownerid.to_s == current_teacher.id.to_s)
								f = { :binder => binder, :owner => Teacher.find(f.ownerid.to_s), :log => f }
								@feed << f if @feed.size < 30
								@subsfeed << f
							else
								c = (@feed.reject { |h| h[:log].ownerid.to_s!=f.ownerid.to_s }).size
								# limit occupancy of non-subscibed teachers to 6
								if c<6
									@feed << { :binder => binder, :owner => Teacher.find(f.ownerid.to_s), :log => f } if @feed.size < 30
								end
							end
						end
					end
					break if @feed.size == 30 && @subsfeed.size == 30
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

end