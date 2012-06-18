module BinderHelper
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
		return "Invalid grade level index!"
	end

	def grade_level_string_by_index(index)
		case index
			when 0
				return "ps"
			when 1
				return "pk"
			when 2
				return "k"
			when (3..14)
				return "#{index-2}g"
			when 15
				return "pr"
			when 16
				return "bsba"
			when 17
				return "ms"
			when 18
				return "phd"
			when 19
				return "pd"
		end
		#otherwise
		return "Invalid grade level index!"
	end

	def subject_title_by_index(index)
		case index
			when 0
				return "Math"
			when 1
				return "Science"
			when 2
				return "Social Studies"
			when 3
				return "English / Language Arts"
			when 4
				return "Foreign Language"
			when 5
				return "Music"
			when 6
				return "Physical Education"
			when 7
				return "Health"
			when 8
				return "Dramatic Arts"
			when 9
				return "Visual Arts"
			when 10
				return "Special Education"
			when 11
				return "Technology and Engineering"
		end
		#otherwise
		return "Invalid subject index!"
	end

	def subject_string_by_index(index)
		case index
			when 0
				return "ma"
			when 1
				return "sc"
			when 2
				return "ss"
			when 3
				return "la"
			when 4
				return "fl"
			when 5
				return "mu"
			when 6
				return "pe"
			when 7
				return "he"
			when 8
				return "da"
			when 9
				return "va"
			when 10
				return "se"
			when 11
				return "te"
		end
		#otherwise
		return "Invalid subject index!"
	end

	#def check_box_value(index)
	#	current_teacher.tag.grade_levels[index]
	#end

#	def grade_level_check_box_value(index)
#		if current_teacher.tag.grade_levels.include? grade_level_string_by_index(index)
#			return true
#		end
#		return false
#	end

#	def subject_check_box_value(index)
#		if current_teacher.tag.subjects.include? subject_string_by_index(index)
#			return true
#		end
#		return false
#	end
end
