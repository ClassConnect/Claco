module BinderHelper
	#def check_box_value(index)
	#	current_teacher.tag.grade_levels[index]
	#end

	#Function that returns routing given a binder object and action
	#Only works for routes in the format of: /username/portfolio(/root)/title/id/action(s)
	#Binder objects preferred over ids
	def named_binder_route(binder, action = "show")

		# return "/#{binder.handle}/portfolio#{binder.parents.length == 1 ? 
		# 										String.new : 
		# 										"/" + CGI.escape(binder.root)
		# 									}/#{CGI.escape(binder.title)}/#{binder.id}#{action == "show" ? 
		# 																					String.new : 
		# 																					"/#{action}"
		# 																				}" if binder.class == Binder

		if binder.class == Binder
			retstr = "/#{binder.handle}/portfolio"

			if binder.parents.length != 1 
				retstr += "/#{CGI.escape(binder.root)}" 
			end

			retstr += "/#{CGI.escape(binder.title)}/#{binder.id}"

			if action != "show" 
				retstr += "/#{action}" 
			end

			return retstr
		elsif binder.class == String 
			return named_binder_route(Binder.find(binder), action)
		else
			return "/500.html"
		end

		#return named_binder_route(Binder.find(binder), action) if binder.class == String

		#return "/500.html"

	end

	# def binder_check_box_value(index,type)
	# 	#if @binder.tag.grade_levels.include? grade_level_string_by_index(index)

	# 	# we don't need to unpack the arrays into sets in order to search for values, although this may help performance
	# 	if(type==0)
	# 		if (@binder.tag.node_tags|@binder.tag.parent_tags).map { |tag| ( tag["title"] if tag["type"]==type ) }.include? grade_level_string_by_index(index)
	# 			return true
	# 		end
	# 	else
	# 		if (@binder.tag.node_tags|@binder.tag.parent_tags).map { |tag| ( tag["title"] if tag["type"]==type ) }.include? subject_string_by_index(index)
	# 			return true
	# 		end
	# 	end
	# 	return false
	# 	#if @binder.nil?
	# 	#	return true
	# 	#end
	# 	#return false
	# end

	# def binder_subject_check_box_value(index)
	# 	#if @binder.tag.subjects.include? subject_string_by_index(index)

	# 	# we don't need to unpack the arrays into sets in order to search for values, although this may help performance
	# 	if (@binder.tag.node_tags|@binder.tag.parent_tags).map { |tag| (tag["title"] if tag["type"]==1 ) }.include? subject_string_by_index(index)
	# 		return true
	# 	end
	# 	return false
	# end

	# def binder_string_value(type)

	# 	ret_array = Array.new

	# 	(@binder.tag.node_tags|@binder.tag.parent_tags).each do |tag| #{ |tag| (tag["title"] if tag["type"]==2) }
	# 		ret_array << tag["title"] if tag["type"]==type
	# 	end

	# 	return ret_array.join(' ')

	# end

	# def binder_other_string_value

	# 	#(@binder.tag.node_tags|@binder.tag.parent_tags).map  |tag| do #{ |tag| (tag["title"] if tag["type"]==3) }
	# 	(@binder.tag.node_tags|@binder.tag.parent_tags).each do |tag| #{ |tag| (tag["title"] if tag["type"]==2) }
	# 		ret_str += "#{tag["title"]} " if tag["type"]==3
	# 	end

	# end
end
