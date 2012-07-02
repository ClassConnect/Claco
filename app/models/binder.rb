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

	# re-inherits the parent tags
	def update_parent_tags

		#if self.parent["id"]=="0"
		#	
		#	self.tag
#
#		end
		node_parent = Binder.find(self.parent["id"])

#		self.tag.debug_data << node_parent.title.to_s
#		self.tag.debug_data << node_parent.to_s

		self.tag.parent_tags = (arr_to_set(node_parent.tag.parent_tags)|arr_to_set(node_parent.tag.node_tags)).to_a

		self.save

	end


	def arr_to_set(array)

		ret_set = Set.new

		array.each do |a|
			ret_set.add(a)
		end

		return ret_set

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



# Tag integer assignments:
# 	 0: grade_level
# 	 1: subject
# 	 2: standard
# 	 3: other

class Tag
	include Mongoid::Document

	field :parent_tags,			:type => Array,	:default => []
	field :node_tags,			:type => Array,	:default => []

	field :debug_data,			:type => Array,	:default => []

	embedded_in :binder

	# Class Methods

	# creates a union of parent_binder's parent and node tags
	def set_parent_tags(params,parent_binder)

		# ensure that this is not a top-level item
		if !parent_binder.nil?

			# the union of parent_tags and node_tags from the parent node is the new parent tag set
			self.parent_tags = (arr_to_set(parent_binder.tag.parent_tags) | arr_to_set(parent_binder.tag.node_tags)).to_a

			self.save
		end

	end

	# only called when creating a new node.  this method does not need to handle conflicts involving updates and moves
	def set_node_tags(params,parent_binder,teacher_id)

		# takes in params from form, returns a single set containing all parameters

		# check that a parent binder exists
		#if !parent_binder
			# no parent binder, so only need to feed params into node_tags
			self.node_tags = marshal_params_to_set(params,teacher_id).to_a
		#else
			# we cannot assume that the parents field has yet been written to
		#	self.node_tags = (marshal_params_to_set(params,teacher_id).subtract(arr_to_set(parent_binder.tag.node_tags)|arr_to_set(parent_binder.tag.parent_tags))).to_a	
		#end

		self.save

	end

	# performs both the set_node_tags and set_parent_tags methods with a single save
	def set_binder_tags(params,parent_binder,teacher_id)

		# check for top-level item
		if !parent_binder.nil?
			# update both
			self.parent_tags = (arr_to_set(parent_binder.tag.parent_tags) | arr_to_set(parent_binder.tag.node_tags)).to_a
			self.node_tags = (marshal_params_to_set(params,teacher_id).subtract(arr_to_set(parent_binder.tag.node_tags))).to_a
		else
			self.node_tags = marshal_params_to_set(params,teacher_id).to_a
		end

		self.save

	end

	# passed the param set, will determine which tags need to be changed, and returns a set of those changed tags
	def update_node_tags(params,teacher_id)

		# collect the parameters into a set
		param_set = marshal_params_to_set(params,teacher_id)

		# collect relevant tags
		# we only have the ability to alter tags that we have added in the past
		existing_owned_tags = (self.node_tags|self.parent_tags).delete_if { |tag| tag["owner"]!= teacher_id.to_s }

		# now retrieve the unique instances from these sets
		# a single instance of them means they were either just created, or just deleted
		changed_tags = param_set^existing_owned_tags

		# a set XOR with the changed tags will remove the duplicates, and leave the singletons
		# this conveniently matches how we want the data to be altered
		self.node_tags = (arr_to_set(self.node_tags)^changed_tags).to_a

		self.save

		return changed_tags

	end

	# THIS METHOD IS DEPRECATED
	# passed a set of changed tags, updates and saves
	# def update_parent_tags(changed_tag_set)

	# 	# a set XOR with the changed tags will remove the duplicates, and leave the singletons
	# 	# this conveniently matches how we want the data to be altered
	# 	self.parent_tags = (arr_to_set(self.parent_tags)^changed_tag_set).to_a

	# 	self.save

	# end



	# this function takes in the posted params and returns a set
	def marshal_params_to_set(params,teacher_id)

		return 	marshal_checkbox_params_to_set(params[:binder][:tag][:grade_levels],0,teacher_id) |
				marshal_checkbox_params_to_set(params[:binder][:tag][:subjects],1,teacher_id) |
				marshal_string_list_to_set(params[:binder][:tag][:standards],2,teacher_id) |
				marshal_string_list_to_set(params[:binder][:tag][:other],3,teacher_id)

	end


	def marshal_checkbox_params_to_set(cb_params,type,owner)

		ret_set = Set.new

		cb_params.each do |cb|
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

end
