module ApplicationHelper


	# passed the index of the checkbox and the type of checkbox
	# returns a boolean representing if the checkbox should be checked or not
	def binder_check_box_value(index,type)

		# we don't need to unpack the arrays into sets in order to search for values, although this may help performance
		if(type==0)
			if (@binder.tag.node_tags|@binder.tag.parent_tags).map { |tag| ( tag["title"] if tag["type"]==type ) }.include? grade_level_string_by_index(index)
				return true
			end
		else
			if (@binder.tag.node_tags|@binder.tag.parent_tags).map { |tag| ( tag["title"] if tag["type"]==type ) }.include? subject_string_by_index(index)
				return true
			end
		end
		return false
	end

	# passed the type of binder tag
	# returns the string to be placed inside the text field
	def binder_string_value(type)

		ret_array = Array.new

		(@binder.tag.node_tags|@binder.tag.parent_tags).each do |tag|
			ret_array << tag["title"] if tag["type"]==type
		end

		return ret_array.join(' ')

	end

	# returns path to subscribe
	def get_subscription_path()
		if !current_teacher.subscribed_to?(@teacher.id)
			return confsub_path(@teacher)
		else
			return confunsub_path(@teacher)
		end
	end

	# passed the form helper object
	# returns appropriate subscription button
	def get_subscription_button(f)
		if !current_teacher.subscribed_to?(@teacher.id)
			#return "Subscribe to #{@teacher.full_name}"
			f.submit "Subscribe to #{@teacher.full_name}", :confirm => 'Are you sure?'
		else
			#return "Unsubscribe from #{@teacher.full_name}"
			f.submit "Unsubscribe from #{@teacher.full_name}", :confirm => 'Are you sure?'
		end
	end

	# returns path to colleague
	def get_colleague_path()
		case current_teacher.colleague_status(@teacher.id)
			# 2 returns an unused dummy URL
			when (0..2)
				return confadd_path(@teacher.id.to_s)
			when 3
				return confremove_path(@teacher.id.to_s)
		end
	end

	# passed the form helper object
	# returns the button to be shown
	def get_colleague_button(f)
		case current_teacher.colleague_status(@teacher.id)
			when 0
				f.submit "Add #{@teacher.full_name} as a colleague", :confirm => 'Are you sure?'
			when 1
				f.submit "Colleague request sent", :disabled => true
			when 2
				f.submit "Accept colleague request from #{@teacher.full_name}", :confirm => 'Are you sure?'
			when 3
				f.submit "Remove #{@teacher.full_name} from colleagues", :confirm => 'Are you sure?'
		end

	end

	# passed the index of the grade level
	# returns a human-readable version from the index
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

	# passed the index of the grade level
	# returns the tiny string to be stored in the database (is readable, but saves space)
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

	# passed the index of the subject
	# returns a human-readable version from the index
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

	# passed the index of the subject
	# returns the tiny string to be stored in the database (is readable, but saves space)
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

	# returns the check box "checked" value based on the index
	def grade_level_check_box_value(index)
		if current_teacher.tag.grade_levels.include? grade_level_string_by_index(index)
			return true
		end
		return false
	end

	# returns the check box "checked" value based on the index
	def subject_check_box_value(index)
		if current_teacher.tag.subjects.include? subject_string_by_index(index)
			return true
		end
		return false
	end

	# passed index of current node
	# returns array of nodes to print in the quasi-filetree
	def print_children(index)
		for i in (0..(@binder_file_tree_array[index].length-1))

			node = @binder_file_tree_array[index][i]

				@retarray << [	node.id.to_s,
								node.title,
								index,
								node.format.to_i,
								node.versions]

			if @binder_parent_id_array.include? @binder_file_tree_array[index][i].id.to_s
				@retarray += print_children(index + 1)
			end
		end
		return @retarray.uniq
	end

	# passed a teacher object, and a hash of the image options
	# returns an image tag with the inserted options
	def get_teacher_avatar(teacher,options)

		if teacher.info.nil? || teacher.info.avatar.size==0
			return "<no profile picture>"
		elsif options.empty?
			return image_tag( "#{teacher.info.avatar}" )
		else
			return image_tag( "#{teacher.info.avatar}", options )
		end

	end

end
