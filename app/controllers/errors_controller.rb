class ErrorsController < ApplicationController

	def not_found
		@title = "The page you were looking for doesn't exist. (404)"

		respond_to do |format|
			format.html {render :status => 404}
			format.any {render :nothing => true, :status => 404}
		end
	end

	def forbidden
		@title = "You are forbidden from accessing this page. (403)"

		respond_to do |format|
			format.html {render :status => 403}
			format.any {render :nothing => true, :status => 403}
		end
	end

end