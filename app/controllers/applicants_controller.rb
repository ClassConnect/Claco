class ApplicantsController < ApplicationController
	before_filter :authenticate_teacher!, :except => [:apply, :create]

	def apply

		@app = Applicant.new

	end

	def create

		@title = "Request an invite"

		@app = Applicant.new(params[:applicant])

		@app.update_attributes(:timestamp => Time.now.to_i)

		render "apply" and return if !@app.errors.empty?

	end

	def viewapps

		@apps = Applicant.all

	end

	def show

		@app = Applicant.find(params[:id])

	end

end