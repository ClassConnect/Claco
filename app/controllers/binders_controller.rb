class BindersController < ApplicationController
	before_filter :authenticate_teacher!

	def index
		@binders = Binder.where(:owner => current_teacher.id, "parent.id" => "0")

		@title = "#{current_teacher.fname} #{current_teacher.lname}'s Binders"
	end

	def new
		@binders = Binder.where(:owner => current_teacher.id, :type => 1)

		@title = "Create a new binder"
	end

	#TODO: Implement size and file count
	#Add Folder Function
	def create
		#Trim to 60 chars (old spec)
		if params[:binder][:title].length < 1
			redirect_to new_binder_path and return
		end

		@parenthash = {}
		@parentsarr = []

		if params[:binder][:parent].to_s == "0"

			@parenthash = {	:id		=> params[:binder][:parent],
							:title	=> ""}

			@parentsarr = [@parenthash]

		else

			@parenthash = {	:id 	=> params[:binder][:parent],
							:title 	=> Binder.find(params[:binder][:parent]).title}

			@parentsarr = Binder.find(params[:binder][:parent]).parents << @parenthash

		end


		#Update parent counts
		if @parentsarr.size > 1
			pids = @parentsarr.map {|p| p["id"] || p[:id]}
			
			pids.each do |pid|

				Binder.find(pid).inc(:folders, 1) if pid != "0"

			end
		end

		Binder.new(	:owner				=> current_teacher.id,
					:title				=> params[:binder][:title].to_s[0..60],
					:parent				=> @parenthash,
					:parents			=> @parentsarr,
					:last_update		=> Time.now.to_i,
					:last_updated_by	=> current_teacher.id.to_s,
					:body				=> params[:binder][:body],
					:type				=> 1).save


		redirect_to binder_path(params[:binder][:parent]) and return if params[:binder][:parent] != "0"

		redirect_to binders_path

	end

	def show

		@binder = Binder.find(params[:id])

		#TODO: Verify permissions before rendering view

		#TODO: Create content dispostion headers and such
		redirect_to @binder.versions.last.data and return if @binder.format == 2

		redirect_to @binder.versions.last.file.url and return if @binder.format == 1

		@title = "Viewing: #{@binder.title}"

		@children = Binder.where("parent.id" => params[:id])

	end

	def edit
		@title = "Edit binder"

		@binder = Binder.find(params[:id])

		#@binders = Binder.where(:owner => current_teacher.id).reject {|x| x.id == params[:id]}#:id => params[:id])
	end

	def newcontent

		@binders = Binder.where(:owner => current_teacher.id, :type => 1)

		@title = "Add new content"

	end

	#Add links function
	def createcontent

		@binder = Binder.new

		#Trim to 60 chars (old spec)
		if params[:binder][:title].length < 1
			redirect_to new_binder_path and return
		end
		
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

		@binder.update_attributes(	:title				=> params[:binder][:title][0..60],
									:owner				=> current_teacher.id,
									:parent				=> @parenthash,
									:parents			=> @parentsarr,
									:last_update		=> Time.now.to_i,
									:last_updated_by	=> current_teacher.id.to_s,
									:body				=> params[:binder][:body],
									:files				=> 1,
									:type				=> 2,
									:format				=> 2)

		@binder.versions << Version.new(:data => params[:binder][:versions][:data],
										:timestamp => Time.now.to_i)

		@binder.save

		pids = @parentsarr.map {|x| x["id"] || x[:id]}

		pids.each do |id|

			Binder.find(id).inc(:files, 1) if id != "0"

		end

		redirect_to binders_path(params[:binder][:parent])

	end

	#TODO: Version control, File/link update support
	def update
		@binder = Binder.find(params[:id])

		@binder.update_attributes(	:title				=> params[:binder][:title][0..60],
									:last_update		=> Time.now.to_i,
									:last_updated_by	=> current_teacher.id.to_s,
									:body				=> params[:binder][:body])

		#@binder.save

		@children = Binder.where("parents.id" => params[:id])

		@index = @binder.parents.length

		@children.each do |h|

			h.parent["title"] = params[:binder][:title][0..60] if h.parent["id"] == params[:id]

			h.parents[@index]["title"] = params[:binder][:title][0..60]

			h.save

		end

		redirect_to binder_path(@binder)

	end

	#Add new file
	def newfile

		@binders = Binder.where(:owner => current_teacher.id, :type => 1)

		@title = "Add new content"

	end

	#Add file process
	def createfile

		@binder = Binder.new

		@parenthash = {}
		@parentsarr = []

		if params[:binder][:parent].to_s == "0"

			@parenthash = {	:id 	=> params[:binder][:parent],
							:title 	=> ""}

			@parentsarr = [@parenthash]

		else

			@parenthash = {	:id 	=> params[:binder][:parent],
							:title 	=>  Binder.find(params[:binder][:parent]).title}

			@parentsarr = Binder.find(params[:binder][:parent]).parents << @parenthash

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
			:files				=> 1,
			:type				=> 2,
			:format				=> 1)

		@binder.versions << Version.new(:file		=> params[:binder][:versions][:file],
										:ext		=> File.extname(params[:binder][:versions][:file].original_filename),
										:size		=> params[:binder][:versions][:file].size,
										:timestamp	=> Time.now.to_i,
										:uid		=> current_teacher.id)

		@binder.save

		pids = @parentsarr.map {|x| x["id"] || x[:id]}

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

		@binders = Binder.where(:owner => current_teacher.id,
								:type => 1).reject {|b| (b.id.to_s == params[:id] ||
								b.id.to_s == @binder.parent["id"] ||
								b.parents.any? {|c| c["id"] == params[:id]})}

	end

	#Process for moving any binders
	#TODO: Add sanity check, make sure no folder-in-self or folder-in-child situation
	def moveitem

		@binder = Binder.find(params[:id])

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


		#If directory, deal with the children
		if @binder.type == 1 #Eventually will apply to type == 3 too

			@index = @binder.parents.length

			@children = Binder.where("parents.id" => params[:id])

			#Something is broken here....
			@children.each do |h|
				@current_parents = h.parents
				@size = @current_parents.size
				h.update_attributes(:parents => @parentsarr + @current_parents[(@index - 1)..(@size - 1)])
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
									:files				=> @binder.files,
									:folders			=> @binder.folders,
									:total_size			=> @binder.total_size,
									:parent				=> @parenthash,
									:parents			=> @parentsarr,
									:owner				=> current_teacher.id,
									:last_update 		=> Time.now.to_i,
									:last_updated_by 	=> current_teacher.id)

		@new_parent.format = @binder.format if @binder.type == 2


		#TODO: Create new version instead of using @binder's last version
		@new_parent.versions << @binder.versions.last if @binder.type != 1

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
										:last_update 		=> Time.now.to_i,
										:last_updated_by 	=> current_teacher.id,
										:type				=> h.type)

				@new_node.format = h.format if h.type != 1

				#TODO: Create new version intead of ripping old one
				@new_node.versions << Version.new(
					:uid		=> h.versions.last.uid,
					:timestamp	=> h.versions.last.timestamp,
					:size		=> h.versions.last.size,
					:ext		=> h.versions.last.ext,
					:data		=> h.versions.last.data) if h.format == 2

				@new_node.versions << Version.new(
					:uid		=> h.versions.last.uid,
					:timestamp	=> h.versions.last.timestamp,
					:size		=> h.versions.last.size,
					:ext		=> h.versions.last.ext,
					:data		=> h.versions.last.data,
					:file		=> h.versions.last.file) if h.format == 1

				@new_node.save

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
									:last_update 		=> Time.now.to_i,
									:last_updated_by 	=> current_teacher.id)

		@new_parent.format = @binder.format if @binder.type == 2


		#TODO: Create new version instead of using @binder's last version
		@new_parent.versions << @binder.versions.last if @binder.type != 1

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
										:last_update 		=> h.last_update,
										:last_updated_by 	=> current_teacher.id,
										:type				=> h.type,
										:forked_from		=> h.versions.last.id,
										:fork_stamp			=> Time.now.to_i)

				@new_node.format = h.format if h.type != 1

				@new_node.versions << Version.new(
					:uid		=> h.versions.last.uid,
					:timestamp	=> h.versions.last.timestamp,
					:size		=> h.versions.last.size,
					:ext		=> h.versions.last.ext,
					:data		=> h.versions.last.data) if h.type != 1 && h.format == 2

				@new_node.versions << Version.new(
					:uid		=> h.versions.last.uid,
					:timestamp	=> h.versions.last.timestamp,
					:size		=> h.versions.last.size,
					:ext		=> h.versions.last.ext,
					:data		=> h.versions.last.data,
					:file		=> h.versions.last.file) if h.type != 1 && h.format == 1

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

		if @binder.format == 1

			@binder.versions << Version.new(:file		=> params[:binder][:versions][:file],
											:ext		=> File.extname(params[:binder][:versions][:file].original_filename),
											:size		=> params[:binder][:versions][:file].size,
											:timestamp	=> Time.now.to_i)

		end

		if @binder.format == 2

			@binder.versions << Version.new(:data		=> params[:binder][:versions][:data],
											:timestamp	=> Time.now.to_i)

		end

		redirect_to binder_path(@binder.parent["id"])
	end

	def versions
		@binder = Binder.find(params[:id])
	end

	#More validation needed
	#TODO: Move "deleted" entries to a separate collection?
	def destroy

		@binder = Binder.find(params[:id])

		@parent = @binder.parent["id"]

		@pids = @binder.parents.collect {|x| x["id"] || x[:id]}

		@pids.each do |id|

			if id != "0"

				@parent_binder = Binder.find(id)

				@parent_binder.update_attributes(	:files		=> @parent_binder.files - @binder.files,
													:folders	=> @parent_binder.folders - @binder.folders - (@binder.type == 1 ? 1 : 0),
													:total_size	=> @parent_binder.total_size - @binder.total_size)	

			end

		end

		@binder.destroy

		#Destroy all children
		Binder.where("parents.id" => params[:id]).destroy

		redirect_to binder_path(@parent) and return if @binder.parent["id"] != "0"

		redirect_to binders_path

	end
#Fuck this shit for now
=begin
	def updatetitle

		@title = params[:title]

		if @title != ''
			if @title.length > 60
				#The title you entered is too long
			end
		else
			#Forgot to enter title
		end

		@binder = Binder.find(params[:id])

		@permissions = verifypermissions(@binder)
		@perlevel = determineperlevel(params[:id], @permissions)

		if @perlevel == 2

			@binder.title = @title[0..60]

			@binder.save


			#If folder, update children
			if @binder.type = 1

				#Update :parent fields of direct children
				@children = Binder.where(:parent["id"] => @binder.id)

				@children.each do |child|

					child.parent["title"] = @title[0..60]
					child.save

				end

				#Update :parents field of children
				@children = Binder.where()

				@children.each do |child|

					child.parents["title"] = @title[0..60]
					child.save

				end



			end

			return true

		else

			#Not the right permissions

		end

	end

	def verifypermissions(bindobj)

		@isowner = false
		@localauth = 0
		@folderloc = 0
		@publicauth = 0

		@binder = bindobj

		@uid = current_teacher.id.to_s

		#Check if current user is owner
		if(@binder.owner == @uid)
			@isowner = true
		else

			@binder.parent_permissions.each do |pper|

				if pper.type == 1

					if pper.shared_id == @uid

						if pper.auth_level > @localauth

							@localauth = pper.auth_level

							@findex = @binder.parents.index(pper.folder_id)

							@folderloc = @folderloc < @findex ? @findex : @folderloc

						end


					end


				#Check if authorized
				elsif pper.type == 2

					if pper.shared_id.include?(params[:courses])

						if pper.auth_level > @localauth

							@localauth = pper.auth_level

							@findex = @binder.parents.index(pper.folder_id)

							@folderloc = @folderloc < @findex ? @findex : @folderloc

						end

					end


				#Check if shared publicly
				elsif pper.type == 3

					@publicauth = 1


					@findex = @binder.parents.index(pper.folder_id)

					@folderloc = @folderloc < @findex ? @findex : @folderloc


				end

			# end @binder.parent_permissions.each do |pper|
			end

			#Check local permissions
			@binder.permissions.each do |per|

				if per.type == 1

					if per.shared_id == @uid

						if per.auth_level > @localauth

							@localauth = per.auth_level

							@findex = @binder.parents.length

							@folderloc = @folderloc < @findex ? @findex : @folderloc

						end

					end

				elsif per.type == 2

					if per.shared_id.include?(params[:courses])

						if per.auth_level > @localauth

							@localauth = per.auth_level

							@findex = @binder.parents.length

							@folderloc = @folderloc < @findex ? @findex : @folderloc

						end

					end

				elsif per.type == 3

					@publicauth = 1

					if per.auth_level > @localauth

						@localauth = per.auth_level

						@findex = @binder.parents.length

						@folderloc = @folderloc < @findex ? @findex : @folderloc

					end

				end

			end

		end

		@result = {"isowner" => @isowner, "localauth" => @localauth, "folderloc" => @folderloc, "publicauth" => @publicauth}

		return @result

	end


	def determineperlevel(objid, perobj)

		@level = 0

		if perobj["isowner"] == 1
			@level = 2 # Read/write
		elsif perobj["localauth"] != 0

			if perobj["localauth"] == 2
				@level = 2 # Read/write
			elsif perobj["localauth"] == 1
				@level = 1 # Read only
			end

		elsif perobj["publicauth"] == 1
			@level = 1
		end


		if objid == 0
			@level = 2
		end

		return @level

	end


	def verifypublic

		@binder = Binder.find(params[:id])

		@binder.parent_permissions.each do |pper|

			if pper.type == 3
				return true
			end
		end

		@binder.permissions.each do |per|

			if per.type == 3
				return true
			end
		end

		return false

	end
=end
end