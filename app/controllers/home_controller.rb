class HomeController < ApplicationController
	before_filter :authenticate_teacher!, :except => [:index, :autocomplete]

	def index
		@title = "Home Page"
		@teachers = Teacher.all

		@testvar = "it worked!"

		# find binders where:
		# => not owned by the current teacher
		# => not deleted
		#
		#@feed = Binder.where( :owner.ne => current_teacher.id.to_s, "parents.id" => { "$ne" => "-1"}).desc(:last_update).limit(10)#, "last_update" => { "$gte" => Time.now-24.hours }  ).desc(:last_update).limit(10)
		@feed = []
		#blacklist = []

		if signed_in?

		# pull logs of relevant content, sort them, iterate through them, break when 10 are found
		#logs = Log.where( :ownerid.ne => current_teacher.id.to_s, :model => "binders", "data.src" => nil  ).in( method: ["create","createfile","createcontent","update","updatetags","setpub"] ).desc(:timestamp)
		logs = Log.where( :model => "binders", "data.src" => nil  ).in( method: ["create","createfile","createcontent","update","updatetags","setpub"] ).desc(:timestamp)

		if logs.any?
			logs.each do |f|

				# push onto the feed if the node is not deleted
				binder = Binder.find(f.modelid.to_s)

				if binder.parents[0]!={ "id" => "-1", "title" => "" } && binder.get_access(current_teacher.id.to_s) > 0

					if !( @feed.map { |g| [g.ownerid,g.method,g.controller,g.modelid,g.params,g.data] }.include? [f.ownerid,f.method,f.controller,f.modelid,f.params,f.data] ) &&
						( f.method=="setpub" ? ( f.params["enabled"]=="true" ) : true )
				
						#@feed.each do |f|

						#c = (@feed.reject { |h| h.ownerid.to_s!=f.ownerid.to_s }).size #&& Time.now.to_i-f.timestamp.to_i<1.hour 

						#Rails.logger.debug "FEEDARR #{@feed}"#.map { |h| f if h.ownerid.to_s==f.ownerid.to_s }}"  

						#if c<8

							#if c==3
							#	if (@feed[-1].ownerid.to_s == f.ownerid.to_s) && (@feed[-2].ownerid.to_s == f.ownerid.to_s) && (@feed[-3].ownerid.to_s == f.ownerid.to_s)
							#		f[:full] = true
							#	end
							#end

							@feed << f
						#elsif c==3
							#blacklist << f.ownerid.to_s
							#f[:full] = true
							#@@feed << f
							#Rails.logger.debug "FULLSYM #{f.inspect.to_s}"
						#else

						#end
					end
				end

				break if @feed.size == 40

			end
		end

		# the array should already be sorted
		# .sort_by { |e| -e.timestamp }
		@feed = @feed.any? ? @feed.map{ |f| {:binder => Binder.find( f.modelid.to_s ), :owner => Teacher.find( f.ownerid.to_s ), :log => f } } : []

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
				format.html {render :text => title[0..49] || " "}
			end
	end

	def autocomplete

		#@results = RestClient.post('http://localhost:3000/sm/search', :types => 'venue', :term => 'an' ) #'http://localhost:3000/sm/search?types[]=venue&term=an'

		#@results = RestClient.get('http://localhost:3000/sm/search?types[]=venue&term=an')



		#@results = Soulmate::EmulatedServer.new

		auto = Soulmate::EmulatedServer.new

		#@results = auto.search({ 'types[]' => 'venue', 'term' => 'an' })
		@results = JSON.pretty_generate(JSON.parse(auto.search(params)))

		@test = JSON.pretty_generate(JSON.parse(File.read("app/assets/json/standards.json")))  #URI.encode_www_form({ 'types' => ['venue','other'], 'term' => 'an' })

		#mount Soulmate::Server

		#@test = Soulmate::Server

		#@results = @test.class

	end

end
