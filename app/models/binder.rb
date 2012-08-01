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

	# [Large, Small1, Small2] - strings
	field :thumbimgids, :type => Array, :default => ["","",""]

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

	# returns array of URLs of images, in order of size
	def self.get_folder_array(id)

		binder = Binder.find(id.to_s)

		retarr = Array.new

		Rails.logger.debug "Thumbimbids array: #{binder.thumbimgids.to_s}"

		retarr << Binder.find(binder.thumbimgids[0].to_s).current_version.imgfile.thumb_lg.url if !binder.thumbimgids[0].empty?
		retarr << Binder.find(binder.thumbimgids[1].to_s).current_version.imgfile.thumb_sm.url if !binder.thumbimgids[1].empty?
		retarr << Binder.find(binder.thumbimgids[2].to_s).current_version.imgfile.thumb_sm.url if !binder.thumbimgids[2].empty?

		Rails.logger.debug "Return array: #{retarr.to_s}"

		return retarr

	end

	# recursive call to parent to set the folder thumbnail
	def self.generate_folder_thumbnail(id,imageset = [[],[],[],[]])

		Rails.logger.debug "GEN: #{id.to_s}"

		#return if id.to_s == "-1" || id.to_s == "0"
 
		binder = Binder.find(id.to_s)

		binder.thumbimgids = []

		#Rails.logger.debug "BINDER INSPECT: #{binder.inspect.to_s}"

		# retrieve images, add to imageset

		#children = Binder.where("parent.id" => binder.parent['id'])
		#children = Binder.where("parent.id" => binder.id.to_s)

		#binder.parents.collect { |x| Binder.find((x["id"] || x[:id]).to_s) }

		#children = Binder.collection.where( "parents.id" => id.to_s )
		#children = Binder.any_in( parents: [{ "id" => "#{binder.id.to_s}","title" => "" }] )#.excludes( parent: { "id" => "-1", "title" => "" } )
		children = Binder.where( "parent.id" => id.to_s )

		Rails.logger.debug "GOT HERE"

		# @ops.each do |opid|
		# 	if opid != "0"
		# 		op = Binder.find(opid)

		Rails.logger.debug "#{binder.title.to_s} CHILDREN INSPECT: (size:#{children.size})"
		children.each do |c|
			Rails.logger.debug "#{c.inspect.to_s}"
		end

		imageset_loc = [[],[],[],[]]
		#imgset_dup = Array.new(imageset)

		if children.any?
			children.each do |c|
				if c.type != 1
					# array values arranged by class
					imageset_loc[c.current_version.imgclass.to_i] << c.id if c.current_version.imgclass.to_i != 4
				end
			end
			[3,imageset_loc.size].min.times do |i|
				binder.thumbimgids << imageset_loc.flatten[i].to_s
			end
		end

		binder.save

		# generate first thumbnail from local imageset if possible

		# Rails.logger.debug "imageset_loc.size #{imageset_loc.size}"
		# Rails.logger.debug "imageset_loc #{imageset_loc}"
		
		# imageset_loc.each do |i|
		# 	if i.any?
		# 		i.each do |j|
		# 			# technically not necessary until random retrieval
		# 			# is popping the LAST one, not the first one

		# 			Rails.logger.debug "Existing item found! #{j.to_s}"
		# 			binder.thumbimgids << i.pop.to_s#.pop
		# 			break# if binder.thumbids.size == 3
		# 		end
		# 		break# if binder.thumbimgids.size == 1
		# 	end
		# end


		# Rails.logger.debug "Thumbimbids array after searching locally: #{binder.thumbimgids.to_s}"
		# # generate remaining thumbnails

		# temp = []

		# imgset_dup.each do |i|
		# 	if i.any?
		# 		i.each do |j|
		# 			# technically not necessary until random retrieval
		# 			# is popping the LAST one, not the first one
		# 			temp << i.pop.to_s
		# 			break if temp.size > 2
		# 		end
		# 	end
		# 	break if temp.size > 2
		# end

		# binder.thumbimgids = binder.thumbimgids | temp

		# Rails.logger.debug "DB_WRITE #{binder.thumbimgids.to_s}"

		# binder.save

		# # merge local thumbnails into all other thumbnails before continuing

		# (0..3).each do |l|
		# 	if imageset_loc[l].any?
		# 		imageset_loc[l].each do |m|
		# 			imageset[l] << m.to_s
		# 		end
		# 	end
		# end

		if binder.parent['id'] == "0"
			return
		else
			return generate_folder_thumbnail(binder.parent['id'],imageset)
		end

	end

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

		new_binder_parent = Binder.find(params[:id]) if params[:id] != "0"

		self.tag = Tag.new

		self.tag.set_parent_tags(params,new_binder_parent) if params[:id] != "0"

		# self.tag.set_node_tags(params,new_binder_parent,teacher_id)

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

	def user
		return username || "#{fname} #{lname}"
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

	##############################################################################################

	# Delayed Job Methods

	# Do not explicitly call these!  All these methods have very long latency.

	# this method is fucking sloppy
	def self.get_croc_thumbnail(id,url)

		# loop until Crocodoc has finished processing the file, or timeout is reached
		timeout = 150 # in tenths of a second
		#while [400,401,404,500].include? RestClient.get(url) {|response, request, result| response.code }.to_i

		Rails.logger.debug "url: #{url.to_s}"

		# we can assume all HTTP codes above 400 represent a failure to fetch the image
		while RestClient.get(url) {|response, request, result| response.code }.to_i >= 400
			sleep 0.1
			timeout -= 1
			raise "Crocodoc thumbnail fetch timed out" and return if timeout == 0
		end

		target = find(id)

		stathash = target.current_version.imgstatus
		stathash['imgfile']['retrieved'] = true

		target.current_version.update_attributes( 	:remote_imgfile_url => url,
									:imgclass => 3,										
									:imgstatus => stathash)

		#Binder.delay.generate_folder_thumbnail(id)
		Binder.generate_folder_thumbnail(target.parent['id'])


	end

	# this method is fucking sloppy
	def self.get_thumbnail_from_url(id,url)

		target = find(id)

		stathash = target.current_version.imgstatus
		if stathash['imgfile'].nil?
			stathash[:imgfile][:retrieved] = true
		else
			stathash['imgfile']['retrieved'] = true
		end

		target.current_version.update_attributes(	:remote_imgfile_url => url,
									:imgclass => 2,
									:imgstatus => stathash)

		#Binder.delay.generate_folder_thumbnail(id)
		Binder.generate_folder_thumbnail(target.parent['id'])

	end

	# this method is fucking sloppy
	def self.get_thumbnail_from_api(id,url,options={})
		if options.empty?
			raise "Called API request method without supplying parent site" and return
		end

		url = URI(url)

		# interfacing with specific API		
		if options[:site]=='vimeo'

			vimeo_id = -1

			# pull out vimeo video ID
			url.path.split('/').each do |f|
				if f.to_i.to_s.length==8
					vimeo_id = f.to_i
					break
				end
			end

			if vimeo_id==-1
				raise "Vimeo video ID not found in URL" and return
			end

			response = JSON.parse(RestClient.get("http://vimeo.com/api/v2/video/#{vimeo_id}.json"))

			api_url = response.first['thumbnail_large']

			#Rails.logger.debug response.first['thumbnail_large']
		elsif options[:site]=='schooltube'

			response = RestClient.get(url.to_s){ |resp, request, result| resp }

			api_url = response.to_s.scan(/poster="(.*_lg.jpg)/).first.first

		elsif options[:site]=='showme'

			response = RestClient.get(url.to_s){ |resp, request, result| resp }

			api_url = response.to_s.scan(/image:"(.*jpg)",skin/).first.first

			#Rails.logger.debug api_url

		else
			raise "get_thumbnail_from_api called without specifying a valid API" and return
		end

		target = find(id).current_version

		stathash = target.imgstatus
		if stathash['imgfile'].nil?
			stathash[:imgfile][:retrieved] = true
		else
			stathash['imgfile']['retrieved'] = true
		end

		target.update_attributes(	:remote_imgfile_url => api_url,
									:imgclass => 2,
									:imgstatus => stathash)

		#Binder.delay.generate_folder_thumbnail(id)
		#Binder.generate_folder_thumbnail(id)
		Binder.generate_folder_thumbnail(Binder.find(id).parent['id'])

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

	# MD5 hash of the uploaded file
	field :file_hash

	# UUID to access the document on crocodoc
	field :croc_uuid

	mount_uploader :file, DataUploader

	field :imgtitle
	field :imgfilename
	field :imgfiletype

	# imgclass represents how the file will be pulled into folder views
	# integers are in order of priority
	# 0 - image file
	# 1 - video link
	# 2 - general URL
	# 3 - document file
	# 4 - <no image>
	field :imgclass,	:type => Integer

	# dimensions of the uncompressed, unprocessed image
	field :imgdims,		:type => Hash, 	:default => { :width => -1, :height => -1 }

	# MD5 hash of the uploaded image
	field :imghash

	# this hash is updated when the image is retrieved, almost always asynchronously
	# the :imgfile uploader cannot be reliably queried to determine if a file exists or not
	field :imgstatus, 	:type => Hash, 	:default => { 	:imageable => 	true,		
														:imgfile => 	{ :retrieved => false },
													 	:imgthumb_lg => { :retrieved => false },
														:imgthumb_sm => { :retrieved => false } }

	# the explicit thumbnail uploaders will be used when ImageMagick is fully utilized
	mount_uploader :imgfile, 		ImageUploader
	#mount_uploader :imgthumb_lg, 	ImageUploader
	#mount_uploader :imgthumb_sm, 	ImageUploader

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

	#field :debug_data,			:type => Array,	:default => []

	embedded_in :binder

	# Class Methods

	def get_tags()

		return self.parent_tags | self.node_tags

	end

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
		#param_set = marshal_params_to_set(params,teacher_id)
		param_set = marshal_bunched_params_to_set(params,teacher_id)

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

	def marshal_bunched_params_to_set(b_params,teacher_id)

		# example param structure:
		# {"grades"=>{"0"=>{"title"=>"1st "}, "1"=>{"title"=>"2nd "}}, "subjects"=>{"0"=>{"title"=>"Math "}}

		ret_set = Set.new

		if b_params["grades"]
			b_params["grades"].size.times do |g|
				ret_set.add({ "title" => b_params["grades"][g.to_s]["title"].strip, "type" => 0, "owner" => teacher_id.to_s })
			end
		end	

		if b_params["subjects"]
			b_params["subjects"].size.times do |g|
				ret_set.add({ "title" => b_params["subjects"][g.to_s]["title"].strip, "type" => 1, "owner" => teacher_id.to_s })
			end
		end

		if b_params["standards"]
			b_params["standards"].size.times do |g|
				ret_set.add({ "title" => b_params["standards"][g.to_s]["title"].strip, "type" => 2, "owner" => teacher_id.to_s })
			end
		end

		if b_params["other"]
			b_params["other"].size.times do |g|
				ret_set.add({ "title" => b_params["other"][g.to_s]["title"].strip, "type" => 3, "owner" => teacher_id.to_s })
			end
		end

		return ret_set

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
