module BinderHelper
	#def check_box_value(index)
	#	current_teacher.tag.grade_levels[index]
	#end

	def binder_grade_level_check_box_value(index)
		if @binder.tag.grade_levels.include? grade_level_string_by_index(index)
			return true
		end
		return false
		#if @binder.nil?
		#	return true
		#end
		#return false
	end

	def binder_subject_check_box_value(index)
		if @binder.tag.subjects.include? subject_string_by_index(index)
			return true
		end
		return false
	end
end
