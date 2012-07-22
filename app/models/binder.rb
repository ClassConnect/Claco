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
	field :username, :type => String
	field :fname, :type => String
	field :lname, :type => String
	field :title, :type => String#File/directory name
	field :body, :type => String #Directory annotation
	field :type, :type => Integer # 1 = Directory, 2 = File, 3 = Lesson

	field :format, :type => Integer, :default => 0 #Only used if type = 2, 1 = File, 2 = Content(link)

	#Parent
	field :parent, :type => Hash
	field :parents, :type => Array #[# => {Title, id}]
	
	#Permissions
	field :permissions, :type => Array, :default => [] #[shared_id, type, auth_level]
	field :parent_permissions, :type => Array, :default => [] #[type, folder_id, shared_id, auth_level]

	# an index of -1 indicates that this node still needs to be serviced to determine placement in the binder
	field :order_index, :type => Integer, :default => -1

	# Version control is only used if type != directory
	#Version Control
	#field :fork_hash, :type => String #Use Binder.id
	embeds_many :versions#, validate: false #Versions are only used if type = 2 or 3

	field :forked_from, :type => String
	field :fork_stamp, :type => Integer
	field :last_update, :type => Integer
	field :last_updated_by, :type => String

	#Counts
	field :files, :type => Integer, :default => 0
	field :folders, :type => Integer, :default => 0
	field :children, :type => Integer, :default => 0
	field :total_size, :type => Integer, :default => 0
	field :fork_total, :type => Integer, :default => 0

	#Social
	field :likes, :type => Integer
	field :comments, :type => Array

	field :debug_data, :type => Array, :default => []

	#TODO: Add indexing functions that allow binders to be put in a user-defined order via dragon drop

	# tag contains both local and parent tag data
	embeds_one :tag

	embeds_one :imageset

	# passed the index to sift above
	# decrement all binders with an index >= that index
	# def sift_children(index)

	# 	Binder.where("parent.id" => self.id).reject { |b| b.order_index < index }.each do |c|

	# 		c.update_attributes( :order_index => c.order_index - 1)
	# 		c.save

	# 	end

	# end

	# passed the index to sift above
	# decrement all binders with an index >= that index
	def sift_siblings()

		#logger.debug "#{Binder.where("parent.id" => self.parent["id"].to_s).to_a.inspect}"#.reject { |b| b.order_index < self.order_index }}"
		
		#logger.debug "self parent id: #{self.parent["id"]}"
		#logger.debug "self order index: #{self.order_index}"

		#Binder.where("parent.id" => self.parent["id"].to_s).each do |c|
		#	logger.debug "#{c.title}, #{c.order_index}"
		#end

		Binder.where("parent.id" => self.parent["id"].to_s).reject { |b| b.order_index.to_i <= self.order_index.to_i }.each do |c|

			#logger.debug "before: #{c.inspect}"

			c.update_attributes( :order_index => c.order_index - 1)
			#c.save

			#logger.debug " after: #{c.inspect}"

		end
	end

	# passed the index the current binder is to be moved to
	# moves the binder to the specified index within the same parent binder
	def move_to_index(index)

		# decrement all indices above the binder's own index
		Binder.where("parent.id" => self.parent["id"].to_s).reject { |b| b.order_index.to_i <= self.order_index.to_i }.each do |c|

			c.update_attributes( :order_index => c.order_index-1 )

		end

		# check for non-
		if index == self.order_index
			logger.debug "Attempted a move to the same index"
			return
		elsif index < self.order_index
			# binder is being moved to a lower index, increment inbetween indices
			Binder.where("parent.id" => self.parent["id"].to_s).reject { |b| b.order_index.to_i < index.to_i ||
																			 b.order_index.to_i > self.order_index }.each do |c|

					c.update_attributes( :order_index => c.order_index+1)

			end
		else
			# binder is being moved to a higher index, decrement inbetween indices
			Binder.where("parent.id" => self.parent["id"].to_s).reject { |b| b.order_index.to_i > index.to_i ||
																			 b.order_index.to_i < self.order_index }.each do |c|

					c.update_attributes( :order_index => c.order_index-1)

			end
		end

		# finally, set the index of the node being moved
		self.update_attributes( :order_index => index )

	end


	def siblings(id)
		return Binder.where(parent["id"] => id).count
	end

	# updates all data within the Tag class
	def create_binder_tags(params,teacher_id)

		new_binder_parent = Binder.find(params[:binder][:parent]) if params[:binder][:parent] != "0"

		self.tag = Tag.new

		self.tag.set_parent_tags(params,new_binder_parent) if params[:binder][:parent] != "0"

		self.tag.set_node_tags(params,new_binder_parent,teacher_id)

	end

	#TODO: change this to a scoped entity
	def get_binder_children_by_id(parent_binder_id)

		return Binders.where("parent.id" => parent_binder_id)

	end

	# re-inherits the parent tags
	def update_parent_tags

		if self.parent[:id] == "0"

			self.tag.parent_tags = []

		else

			node_parent = Binder.find(self.parent[:id] || self.parent["id"])

			self.tag.parent_tags = (arr_to_set(node_parent.tag.parent_tags)|arr_to_set(node_parent.tag.node_tags)).to_a

		end

		self.save

	end



	# updates parent, parents, and tags fields for all of the passed node's children
	# this method is unused
	# def amend_child_metadata(common_ancestor,params)

	# 	children = Binder.where("parents.id" => common_ancestor.id).sort_by { |b| b.parents.length }

	# 	index = common_ancestor.parents.length

	# 	children.each.do |child|

	# 		child.parent["title"] = params[:binder][:title][0..60] if h.parent["id"] == params[:id]

	# 		child.parents[index]["title"] = params[:binder][:title][0..60]

	# 		child.tag.update_parent_tags()

	# 	end

	# end

	def arr_to_set(array)

		ret_set = Set.new

		array.each do |a|
			ret_set.add(a)
		end

		return ret_set
	end

	def parent_ids
		return parents.collect {|x| x["id"] || x[:id]}
	end

	def children
		return Binder.where("parent.id" => self.id.to_s)
	end

	def current_version
		versions.each {|v| return v if v.active}

		return versions.sort_by {|v| v.timestamp}.last
	end

	def owner?(id)
		return owner == id.to_s
	end

	def handle
		return username || owner
	end

	def get_access(id)
		#Owner will always have r/w access
		return 2 if owner?(id)

		#Only owner will be able to see trash folders
		return 0 if parents.first["id"] == "-1"

		#Explicit permissions always take precedence
		permissions.each do |p|

			#Check what type of permission it is: 1 = person
			return p.auth_level if p.shared_id == id && p.type == 1

			#2 is reserved for classes

			#3 = Public and always read-only
			return 1 if p.type == 3

			#4 is reserved for networks

		end

		parent_permissions.each do |p|

			#Check what type of permission it is: 1 = person
			return p.auth_level if p.shared_id == id && p.type == 1

			#2 is reserved for classes

			#3 = Public and always read-only
			return 1 if p.type == 3

		end

		return 0

	end

	def root
		return parents.second["title"] if parents.size > 1

		return title
	end

	# Delayed Job Methods

	def self.get_thumbnail(id,url)

		Rails.logger.debug "Got to the self call"

		#find(id).versions.last.get_thumbnail(url)
		#find(id).get_thumbnail(url)

		sleep 8

		target = find(id).versions.last

		stathash = target.imgstatus
		stathash['imgfile']['retrieved'] = true

		target.update_attributes( 	:remote_imgfile_url => url,										
									:imgstatus => stathash)

		# binder = find(id).versions.last#.update_attributes( :imghash => "shitcock")

		#find(id).versions.last.update_attributes( :imghash => "shitcock")


		#statushash = binder.versions.last.imgfilestatus
		#statushash['retrieved'] = true

		#binder.versions.last.imgfilestatus['retrieved'] = true
		#binder.versions.last.imgfilestatus.retrieved = true
		#binder.versions.last.imgfilestatus = statushash
		#binder.versions.last.imghash = 'fuckballs'
		#binder.remote_imgfile_url = url

		#binder.imghash = 'shitballs'
		#binder.save

		# binder.update_attributes( :imghash => "shitcock")
		# 							#:remote_imgfile_url => url )
		# #binder.versions.last.save


		# binder.update_attributes( :remote_imgfile_url => url)#,
		# 							#:imgstatus[:imgfile][:retrieved] => true )


		# stathash = binder.imgstatus
		# stathash['imgfile']['retrieved'] = true
		# binder.imgstatus = stathash
		# binder.save


	end

	# def get_thumbnail(url)

	# 	Rails.logger.debug "Got here! url:#{url}"

	# 	sleep 8

	# 	versions.last.update_attribute(:remote_imgfile_url => url)
	# end

	#handle_asynchronously :get_thumbnail#, :run_at => Proc.new { 10.seconds.from_now }

end



class Version
	include Mongoid::Document

	field :owner, :type => String #Owner of version
	field :timestamp, :type => Integer
	field :comments_priv, :type => Array
	field :comments_pub, :type => Array
	field :size, :type => Integer, :default => 0
	field :ext, :type => String
	field :data, :type => String #URL, path to file
	field :active, :type => Boolean, :default => false

	field :file_hash, :type => String
	field :croc_uuid, :type => String

	mount_uploader :file, DataUploader

	# file image data

	field :imgtitle,	:type => String
	field :imgfilename,	:type => String
	field :imgfiletype,	:type => String
	field :imgclass,	:type => Integer
	field :imgdims,		:type => Hash, 	:default => { :width => -1, :height => -1 }

	field :imghash,		:type => String

	field :imgstatus, 	:type => Hash, 	:default => { 	:imgfile => 	{ :retrieved => false },
													 	:imgthumb_lg => { :retrieved => false },
														:imgthumb_sm => { :retrieved => false } }

	# field :imgfilestatus, 		:type => Hash, :default => { :retrieved => false }
	# field :imgthumb_lgstatus, 	:type => Hash, :default => { :retrieved => false }
	# field :imgthumb_smstatus, 	:type => Hash, :default => { :retrieved => false }

	mount_uploader :imgfile, 		ImageUploader
	mount_uploader :imgthumb_lg, 	ImageUploader
	mount_uploader :imgthumb_sm, 	ImageUploader

	embedded_in :binder

	# class Imageset
	# 	include Mongoid::Document

	# 	field :title,		:type => String
	# 	field :filename,	:type => String
	# 	field :filetype,	:type => String
	# 	field :class,		:type => Integer
	# 	field :dimensions,	:type => Hash, 	:default => {:width => -1, :height => -1}

	# 	field :image_hash,	:type => String

	# 	# file id from which the image was generated, should not be self-referential
	# 	field :parent_file,	:type => String

	# 	mount_uploader :fullimage, 		ImageUploader
	# 	mount_uploader :thumbnail_lg, 	ImageUploader
	# 	mount_uploader :thumbnail_sm, 	ImageUploader

	# 	embedded_in :version

	# end


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

	# # re-inherits the parent tags
	# def update_parent_tags(parent_id)

	# 	node_parent = Binder.find(parent_id)

	# 	self.parent_tags = (arr_to_set(node_parent.tag.parent_tags)|arr_to_set(node_parent.tag.node_tags)).to_a

	# 	self.save

	# end

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
