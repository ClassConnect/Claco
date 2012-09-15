class MediaServerApiController < ApplicationController

	def tokencheck

		error = ''

		#debugger

		begin
			binder = Binder.find(params[:id].to_s)

			if binder.current_version.nil? || binder.current_version.imgfile.nil?
				error = 'Could not service request - undefined image path'
			elsif binder.current_version.media_server_token != params[:token].to_s
				error = 'Could not service request - invalid token' 
			end
		rescue
			error = 'Could not service request - invalid binder ID'
		ensure
			respond_to do |format|
				if error.empty?
					format.json { render :text => MultiJson.encode({ :path => binder.current_version.imgfile.url })}
				else
					format.json { render :text => MultiJson.encode({ :error => error }) }
				end
			end
		end
	end

end
