class AdminController < ApplicationController
	before_filter :authenticate_admin

	def index

	end

	def sendinvite

		Invitation.new(	:from => "0",
						:to => params[:to],
						:submitted => Time.now.to_i)

	end

	def invites

		@invites = Invitation.all

	end

	def viewapps

		@apps = Applicant.all

	end

	def viewusers

		@teachers = Teacher.all

	end

	def settings

	end

	def setfeatured

		Setting.f("featured").v = [] if Setting.f("featured").v.nil?

		Setting.f("featured").v = Setting.f("featured").v << params[:binder]

		redirect_to "/admin"

	end

	def setfpfeatured

		Setting.f("fpfeatured").v = [] if Setting.f("fpfeatured").v.nil?

		Setting.f("fpfeatured").v = Setting.f("fpfeatured").v << {	"top" => params[:binder1],
																	"bot" => params[:binder2],
																	"time" => Time.now.to_i}

		expire_fragment('publichome')

		redirect_to "/admin"

	end

protected

	def authenticate_admin

		render "public/404.html", :status => 404 unless signed_in? && current_teacher.admin

	end

end