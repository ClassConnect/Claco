class ErrorsController < ApplicationController

	def not_found
		@title = "The page you were looking for doesn't exist. (404)"

		render :status => 404
	end

	def forbidden
		@title = "You are forbidden from accessing this page. (403)"

		render :status => 403
	end

end