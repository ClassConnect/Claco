class MediaServerApiController < ApplicationController

	def addthumbs

		#debugger

		errors = []

		# thumbs is an array of all the thumbnail URLs
		# model is an array of the model name, as a string, and the model id, as a string

		#debugger

		Mongo.log(	'',
					__method__.to_s,
					params[:controller].to_s,
					'',
					params)

		if !params[:thumbs] || !params[:model] || !params[:datahash]
			errors << 'Invalid parameter set'
		elsif Digest::MD5.hexdigest(params[:thumbs].to_s + params[:model].to_s + RX_PRIVATE_KEY) != params[:datahash]
			errors << 'Invalid key'
		end

			
		case params[:model][0]
		when 'binder'
			# get version corresponding to thumbs
			model = Binder.find(params[:model][1]).versions.reject { |f| f.id.to_s != params[:model][2] }.first
			errors << 'Referenced version not found' if model.nil?
		when 'teacher'
			#debugger
			model = Teacher.find(params[:model][1]).info
		end

		if errors.any?
			respond_to do |format|
				format.json { render :text => MultiJson.encode({ :status => 0, :errors => errors }) }
			end
		else

			#model.update_attributes(:thumbnails => params[:thumbs])


			case params[:model][0]
			when 'binder'
				model.update_attributes(:thumbnails => params[:thumbs])
			when 'teacher'
				# must call save on the root class to enable ElasticSearch callbacks

				stathash = model.avatarstatus
				stathash['avatar_thumb_lg']['scheduled'] = false
				stathash['avatar_thumb_mg']['scheduled'] = false
				stathash['avatar_thumb_md']['scheduled'] = false
				stathash['avatar_thumb_sm']['scheduled'] = false
				stathash['avatar_thumb_lg']['generated'] = true
				stathash['avatar_thumb_mg']['generated'] = true
				stathash['avatar_thumb_md']['generated'] = true
				stathash['avatar_thumb_sm']['generated'] = true

				model.update_attributes(:avatarstatus => stathash)

				model.thumbnails = params[:thumbs]
				#model.update_attribute(:thumbnails,params[:thumbs])
				model.teacher.save
			end

			respond_to do |format|
				#format.html {render :text => "PARAMS: #{params.to_s}, taskid: #{task.id.to_s}" }
				#format.html {render :text => "PARAMS: #{params.to_s}" }
				format.json { render :text => MultiJson.encode({ :status => 1 }) }
			end
		end
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
