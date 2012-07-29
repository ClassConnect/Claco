class HomeController < ApplicationController
	before_filter :authenticate_teacher!, :except => [:index, :autocomplete]

	def index
		@title = "Home Page"
		@teachers = Teacher.all
	end

	def gettitle
		open(URI.parse(params[:url].to_s).to_s).read =~ /<title>(.*?)<\/title>/

		respond_to do |format|
			format.html {render :text => $1}
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
