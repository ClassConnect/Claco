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
		@feed = Binder.where( :owner.ne => current_teacher.id.to_s, "parents.id" => { "$ne" => "-1"}).desc(:last_update).limit(10)#, "last_update" => { "$gte" => Time.now-24.hours }  ).desc(:last_update).limit(10)

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