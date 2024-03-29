class ApplicantsController < ApplicationController
	before_filter :authenticate_admin!, :only => [:show, :approve, :deny]
	def apply

		@title = "Request an invite"

		@app = Applicant.new

	end

	def create

		@title = "Request an invite"

		@app = Applicant.new(params[:applicant])

		@app.update_attributes(:timestamp => Time.now.to_i)

		render :apply and return if !@app.errors.empty?

	end

	def approve

		app = Applicant.find(params[:id])

		app.approve

		redirect_to apps_path
	end

	def deny

		app = Applicant.find(params[:id])

		app.deny

		redirect_to apps_path
	end

	def show

		@app = Applicant.find(params[:id])

	end

	###############################################################################################

							#    #  ##### #     #####  ##### #####   #### 
							#    #  #     #     #    # #     #    # #    #
							#    #  #     #     #    # #     #    # # 
							######  ####  #     #####  ####  #####   ####
							#    #  #     #     #      #     #  #        #
							#    #  #     #     #      #     #   #  #    #
							#    #  ##### ##### #      ##### #    #  ####

	###############################################################################################

	module Mongo
		extend self

		def log(ownerid,method,model,modelid,params,data = {})

			log = Log.new( 	:ownerid => ownerid.to_s,
							:timestamp => Time.now.to_f,
							:method => method.to_s,
							:model => model.to_s,
							:modelid => modelid.to_s,
							:params => params,
							:data => data,
							:actionhash => Digest::MD5.hexdigest(ownerid.to_s+method.to_s+modelid.to_s))

			log.save

			return log.id.to_s

		end
	end

end