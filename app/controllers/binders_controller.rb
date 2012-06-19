class BindersController < ApplicationController
	before_filter :authenticate_teacher!

	def index
		@binders = Binder.where(:owner => current_teacher.id, "parent.id" => "0")

		@title = "#{current_teacher.fname} #{current_teacher.lname}'s Binders"
	end

#	def pubindex
#		@binders = Binder.where("permissions" => "2")
#	end

	def new
		@binders = Binder.where(:owner => current_teacher.id, :type => 1)

		@title = "Create a new binder"

		@new_binder = Binder.new

		# pre-build tag class for nested form builder
		@new_binder.build_tag
	end

	def create
		#Trim to 60 chars (old spec)
		if params[:binder][:title].length < 1
			redirect_to new_binder_path and return
		end

		new_binder = Binder.new
		#new_binder.tag = Tag.new

		new_binder.create_new_binder(params,current_teacher.id)

		redirect_to binder_path(params[:binder][:parent]) and return if params[:binder][:parent] != "0"

		redirect_to binders_path

	end

	def show

		@binder = Binder.find(params[:id])

		#TODO: Verify permissions before rendering view

		redirect_to @binder.versions.last.data and return if @binder.format == 2

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

	def createcontent

		@binder = Binder.new

		@binder.owner = current_teacher.id

		#Trim to 60 chars (old spec)
		if params[:binder][:title].length < 1
			redirect_to new_binder_path and return
		end

		@parenthash = {}
		@parentsarr = []

		if params[:binder][:parent].to_s == "0"

			@parenthash = {:id => params[:binder][:parent],
				:title => ""}

			@parentsarr = [@parenthash]

		else

			@parenthash = {:id => params[:binder][:parent],
				:title =>  Binder.find(params[:binder][:parent]).title}

			@parentsarr = Binder.find(params[:binder][:parent]).parents << @parenthash

		end

		@binder.update_attributes(	:title 			=> params[:binder][:title][0..60],
						:parent 		=> @parenthash,
						:parents 		=> @parentsarr,
						:last_update 		=> Time.now.to_i,
						:last_updated_by	=> current_teacher.id.to_s,
						:body 			=> params[:binder][:body],
						:type 			=> 2,
						:format 		=> 2)

		@binder.versions << Version.new(:data => params[:binder][:versions][:data])

		@binder.save

		redirect_to binders_path(params[:binder][:parent])

	end

	#IMPORTANT TODO: UPDATE CHILDRENS' :PARENTS ATTRIBUTES
	#TODO: Version control, File/link update support
	def update
		@binder = Binder.find(params[:id])

		@binder.update_attributes(	:title			=> params[:binder][:title][0..60],
						:last_update		=> Time.now.to_i,
						:last_updated_by	=> current_teacher.id.to_s,
						:body			=> params[:binder][:body])#,
						#:tags			=> params[:binder][:tags].downcase.split.uniq)

		#@binder.save
		if @binder.parent["id"] == "0"
			@binder.tag.set_binder_tags(params,nil)
		else
			@binder.tag.set_binder_tags(params,Binder.find(@binder.parent["id"]))
		end

		@children = Binder.where("parents.id" => params[:id])

		@index = @binder.parents.length

		@children.each do |h|

			h.parent["title"] = params[:binder][:title][0..60] if h.parent["id"] == params[:id]

			h.parents[@index]["title"] = params[:binder][:title][0..60]

			h.tag.set_binder_parent_tags(params,Binder.find(h.parent["id"]))

			h.save
		end

		#If not directory, apply versioning
		if @binder.type != 1

		end

		redirect_to binder_path(@binder)

	end

	#Add new file
	def newfile

		@binders = Binder.where(:owner => current_teacher.id, :type => 1)

		@title = "Add new content"

	end

	def createfile

		@binder = Binder.new

		@binder.owner = current_teacher.id

		#Trim to 60 chars (old spec)
		#if params[:binder][:title].length < 1
		#	redirect_to new_binder_path and return
		#end

		@parenthash = {}
		@parentsarr = []

		if params[:binder][:parent].to_s == "0"

			@parenthash = {	:id => params[:binder][:parent],
					:title => ""}

			@parentsarr = [@parenthash]

		else

			@parenthash = {:id => params[:binder][:parent],
				:title =>  Binder.find(params[:binder][:parent]).title}

			@parentsarr = Binder.find(params[:binder][:parent]).parents << @parenthash

		end

		@binder.update_attributes(	:title			=> File.basename(params[:binder][:versions][:file].original_filename, File.extname(params[:binder][:versions][:file].original_filename)),
						:parent			=> @parenthash,
						:parents 		=> @parentsarr,
						:last_update 		=> Time.now.to_i,
						:last_updated_by	=> current_teacher.id.to_s,
						:body 			=> params[:binder][:body],
						:type 			=> 2,
						:format 		=> 1)

		@binder.versions << Version.new(:file => params[:binder][:versions][:file], :ext => File.extname(params[:binder][:versions][:file].original_filename))

		#@binder.title = File.basename(params[:binder][:versions][:file].original_filename, File.extname(params[:binder][:versions][:file].original_filename))

		@binder.save

		redirect_to binder_path(params[:binder][:parent])

	end

	def move

		@binder = Binder.find(params[:id])

		@binders = Binder.where(:owner => current_teacher.id,
			:type => 1).reject {|b| (b.id.to_s == params[:id] ||
			b.id.to_s == @binder.parent["id"] || b.parents.any? {|c| c["id"] == params[:id]})}

	end

	#Process from moving
	#TODO: Add sanity check, make sure no folder-in-self or folder-in-child situation
	def moveitem

		@binder = Binder.find(params[:id])

		@parenthash = {}
		@parentsarr = []


		if params[:binder][:parent].to_s == "0"

			@parenthash = {:id => params[:binder][:parent],
				:title => ""}

			@parentsarr = [@parenthash]

		else

			@parenthash = {:id => params[:binder][:parent],
				:title =>  Binder.find(params[:binder][:parent]).title}

			@parentsarr = Binder.find(params[:binder][:parent]).parents << @parenthash

		end


		#If directory, deal with the children
		if @binder.type == 1 #Eventually will apply to type == 3 too

			@index = @binder.parents.length

			@children = Binder.where("parents.id" => params[:id])

			@children.each do |h|
				@current_parents = h.parents
				@size = @current_parents.size
				h.update_attributes(:parents => @parentsarr + @current_parents[@index..(@size - 1)])
			end

		end

		@binder.update_attributes(:parent => @parenthash,
			:parents => @parentsarr)

		redirect_to binder_path(params[:binder][:parent]) and return if params[:binder][:parent] != "0"

		redirect_to binders_path

	end

	def copy

		@binder = Binder.find(params[:id])

		@binders = Binder.where(:owner => current_teacher.id,
			:type => 1).reject {|b| (b.id.to_s == params[:id] ||
			b.id.to_s == @binder.parent["id"] ||
			b.parents.any? {|c| c["id"] == params[:id]})}

	end

	def copyitem

		@binder = Binder.find(params[:id])

		@parenthash = {}
		@parentsarr = []


		if params[:binder][:parent].to_s == "0"

			@parenthash = {:id => params[:binder][:parent],
				:title => ""}

			@parentsarr = [@parenthash]

		else

			@parenthash = {:id => params[:binder][:parent],
				:title =>  Binder.find(params[:binder][:parent]).title}

			@parentsarr = Binder.find(params[:binder][:parent]).parents << @parenthash

		end

		@new_parent = Binder.new(	:title 			=> @binder.title,
						:body			=> @binder.body,
						:type			=> @binder.type,
						:parent 		=> @parenthash,
						:parents		=> @parentsarr,
						:owner			=> current_teacher.id,
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

				@node_parent = {"id" 	=> @hash_index[h.parent["id"]],
								"title" => h.parent["title"]}

				@node_parents = Binder.find(@hash_index[h.parent["id"]]).parents << @node_parent

				@new_node = Binder.new(	:title			=> h.title,
							:body 			=> h.body,
							:parent 		=> @node_parent,
							:parents 		=> @node_parents,
							:owner 			=> current_teacher.id,
							:last_update 		=> Time.now.to_i,
							:last_updated_by 	=> current_teacher.id,
							:type			=> h.type)

				@new_node.format = h.format if h.type != 1

				#TODO: Create new version intead of ripping old one
				@new_node.versions << h.versions.last if h.type != 1

				@new_node.save

				@hash_index[h.id.to_s] = @new_node.id.to_s
			end

		end

		redirect_to binder_path(params[:binder][:parent]) and return if params[:binder][:parent] != "0"

		redirect_to binders_path
	end

	#More validation needed
	def destroy

		@binder = Binder.find(params[:id])

		@parent = @binder.parent["id"]

		@binder.destroy

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
