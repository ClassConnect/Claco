class NomineesController < ApplicationController
	before_filter :authenticate_admin!, :only => [:approve, :deny]

	def create

		render :nothing => true, :status => 406 and return if params[:inviter].blank?

		params[:emails].each do |email|

			Nominee.new(:from => params[:inviter], :email => email).save unless email.blank?

		end

		render :text => "1"

	end

	def approve

		nom = Nominee.find(params[:id])

		nom.approve

		redirect_to nominees_path

	end

	def deny

		nom = Nominee.find(params[:id])

		nom.deny

		redirect_to nominees_path

	end

end