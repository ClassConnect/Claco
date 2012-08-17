class Binder
	include Mongoid::Document

	class FilelessIO < StringIO
		attr_accessor :original_filename

		def set_filename(name = "")
			@original_filename = name
			return self
		end
	end

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
	field :body, :type => String, :default => "" #Directory annotation
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

	# categorized by last update type
	# 0 - creation
	# 1 - update data
	# 2 - new/modified version
	# 3 - rename
	# 4 - created/modified tags
	# 5 - move
	# 6 - copy
	# 7 - delete
	# 8 - permission modification
	# 9 - reordered
	# 10- downloaded
	# 11- forked

	field :download_count, :type => Integer, :default => 0

	#field :last_action_update, :type => Array, :default => [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]
	#55field :last_action_owner, :type => Array, :default 	=> [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]

	#Counts
	field :files, :type => Integer, :default => 0
	field :folders, :type => Integer, :default => 0
	field :children, :type => Integer, :default => 0
	field :total_size, :type => Integer, :default => 0
	field :pub_size, :type => Integer, :default => 0
	field :priv_size, :type => Integer, :default => 0
	field :fork_total, :type => Integer, :default => 0

	#Social
	field :likes, :type => Integer
	field :comments, :type => Array

	# [Large, Small1, Small2] - strings
	field :thumbimgids, :type => Array, :default => ["","","",""]

	#field :debug_data, :type => Array, :default => []

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


	# def self.seedbinder(id)

	# 	a = Binder.new

	# 	a.update_attributes( 	:owner => id.to_s,
	# 							:parent => { :id => "0", :title => "" },
	# 							:parents => [{ :id => "0", :title => "" }],
	# 							:title => "seed binder",
	# 							:type => 1,
	# 							:last_update => Time.now)

	# 	a.save

	# end

	# returns array of URLs of images, in order of size
	def self.get_folder_array(id)

		binder = Binder.find(id.to_s)

		retarr = Array.new

		#Rails.logger.debug "Thumbimbids array: #{binder.thumbimgids.to_s}"

		# retarr << Binder.find(binder.thumbimgids[0].to_s).current_version.imgfile.thumb_lg.url if !binder.thumbimgids[0].empty?
		# retarr << Binder.find(binder.thumbimgids[1].to_s).current_version.imgfile.thumb_sm.url if !binder.thumbimgids[1].empty?
		# retarr << Binder.find(binder.thumbimgids[2].to_s).current_version.imgfile.thumb_sm.url if !binder.thumbimgids[2].empty?

		retarr << Binder.find(binder.thumbimgids[0].to_s).current_version.img_thumb_lg.url if !(binder.thumbimgids[0].nil?) && !(binder.thumbimgids[0].empty?)
		retarr << Binder.find(binder.thumbimgids[1].to_s).current_version.img_thumb_sm.url if !(binder.thumbimgids[1].nil?) && !(binder.thumbimgids[1].empty?)
		retarr << Binder.find(binder.thumbimgids[2].to_s).current_version.img_thumb_sm.url if !(binder.thumbimgids[2].nil?) && !(binder.thumbimgids[2].empty?)
		retarr << Binder.find(binder.thumbimgids[3].to_s).current_version.img_thumb_sm.url if !(binder.thumbimgids[3].nil?) && !(binder.thumbimgids[3].empty?)

		#Rails.logger.debug "Return array: #{retarr.to_s}"

		return retarr

	end

	# recursive call to parent to set the folder thumbnail
	def self.generate_folder_thumbnail(id,imageset = [[],[],[],[]])

		#Rails.logger.debug "GEN: #{id.to_s}"

		return if id.to_s == "-1" || id.to_s == "0"
 
		binder = Binder.find(id.to_s)

		# wipe out thumbimbids array.  must be restored to 3 values again before saving!
		binder.thumbimgids = []

		children = binder.children

		subtree = children.map { |c| c.subtree }.flatten if (children.nil? || children.any?)

		imageset_loc = [[],[],[],[]]

		# if possible, retrieve pictures locally
		if children.any?
			children.each do |c|
				if c.type != 1
					# array values arranged by class
					imageset_loc[c.current_version.imgclass.to_i] << c.id if c.current_version.imgclass.to_i != 4
				end
			end
			[4,imageset_loc.flatten.size].min.times do |i|
				binder.thumbimgids << imageset_loc.flatten[i].to_s
			end
		end

		# variable number of pictures retrieved locally, now expand scope to all descendant binders
		if binder.thumbimgids.size < 4
			if !subtree.nil? && subtree.any?
				subtree.each do |s|
					if s.type != 1
						# array values arranged by class
						imageset[s.current_version.imgclass.to_i] << s.id if s.current_version.imgclass.to_i != 4
					end
				end
			end
			(4 - binder.thumbimgids.size).times do |i|
				binder.thumbimgids << imageset.flatten[i].to_s
			end
			#end
		end

		# fill up extra space so there are always 3 entries
		(4 - binder.thumbimgids.size).times do |i|
			binder.thumbimgids << ""
		end

		# technically not necessary to save until reaching the top node
		binder.save

		Binder.delay(:queue => 'thumbgen').generate_folder_thumbnail(binder.parent["id"] || binder.parent[:id])# if parent['id'] == "0" || parent[:id] == "0"

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

		new_binder_parent = Binder.find(params[:id]) if !params[:id].nil?

		self.tag = Tag.new

		self.tag.set_parent_tags(params,new_binder_parent) if !params[:id].nil?

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

	def subtree
		return Binder.where("parents.id" => self.id.to_s)
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

	def get_access(id = 0)
		#Owner will always have r/w access
		return 2 if owner?(id)

		#Only owner will be able to see trash folders
		return 0 if parents.first["id"] == "-1"

		#Parent permissions always take precedence
		parent_permissions.each {|p| return p["auth_level"] if p["shared_id"] == id && p["type"] == 1} if id != 0

		permissions.each {|p| return p["auth_level"] if p["shared_id"] == id && p["type"] == 1} if id != 0

		if !permissions.find{|p| p["type"] == 3}.nil?

			return 1 if permissions.find{|p| p["type"] == 3}["auth_level"] == 1
		
		end

		if !parent_permissions.find{|p| p["type"] == 3}.nil?

			return 1 if parent_permissions.find{|p| p["type"] == 3}["auth_level"] == 1

		end

		return 0

	end

	def inherited_pub?

		return false if parent_permissions.empty?

		return parent_permissions.find {|p| p["type"] == 3}["auth_level"] == 1

	end

	def is_pub?

		return get_access == 1

	end

	def root
		return parents.second["title"] if parents.size > 1

		return title
	end

	###############################################################################################

	            ####   ##### #       ##   #     # ##### ####          # ##### ####
	            #   #  #     #      #  #   #   #  #     #   #         # #   # #   #
	            #    # #     #     #    #   # #   #     #    #        # #   # #   #
	            #    # ##### #     ######    #    ##### #    #        # #   # ####
	            #    # #     #     #    #    #    #     #    #        # #   # #   #
	            #   #  #     #     #    #    #    #     #   #     #   # #   # #   #
	            ####   ##### ##### #    #    #    ##### ####       ###  ##### ####

	###############################################################################################

	# Delayed Job Methods

	# Do not explicitly call these!  All these methods have very long latency.

	def self.gen_url_thumbnails(id)

		binder = Binder.find(id.to_s)

		origimg = Magick::ImageList.new

		# retrieve fullsize image from S3 store, read into an ImageList object
		open(binder.current_version.imgfile.url.to_s) do |f|
			origimg.from_blob(f.read)
		end

        origimg.format = BLOB_FILETYPE

		# Wrap filestring as pseudo-IO object, compress if width exceeds 700
		if !(origimg.columns.to_i < CV_WIDTH)

			binder.current_version.update_attributes(	:img_contentview => FilelessIO.new(origimg.resize_to_fit!(CV_WIDTH,nil).to_blob).set_filename(CV_FILENAME))

			# shrink image to be reasonably processed (this is what the thumb algos will use)
			#origimg.resize_to_fit!(IMGSCALE,IMGSCALE)
		else

			binder.current_version.update_attributes(	:img_contentview => FilelessIO.new(origimg.to_blob).set_filename(CV_FILENAME))

		end

		GC.start

		binder.current_version.update_attributes(	:img_thumb_lg => FilelessIO.new(origimg.resize_to_fill!(LTHUMB_W,LTHUMB_H,Magick::NorthGravity).to_blob).set_filename(LTHUMB_FILENAME))

		GC.start

		stathash = binder.current_version.imgstatus
		stathash['img_contentview']['generated'] = true
		stathash['img_thumb_lg']['generated'] = true
		stathash['img_thumb_sm']['generated'] = true

		binder.current_version.update_attributes(	:img_thumb_sm => FilelessIO.new(origimg.resize_to_fill!(STHUMB_W,STHUMB_H,Magick::NorthGravity).to_blob).set_filename(STHUMB_FILENAME),
													:imgstatus => stathash)

		origimg.destroy!

		GC.start



	end

	def self.gen_video_thumbnails(id)

		binder = Binder.find(id.to_s)

		origimg = Magick::ImageList.new

		# retrieve fullsize image from S3 store, read into an ImageList object
		open(binder.current_version.imgfile.url.to_s) do |f|
			origimg.from_blob(f.read)
		end

        origimg.format = BLOB_FILETYPE

		if (origimg.columns.to_i > IMGSCALE || origimg.rows.to_i > IMGSCALE)
			origimg.resize_to_fit!(IMGSCALE,IMGSCALE)
		end

		GC.start

		binder.current_version.update_attributes(	:img_thumb_lg => FilelessIO.new(origimg.resize_to_fill!(LTHUMB_W,LTHUMB_H,Magick::CenterGravity).to_blob).set_filename(LTHUMB_FILENAME))

		GC.start

		stathash = binder.current_version.imgstatus
		stathash['img_thumb_lg']['generated'] = true
		stathash['img_thumb_sm']['generated'] = true

		binder.current_version.update_attributes(	:img_thumb_sm => FilelessIO.new(origimg.resize_to_fill!(STHUMB_W,STHUMB_H,Magick::CenterGravity).to_blob).set_filename(STHUMB_FILENAME),
													:imgstatus => stathash)

		origimg.destroy!

		GC.start
	end

	def self.gen_croc_thumbnails(id)

		binder = Binder.find(id.to_s)

		origimg = Magick::ImageList.new

		# retrieve fullsize image from S3 store, read into an ImageList object
		open(binder.current_version.imgfile.url.to_s) do |f|
			origimg.from_blob(f.read)
		end

        origimg.format = BLOB_FILETYPE

		if (origimg.columns.to_i > IMGSCALE || origimg.rows.to_i > IMGSCALE)
			origimg.resize_to_fit!(IMGSCALE,IMGSCALE)
		end

		GC.start

		new_img_lg = Magick::ImageList.new
		new_img_lg << Magick::Image.new(LTHUMB_W,LTHUMB_H)
		filled_lg = new_img_lg.first.color_floodfill(1,1,Magick::Pixel.from_color(CROC_BACKGROUND_COLOR))
		filled_lg.composite!(origimg.resize_to_fit(LTHUMB_W-4,LTHUMB_H-4).border(1,1,CROC_BORDER_COLOR),Magick::CenterGravity,Magick::OverCompositeOp)
		filled_lg.format = BLOB_FILETYPE

		binder.current_version.update_attributes(	:img_thumb_lg => FilelessIO.new(filled_lg.to_blob).set_filename(LTHUMB_FILENAME))

		new_img_lg.destroy!
		filled_lg.destroy!

		GC.start

		new_img_sm = Magick::ImageList.new
		new_img_sm << Magick::Image.new(STHUMB_W,STHUMB_H)
		filled_sm = new_img_sm.first.color_floodfill(1,1,Magick::Pixel.from_color(CROC_BACKGROUND_COLOR))
		filled_sm.composite!(origimg.resize_to_fit(STHUMB_W-4,STHUMB_H-4).border(1,1,CROC_BORDER_COLOR),Magick::CenterGravity,Magick::OverCompositeOp)
		filled_sm.format = BLOB_FILETYPE

		stathash = binder.current_version.imgstatus
		stathash['img_thumb_lg']['generated'] = true
		stathash['img_thumb_sm']['generated'] = true

		binder.current_version.update_attributes(	:img_thumb_sm => FilelessIO.new(filled_sm.to_blob).set_filename(STHUMB_FILENAME),
													:imgstatus => stathash)

		new_img_sm.destroy!
		filled_sm.destroy!
		origimg.destroy!

		GC.start

	end

	def self.gen_smart_thumbnails(id)

		if false

			binder = Binder.find(id.to_s)

			origimg = Magick::ImageList.new

			# retrieve fullsize image from S3 store, read into an ImageList object
			open(binder.current_version.imgfile.url.to_s) do |f|
				origimg.from_blob(f.read)
			end

	        origimg.format = BLOB_FILETYPE

			# Wrap filestring as pseudo-IO object, compress if width exceeds 700
			if !(origimg.columns.to_i < CV_WIDTH)

				binder.current_version.update_attributes(	:img_contentview => FilelessIO.new(origimg.resize_to_fit!(CV_WIDTH,nil).to_blob).set_filename(CV_FILENAME))

				# shrink image to be reasonably processed (this is what the thumb algos will use)
				#origimg.resize_to_fit!(IMGSCALE,IMGSCALE)
			else

				binder.current_version.update_attributes(	:img_contentview => FilelessIO.new(origimg.to_blob).set_filename(CV_FILENAME))

			end

			GC.start

			binder.current_version.update_attributes(	:img_thumb_lg => FilelessIO.new(origimg.resize_to_fill!(LTHUMB_W,LTHUMB_H,Magick::CenterGravity).to_blob).set_filename(LTHUMB_FILENAME))

			GC.start

			stathash = binder.current_version.imgstatus
			stathash['img_contentview']['generated'] = true
			stathash['img_thumb_lg']['generated'] = true
			stathash['img_thumb_sm']['generated'] = true

			binder.current_version.update_attributes(	:img_thumb_sm => FilelessIO.new(origimg.resize_to_fill!(STHUMB_W,STHUMB_H,Magick::CenterGravity).to_blob).set_filename(STHUMB_FILENAME),
														:imgstatus => stathash)

			origimg.destroy!

			GC.start

		# actual algorithm, is ignored:

		#if false
		else

			binder = Binder.find(id.to_s)

			origimg = Magick::ImageList.new

			# retrieve fullsize image from S3 store, read into an ImageList object
			open(binder.current_version.imgfile.url.to_s) do |f|
				origimg.from_blob(f.read)
			end

	        origimg.format = BLOB_FILETYPE

			# Wrap filestring as pseudo-IO object, compress if width exceeds 700
			if !(origimg.columns.to_i < CV_WIDTH)

				binder.current_version.update_attributes(	:img_contentview => FilelessIO.new(origimg.resize_to_fit(CV_WIDTH,nil).to_blob).set_filename(CV_FILENAME))

				# shrink image to be reasonably processed (this is what the thumb algos will use)
				#origimg.resize_to_fit!(IMGSCALE,IMGSCALE)
			else

				binder.current_version.update_attributes(	:img_contentview => FilelessIO.new(origimg.to_blob).set_filename(CV_FILENAME))

			end

			GC.start

			# # Wrap filestring as pseudo-IO object, compress if width exceeds 700
			# if !(origimg.columns.to_i < CV_WIDTH)
			# 	io_cv = FilelessIO.new(origimg.resize_to_fit(CV_WIDTH,nil).to_blob)
			# 	# shrink image to be reasonably processed (this is what the thumb algos will use)
			# 	origimg.resize_to_fit!(IMGSCALE,IMGSCALE)
			# else
			# 	io_cv = FilelessIO.new(origimg.to_blob)
			# end

			#Rails.logger.debug "origimg width: #{origimg.columns}"
			#Rails.logger.debug "origimg height: #{origimg.rows}"

			# bring edge-detected image into memory
			# a weight of 4 ensures that edges which are too tightly packed are weighted less
			img = origimg.edge(4)

	        xcount = 0
	        ycount = 0
	        xsum = 0
	        ysum = 0
	        xsqr = 0
	        ysqr = 0
	        xcube = 0
	        ycube = 0

	        width = img.columns
	        height = img.rows

	        imgview = img.view(0,0,width,height)

	        height.times do |y|
	          width.times do |x|
	            pixel = imgview[y][x]

	            if pixel.red > EDGEPIX_THRESH_PRIMARY || pixel.green > EDGEPIX_THRESH_PRIMARY || pixel.blue > EDGEPIX_THRESH_PRIMARY
	              xcount += 1
	              ycount += 1
	              xsum += x
	              ysum += y
	              xsqr += x**2
	              ysqr += y**2
	              xcube += x**3
	              ycube += y**3
	            end
	          end
	        end

	        # calculation of global statistical data

	        xcentroid = Float(xsum)/Float(xcount)
	        ycentroid = Float(ysum)/Float(ycount)

	        # Unused
	        xvariance = (Float(xsqr)/Float(xcount))-xcentroid**2
	        yvariance = (Float(ysqr)/Float(ycount))-ycentroid**2

	        # Unused
	        xsigma = Math.sqrt(xvariance)
	        ysigma = Math.sqrt(yvariance)

	        #Rails.logger.debug "xcentroid #{xcentroid}"
	        #Rails.logger.debug "ycentroid #{ycentroid}"
	        #Rails.logger.debug "xsigma: #{xsigma}"
	        #Rails.logger.debug "ysigma: #{ysigma}"

	        xEX3 = Float(xcube)/Float(xcount)
	        yEX3 = Float(ycube)/Float(ycount)

	        xskew =  Float(xEX3 - (3 * xcentroid  * xvariance)  - (xcentroid)**3)  / Float(xsigma**3)
	        yskew =  Float(yEX3 - (3 * ycentroid  * yvariance)  - (ycentroid)**3)  / Float(ysigma**3)

	        #Rails.logger.debug "xskew: #{xskew}"
	        #Rails.logger.debug "yskew: #{yskew}"

			topcount = 0
	        topsum = 0
	        topsqr = 0
	        topcube = 0
	        bottomcount = 0
	        bottomsum = 0
	        bottomsqr = 0
	        bottomcube = 0
	        leftcount = 0
	        leftsum = 0
	        leftsqr = 0
	        leftcube = 0
	        rightcount = 0
	        rightsum = 0
	        rightsqr = 0
	        rightcube = 0

	        height.times do |y|
	          width.times do |x|
	            pixel = imgview[y][x]

	            if pixel.red > EDGEPIX_THRESH_SECONDARY || pixel.green > EDGEPIX_THRESH_SECONDARY || pixel.blue > EDGEPIX_THRESH_SECONDARY
	              if x < xcentroid
	                leftcount += 1
	                leftsum += x
	                leftsqr += x**2
	                leftcube += x**3
	              else
	                rightcount += 1
	                rightsum += x
	                rightsqr += x**2
	                rightcube += x**3
	              end

	              if y < ycentroid
	                topcount += 1
	                topsum += y
	                topsqr += y**2
	                topcube += y**3
	              else
	                bottomcount += 1
	                bottomsum += y
	                bottomsqr += y**2
	                bottomcube += y**3
	              end
	            end
	          end
	        end

	        img.destroy!
	        #imgview.destroy!

	        GC.start

	        # calculation of quadrant-relative statistical data

	        topcentroid = Float(topsum)/Float(topcount)
	        bottomcentroid = Float(bottomsum)/Float(bottomcount)
	        leftcentroid = Float(leftsum)/Float(leftcount)
	        rightcentroid = Float(rightsum)/Float(rightcount)

	        topvariance   = (Float(topsqr)/   Float(topcount   ))-topcentroid**2
	        bottomvariance  = (Float(bottomsqr)/Float(bottomcount))-bottomcentroid**2
	        leftvariance  = (Float(leftsqr)/  Float(leftcount  ))-leftcentroid**2
	        rightvariance   = (Float(rightsqr)/ Float(rightcount ))-rightcentroid**2

	        topsigma = Math.sqrt(topvariance)
	        bottomsigma = Math.sqrt(bottomvariance)
	        leftsigma = Math.sqrt(leftvariance)
	        rightsigma = Math.sqrt(rightvariance)

	        #topEX3 = Float(topcube)/Float(topcount)
	        #bottomEX3 = Float(bottomcube)/Float(bottomcount)
	        #leftEX3 = Float(leftcube)/Float(leftcount)
	        #rightEX3 = Float(rightcube)/Float(rightcount)

	        #topskew =     Float(topEX3 -    (3 * topcentroid     * topvariance)     - (topcentroid)**3)     / Float(topsigma**3)
	        #bottomskew =  Float(bottomEX3 - (3 * bottomcentroid  * bottomvariance)  - (bottomcentroid)**3)  / Float(bottomsigma**3)
	        #leftskew =    Float(leftEX3 -   (3 * leftcentroid    * leftvariance)    - (leftcentroid)**3)    / Float(leftsigma**3)
	        #rightskew =   Float(rightEX3 -  (3 * rightcentroid   * rightvariance)   - (rightcentroid)**3)   / Float(rightsigma**3)

	        #Rails.logger.debug "topskew:    #{topskew.to_s}"
	        #Rails.logger.debug "bottomskew: #{bottomskew.to_s}"
	        #Rails.logger.debug "leftskew:   #{leftskew.to_s}"
	        #Rails.logger.debug "rightskew:  #{rightskew.to_s}"

	        topedge = Integer(topcentroid - topsigma)
	        bottomedge = Integer(bottomcentroid + bottomsigma)
	        leftedge = Integer(leftcentroid - leftsigma)
	        rightedge = Integer(rightcentroid + rightsigma)

	        xskew = -1.0 if xskew < -1.0
	        xskew = 1.0 if xskew > 1.0
	        yskew = -1.0 if yskew < -1.0
	        yskew = 1.0 if yskew > 1.0

	        # calculate skew shift
	        if xskew > 0
	        	xadj = Integer((rightedge-width)*xskew)
	        else
	        	xadj = Integer((0-leftedge)*xskew)
	        end

	        if yskew > 0
	        	yadj = Integer((bottomedge-height)*yskew)
	        else
	        	yadj = Integer((0-topedge)*yskew)
	        end

	        #Rails.logger.debug "xadj: #{xadj}"
	        #Rails.logger.debug "yadj: #{yadj}"

	        thumb_width = rightedge-leftedge
	        thumb_height = bottomedge-topedge

	        # calculate differential to align aspect ratios
	        if Float(thumb_height)/Float(thumb_width) > Float(LTHUMB_H)/Float(LTHUMB_W)
	          # smartselect aspect ratio is wider than thumbnail aspect ratio, crop down vertically
	          y = Integer(thumb_height-(LTHUMB_H*thumb_width)/LTHUMB_W)/2

	          topedge += y
	          bottomedge -= y

	        else
	          # smartselect aspect ratio is taller than thumbnail aspect ratio, crop down horizontally
	          x = Integer(thumb_width-(LTHUMB_W*thumb_height)/LTHUMB_H)/2

	          leftedge += x
	          rightedge -= x

	        end

	    	#io_lg = FilelessIO.new(origimg.crop(leftedge+xadj,topedge+yadj,(rightedge-leftedge),(bottomedge-topedge)).crop_resized(LTHUMB_W,LTHUMB_H,Magick::CenterGravity).to_blob)

	    	#Rails.logger.debug "Before crop"
	    	#Rails.logger.debug "LWDIMS: #{origimg.columns.to_i} #{LTHUMB_W.to_i}"
	    	#Rails.logger.debug "LHDIMS: #{origimg.rows.to_i} #{LTHUMB_H.to_i}"



	    	if !(((rightedge-leftedge).to_i<LTHUMB_W.to_i) || ((bottomedge-topedge).to_i<LTHUMB_H.to_i))
	    		#binder.current_version.update_attributes(	:img_thumb_lg => FilelessIO.new(origimg.resize_to_fill!(LTHUMB_W,LTHUMB_H,Magick::CenterGravity).to_blob).set_filename(LTHUMB_FILENAME))
	    	#else
	    		origimg.crop!(leftedge+xadj,topedge+yadj,(rightedge-leftedge),(bottomedge-topedge),true)

	    		#Rails.logger.debug "After crop, before resize_to_fill"
		    	#Rails.logger.debug "LWDIMS: #{origimg.columns.to_i} #{LTHUMB_W.to_i}"
		    	#Rails.logger.debug "LHDIMS: #{origimg.rows.to_i} #{LTHUMB_H.to_i}"

	    		#binder.current_version.update_attributes(	:img_thumb_lg => FilelessIO.new(origimg.resize_to_fill!(LTHUMB_W,LTHUMB_H,Magick::CenterGravity).to_blob).set_filename(LTHUMB_FILENAME))#.resize_to_fill!(LTHUMB_W,LTHUMB_H,Magick::CenterGravity).to_blob).set_filename(LTHUMB_FILENAME))
	    	end

			binder.current_version.update_attributes(	:img_thumb_lg => FilelessIO.new(origimg.resize_to_fill!(LTHUMB_W,LTHUMB_H,Magick::CenterGravity).to_blob).set_filename(LTHUMB_FILENAME))#.resize_to_fill!(LTHUMB_W,LTHUMB_H,Magick::CenterGravity).to_blob).set_filename(LTHUMB_FILENAME))
	    	
	    	#Rails.logger.debug "After resize_to_fill"
	    	#Rails.logger.debug "LWDIMS: #{origimg.columns.to_i} #{LTHUMB_W.to_i}"
	    	#Rails.logger.debug "LHDIMS: #{origimg.rows.to_i} #{LTHUMB_H.to_i}"

			#binder.current_version.update_attributes(	:img_thumb_lg => FilelessIO.new(origimg.crop(leftedge+xadj,topedge+yadj,(rightedge-leftedge),(bottomedge-topedge)).crop_resized(LTHUMB_W,LTHUMB_H,Magick::CenterGravity).to_blob).set_filename(LTHUMB_FILENAME))

			GC.start

	        # reset edge data for small thumb generation
	        topedge = Integer(topcentroid - topsigma)
	        bottomedge = Integer(bottomcentroid + bottomsigma)
	        leftedge = Integer(leftcentroid - leftsigma)
	        rightedge = Integer(rightcentroid + rightsigma)

	        thumb_width = rightedge-leftedge
	        thumb_height = bottomedge-topedge

	        # calculate differential to align aspect ratios
	        if Float(thumb_height)/Float(thumb_width) > STHUMB_H/STHUMB_W
	          # smartselect aspect ratio is wider than thumbnail aspect ratio, crop down vertically
	          y = Integer(thumb_height-(STHUMB_H*thumb_width)/STHUMB_W)/2

	          topedge += y
	          bottomedge -= y

	        else
	          # smartselect aspect ratio is taller than thumbnail aspect ratio, crop down horizontally
	          x = Integer(thumb_width-(STHUMB_W*thumb_height)/STHUMB_H)/2

	          leftedge += x
	          rightedge -= x

	        end

	    	#io_sm = FilelessIO.new(origimg.crop(leftedge+xadj,topedge+yadj,(rightedge-leftedge),(bottomedge-topedge)).crop_resized(STHUMB_W,STHUMB_H,Magick::CenterGravity).to_blob)



	        # set filenames of pseudoIO objects
	        #io_cv.original_filename = CV_FILENAME
	        #io_lg.original_filename = LTHUMB_FILENAME
	        #io_sm.original_filename = STHUMB_FILENAME

	        # set flags in the stathash
	        stathash = binder.current_version.imgstatus
			stathash['img_contentview']['generated'] = true
			stathash['img_thumb_lg']['generated'] = true
			stathash['img_thumb_sm']['generated'] = true

	    	#Rails.logger.debug "SWDIMS: #{(rightedge-leftedge).to_i} #{STHUMB_W.to_i}"
	    	#Rails.logger.debug "SHDIMS: #{(bottomedge-topedge).to_i} #{STHUMB_H.to_i}"

			# if ((rightedge-leftedge).to_i<STHUMB_W.to_i) || ((bottomedge-topedge).to_i<STHUMB_H.to_i)
	  #   		binder.current_version.update_attributes(	:img_thumb_sm => FilelessIO.new(origimg.crop_resized!(STHUMB_W,STHUMB_H,Magick::CenterGravity).to_blob).set_filename(STHUMB_FILENAME),
			# 												:imgstatus => stathash)   
	  #   	else
				binder.current_version.update_attributes(	:img_thumb_sm => FilelessIO.new(origimg.resize_to_fill!(STHUMB_W,STHUMB_H,Magick::CenterGravity).to_blob).set_filename(STHUMB_FILENAME),
															:imgstatus => stathash)    	
			# end

			#binder.current_version.update_attributes(	:img_thumb_sm => FilelessIO.new(origimg.crop(leftedge+xadj,topedge+yadj,(rightedge-leftedge),(bottomedge-topedge)).crop_resized(STHUMB_W,STHUMB_H,Magick::CenterGravity).to_blob).set_filename(STHUMB_FILENAME),
			#											:imgstatus => stathash)

			origimg.destroy!

			GC.start

			# write to DB/S3
			#binder.current_version.update_attributes(	:img_contentview => io_cv,
			#											:img_thumb_lg => io_lg,
			#											:img_thumb_sm => io_sm,
			#											:imgstatus => stathash)

			#GC.start
		end

	end

	# this method is fucking sloppy
	def self.get_croc_thumbnail(id,url)

		# loop until Crocodoc has finished processing the file, or timeout is reached
		timeout = 50 # in tenths of a second
		#while [400,401,404,500].include? RestClient.get(url) {|response, request, result| response.code }.to_i

		Rails.logger.debug "url: #{url.to_s}"

		# we can assume all HTTP codes above 400 represent a failure to fetch the image
		while RestClient.get(url) {|response, request, result| response.code }.to_i >= 400
			sleep 0.1
			timeout -= 1
			if timeout==0
				# image fetch timed out
				#Binder.delay(:queue => 'mulligan', :priority => 1, run_at: 15.minutes.from_now).get_croc_thumbnail(id,url)
				raise "Crocodoc thumbnail fetch timed out" and return
			end
		end

		target = find(id)

		stathash = target.current_version.imgstatus
		stathash['imgfile']['retrieved'] = true

		target.current_version.update_attributes( 	:remote_imgfile_url => url,
													:imgclass => 3,										
													:imgstatus => stathash)


		#Binder.delay.generate_folder_thumbnail(id)
		Binder.delay(:queue => 'thumbgen').generate_folder_thumbnail(target.parent['id'] || target.parent[:id])


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

		GC.start

		#Binder.delay.generate_folder_thumbnail(id)
		Binder.delay(:queue => 'thumbgen').generate_folder_thumbnail(target.parent['id'] || target.parent[:id])

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
			vimeo_id = url.path.split('/').last

			if vimeo_id==-1
				raise "Vimeo video ID not found in URL" and return
			end

			response = JSON.parse(RestClient.get("http://vimeo.com/api/v2/video/#{vimeo_id}.json"))

			api_url = response.first['thumbnail_large']

			#Rails.logger.debug response.first['thumbnail_large']
		elsif options[:site]=='schooltube'

			response = RestClient.get(url.to_s){ |resp, request, result| resp }

			doc = Nokogiri::HTML(response)

			if doc.at('iframe').nil?

				api_url = response.to_s.scan(/poster="(.*.jpg)/).first.first

			else

				api_url = Nokogiri::HTML(RestClient.get(doc.at('iframe')['src'])).at('video')['poster']

			end

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

							
		GC.start

		#Binder.delay.generate_folder_thumbnail(id)
		#Binder.generate_folder_thumbnail(id)
		Binder.delay(:queue => 'thumbgen').generate_folder_thumbnail(Binder.find(id).parent['id'])

	end

	#handle_asynchronously :get_thumbnail#, :run_at => Proc.new { 10.seconds.from_now }

end

# End Delayed Job Methods

###################################################################################################

class Version
	include Mongoid::Document

	#attr_accessible :thumbnailgen

	field :owner, :type => String #Owner of version
	field :timestamp, :type => Integer
	field :comments_priv, :type => Array
	field :comments_pub, :type => Array
	field :size, :type => Integer, :default => 0
	field :ext, :type => String
	field :data, :type => String #URL, path to file
	field :embed, :type => Boolean, :default => false
	field :active, :type => Boolean, :default => false

	# MD5 hash of the uploaded file
	field :file_hash

	# UUID to access the document on crocodoc
	field :croc_uuid

	mount_uploader :file, DataUploader

	field :imgtitle
	field :imgfilename
	field :imgfiletype

	# 0 - standard (smartthumb detection)
	# 1 - video (horiz fill, crop top & bottom)
	# 2 - website (horiz fill, crop bottom)
	# 3 - document (center, no cropping)
	field :thumbnailgen, :type => Integer, :default => 0

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
	field :imgstatus, 	:type => Hash, 	:default => { 	:imageable => 		true,		
														:imgfile => 		{ :retrieved => false },
													 	:img_contentview => { :generated => false },
													 	:img_thumb_lg => 	{ :generated => false },
														:img_thumb_sm => 	{ :generated => false } }

	# the explicit thumbnail uploaders will be used when ImageMagick is fully utilized
	mount_uploader :imgfile, 		ImageUploader
	mount_uploader :img_contentview,ImageUploader
	mount_uploader :img_thumb_lg, 	ImageUploader
	mount_uploader :img_thumb_sm, 	ImageUploader

	embedded_in :binder

	def thumbnailgen

		return self.thumbnailgen

	end

	def get_croc_session

		return CROC_VALID_FILE_FORMATS.include?(ext.downcase) ? JSON.parse(RestClient.post(CROC_API_URL + PATH_SESSION, :token => CROC_API_TOKEN, :uuid => croc_uuid){ |response, request, result| response })["session"] : ""

	end

	def get_youtube_id

		return CGI.parse(URI.parse(data).query)['v'].first if youtube?

	end

	def get_educreations_id

		return URI.parse(data).path.split("/").last if educreations?

	end

	def get_vimeo_id

		return URI.parse(data).path.split("/").last if vimeo?

	end

	def get_schooltube_id

		return URI.parse(data).path.split("/")[2] if schooltube?

	end

	def get_showme_id

		return CGI.parse(URI.parse(data).query)["h"].first if showme?

	end

	#TODO: There needs to be a better way for content type than these boolean functions...
	def croc?

		return CROC_VALID_FILE_FORMATS.include? ext.downcase if !ext.nil?

		return false

	end

	def youtube?

		uri = URI.parse(data)

		return uri.host.nil? ? false : (uri.host.include?('youtube.com') && uri.path.include?('/watch'))

		rescue URI::InvalidURIError
			return false

	end

	def educreations?

		uri = URI.parse(data)

		return uri.host.nil? ? false : (uri.host.include?('educreations.com') && uri.path.include?('lesson/view'))

		rescue URI::InvalidURIError
			return false

	end

	def vimeo?

		uri = URI.parse(data)

		return uri.host.nil? ? false : uri.host.include?('vimeo.com') && uri.path.to_s.length > 0

		rescue URI::InvalidURIError
			return false

	end

	def schooltube?

		uri = URI.parse(data)

		return uri.host.nil? ? false : uri.host.include?('schooltube.com') && uri.path.to_s.length > 0

		rescue URI::InvalidURIError
			return false

	end

	def showme?

		uri = URI.parse(data)

		return uri.host.nil? ? false : uri.host.include?('showme.com') && uri.path.include?('/sh')

		rescue URI::InvalidURIError
			return false

	end

	def img?
		return imgclass == 0
	end

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

			#self.binder.update_attributes( 	:last_update		=> Time.now.to_i,
			#								:last_updated_by	=> current_teacher.id.to_s)

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

		#Rails.logger.debug "binder #{self.binder.title}"
		#Rails.logger.debug "self.node_tags #{self.node_tags}"
		#Rails.logger.debug "self.parent_tags #{self.parent_tags}"
		#Rails.logger.debug "existing_owned_tags #{existing_owned_tags.to_a.to_s}"
		#Rails.logger.debug "param_set #{param_set.to_a.to_s}"

		# now retrieve the unique instances from these sets
		# a single instance of them means they were either just created, or just deleted
		changed_tags = param_set^existing_owned_tags

		#Rails.logger.debug "changed_tags #{changed_tags.to_a.to_s}"

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
