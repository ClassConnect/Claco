class PioneersController < ApplicationController

	def index

		@pibinders = Binder.find(Setting.f("pioneer").v).children.sort_by(&:order_index).reverse

		@current = @pibinders.first

		@title = "Pioneers - #{@current.title}"

		render "pioneers"

	end

	def show

		@current = Binder.find(params[:id])

		@title = "Pioneers - #{@current.title}"

		@pibinders = Binder.find(Setting.f("pioneer").v).children.sort_by(&:order_index).reverse

		redirect_to pioneer_route(@current), :status => 301 and return unless pioneer_routing_ok?(@current)

		render "pioneers"

		rescue BSON::InvalidObjectId
			render "errors/not_found", :status => 404 and return
		rescue Mongoid::Errors::DocumentNotFound
			render "errors/not_found", :status => 404 and return

	end

protected
	def pioneer_routing_ok?(binder)

		return request.path[0..pioneer_route(binder).size - 1] == pioneer_route(binder)

	end

	def pioneer_route(binder)
		if binder.class == Binder && binder.parent["id"] == Setting.f("pioneer").v
			return "/pioneers/#{CGI.escape(binder.title.gsub(" ", "-"))}/#{binder.id.to_s}"
		end
	end

end