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

		@new_binder.tag = Tag.new

		@colleagues = Teacher.all.reject {|t| t == current_teacher}

	end

	#Add Folder Function
	def create
		#Trim to 60 chars (old spec)
		if params[:binder][:title].length < 1
			redirect_to new_binder_path and return
		end

		#TODO: Write helper functions to populate the three arrays/hashes and use in all three create functions
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
							:title	=> @parent.title}

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

		new_binder = Binder.new(:owner				=> current_teacher.id,
								:fname				=> current_teacher.fname,
								:lname				=> current_teacher.lname,
								:username			=> current_teacher.username,
								:title				=> params[:binder][:title].to_s[0..60],
								:parent				=> @parenthash,
								:parents			=> @parentsarr,
								:body				=> params[:binder][:body],
								:permissions		=> (params[:accept] == "1" ? [{	:type		=> params[:type],
																					:shared_id	=> (params[:type] == "1" ? params[:shared_id] : "0"),
																					:auth_level	=> params[:auth_level]}] : []),
								:parent_permissions	=> @parentperarr,
								:last_update		=> Time.now.to_i,
								:last_updated_by	=> current_teacher.id.to_s,
								:type				=> 1)

		new_binder.save

		new_binder.create_binder_tags(params,current_teacher.id)

		redirect_to named_binder_route(params[:binder][:parent]) and return if params[:binder][:parent] != "0"

		redirect_to binders_path

	end

	def show

		@binder = Binder.find(params[:id])

		redirect_to "/404.html" and return if !binder_routing_ok?(@binder, params[:action])

		#redirect_to show_binder_path(@binder.owner, @binder.root, @binder.title, params[:id])

		#TODO: Verify permissions before rendering view

		redirect_to @binder.current_version.data and return if @binder.format == 2

		send_file @binder.current_version.file.path and return if @binder.format == 1

		@title = "Viewing: #{@binder.title}"

		@children = Binder.where("parent.id" => params[:id])
		
		rescue BSON::InvalidObjectId
			redirect_to "/404.html" and return

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
							:title	=> @parent.title}

			@parentsarr = @parent.parents << @parenthash

			@parentperarr = @parent.parent_permissions

			@parent.permissions.each do |p|
				p["folder_id"] = params[:binder][:parent]
				@parentperarr << p
			end

		end

		@binder.update_attributes(	:title				=> params[:binder][:title][0..60],
									:owner				=> current_teacher.id,
									:username			=> current_teacher.username,
									:fname				=> current_teacher.fname,
									:lname				=> current_teacher.lname,
									:parent				=> @parenthash,
									:parents			=> @parentsarr,
									:last_update		=> Time.now.to_i,
									:last_updated_by	=> current_teacher.id.to_s,
									:body				=> params[:binder][:body],
									:permissions		=> (params[:accept] == "1" ? [{:type => params[:type],
															:shared_id => (params[:type] == "1" ? params[:shared_id] : "0"),
															:auth_level => params[:auth_level]}] : []),
#Not working						:version			=> Version.new(	:data => params[:binder][:versions][:data],
#																		:timestamp => Time.now.to_i),
									:parent_permissions	=> @parentperarr,
									:files				=> 1,
									:type				=> 2,
									:format				=> 2)

		@binder.versions << Version.new(:data		=> params[:binder][:versions][:data],
										:timestamp	=> Time.now.to_i,
										:owner		=> current_teacher.id)

		#@binder.save

		@binder.create_binder_tags(params,current_teacher.id)

		pids = @parentsarr.collect {|x| x["id"] || x[:id]}

		pids.each {|id| Binder.find(id).inc(:files, 1) if id != "0"}

		redirect_to named_binder_route(params[:binder][:parent])

	end

	def update

		@binder = Binder.find(params[:id])

		@binder.update_attributes(	:title				=> params[:binder][:title][0..60],
									:last_update		=> Time.now.to_i,
									:last_updated_by	=> current_teacher.id.to_s,
									:body				=> params[:binder][:body])

		@binder.tag.update_node_tags(params,current_teacher.id)

		@children = Binder.where("parents.id" => params[:id]).sort_by {|binder| binder.parents.length}

		@index = @binder.parents.length

		@children.each do |h|

			h.parent["title"] = params[:binder][:title][0..60] if h.parent["id"] == params[:id]

			h.parents[@index]["title"] = params[:binder][:title][0..60]
			h.update_parent_tags()

			h.save

		end

		redirect_to named_binder_route(@binder.parent["id"]) and return if @binder.parent["id"] != "0"

		redirect_to binders_path

	end

	#Add new file
	def newfile

		@binders = Binder.where(:owner => current_teacher.id, :type => 1).reject {|b| b.parents.first["id"] == "-1"}

		@title = "Add new files"

	end

	#Add file process
	def createfile

		@binder = Binder.new

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
							:title	=> @parent.title}

			@parentsarr = @parent.parents << @parenthash

			@parentperarr = @parent.parent_permissions

			@parent.permissions.each do |p|
				p["folder_id"] = params[:binder][:parent]
				@parentperarr << p
			end

		end


		@binder.update_attributes(
			:title				=> File.basename(	params[:binder][:versions][:file].original_filename,
													File.extname(params[:binder][:versions][:file].original_filename)),
			:owner				=> current_teacher.id,
			:fname				=> current_teacher.fname,
			:lname				=> current_teacher.lname,
			:parent				=> @parenthash,
			:parents			=> @parentsarr,
			:last_update		=> Time.now.to_i,
			:last_updated_by	=> current_teacher.id.to_s,
			:body				=> params[:binder][:body],
			:total_size			=> params[:binder][:versions][:file].size,
			:permissions		=> (params[:accept] == "1" ? [{	:type		=> params[:type],
																:shared_id	=> (params[:type] == "1" ? params[:shared_id] : "0"),
																:auth_level	=> params[:auth_level]}] : []),
			:parent_permissions	=> @parentperarr,
			:files				=> 1,
			:type				=> 2,
			:format				=> 1)

		@binder.versions << Version.new(:file		=> params[:binder][:versions][:file],
										:ext		=> File.extname(params[:binder][:versions][:file].original_filename),
										:data		=> params[:binder][:versions][:file].path,
										:size		=> params[:binder][:versions][:file].size,
										:timestamp	=> Time.now.to_i,
										:owner		=> current_teacher.id)

		@binder.create_binder_tags(params,current_teacher.id)

		pids = @parentsarr.collect {|x| x["id"] || x[:id]}

		pids.each do |id|

			if id != "0"
				parent = Binder.find(id)
				parent.update_attributes(	:files		=> parent.files + 1,
											:total_size	=> parent.total_size + params[:binder][:versions][:file].size)
			end
		end

		redirect_to named_binder_route(params[:binder][:parent])

	end

	def move

		@binder = Binder.find(params[:id])

		redirect_to "/404.html" and return if !binder_routing_ok?(@binder, params[:action])

		@binders = Binder.where(:owner => current_teacher.id, #Query for possible new parents
								:type => 1).reject {|b| (b.id.to_s == params[:id] || #Reject current Binder
														(b.id.to_s == @binder.parent["id"]) || #Reject current parent
														(b.parents.first["id"] == "-1") || #Reject any trash binders
														(b.parents.any? {|c| c["id"] == params[:id]}))} #Reject any child folders

	end

	#Process for moving any binders
	#TODO: Add sanity check, make sure no folder-in-self or folder-in-child situation
	def moveitem

		@binder = Binder.find(params[:id])

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
							:title	=> @parent.title}

			@parentsarr = @parent.parents << @parenthash

			@parentperarr = @parent.parent_permissions

			@parent.permissions.each do |p|
				p["folder_id"] = params[:binder][:parent]
				@parentperarr << p
			end

		end

		@ops = @binder.parents.collect {|x| x["id"] || x[:id]}
		@ops.each do |opid|
			if opid != "0"
				op = Binder.find(opid)

				op.update_attributes(	:files		=> op.files - @binder.files,
										:folders	=> op.folders - @binder.folders - (@binder.type == 1 ? 1 : 0),
										:total_size	=> op.total_size - @binder.total_size)
			end
		end

		#Save old permissions to remove childrens' inherited permissions
		@ppers = @binder.parent_permissions

		@binder.update_attributes(	:parent				=> @parenthash,
									:parents			=> @parentsarr,
									:parent_permissions	=> @parentperarr)


		# must update the common ancestor of the children before 
		@binder.update_parent_tags()

		#@binder is the object being moved
		#If directory, deal with the children
		if @binder.type == 1 #Eventually will apply to type == 3 too

			@children = Binder.where("parents.id" => params[:id])

			@children.each do |h|

				@current_parents = h.parents

				@size = @current_parents.size

				@npperarr = h.parent_permissions
				
				@ppers.each {|p| @npperarr.delete(p)}

				h.update_attributes(:parents			=> @parentsarr + @current_parents[(@current_parents.index({"id" => @binder.id.to_s, "title" => @binder.title}))..(@size - 1)],
									:parent_permissions	=> @parentperarr + @npperarr)

				h.update_parent_tags()

			end

		end

		#Update new parents' folder/file/size counts
		@parents = @binder.parents.collect {|x| x["id"] || x[:id]}

		@parents.each do |pid|
			if pid != "0"
				parent = Binder.find(pid)

				parent.update_attributes(	:files		=> parent.files + @binder.files,
											:folders	=> parent.folders + @binder.folders + (@binder.type == 1 ? 1 : 0),
											:total_size	=> parent.total_size + @binder.total_size)
			end
		end

		redirect_to named_binder_route(params[:binder][:parent]) and return if params[:binder][:parent] != "0"

		redirect_to binders_path

	end

	#Copy will only be available to current user
	#(Nearly the same functionality as fork without updating fork counts)
	def copy		

		@binder = Binder.find(params[:id])

		redirect_to "/404.html" and return if !binder_routing_ok?(@binder, params[:action])

		@binders = Binder.where(:owner => current_teacher.id,
								:type => 1).reject {|b| (b.id.to_s == params[:id] ||
														b.id.to_s == @binder.parent["id"] ||
														b.parents.first["id"] == "-1" ||
														b.parents.any? {|c| c["id"] == params[:id]})}

	end

	#Copy Binders to new location
	def copyitem

		@binder = Binder.find(params[:id])

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
							:title	=> @parent.title}

			@parentsarr = @parent.parents << @parenthash

			@parentperarr = @parent.parent_permissions

			@parent.permissions.each do |p|
				p["folder_id"] = params[:binder][:parent]
				@parentperarr << p
			end

		end

		@ppers = @binder.parent_permissions

		@new_parent = Binder.new(	:title				=> @binder.title,
									:body				=> @binder.body,
									:type				=> @binder.type,
									:format				=> @binder.type == 2 ? @binder.format : nil,
									:files				=> @binder.files,
									:folders			=> @binder.folders,
									:total_size			=> @binder.total_size,
									:parent				=> @parenthash,
									:parents			=> @parentsarr,
									:permissions		=> @binder.permissions,
									:parent_permissions	=> @parentperarr,
									:owner				=> current_teacher.id,
									:last_update		=> Time.now.to_i,
									:last_updated_by	=> current_teacher.id)

		#@new_parent.format = @binder.format if @binder.type == 2

		@new_parent.versions << Version.new(:owner		=> @binder.current_version.owner,
											:timestamp	=> @binder.current_version.timestamp,
											:size		=> @binder.current_version.size,
											:ext		=> @binder.current_version.ext,
											:data		=> @binder.current_version.data,
											:file		=> @binder.format == 1 ? @binder.current_version.file : nil) if @binder.type == 2

		@new_parent.save

		@new_parent.tag = Tag.new(	:node_tags => @binder.tag.node_tags)

		@new_parent.update_parent_tags()

		#Hash table for oldid => newid lookups
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

				@old_permissions = h.parent_permissions

				@ppers.each {|p| @old_permissions.delete(p)}

				#Swap old folder ids with new folder ids
				@old_permissions.each {|op| op["folder_id"] = @hash_index[op["folder_id"]]}

				@new_node = Binder.new(	:title				=> h.title,
										:body				=> h.body,
										:parent				=> @node_parent,
										:parents			=> @node_parents,
										:permissions		=> h.permissions,
										:parent_permissions	=> @parentperarr + @old_permissions,
										:owner				=> current_teacher.id,
										:last_update		=> Time.now.to_i,
										:last_updated_by	=> current_teacher.id,
										:type				=> h.type,
										:format				=> (h.type != 1 ? h.format : nil),
										:files				=> h.files,
										:folders			=> h.folders,
										:total_size			=> h.total_size)

				@new_node.versions << Version.new(	:owner		=> h.current_version.owner,
													:timestamp	=> h.current_version.timestamp,
													:size		=> h.current_version.size,
													:ext		=> h.current_version.ext,
													:data		=> h.current_version.data,
													:file		=> h.format == 1 ? h.current_version.file : nil) if h.type == 2

				@new_node.save

				@new_node.tag = Tag.new(:node_tags => h.tag.node_tags)

				@new_node.update_parent_tags()

				@hash_index[h.id.to_s] = @new_node.id.to_s
			end

		end

		#Update parents' folder/file/size counts
		@parents = @new_parent.parents.collect {|x| x["id"] || x[:id]}

		@parents.each do |pid|
			if pid != "0"
				parent = Binder.find(pid)

				parent.update_attributes(	:files		=> parent.files + @new_parent.files,
											:folders	=> parent.folders + @new_parent.folders + (@new_parent.type == 1 ? 1 : 0),
											:total_size	=> parent.total_size + @new_parent.total_size)
			end
		end

		redirect_to named_binder_route(params[:binder][:parent]) and return if params[:binder][:parent] != "0"

		redirect_to binders_path
	end


	def fork

		@binder = Binder.find(params[:id])

		redirect_to named_binder_route(params[:id]) and return if @binder.owner == current_teacher.id.to_s

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

			@parent = Binder.find(params[:binder][:parent])

			@parenthash = {	:id		=> params[:binder][:parent],
							:title	=> @parent.title}

			@parentsarr = @parent.parents << @parenthash

			@parentperarr = @parent.parent_permissions

			@parent.permissions.each do |p|
				p["folder_id"] = params[:binder][:parent]
				@parentperarr << p
			end
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


		@new_parent.versions << Version.new(:owner		=> @binder.current_version.owner,
											:timestamp	=> @binder.current_version.timestamp,
											:size		=> @binder.current_version.size,
											:ext		=> @binder.current_version.ext,
											:data		=> @binder.current_version.data,
											:file		=> @binder.format == 1 ? @binder.current_version.file : nil) if @binder.type == 2

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
										:format				=> (h.type != 1 ? h.format : nil),
										:forked_from		=> h.versions.last.id,
										:fork_stamp			=> Time.now.to_i)

				@new_node.versions << Version.new(	:owner		=> h.current_version.owner,
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

		redirect_to named_binder_route(@parent) and return if params[:binder][:parent] != "0"

		redirect_to binders_path
	end

	def newversion
		@binder = Binder.find(params[:id])

		redirect_to named_binder_route(@binder) if @binder.type != 2
	end

	def createversion
		@binder = Binder.find(params[:id])

		@old_size = @binder.total_size

		@binder.versions.each {|v| v.update_attributes(:active => false)}

		@binder.versions << Version.new(:file		=> params[:binder][:versions][:file],
										:ext		=> (@binder.format == 1 ? File.extname(params[:binder][:versions][:file].original_filename) : nil),
										:size		=> (@binder.format == 1 ? params[:binder][:versions][:file].size : nil),
										:data		=> (@binder.format == 1 ? params[:binder][:versions][:file].path : params[:binder][:versions][:data]),
										:timestamp	=> Time.now.to_i,
										:active		=> true)
		if @binder.format == 1 && @old_size != params[:binder][:versions][:file].size

			@binder.update_attributes(:total_size => params[:binder][:versions][:file].size)

			@parents = @binder.parents.collect {|x| x["id"] || x[:id]}

			@parents.each do |pid|
				if pid != "0"
					parent = Binder.find(pid)

					@parent = parent if pid == @binder.parent["id"]

					parent.update_attributes(:total_size	=> parent.total_size - @old_size + @binder.total_size)
				end
			end

		end

		redirect_to named_binder_route(@parent || @binder.parent["id"])
	end

	def versions
		@binder = Binder.find(params[:id])

		redirect_to named_binder_route(@binder.parent["id"]) and return if @binder.type == 1 && @binder.parent["id"] != "0"

		redirect_to binders_path if @binder.type == 1
	end

	def swap
		@binder = Binder.find(params[:id])

		@binder.versions.each {|v| v.update_attributes(:active => v.id.to_s == params[:version][:id])}

		redirect_to named_binder_route(@binder.parent["id"])
	end

	#Only owner can set permissions
	def permissions
		@binder = Binder.find(params[:id])

		redirect_to "/404.html" and return if current_teacher.id.to_s != @binder.owner

		@title = "Permissions for #{@binder.title}"

		#To be replaced with current_teacher.colleagues
		@colleagues = Teacher.all.reject {|t| t == current_teacher}
	end

	def createpermission
		@binder = Binder.find(params[:id])

		@new = false

		@binder.permissions.each {|p| @new = true if p["shared_id"] == params[:shared_id]}

		@binder.parent_permissions.each {|pp| @new = true if pp["shared_id"] == params[:shared_id]} 

		@binder.permissions << {:type		=> params[:type],
								:shared_id	=> (params[:type] == "1" ? params[:shared_id] : "0"),
								:auth_level	=> params[:auth_level]} if !@new

		@binder.save

		@children = Binder.where("parents.id" => params[:id])

		@children.each {|c| c.update_attributes(:parent_permissions => c.parent_permissions << {:type => params[:type],
																								:shared_id => params[:shared_id],
																								:auth_level => params[:auth_level],
																								:folder_id => params[:id]})} if !@new

		redirect_to named_binder_route(@binder, "permissions")
	end

	def destroypermission
		@binder = Binder.find(params[:id])

		pper = @binder.permissions[params[:pid].to_i]

		pper["folder_id"] = params[:id]

		@binder.permissions.delete_at(params[:pid].to_i)

		@children = Binder.where("parents.id" => params[:id])

		@children.each do |c|
			c.parent_permissions.delete(pper)
			c.save
		end

		@binder.save

		redirect_to named_binder_route(@binder, "permissions")
	end

	def trash
		@binders = Binder.where(:owner => current_teacher.id, "parent.id" => "-1")

		redirect_to "/404.html" and return if params[:username] != current_teacher.username

		@title = "#{current_teacher.fname} #{current_teacher.lname}'s Trash"
	end

	#More validation needed, Permissions
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

		redirect_to named_binder_route(@op) and return if defined?(@op)

		redirect_to binders_path

	end



	#HELPERS:

	#Because named_binder_route can accept an id or object, so can this check
	def binder_routing_ok?(binder, action)

		return request.fullpath == named_binder_route(binder, action)

	end

	#Function that returns routing given a binder object and action
	#Only works for routes in the format of: /username/portfolio(/root)/title/id/action(s)
	#Binder objects preferred over ids
	def named_binder_route(binder, action = "show")

		return "/#{binder.handle}/portfolio#{binder.parents.length == 1 ? String.new : "/" + CGI.escape(binder.root)}/#{CGI.escape(binder.title)}/#{binder.id}#{action == "show" ? String.new : "/#{action}"}" if binder.class == Binder

		return named_binder_route(Binder.find(binder), action) if binder.class == String

		return "/500.html"

	end

end