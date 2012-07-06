module TeacherHelper
#	def full_name(teacher)
#		"#{teacher.fname teacher.lname}"
#	end

# 	# function unused, doesn't work
# 	def display_incoming_colleague_requests
# 		if @colleague_requests.any?
# 			raw("<p>You have pending colleague requests!</p>")
# 			@colleague_requests.each do |request|
# 				form_for request, :url => confadd_path(request.user_id) do |f|
# 					f.submit "Accept colleague request from #{Teacher.find(request.user_id).full_name}", :confirm => "Are you absofuckinlutely positve?"
# 				end

# 				#link_to "Accept colleague request from #{Teacher.find(request.user_id).full_name}", confadd_path(request.user_id)
# 				#"#{Teacher.find(request.user_id).full_name}"
# 				#request[:user_id]
# 				#"#{@colleague_requests.count}"
# 				#link_to "Accept colleague request from #{Teacher.find(@colleague_requests.user_id).full_name}", confadd_path(@colleague_requests.user_id)
# 				#"#{request.user_id} "
# 				#@colleague_requests.size
# 				#"TEST"
# 			end
# 		end
# 		#"DERP"
# 	end

# 	def get_subscription_path
# 		if !current_teacher.subscribed_to?(@teacher.id)
# 			return confsub_path(@teacher)
# 		else
# 			return confunsub_path(@teacher)
# 		end
# 	end

# 	def get_subscription_button(f)
# 		if !current_teacher.subscribed_to?(@teacher.id)
# 			#return "Subscribe to #{@teacher.full_name}"
# 			f.submit "Subscribe to #{@teacher.full_name}", :confirm => 'Are you sure?'
# 		else
# 			#return "Unsubscribe from #{@teacher.full_name}"
# 			f.submit "Unsubscribe from #{@teacher.full_name}", :confirm => 'Are you sure?'
# 		end
# 	end

# 	def get_colleague_path
# 		case current_teacher.colleague_status(@teacher.id)
# 			# 2 returns an unused dummy URL
# 			when (0..2)
# 				return confadd_path(@teacher.id.to_s)
# 			when 3
# 				return confremove_path(@teacher.id.to_s)
# 		end
# 	end

# 	def get_colleague_button(f)
# 		case current_teacher.colleague_status(@teacher.id)
# 			when 0
# 				f.submit "Add #{@teacher.full_name} as a colleague", :confirm => 'Are you sure?'
# 			when 1
# 				f.submit "Colleague request sent", :disabled => true
# 			when 2
# 				f.submit "Accept colleague request from #{@teacher.full_name}", :confirm => 'Are you sure?'
# 			when 3
# 				f.submit "Remove #{@teacher.full_name} from colleagues", :confirm => 'Are you sure?'
# 		end

# 	end

# 	def grade_level_title_by_index(index)
# 		case index
# 			when 0
# 				return "Preschool"
# 			when 1
# 				return "Pre-Kindergarten"
# 			when 2
# 				return "Kindergarten"
# 			when (3..14)
# 				return "#{(index-2).ordinalize} Grade"
# 			when 15
# 				return "Preparatory"
# 			when 16
# 				return "BS/BA"
# 			when 17
# 				return "Masters"
# 			when 18
# 				return "PhD"
# 			when 19
# 				return "Post-Doctorate"
# 		end
# 		# otherwise,
# 		return "Invalid grade level index!"
# 	end

# 	def grade_level_string_by_index(index)
# 		case index
# 			when 0
# 				return "ps"
# 			when 1
# 				return "pk"
# 			when 2
# 				return "k"
# 			when (3..14)
# 				return "#{index-2}g"
# 			when 15
# 				return "pr"
# 			when 16
# 				return "bsba"
# 			when 17
# 				return "ms"
# 			when 18
# 				return "phd"
# 			when 19
# 				return "pd"
# 		end
# 		#otherwise
# 		return "Invalid grade level index!"
# 	end

# 	def subject_title_by_index(index)
# 		case index
# 			when 0
# 				return "Math"
# 			when 1
# 				return "Science"
# 			when 2
# 				return "Social Studies"
# 			when 3
# 				return "English / Language Arts"
# 			when 4
# 				return "Foreign Language"
# 			when 5
# 				return "Music"
# 			when 6
# 				return "Physical Education"
# 			when 7
# 				return "Health"
# 			when 8
# 				return "Dramatic Arts"
# 			when 9
# 				return "Visual Arts"
# 			when 10
# 				return "Special Education"
# 			when 11
# 				return "Technology and Engineering"
# 		end
# 		#otherwise
# 		return "Invalid subject index!"
# 	end

# 	def subject_string_by_index(index)
# 		case index
# 			when 0
# 				return "ma"
# 			when 1
# 				return "sc"
# 			when 2
# 				return "ss"
# 			when 3
# 				return "la"
# 			when 4
# 				return "fl"
# 			when 5
# 				return "mu"
# 			when 6
# 				return "pe"
# 			when 7
# 				return "he"
# 			when 8
# 				return "da"
# 			when 9
# 				return "va"
# 			when 10
# 				return "se"
# 			when 11
# 				return "te"
# 		end
# 		#otherwise
# 		return "Invalid subject index!"
# 	end

# 	#def check_box_value(index)
# 	#	current_teacher.tag.grade_levels[index]
# 	#end

# 	def grade_level_check_box_value(index)
# 		if current_teacher.tag.grade_levels.include? grade_level_string_by_index(index)
# 			return true
# 		end
# 	end

# 	def subject_check_box_value(index)
# 		if current_teacher.tag.subjects.include? subject_string_by_index(index)
# 			return true
# 		end
# 		return false
# 	end

# 	# def print_children(parent_id,parent_height)
		
# 	# 	if !(@nodechildren = Binder.where("parent.id" => parent_id))
# 	# 		FUCK
# 	# 	end

# 	# 	#if @nodechildren.any?
# 	# 		@nodechildren.count.times do
# 	# 			raw("Nigger")
# 	# 		end
# 	# 		#i = 0
# 	# 		#@nodechildren
# 	# 		#	i.to_s
# 	# 			#{}"childnode.title"
# 	# 			#<br />
# 	# 		#end
# 	# 	#end
# 	# end

# #  	@current_binder.parents[i]["id"].to_s == node.id.to_s

# 	def print_children(index)
# 		for i in (0..(@binder_file_tree_array[index].length-1))

# 			node = @binder_file_tree_array[index][i]

# 				@retarray << [	node.id.to_s,
# 								node.title,
# 								index,
# 								node.format.to_i,
# 								node.versions]

# 			if @binder_parent_id_array.include? @binder_file_tree_array[index][i].id.to_s
# 				@retarray += print_children(index + 1)
# 			end
# 		end
# 		return @retarray.uniq#.sort! { |a,b| a[3] <=> b[3] }
# 	end
end
