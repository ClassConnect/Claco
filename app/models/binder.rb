class Binder
	include Mongoid::Document

	#validates :title, :presence => true

	# validate embedded document with parent document
	validates_associated :tag

	# allows submitting a nested has with attributes for the embedded tag object
	# Employee.new({ :first_name => "John", :address => { :street => "Baker St." } })
	accepts_nested_attributes_for :tag

	#File/Directory-specific Attributes
	field :owner, :type => String
	field :title, :type => String#File/directory name
	field :body, :type => String #Directory annotation
	field :type, :type => Integer # 1 = Directory, 2 = File, 3 = Lesson
	#field :permissions, :type => Array # [shared_id, type, auth_level]
	embeds_one :permisson#, validate: false

	#field :tags, :type => Array#, :default => [""] # [index, {title, owner, type}]
	field :format, :type => Integer, :default => 0 #Only used if type = 2, 1 = File, 2 = Content(link)

	#Parent
	field :parent, :type => Hash
	field :parents, :type => Array #[# => {Title, id}]
	field :parent_permissions, :type => Array #[type, folder_id, shared_id, auth_level]
	#field :parent_tags, :type => Array

	# Version control is only used if type != directory
	#Version Control
	#field :versions, :type => Array # Array(# => [id, uid, timestamp, comments_priv, comments_pub, size, ext, fork_total, recs])
	embeds_many :versions#, validate: false #Versions are only used if type = 2 or 3

	field :forked_from, :type => String
	field :fork_hash, :type => String
	field :fork_stamp, :type => String
	field :last_update, :type => Integer
	field :last_updated_by, :type => String

	#Counts
	field :files, :type => Integer
	field :folders, :type => Integer
	field :total_size, :type => Integer

	#Social
	field :likes, :type => Integer
	field :comments, :type => Array

	# tag contains both local and parent tag data
	embeds_one :tag

	# embeds_one :parent_tag
	# embeds_one :node_tag

	# updates all data within the Tag class
	def create_new_binder(params,teacher_id)

		@parenthash = {}
		@parentsarr = []

		new_binder_parent = Binder.find(params[:binder][:parent]) if params[:binder][:parent] != "0"

		if params[:binder][:parent].to_s == "0"

			@parenthash = { :id 	=> params[:binder][:parent],
							:title	=> ""}

			@parentsarr = [@parenthash]

		else

			@parenthash = { :id 	=> params[:binder][:parent],
							:title 	=> new_binder_parent.title}

			#Grab
			@parentsarr = new_binder_parent.parents << @parenthash

		end

		#new_binder = Binder.new(:owner 			=> current_teacher.id,
		self.update_attributes(	:owner				=> teacher_id,	#current_teacher.id,
								:title 				=> params[:binder][:title].to_s[0..60],
								:parent 			=> @parenthash,
								:parents 			=> @parentsarr,
								:last_update 		=> Time.now.to_i,
								:last_updated_by	=> teacher_id,	#current_teacher.id.to_s,
								:body 				=> params[:binder][:body],
								:type 				=> 1)

		self.tag = Tag.new

		#self.tag.set_binder_tags(params,new_binder_parent)

		self.tag.set_parent_tags(params,new_binder_parent) if params[:binder][:parent] != "0"

		self.tag.set_node_tags(params,new_binder_parent,teacher_id)

		#if params[:binder][:parent] == "0"
		#
		#else
		#	parent_binder = Binder.find(params[:binder][:parent])
		#end

	end

	#TODO: change this to a scoped entity
	def get_binder_children_by_id(parent_binder_id)
		return Binders.where("parent.id" => parent_binder_id)
	end

end

class Version
	include Mongoid::Document

	field :uid, :type => String #Owner of version
	field :timestamp, :type => Integer
	field :comments_priv, :type => Array
	field :comments_pub, :type => Array
	field :size, :type => Integer
	field :ext, :type => String
	field :fork_total, :type => Integer
	field :data, :type => String #URL

	mount_uploader :file, DataUploader

	embedded_in :binder
end

class Permission
	include Mongoid::Document

	field :shared_id, :type => String
	field :type, :type => Integer
	field :auth_level, :type => Integer

	embedded_in :binder
end


# # tags inherited from node's parent
# class Parent_Tag

# 	field :tags, :type => Array, :default => []

# 	embedded_in :binder

# 	# Class Methods

# 	# called when creating a new binder
# 	def set_binder_tags(params,)



# 	end

# end

# # tags locally assigned
# class Node_Tag

# 	field :tags, :type => Array, :default => []

# 	embedded_in :binder

# 	# Class Methods

# end

# Tag integer assignments:
# 	 0: grade_level
# 	 1: subject
# 	 2: standard
# 	 3: other

class Tag
	include Mongoid::Document

	# field :grade_levels, 		:type => Array, :default => []
	# field :subjects, 			:type => Array, :default => []
	# field :standards, 			:type => Array, :default => []
	# field :other, 				:type => Array, :default => []

	# field :parent_grade_levels,	:type => Array, :default => []
	# field :parent_subjects,		:type => Array, :default => []
	# field :parent_standards,	:type => Array, :default => []
	# field :parent_other,		:type => Array, :default => []

	# field :node_tags,			:type => Array,	:default => []
	# field :parent_tags,			:type => Array, :default => []

	field :parent_tags,			:type => Array,	:default => []
	field :node_tags,			:type => Array,	:default => []

	field :debug_data,			:type => Array,	:default => []

	embedded_in :binder

	# Class Methods

	# creates a union of parent_binder's parent and node tags
	def set_parent_tags(params,parent_binder)

		if !parent_binder.nil?

			# the union of parent_tags and node_tags from the parent node is the new parent tag set

			self.parent_tags = (arr_to_set(parent_binder.tag.parent_tags) | arr_to_set(parent_binder.tag.node_tags)).to_a

			#self.debug_data << "parent binder node tags"
			#self.debug_data << parent_binder.tag.node_tags.to_s
			#self.debug_data << "parent binder parent tags"

			#self.parent_tags = parent_binder.tag.parent_tags | parent_binder.tag.node_tags

			self.save
		end

	end

	# pulls in params, generates...
	def set_node_tags(params,parent_binder,teacher_id)

		# takes in params from form, returns a single set containing all parameters

		# self.node_tags should contain all members not contained within the parent_tags set
		#self.node_tags = (marshal_params_to_set(params,teacher_id).subtract(arr_to_set(self.parent_tags))).to_a
		if !parent_binder
			self.node_tags = marshal_params_to_set(params,teacher_id).to_a
			#self.debug_data << "NO PARENT FOUND"
		else
			self.node_tags = (marshal_params_to_set(params,teacher_id).subtract(arr_to_set(parent_binder.tag.node_tags)|arr_to_set(parent_binder.tag.parent_tags))).to_a	
			#self.node_tags = (marshal_params_to_set(params,teacher_id).subtract(arr_to_set(self.parent_tags))).to_a
			#self.debug_data << parent_binder.tag.node_tags.to_s
			#self.debug_data << "set of posted params:"
			#self.debug_data << marshal_params_to_set(params,teacher_id).to_a
			#self.debug_data << "set of this node's parent tags:"
			#self.debug_data << arr_to_set(parent_binder.tag.node_tags).to_a
		end


		self.save

	end

	# performs both the set_node_tags and set_parent_tags methods with a single save
	def set_binder_tags(params,parent_binder,teacher_id)

		if !parent_binder.nil?
			self.parent_tags = (arr_to_set(parent_binder.tag.parent_tags) | arr_to_set(parent_binder.tag.node_tags)).to_a
		end

		self.node_tags = (marshal_params_to_set(params,teacher_id).subtract(arr_to_set(parent_binder.tag.node_tags))).to_a

		self.save

	end

	def update_node_tags(params,teacher_id)

		#needs to maintain priority of who checked a box first, regardlgsess of submitted params
		#old_tagset = Set.new
		#new_tagset = Set.new

		#old_tagset = arr_to_set(self.node_tags)
		#new_tagset = marshal_params_to_set(params,teacher_id).subtract(arr_to_set(self.parent_tags))

		# combine existing tags with new tags posted from form, and remove the parent tags immediately
		# THIS IS A FUCKING SLOW OPERATION
		tagset = (arr_to_set(self.node_tags)|marshal_params_to_set(params,teacher_id)).subtract(arr_to_set(self.parent_tags))

		# divide the tagset by title.  sets with multiple instances will have duplicates
		tagset.divide{ |i,j| i[:title]==j[:title] }.each do |subset|
			# if there is a duplicate, we can assume the current user tried to duplicate an existing tag
			if subset.size > 1
				# find the duplicate within the subset (this can almost certainly be done more efficiently)
				subset.each do |tag|
					# delete the tag if the owner of the tag is the current teacher
					subset.delete_if(tag[:owner].to_s==teacher_id.to_s)
				end
			end
		end

		# we can now assume all duplicate tags are removed
		self.node_tags = tagset.flatten

		self.save

		# u is the merged tagset
		# u.each do |tagset|
		# 	if subset.size > 1
		# 		subset.delete_if( owner is current user )
		# 	end
		# enda

	end

	# this function takes in the posted params and returns a set
	def marshal_params_to_set(params,teacher_id)

		# the set we are going to stuff all the parameters into
		# ret_set = Set.new

		# ret_set.add( marshal_checkbox_params_to_set(params[:binder][:tag][:grade_levels],0,teacher_id) )

		# ret_set.add( marshal_checkbox_params_to_set(params[:binder][:tag][:subjects],1,teacher_id) )

		# ret_set.add( marshal_string_list_to_set(params[:binder][:tag][:standards],2,teacher_id) )

		# ret_set.add( marshal_string_list_to_set(params[:binder][:tag][:other],3,teacher_id) )

		# return ret_set

		return 	marshal_checkbox_params_to_set(params[:binder][:tag][:grade_levels],0,teacher_id) |
				marshal_checkbox_params_to_set(params[:binder][:tag][:subjects],1,teacher_id) |
				marshal_string_list_to_set(params[:binder][:tag][:standards],2,teacher_id) |
				marshal_string_list_to_set(params[:binder][:tag][:other],3,teacher_id)

	# 	cleaned_standards_tags_array = Array.new
	# 	cleaned_other_tags_array = Array.new

	# 	cleaned_standards_tags_array = params[:binder][:tag][:standards].downcase.split.uniq if params[:binder][:tag][:standards].empty?
	# 	cleaned_other_tags_array = params[:binder][:tag][:standards].downcase.split.uniq if params[:binder][:tag][:other].empty?

	# # 	# decimate existing array
	#  	self.node_tags = []

	# 	# update grade_levels array
	# 	(1..(params[:binder][:tag][:grade_levels].length-1)).each do |i|
	# 	#(1..(params[:tag][:grade_levels].length-1)).each do |i|
	# 		#if params[:tag][:grade_levels][i] == "0"
	# 		#	zero_count += 1
	# 		#else
	# 		#	true_checkbox_array[zero_count] = true
	# 		#end
	# 		#grade_levels_checkbox_array << params[:binder][:tag][:grade_levels][i] if params[:binder][:tag][:grade_levels][i] != "0"
	# 		#grade_levels_checkbox_array << params[:tag][:grade_levels][i] if params[:tag][:grade_level][i] != "0"

	# 		if params[:binder][:tag][:grade_levels][i] != "0"
	# 			# self.node_tags << { :owner => current_teacher.id, 
	# 			# 					:type => 0,
	# 			# 					:title => params[:binder][:tag][:grade_levels][i] }

	# 			# build_tag_hash(owner,type,data,index)

	# 			self.node_tags << build_tag_hash(teacher_id, 0, params,i)
	# 		end
	# 	end

	# 	# update subjects array
	# 	(1..(params[:binder][:tag][:subjects].length-1)).each do |i|
	# 	#(1..(params[:tag][:subjects].length-1)).each do |i|
	# 		#subjects_checkbox_array << params[:binder][:tag][:subjects][i] if params[:binder][:tag][:subjects][i] != "0"
	# 		#subjects_checkbox_array << params[:tag][:subjects][i] if params[:tag][:subjects][i] != "0"
		

	# 		if params[:binder][:tag][:subjects][i] != "0"
	# 			# self.node_tags << { :owner => current_teacher.id, 
	# 			# 					:type => 1,
	# 			# 					:title => params[:binder][:tag][:subjects][iself


	# 			] }.node_tags << build_tag_hash(teacher_id, 1, params,i)
	# 		end
	# 	end

	# 	cleaned_standards_tags_array.each do |standard|
	# 		self.node_tags << build_tag_hash(teacher_id, 2, standard, -1)
	# 	end

	# 	cleaned_other_tags_array.each do |other|
	# 		self.node_tags <<  build_tag_hash(teacher_id, 3, other, -1)
	# 	end

	# 	self.save
	# 	#end

	end


	def marshal_checkbox_params_to_set(cb_params,type,owner)

		ret_set = Set.new

		cb_params.each do |cb|
			#ret_set.add( { :title => cb.to_s, :type => type.to_i, :owner => owner.to_s } ) if cb.to_s != "0"
			ret_set.add( { "title" => cb.to_s, "type" => type.to_i, "owner" => owner.to_s } ) if cb.to_s != "0"
		end

		return ret_set

	end


	def marshal_string_list_to_set(str_params,type,owner)

		ret_set = Set.new

		str_params.downcase.split.each do |str|
			# set datatype ensures uniqueness
			#ret_set.add( { :title => str.to_s, :type => type.to_i, :owner => owner.to_s } )
			ret_set.add( { "title" => str.to_s, "type" => type.to_i, "owner" => owner.to_s } )
		end

		return ret_set

	end

	def arr_to_set(array)

		ret_set = Set.new

		array.each do |a|
			ret_set.add(a)
		end

		return ret_set

	end

	# this method must ensure that each tag is a singleton in their respective array

	# def update_tags(params,parent_binder)

	# 	# update parent tags as normal
	# 	set_parent_tags(params,parent_binder)



	# end+

	# # this will be used for initialization as well as updating,
	# # so must wipe out the existing array and rebuild it
	# def set_parent_tags(params,parent_binder)

	# 	# decimate existing array
	# 	self.parent_tags = []

	# 	# only add parent members if node is at a nonzero height
	# 	if !parent_binder.nil?

	# 		# bring down node and parent tags into the local node's parent tags, remove duplicates
	# 		# THIS DOES NOT WORK, owner id's prevent uniqueness detection
	# 		self.parent_tags = (parent_binder.tag.parent_tags + parent_binder.tag.node_tags).uniq

	# 	end

	# 	self.save

	# 	#(1..(params[:binder][:tag][:grade_levels].length-1)).each do |i|
	# 	# if parent_binder.nil?
	# 	# 	# is at root level, nothing to inherit
	# 	# 	parent_grade_levels_tags = []
	# 	# 	parent_subjects_tags = []
	# 	# 	parent_standards_tags = []
	# 	# 	parent_other_tags = []
	# 	# else
	# 	# 	# grab parent tags, merge into values to be inserted
	# 	# 	# TODO: determine if the uniq method at the end of the assignments is necessary
	# 	# 	parent_grade_levels_tags 	= (parent_binder.tag.grade_levels 	+ parent_binder.tag.parent_grade_levels).uniq
	# 	# 	parent_subjects_tags 		= (parent_binder.tag.subjects 		+ parent_binder.tag.parent_subjects).uniq
	# 	# 	parent_standards_tags 		= (parent_binder.tag.standards 		+ parent_binder.tag.parent_standards).uniq
	# 	# 	parent_other_tags			= (parent_binder.tag.other 			+ parent_binder.tag.parent_other).uniq
	# 	# end


	# 	#end

	# end

	# # this will be used for initialization as well as updating,
	# # so must wipe out the existing array and rebuild it
	# def set_node_tags(params,teacher_id)#,parent_binder)

	#  	# marshal posted values
	# 	cleaned_standards_tags_array = Array.new
	# 	cleaned_other_tags_array = Array.new

	# 	cleaned_standards_tags_array = params[:binder][:tag][:standards].downcase.split.uniq if params[:binder][:tag][:standards].empty?
	# 	cleaned_other_tags_array = params[:binder][:tag][:standards].downcase.split.uniq if params[:binder][:tag][:other].empty?

	# # 	# decimate existing array
	#  	self.node_tags = []

	# 	# update grade_levels array
	# 	(1..(params[:binder][:tag][:grade_levels].length-1)).each do |i|
	# 	#(1..(params[:tag][:grade_levels].length-1)).each do |i|
	# 		#if params[:tag][:grade_levels][i] == "0"
	# 		#	zero_count += 1
	# 		#else
	# 		#	true_checkbox_array[zero_count] = true
	# 		#end
	# 		#grade_levels_checkbox_array << params[:binder][:tag][:grade_levels][i] if params[:binder][:tag][:grade_levels][i] != "0"
	# 		#grade_levels_checkbox_array << params[:tag][:grade_levels][i] if params[:tag][:grade_level][i] != "0"

	# 		if params[:binder][:tag][:grade_levels][i] != "0"
	# 			# self.node_tags << { :owner => current_teacher.id, 
	# 			# 					:type => 0,
	# 			# 					:title => params[:binder][:tag][:grade_levels][i] }

	# 			# build_tag_hash(owner,type,data,index)

	# 			self.node_tags << build_tag_hash(teacher_id, 0, params,i)
	# 		end
	# 	end

	# 	# update subjects array
	# 	(1..(params[:binder][:tag][:subjects].length-1)).each do |i|
	# 	#(1..(params[:tag][:subjects].length-1)).each do |i|
	# 		#subjects_checkbox_array << params[:binder][:tag][:subjects][i] if params[:binder][:tag][:subjects][i] != "0"
	# 		#subjects_checkbox_array << params[:tag][:subjects][i] if params[:tag][:subjects][i] != "0"
		

	# 		if params[:binder][:tag][:subjects][i] != "0"
	# 			# self.node_tags << { :owner => current_teacher.id, 
	# 			# 					:type => 1

	# 			# 					:title => params[:binder][:tag][:subjects][iself


	# 			] }.node_tags << build_tag_hash(teacher_id, 1, params,i)
	# 		end
	# 	end

	# 	cleaned_standards_tags_array.each do |standard|
	# 		self.node_tags << build_tag_hash(teacher_id, 2, standard, -1)
	# 	end

	# 	cleaned_other_tags_array.each do |other|
	# 		self.node_tags <<  build_tag_hash(teacher_id, 3, other, -1)
	# 	end

	# 	self.save
	# 	#end
	#  end


	# end set_binder_tags(params,parent_binder)

	# 	# array to be eventually passed into the :grade_levels field
	# 	#true_checkbox_array = Array.new(20, false)
	# 	grade_levels_checkbox_array = Array.new
	# 	subjects_checkbox_array = Array.new
	# 	#zero_count = 0

	# 	# update grade_levels array
	# 	(1..(params[:binder][:tag][:grade_levels].length-1)).each do |i|
	# 	#(1..(params[:tag][:grade_levels].length-1)).each do |i|
	# 		#if params[:tag][:grade_levels][i] == "0"
	# 		#	zero_count += 1
	# 		#else
	# 		#	true_checkbox_array[zero_count] = true
	# 		#end
	# 		grade_levels_checkbox_array << params[:binder][:tag][:grade_levels][i] if params[:binder][:tag][:grade_levels][i] != "0"
	# 		#grade_levels_checkbox_array << params[:tag][:grade_levels][i] if params[:tag][:grade_level][i] != "0"
	# 	end

	# 	# update subjects array
	# 	(1..(params[:binder][:tag][:subjects].length-1)).each do |i|
	# 	#(1..(params[:tag][:subjects].length-1)).each do |i|
	# 		subjects_checkbox_array << params[:binder][:tag][:subjects][i] if params[:binder][:tag][:subjects][i] != "0"
	# 		#subjects_checkbox_array << params[:tag][:subjects][i] if params[:tag][:subjects][i] != "0"
	# 	end

	# 	# build parent values
	# 	# if parent_binder.id == "0"
	# 	# THIS ROOT LEVEL IS INHERENTLY FLAWED, AND THEREFORE DANGEROUS!
	# 	if parent_binder.nil?
	# 		# is at root level, nothing to inherit
	# 		parent_grade_levels_tags = []
	# 		parent_subjects_tags = []
	# 		parent_standards_tags = []
	# 		parent_other_tags = []
	# 	else
	# 		# grab parent tags, merge into values to be inserted
	# 		# TODO: determine if the uniq method at the end of the assignments is necessary
	# 		parent_grade_levels_tags 	= (parent_binder.tag.grade_levels 	+ parent_binder.tag.parent_grade_levels).uniq
	# 		parent_subjects_tags 		= (parent_binder.tag.subjects 		+ parent_binder.tag.parent_subjects).uniq
	# 		parent_standards_tags 		= (parent_binder.tag.standards 		+ parent_binder.tag.parent_standards).uniq
	# 		parent_other_tags			= (parent_binder.tag.other 			+ parent_binder.tag.parent_other).uniq
	# 	end

	# 	# downcase.split.uniq will insert an empty string into the array in the db if there is no tag submitted for that field
	# 	# this empty string will propagate down to child nodes, who do not distinguish empty strings in parent data
	# 	# prevent insertion of empty strings into tags array
	# 	cleaned_standards_tags_array = Array.new
	# 	cleaned_other_tags_array = Array.new

	# 	cleaned_standards_tags_array = params[:binder][:tag][:standards].downcase.split.uniq if params[:binder][:tag][:standards].empty?
	# 	cleaned_other_tags_array = params[:binder][:tag][:standards].downcase.split.uniq if params[:binder][:tag][:other].empty?

	# 	# this update query is partially duplicated below in order to make writes to the database atomic
	# 	self.update_attributes(	:grade_levels 			=> grade_levels_checkbox_array,
	# 							:subjects 				=> subjects_checkbox_array,
	# 							#:standards 			=> params[:binder][:tag][:standards].downcase.split.uniq,
	# 							#:other 				=> params[:binder][:tag][:other].downcase.split.uniq,
	# 							:standards				=> cleaned_standards_tags_array,
	# 							:other					=> cleaned_other_tags_array,
	# 							:parent_grade_levels 	=> parent_grade_levels_tags,
	# 							:parent_subjects 		=> parent_subjects_tags,
	# 							:parent_standards 		=> parent_standards_tags,
	# 							:parent_other 			=> parent_other_tags)

	# end

	# def set_binder_parent_tags(params,parent_binder)

	# 	# build parent values
	# 	# if parent_binder.id == "0"
	# 	# THIS ROOT LEVEL IS INHERENTLY FLAWED, AND THEREFORE DANGEROUS!
	# 	if parent_binder.nil?
	# 		# is at root level, nothing to inherit
	# 		parent_grade_levels_tags = []
	# 		parent_subjects_tags = []
	# 		parent_standards_tags = []
	# 		parent_other_tags = []
	# 	else
	# 		# grab parent tags, merge into values to be inserted
	# 		# TODO: determine if the uniq method at the end of the assignments is necessary
	# 		parent_grade_levels_tags 	= (parent_binder.tag.grade_levels 	+ parent_binder.tag.parent_grade_levels).uniq
	# 		parent_subjects_tags 		= (parent_binder.tag.subjects 		+ parent_binder.tag.parent_subjects).uniq
	# 		parent_standards_tags 		= (parent_binder.tag.standards 		+ parent_binder.tag.parent_standards).uniq
	# 		parent_other_tags			= (parent_binder.tag.other 			+ parent_binder.tag.parent_other).uniq
	# 	end

	# 	self.update_attributes(	:parent_grade_levels 	=> parent_grade_levels_tags,
	# 							:parent_subjects 		=> parent_subjects_tags,
	# 							:parent_standards 		=> parent_standards_tags,
	# 							:parent_other 			=> parent_other_tags)

	# end

	# takes in a teacher_id string, the integer type, 
	# def build_tag_hash(owner,type,data,index)

	# 	rethash = { :owner => owner, :type => type }

	# 	if index > -1
	# 		# passed a checkbox input
	# 		if type == 0
	# 			# grade levels tag
	# 			rethash[:title] = data[:binder][:tag][:grade_levels][index]
	# 		else
	# 			# subjets tag
	# 			rethash[:title] = data[:binder][:tag][:subjects][index]
	# 		end
	# 	else
	# 		# passed string array input
	# 		#if type == 2
	# 			# standards tag
	# 			rethash[:title] = data
	# 		#else
	# 			# other tag
	# 		#end
	# 	end

	# 	return rethash
	#end
end
