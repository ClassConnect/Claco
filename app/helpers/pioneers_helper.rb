module PioneersHelper
	def pioneer_route(binder)
		if binder.class == Binder && binder.parent["id"] == Setting.f("pioneer").v
			return "/pioneers/#{CGI.escape(binder.title.gsub(" ", "-"))}/#{binder.id.to_s}"
		end
	end 
end