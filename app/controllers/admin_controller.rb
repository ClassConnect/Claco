class AdminController < ApplicationController
	before_filter :authenticate_admin!

	def sendinvite

		Invitation.new(	:from		=> "0",
						:to			=> params[:to],
						:submitted	=> Time.now.to_i).save

		redirect_to "/admin"

	end

	def invites

		@invites = Invitation.page(params[:page]).per(100)

	end

	def showinv

		@invite = Invitation.find(params[:id])

	end

	def apps

		@apps = Applicant.page(params[:page]).per(100)

	end

	def ghost
		sign_in(:teacher, Teacher.find(params[:id]))
		redirect_to root_url
	end

	def users

		@teachers = Teacher.page(params[:page]).per(100)

	end

	# Concurrency fix
	# Setting.f("sys_inv_list").v = Setting.f("sys_inv_list").v.map{|e| i = Invitation.where(:to => e["email"]).first; e["invited_at"] = i.submitted unless i.nil?; e["invited"] = true unless i.nil?; e}
	
	def sysinvlist

		@invs = Setting.f("sys_inv_list").v

	end

	def choosepibinder

		@pibinder = Setting.f("pioneer").v

	end

	def setpibinder

		Setting.f("pioneer").v = params[:binder]

		redirect_to "/admin"

	end

	def setfeatured

		Setting.f("featured").v = [] if Setting.f("featured").v.nil?

		Setting.f("featured").v = Setting.f("featured").v << params[:binder]

		redirect_to "/admin"

	end

	def choosefpfeatured

		@fpfeatured = Setting.f("fpfeatured").v || []

	end

	def setfpfeatured

		Setting.f("fpfeatured").v = [] if Setting.f("fpfeatured").v.nil?

		Setting.f("fpfeatured").v = Setting.f("fpfeatured").v << {	"top" => params[:binder1],
																	"bot" => params[:binder2],
																	"time" => Time.now.to_i}

		expire_fragment('publichome')

		redirect_to "/admin"

	end

end