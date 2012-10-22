class NomineesController < ApplicationController
	before_filter :authenticate_admin!, :only => [:approve, :deny]

	def create

		nom = Nominee.new(params[:nominee])

		nom.save

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