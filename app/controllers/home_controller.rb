class HomeController < ApplicationController
	before_filter :authenticate_user!, :except => [:show, :index]

	def index
		@title = "Home Page"
		@teachers = Teacher.all
	end
end
