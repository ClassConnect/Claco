class AdminController < ApplicationController
	before_filter :authenticate_admin

	def index

	end

	def viewapps

		@apps = Applicant.all

	end

	def viewusers

		@teachers = Teacher.all

	end

protected

	def authenticate_admin

		render "public/404.html", :status => 404 unless signed_in? && current_teacher.admin

	end

end