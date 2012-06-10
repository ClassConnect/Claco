class HomeController < ApplicationController
	before_filter :authenticate_user!, :except => :index

	def index
		@title = "Home Page"
		@teachers = Teacher.all
	end
end
