class AdminController < ApplicationController
	before_filter :authenticate_admin

	def viewapps

		@apps = Applicant.all

	end

	

protected

	def authenticate_admin

		render "public/404.html", :status => 404 unless signed_in? && current_teacher.admin

	end

end