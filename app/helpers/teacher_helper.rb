module TeacherHelper
#	def full_name(teacher)
#		"#{teacher.fname teacher.lname}"
#	end

	def grade_level_title_by_index(index)
		case index
			when 0
				return "Preschool"
			when 1
				return "Pre-Kindergarten"
			when 2
				return "Kindergarten"
			when (3..14)
				return "#{(index-2).ordinalize} Grade"
			when 15
				return "Preparatory"
			when 16
				return "BS/BA"
			when 17
				return "Masters"
			when 18
				return "PhD"
			when 19
				return "Post-Doctorate"
		end
		# otherwise,
		return "Invalid index!"
	end

	def check_box_value(index)
		current_teacher.tag.grade_levels[index]
	end

	def test_helper
		true
	end
end
