module ApplicationHelper

	#def time_ago_in_words_wrapper(data)



	#end

	def map_to_model(modelid,cachekey)

		#debugger

		keys = Rails.cache.read(modelid.to_s)

		#return if keys.nil?

		#debugger

		if keys.nil?
			Rails.cache.write(modelid.to_s,[cachekey])
		elsif !keys.include?(cachekey.to_s)
			keys << cachekey.to_s
			Rails.cache.write(modelid.to_s,keys)
		end
		
		#debugger

		#test = 1

	end

	def teacher_thumb_lg(teacher)
		ret = Teacher.thumb_lg(teacher).to_s
		if ret.empty?
			# only display the generating image if the current teacher is viewing the thumb
			#if Teacher.thumbscheduled?(teacher,'avatar_thumb_lg') && signed_in? && teacher.id.to_s == current_teacher.id.to_s
				#asset_path("profile/gen-face-170.png")
			#else
				asset_path("profile/face-170.png")
			#end
		else
			ret
		end
	end

	def teacher_thumb_mg(teacher)
		ret = Teacher.thumb_mg(teacher).to_s
		if ret.empty?
			# only display the generating image if the current teacher is viewing the thumb
			#if Teacher.thumbscheduled?(teacher,'avatar_thumb_mg') && signed_in? && teacher.id.to_s == current_teacher.id.to_s
			#	asset_path("profile/gen-face-122.png")
			#else
				asset_path("profile/face-122.png")
			#end
		else
			ret
		end
	end

	def teacher_thumb_md(teacher)
		ret = Teacher.thumb_md(teacher).to_s
		if ret.empty?
			# only display the generating image if the current teacher is viewing the thumb
			#if Teacher.thumbscheduled?(teacher,'avatar_thumb_md') && signed_in? && teacher.id.to_s == current_teacher.id.to_s
			#	asset_path("profile/gen-face-48.png")
			#else
				asset_path("profile/face-48.png")
			#end
		else
			ret
		end		
	end

	def teacher_thumb_sm(teacher)
		ret = Teacher.thumb_sm(teacher).to_s
		if ret.empty?
			# only display the generating image if the current teacher is viewing the thumb
			#if Teacher.thumbscheduled?(teacher,'avatar_thumb_sm') && signed_in? && teacher.id.to_s == current_teacher.id.to_s
			#	asset_path("profile/gen-face-30.png")
			#else
				asset_path("profile/face-30.png")
			#end
		else
			ret
		end		
	end

	def binder_contentview(binder)
		ret = Binder.contentview(binder)
		ret.nil? ? asset_path("common/nothumb.png") : ret
	end

	def binder_thumb_lg(binder)
		ret = Binder.thumb_lg(binder)
		ret.nil? ? asset_path("common/nothumb.png") : ret
	end

	def binder_thumb_sm(binder)
		ret = Binder.thumb_sm(binder)
		ret.nil? ? asset_path("common/nothumb.png") : ret
	end

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
	def get_teacher_avatar(teacher,options = {})

		return "<no profile picture>" if (teacher.info.nil? || teacher.info.avatar.nil?)#.size==0

		if options[:thumb_lg]
			#if teacher.info.nil? || teacher.info.avatar.nil?#.size==0
			#	return "<no profile picture>"
			#else
				return image_tag( "#{teacher_thumb_lg(teacher)}", options )
			#end
		elsif options[:thumb_sm]
			#if teacher.info.nil? || teacher.info.avatar.nil?#.size==0
			#else
				return image_tag( "#{teacher_thumb_sm(teacher)}", options )
			#end
		else
			#if teacher.info.nil? || teacher.info.avatar.nil?#.size==0
			#	return "<no profile picture>"
			#else
				return image_tag( "#{teacher.avatar}", options )
			#end
		end

	end

	def get_binder_image(binder,options = {})


		if binder.versions.nil?
			return "<no image>"
			#return asset_path("stockfilethumbs/wideblankpaper.png")
		elsif binder.current_version.nil?
			return "<no image>"
			#return asset_path("stockfilethumbs/wideblankpaper.png")
		elsif binder.current_version.imgstatus['imageable'] == false
			#return "[#{binder.current_version.ext.upcase}]"
			return "<no image>"
			#return asset_path("stockfilethumbs/wideblankpaper.png")
		elsif binder.current_version.imgstatus['imgfile']['retrieved'] == false#?['imagefile']['retrieved']?
			return "<no image>"
			#return asset_path("stockfilethumbs/wideblankpaper.png")
		elsif binder.current_version.img_thumb_lg.nil? || binder.current_version.img_thumb_lg.url.to_s.to_s.empty?
			return "<no image>"
			#return asset_path("stockfilethumbs/wideblankpaper.png")
		else
			#return image_tag( "#{binder.versions.last.imgfile}", options ) + raw('&nbsp;')# + 
			#return	image_tag( "#{binder.versions.last.imgfile.thumb_lg}",options) + raw('&nbsp;') + 
			#		image_tag( "#{binder.versions.last.imgfile.thumb_sm}",options )
			# case binder.current_version.thumbnailgen.to_i
			# when 0
			# 	return "#{binder.current_version.imgfile.img_thumb_lg.url}"
			# when 1
			# 	return "#{binder.current_version.imgfile.video_thumb_lg.url}"
			# when 2
			# 	return "#{binder.current_version.imgfile.url_thumb_lg.url}"
			# when 3
			# 	return "#{binder.current_version.imgfile.doc_thumb_lg.url}"
			# end

			#return "#{binder.current_version.imgfile.thumb_lg.url}"
			return binder.current_version.img_thumb_lg.url.to_s
		end


		#Rails.logger.debug "Imgfile: #{binder.versions.last.imgfile.to_s}"
		#Rails.logger.debug "Imgfile: #{binder.versions.last.imgfile.url.to_s}"

	end

	def get_contype_icon(binder)

		unless binder.current_version.nil?
			if binder.current_version.croc?
				return asset_path("binders/types/file.png")
			elsif !binder.current_version.vidtype.empty?
				return asset_path("binders/types/video.png")
			elsif binder.current_version.img?
				return asset_path("binders/types/pic.png")
			elsif binder.type == 1
				return asset_path("binders/types/folder.png")
			elsif binder.format == 2
				return asset_path("binders/types/web.png")
			else
				return asset_path("binders/types/file.png")
			end
		end
			

	end

	def get_username(teacher_id)

		return Teacher.find(teacher_id).username

	end

	# FUCK THESE GODDAMN VIEW HELPERS
	def write_tags(tags)

		return if tags.empty?

		tags.each do |f|
        	raw("<li><a href=\"#\">")
        	f["title"] 
        	raw("</a><div class=\"delcir\" onclick=\"delTag(this)\">x</div></li>")
        end

		# <% @tags[0].each do |f| %>
		#   <li>
		#     <a href="#"><%= f["title"] %></a>
		#     <div class="delcir" onclick="delTag(this)">x</div>
		#   </li>
		# <% end %>

	end

	def tagvis(set,tagset)

		#@tags[0].any? ? raw("style=\"display: block; opacity: 1;\"") : raw("style=\"display: none; opacity: 0;\"")

		return raw("") if tagset.empty?

		if set.any?
			raw("style=\"display: block; opacity: 1;\"")
			#raw("style=\"opacity: 1;\"")
		else
			raw("style=\"display: none; opacity: 0;\"")
			#raw("style=\"opacity: 0;\"")
		end

	end

	def boxvis(tagset)

		if tagset.empty?
			return raw("style=\"\"")
		else
			return raw("style=\"display: none; opacity: 0;\"")
		end

	end

end
