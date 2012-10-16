module BinderHelper
	#def check_box_value(index)
	#	current_teacher.tag.grade_levels[index]
	#end


	#Function that returns routing given a binder object and action
	#Only works for routes in the format of: /username/portfolio(/root)/title/id/action(s)
	#Binder objects preferred over ids
	def named_binder_route(binder, action = "show")
		if binder.class == Binder
			retstr = "/#{binder.handle}/portfolio"

			if binder.parents.length != 1 
				retstr += "/#{CGI.escape(binder.root.gsub(" ", "-"))}"
			end

			retstr += "/#{CGI.escape(binder.title.gsub(" ", "-"))}/#{binder.id}"

			if action != "show" 
				retstr += "/#{action}" 
			end

			return retstr
		elsif binder.class == String 
			return named_binder_route(Binder.find(binder), action)
		else
			return "/500.html"
		end
	end

	def zenframe(binder)

		return "#{named_binder_route(binder)}/video"

	end
end
