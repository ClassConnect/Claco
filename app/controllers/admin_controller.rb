class AdminController < ApplicationController
	before_filter :authenticate_admin

	def sendinvite

		Invitation.new(	:from => "0",
						:to => params[:to],
						:submitted => Time.now.to_i).save

		redirect_to "/admin"

	end

	def invites

		@invites = Invitation.all

	end

	def showinv

		@invite = Invitation.find(params[:id])

	end

	def apps

		@apps = Applicant.all

	end

	def users

		@teachers = Teacher.all

	end

	def sysinvlist

		@invs = Setting.f("sys_inv_list").v

	end

	def choosepibinder

		@pibinder = Setting.f("pioneer").v

	end

	def setpibinder

		Setting.f("pioneer").v = params[:binder]

	end

	def setfeatured

		Setting.f("featured").v = [] if Setting.f("featured").v.nil?

		Setting.f("featured").v = Setting.f("featured").v << params[:binder]

		redirect_to "/admin"

	end

	def choosefpfeatured

		@fpfeatured = Setting.f("fpfeatured").v

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