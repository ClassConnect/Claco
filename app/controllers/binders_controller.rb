class BindersController < ApplicationController
	before_filter :authenticate_teacher!

	def index
		@binders = Binder.where(:owner => current_teacher.id, "parent.id" => "0")

		@title = "#{current_teacher.fname} #{current_teacher.lname}'s Binders"
	end

	def new
		@binders = Binder.where(:owner => current_teacher.id, :type => 1).reject {|b| b.parents.first["id"] == "-1"}

		@title = "Create a new binder"


		@new_binder = Binder.new

		# pre-build tag class for nested form builder
		#@new_binder.build_tag

		@new_binder.tag = Tag.new

		@colleagues = Teacher.all.reject {|t| t == current_teacher}

	end

	#Add Folder Function
	def create
		#Trim to 60 chars (old spec)
		if params[:binder][:title].length < 1
			redirect_to new_binder_path and return
		end

		#TODO: clean this up, double new binder assignemnt?

		#new_binder = Binder.new
		#new_binder.tag = Tag.new

		@parenthash = {}
		@parentsarr = []
		@parentperarr = []

		if params[:binder][:parent].to_s == "0"

			@parenthash = {	:id		=> params[:binder][:parent],
							:title	=> ""}

			@parentsarr = [@parenthash]

		else

			@parent = Binder.find(params[:binder][:parent])

			@parenthash = {	:id		=> params[:binder][:parent],
							:title	=> Binder.find(params[:binder][:parent]).title}

			@parentsarr = @parent.parents << @parenthash

			@parentperarr = @parent.parent_permissions

			@parent.permissions.each do |p|
				p["folder_id"] = params[:binder][:parent]
				@parentperarr << p
			end

		end


		#Update parent counts
		if @parentsarr.size > 1
			pids = @parentsarr.collect {|p| p["id"] || p[:id]}
			
			pids.each {|pid| Binder.find(pid).inc(:folders, 1) if pid != "0"}
		end

		new_binder = Binder.new(	:owner				=> current_teacher.id,
					:title				=> params[:binder][:title].to_s[0..60],
					:parent				=> @parenthash,
					:parents			=> @parentsarr,
					:body				=> params[:binder][:body],
					:permissions		=> (params[:accept] == "1" ? [{:type => params[:type],
											:shared_id => (params[:type] == "1" ? params[:shared_id] : "0"),
											:auth_level => params[:auth_level]}] : []),
					:parent_permissions	=> @parentperarr,
					:last_update		=> Time.now.to_i,
					:last_updated_by	=> current_teacher.id.to_s,
					:type				=> 1)


		new_binder.save

		new_binder.create_binder_tags(params,current_teacher.id)

		redirect_to binder_path(params[:binder][:parent]) and return if params[:binder][:parent] != "0"

		redirect_to binders_path

	end

	def show

		@binder = Binder.find(params[:id])

		redirect_to show_binder_path(@binder.owner, @binder.root, @binder.title, params[:id])

		#TODO: Verify permissions before rendering view

		#TODO: Create content dispostion headers and such
		redirect_to @binder.current_version.data and return if @binder.format == 2

		send_file @binder.current_version.file.path and return if @binder.format == 1

		@title = "Viewing: #{@binder.title}"

		@children = Binder.where("parent.id" => params[:id])

	end


	#TODO: When advanced routing is complete, replace show with nshow (and remove nshow)
	#Specs: Needs to cross check all url variables with :id's properties
	#Redirect/render something else if invalid
	#
	def nshow

		@binder = Binder.find(params[:id])

		#redirect_to show_binder_path(@binder.owner, @binder.root, @binder.title, params[:id])

		#TODO: Verify permissions before rendering view

		#TODO: Create content dispostion headers and such
		redirect_to @binder.current_version.data and return if @binder.format == 2

		send_file @binder.current_version.file.path and return if @binder.format == 1

		@title = "Viewing: #{@binder.title}"

		@children = Binder.where("parent.id" => params[:id])

	end


	def edit

		@title = "Edit binder"

		@binder = Binder.find(params[:id])

		#@binders = Binder.where(:owner => current_teacher.id).reject {|x| x.id == params[:id]}#:id => params[:id])
	end

	def newcontent

		@binders = Binder.where(:owner => current_teacher.id, :type => 1).reject {|b| b.parents.first["id"] == "-1"}

		@title = "Add new content"

	end

	#Add links function
	def createcontent

		@binder = Binder.new

		#Trim to 60 chars (old spec)
		if params[:binder][:title].length < 1
			redirect_to new_binder_content_path and return
		end

		@parenthash = {}
		@parentsarr = []
		@parentperarr = []

		if params[:binder][:parent].to_s == "0"


			@parenthash = {	:id		=> params[:binder][:parent],
							:title	=> ""}

			@parentsarr = [@parenthash]

		else
			
			@parent = Binder.find(params[:binder][:parent])

			@parenthash = {	:id		=> params[:binder][:parent],
							:title	=> Binder.find(params[:binder][:parent]).title}

			@parentsarr = @parent.parents << @parenthash

			@parentperarr = @parent.parent_permissions

			@parent.permissions.each do |p|
				p["folder_id"] = params[:binder][:parent]
				@parentperarr << p
			end

		end

		@binder.update_attributes(	:title				=> params[:binder][:title][0..60],
									:owner				=> current_teacher.id,
									:parent				=> @parenthash,
									:parents			=> @parentsarr,
									:last_update		=> Time.now.to_i,
									:last_updated_by	=> current_teacher.id.to_s,
									:body				=> params[:binder][:body],
									:permissions		=> (params[:accept] == "1" ? [{:type => params[:type],
															:shared_id => (params[:type] == "1" ? params[:shared_id] : "0"),
															:auth_level => params[:auth_level]}] : []),
#									:version			=> Version.new(	:data => params[:binder][:versions][:data],
#																		:timestamp => Time.now.to_i),
									:parent_permissions	=> @parentperarr,
									:files				=> 1,
									:type				=> 2,
									:format				=> 2)

		@binder.versions << Version.new(:data => params[:binder][:versions][:data],
										:timestamp => Time.now.to_i)

		#@binder.save

		pids = @parentsarr.collect {|x| x["id"] || x[:id]}

		pids.each {|id| Binder.find(id).inc(:files, 1) if id != "0"}

		redirect_to binders_path(params[:binder][:parent])

	end

	def update

		alteration_set = Set.new

		@binder = Binder.find(params[:id])

		@binder.update_attributes(	:title				=> params[:binder][:title][0..60],
									:last_update		=> Time.now.to_i,
									:last_updated_by	=> current_teacher.id.to_s,
									:body				=> params[:binder][:body])#,
									#:tags				=> params[:binder][:tags].downcase.split.uniq)

		@binder.tag.update_node_tags(params,current_teacher.id)

		@binder.save

		#alteration_set = @binder.tag.update_node_tags(params,current_teacher.id.to_s)

		@children = Binder.where("parents.id" => params[:id]).sort_by {|binder| binder.parents.length}

		@index = @binder.parents.length

		@children.each do |h|

			h.parent["title"] = params[:binder][:title][0..60] if h.parent["id"] == params[:id]

			h.parents[@index]["title"] = params[:binder][:title][0..60]

			#h.tag.update_parent_tags(alteration_set)
			#h.tag.update_parent_tags(@binder.id)

			h.update_parent_tags()

			h.save

		end

		redirect_to binder_path(@binder)

	end

	#Add new file
	def newfile

		@binders = Binder.where(:owner => current_teacher.id, :type => 1).reject {|b| b.parents.first["id"] == "-1"}

		@title = "Add new files"

	end

	#Add file process
	def createfile

		@binder = Binder.new

		@binder.owner = current_teacher.id

		#Trim to 60 chars (old spec)
		#if params[:binder][:title].length < 1
		#	redirect_to new_binder_path and return
		#end

		@parenthash = {}
		@parentsarr = []
		@parentperarr = []

		if params[:binder][:parent].to_s == "0"

			@parenthash = {	:id		=> params[:binder][:parent],
							:title	=> ""}

			@parentsarr = [@parenthash]

		else

			@parent = Binder.find(params[:binder][:parent])

			@parenthash = {	:id		=> params[:binder][:parent],
							:title	=> Binder.find(params[:binder][:parent]).title}

			@parentsarr = @parent.parents << @parenthash

			@parentperarr = @parent.parent_permissions

			@parent.permissions.each do |p|
				p["folder_id"] = params[:binder][:parent]
				@parentperarr << p
			end

		end


		@binder.update_attributes(
			:title				=> File.basename(params[:binder][:versions][:file].original_filename, File.extname(params[:binder][:versions][:file].original_filename)),
			:owner				=> current_teacher.id,
			:parent				=> @parenthash,
			:parents			=> @parentsarr,
			:last_update		=> Time.now.to_i,
			:last_updated_by	=> current_teacher.id.to_s,
			:body				=> params[:binder][:body],
			:total_size			=> params[:binder][:versions][:file].size,
			:data				=> params[:binder][:versions][:file].path,
			:permissions		=> (params[:accept] == "1" ? [{	:type		=> params[:type],
																:shared_id	=> (params[:type] == "1" ? params[:shared_id] : "0"),
																:auth_level	=> params[:auth_level]}] : []),
			:parent_permissions	=> @parentperarr,
			:files				=> 1,
			:type				=> 2,
			:format				=> 1)

		@binder.versions << Version.new(:file		=> params[:binder][:versions][:file],
										:ext		=> File.extname(params[:binder][:versions][:file].original_filename),
										:size		=> params[:binder][:versions][:file].size,
										:timestamp	=> Time.now.to_i,
										:owner		=> current_teacher.id)


		@binder.save

		pids = @parentsarr.collect {|x| x["id"] || x[:id]}

		pids.each do |id|

			if id != "0"
				parent = Binder.find(id)
				parent.update_attributes(	:files		=> parent.files + 1,
											:total_size	=> parent.total_size + params[:binder][:versions][:file].size)
			end
		end

		redirect_to binder_path(params[:binder][:parent])

	end

	def move

		@binder = Binder.find(params[:id])

		@binders = Binder.where(:owner => current_teacher.id, #Query for possible new parents
								:type => 1).reject {|b| (b.id.to_s == params[:id] || #Reject current Binder
								b.id.to_s == @binder.parent["id"] || #Reject current parent
								b.parents.first["id"] == "-1" || #Reject any trash binders
								b.parents.any? {|c| c["id"] == params[:id]})} #Reject any child folders

	end

	#Process for moving any binders
	#TODO: Add sanity check, make sure no folder-in-self or folder-in-child situation
	def moveitem

		@binder = Binder.find(params[:id])

		@binder.tag.debug_data << "params[id]"
		@binder.tag.debug_data << params[:id]
		@binder.save

		@parenthash = {}
		@parentsarr = []

		if params[:binder][:parent].to_s == "0"

			@parenthash = {	:id		=> params[:binder][:parent],
							:title	=> ""}

			@parentsarr = [@parenthash]

		else

			@parenthash = {	:id		=> params[:binder][:parent],
							:title	=> Binder.find(params[:binder][:parent]).title}

			@parentsarr = Binder.find(params[:binder][:parent]).parents << @parenthash

		end

		#OP = Original Parent
		if @binder.parent["id"] != "0"
			@op = Binder.find(@binder.parent["id"])

			@op.update_attributes(	:files		=> @op.files - @binder.files,
									:folders	=> @op.folders - @binder.folders - (@binder.type == 1 ? 1 : 0),
									:total_size	=> @op.total_size - @binder.total_size)
		end

		@binder.update_attributes(	:parent		=> @parenthash,
									:parents	=> @parentsarr)

		#@binder.tag.debug_data << "parent hash"
		#@binder.tag.debug_data << @parenthash
		@binder.save

		# must update the common ancestor of the children before 
		@binder.update_parent_tags()

		#@binder is the object being moved
		#If directory, deal with the children
		if @binder.type == 1 #Eventually will apply to type == 3 too

			#@index = @binder.parents.index({@binder})

			@children = Binder.where("parents.id" => params[:id])

			#Something is broken here....
			@children.each do |h|

				@current_parents = h.parents

				@size = @current_parents.size

				h.update_attributes(:parents => @parentsarr + @current_parents[(@current_parents.index({"id" => @binder.id.to_s, "title" => @binder.title}))..(@size - 1)])

				h.update_parent_tags()

			end

		end

		@parents = @binder.parents.collect {|x| x["id"] || x[:id]}

		@parents.each do |pid|
			if pid != "0"
				parent = Binder.find(pid)

				parent.update_attributes(	:files		=> parent.files + @binder.files,
											:folders	=> parent.folders + @binder.folders + (@binder.type == 1 ? 1 : 0),
											:total_size	=> parent.total_size + @binder.total_size)
			end
		end

		redirect_to binder_path(params[:binder][:parent]) and return if params[:binder][:parent] != "0"

		redirect_to binders_path

	end

	#Copy will only be available to current user
	#(Nearly the same functionality as fork without updating fork counts)
	def copy

		@binder = Binder.find(params[:id])

		@binders = Binder.where(:owner => current_teacher.id,
								:type => 1).reject {|b| (b.id.to_s == params[:id] ||
														b.id.to_s == @binder.parent["id"] ||
														b.parents.any? {|c| c["id"] == params[:id]})}

	end

	#Copy Binders to new location
	def copyitem

		@binder = Binder.find(params[:id])

		@parenthash = {}
		@parentsarr = []


		if params[:binder][:parent].to_s == "0"

			@parenthash = {	:id		=> params[:binder][:parent],
							:title	=> ""}

			@parentsarr = [@parenthash]

		else

			@parenthash = {	:id		=> params[:binder][:parent],
							:title	=>  Binder.find(params[:binder][:parent]).title}

			@parentsarr = Binder.find(params[:binder][:parent]).parents << @parenthash

		end

		@new_parent = Binder.new(	:title				=> @binder.title,
									:body				=> @binder.body,
									:type				=> @binder.type,
									:format				=> @binder.type == 2 ? @binder.format : nil,
									:files				=> @binder.files,
									:folders			=> @binder.folders,
									:total_size			=> @binder.total_size,
									:parent				=> @parenthash,
									:parents			=> @parentsarr,
									:owner				=> current_teacher.id,
									:last_update		=> Time.now.to_i,
									:last_updated_by	=> current_teacher.id)

		#@new_parent.format = @binder.format if @binder.type == 2

		#TODO: Create new version instead of using @binder's last version
		@new_parent.versions << @binder.current_version if @binder.type != 1

		@new_parent.save

		@new_parent.tag = Tag.new(	:node_tags => @binder.tag.node_tags)

		@new_parent.update_parent_tags()

		@hash_index = {params[:id] => @new_parent.id.to_s}


		#If directory, deal with the children
		if @binder.type == 1 #Eventually will apply to type == 3 too

			@index = @binder.parents.length

			#Select old children, order by parents.length
			@children = Binder.where("parents.id" => params[:id]).sort_by {|binder| binder.parents.length}

			#Spawn new children, These children need to have updated parent ids
			@children.each do |h|

				@node_parent = {"id"	=> @hash_index[h.parent["id"]],
								"title"	=> h.parent["title"]}

				@node_parents = Binder.find(@hash_index[h.parent["id"]]).parents << @node_parent

				@new_node = Binder.new(	:title				=> h.title,
										:body				=> h.body,
										:parent				=> @node_parent,
										:parents			=> @node_parents,
										:owner				=> current_teacher.id,
										:last_update		=> Time.now.to_i,
										:last_updated_by	=> current_teacher.id,
										:type				=> h.type)

				@new_node.format = h.format if h.type != 1

				#TODO: Fork should also accept old versions
				@new_node.versions << Version.new(
					:owner		=> h.current_version.owner,
					:timestamp	=> h.current_version.timestamp,
					:size		=> h.current_version.size,
					:ext		=> h.current_version.ext,
					:data		=> h.current_version.data,
					:file		=> h.format == 1 ? h.current_version.file : nil)

				@new_node.save

				@new_node.tag = Tag.new(:node_tags => h.tag.node_tags)

				@new_node.update_parent_tags()

				@hash_index[h.id.to_s] = @new_node.id.to_s
			end

		end

		@parents = @new_parent.parents.collect {|x| x["id"] || x[:id]}

		@parents.each do |pid|
			if pid != "0"
				parent = Binder.find(pid)

				parent.update_attributes(	:files		=> parent.files + @new_parent.files,
											:folders	=> parent.folders + @new_parent.folders + (@new_parent.type == 1 ? 1 : 0),
											:total_size	=> parent.total_size + @new_parent.total_size)
			end
		end

		redirect_to binder_path(params[:binder][:parent]) and return if params[:binder][:parent] != "0"

		redirect_to binders_path
	end


	def fork

		@binder = Binder.find(params[:id])

		redirect_to binder_path(params[:id]) and return if @binder.owner == current_teacher.id.to_s

		@binders = Binder.where(:owner => current_teacher.id, :type => 1)

	end

	#Copy Binders to new location
	def forkitem

		@binder = Binder.find(params[:id])

		@parenthash = {}
		@parentsarr = []


		if params[:binder][:parent].to_s == "0"

			@parenthash = {	:id		=> params[:binder][:parent],
							:title	=> ""}

			@parentsarr = [@parenthash]

		else

			@parenthash = {	:id		=> params[:binder][:parent],
							:title	=>  Binder.find(params[:binder][:parent]).title}

			@parentsarr = Binder.find(params[:binder][:parent]).parents << @parenthash

		end

		@new_parent = Binder.new(	:title				=> @binder.title,
									:body				=> @binder.body,
									:type				=> @binder.type,
									:files				=> @binder.files,
									:folders			=> @binder.folders,
									:total_size			=> @binder.total_size,
									:parent				=> @parenthash,
									:parents			=> @parentsarr,
									:owner				=> current_teacher.id,
									:last_update		=> Time.now.to_i,
									:last_updated_by	=> current_teacher.id,
									:format				=> @binder.type == 2 ? @binder.format : nil)

		#@new_parent.format = @binder.format if @binder.type == 2


		#TODO: Create new version instead of using @binder's last version
		@new_parent.versions << @binder.current_version if @binder.type != 1

		@new_parent.save

		@hash_index = {params[:id] => @new_parent.id.to_s}


		#If directory, deal with the children
		if @binder.type == 1 #Eventually will apply to type == 3 too

			@index = @binder.parents.length

			#Select old children, order by parents.length
			@children = Binder.where("parents.id" => params[:id]).sort_by {|binder| binder.parents.length}

			#Spawn new children, These children need to have updated parent ids
			@children.each do |h|

				@node_parent = {"id"	=> @hash_index[h.parent["id"]],
								"title"	=> h.parent["title"]}

				@node_parents = Binder.find(@hash_index[h.parent["id"]]).parents << @node_parent

				@new_node = Binder.new(	:title				=> h.title,
										:body				=> h.body,
										:parent				=> @node_parent,
										:parents			=> @node_parents,
										:owner				=> current_teacher.id,
										:last_update		=> h.last_update,
										:last_updated_by	=> current_teacher.id,
										:type				=> h.type,
										:forked_from		=> h.versions.last.id,
										:fork_stamp			=> Time.now.to_i)

				@new_node.format = h.format if h.type != 1

				@new_node.versions << Version.new(
					:owner		=> h.current_version.owner,
					:timestamp	=> h.current_version.timestamp,
					:size		=> h.current_version.size,
					:ext		=> h.current_version.ext,
					:data		=> h.current_version.data,
					:file		=> h.format == 1 ? h.current_version.file : nil)

				@new_node.save

				h.inc(:fork_total, 1)

				@hash_index[h.id.to_s] = @new_node.id.to_s
			end

		end


		@parents = @new_parent.parents.collect {|x| x["id"] || x[:id]}

		@parents.each do |pid|
			if pid != "0"
				parent = Binder.find(pid)

				parent.update_attributes(	:files		=> parent.files + @new_parent.files,
											:folders	=> parent.folders + @new_parent.folders + (@new_parent.type == 1 ? 1 : 0),
											:total_size	=> parent.total_size + @new_parent.total_size)
			end
		end

		redirect_to binder_path(params[:binder][:parent]) and return if params[:binder][:parent] != "0"

		redirect_to binders_path
	end

	def newversion
		@binder = Binder.find(params[:id])

		redirect_to binder_path(@binder) if @binder.type != 2
	end

	def createversion
		@binder = Binder.find(params[:id])

		@binder.versions.each {|v| v.update_attributes(:active => false)}

		if @binder.format == 1
			#TODO: Need to update parents' size
			@binder.update_attributes(:total_size => params[:binder][:versions][:file].size)

			@binder.versions << Version.new(:file		=> params[:binder][:versions][:file],
											:ext		=> File.extname(params[:binder][:versions][:file].original_filename),
											:size		=> params[:binder][:versions][:file].size,
											:timestamp	=> Time.now.to_i,
											:active		=> true)
		#TODO: Use nil to merge the ifs
		elsif @binder.format == 2
			@binder.versions << Version.new(:data		=> params[:binder][:versions][:data],
											:timestamp	=> Time.now.to_i,
											:active		=> true)
		end

		redirect_to binder_path(@binder.parent["id"])
	end

	def versions
		@binder = Binder.find(params[:id])

		redirect_to binder_path(@binder.parent["id"]) and return if @binder.type == 1 && @binder.parent["id"] != "0"

		redirect_to binders_path if @binder.type == 1
	end

	def swap
		@binder = Binder.find(params[:id])

		@binder.versions.each {|v| v.update_attributes(:active => v.id.to_s == params[:version][:id])}

		redirect_to binder_path(@binder.parent["id"])
	end

	#Only owner can set permissions
	def permissions
		@binder = Binder.find(params[:id])

		@title = "Permissions for #{@binder.title}"

		#To be replaced with current_teacher.colleagues
		@colleagues = Teacher.all.reject {|t| t == current_teacher}
	end

	def createpermission
		@binder = Binder.find(params[:id])

		@new = false

		@binder.permissions.each {|p| @new = true if p["shared_id"] == params[:shared_id]}

		@binder.parent_permissions.each {|pp| @new = true if pp["shared_id"] == params[:shared_id]} 

		@binder.permissions << {:type => params[:type],
								:shared_id => (params[:type] == "1" ? params[:shared_id] : "0"),
								:auth_level => params[:auth_level]} if !@new

		@binder.save

		@children = Binder.where("parents.id" => params[:id])

		@children.each {|c| c.update_attributes(:parent_permissions => c.parent_permissions << {:type => params[:type],
																								:shared_id => params[:shared_id],
																								:auth_level => params[:auth_level],
																								:folder_id => params[:id]})} if !@new

		redirect_to binder_permissions_path(params[:id])
	end

	def destroypermission
		@binder = Binder.find(params[:id])

		@binder.permissions.delete_at(params[:pid].to_i)

		@binder.save

		redirect_to binder_permissions_path(params[:id])
	end

	def trash
		@binders = Binder.where(:owner => current_teacher.id, "parent.id" => "-1")

		@title = "#{current_teacher.fname} #{current_teacher.lname}'s Trash"
	end

	#More validation needed
	#TODO: Move "deleted" entries to a separate collection?
	def destroy
		@binder = Binder.find(params[:id])

		@parenthash = {	:id		=> "-1",
						:title	=> ""}

		@parentsarr = [@parenthash]

		#OP = Original Parent
		if @binder.parent["id"] != "0"
			@op = Binder.find(@binder.parent["id"])

			@op.update_attributes(	:files		=> @op.files - @binder.files,
									:folders	=> @op.folders - @binder.folders - (@binder.type == 1 ? 1 : 0),
									:total_size	=> @op.total_size - @binder.total_size)
		end

		@binder.update_attributes(	:parent		=> @parenthash,
									:parents	=> @parentsarr)


		#If directory, deal with the children
		if @binder.type == 1 #Eventually will apply to type == 3 too

			#@index = @binder.parents.length

			@children = Binder.where("parents.id" => params[:id])

			@children.each do |h|
				@current_parents = h.parents
				@size = @current_parents.size
				h.update_attributes(:parents => @parentsarr + @current_parents[(@current_parents.index({"id" => @binder.id.to_s, "title" => @binder.title}))..(@size - 1)])
			end

		end


		@parents = @binder.parents.collect {|x| x["id"] || x[:id]}

		@parents.each do |pid|
			if pid != "-1"
				parent = Binder.find(pid)

				parent.update_attributes(	:files		=> parent.files + @binder.files,
											:folders	=> parent.folders + @binder.folders + (@binder.type == 1 ? 1 : 0),
											:total_size	=> parent.total_size + @binder.total_size)
			end
		end

		redirect_to binder_path(@op) and return if defined?(@op)

		redirect_to binders_path

	end

end
