class MediaServerApiController < ApplicationController

	def addthumbs

		errors = []

		# thumbs is an array of all the thumbnail URLs
		# model is an array of the model name, as a string, and the model id, as a string

		#debugger

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
			model = Teacher.find(params[:model][1]).info
		end

		if errors.any?
			respond_to do |format|
				format.json { render :text => MultiJson.encode({ :status => 0, :errors => errors }) }
			end
		else

			model.update_attributes(:thumbnails => params[:thumbs])

			respond_to do |format|
				#format.html {render :text => "PARAMS: #{params.to_s}, taskid: #{task.id.to_s}" }
				#format.html {render :text => "PARAMS: #{params.to_s}" }
				format.json { render :text => MultiJson.encode({ :status => 1 }) }
			end
		end
	end
end
