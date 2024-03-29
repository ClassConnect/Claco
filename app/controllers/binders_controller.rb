class BindersController < ApplicationController
	before_filter :authenticate_teacher!, :except => [:show, :zenframe]
	before_filter :authenticate_admin!, :only => [:regen]

	class FilelessIO < StringIO
		attr_accessor :original_filename
	end

	#Add Folder Function
	def create

		binder = Binder.create_folder((params[:id] || "0"), params, current_teacher)

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					binder.owner,
					params)

		rescue Exception => ex
		ensure
			if params[:id].nil?
				respond_to do |format|
					format.html {render :text => ex.nil? ? {"success" => 1, "data" => named_binder_route(binder)}.to_json : {"success" => 2, "data" => "<li>#{ex.to_s}</li>".html_safe}.to_json}
				end
			else
				respond_to do |format|
					format.html {render :text => ex.nil? ?  1 : "<li>#{ex.to_s}</li>".html_safe}
				end
			end

	end

	def show

		@binder = Binder.find(params[:id])

		@owner = Teacher.find(@binder.owner)

		Mongo.log(	signed_in? ? current_teacher.id.to_s : nil,
					__method__.to_s,
					params[:controller].to_s,
					@binder.id.to_s,
					params)

		@root = signed_in? ? current_teacher.binders.root_binders : []

		@access = signed_in? ? @binder.get_access(current_teacher.id) : @binder.get_access

		@is_self = signed_in? ? current_teacher.username.downcase == params[:username].downcase : false

		if !binder_routing_ok?(@binder, params[:action])
			error = true
			redirect_to named_binder_route(@binder, params[:action]), :status => 301 and return
		end

		if @access == 0
			error = true
			render "errors/forbidden", :status => 403 and return
		end

		#Rails.logger.debug @tags

		# sort the tags into an array
		@tags = [[],[],[],[]]

		# this is a hack
		@binder.tag = Tag.new if !@binder.tag

		@tagset = @binder.tag.get_tags()

		if @tagset.any?
			@tagset.each do |tag|
				@tags[tag['type']] << tag
			end
		end

		@title = @binder.title

		@children = (teacher_signed_in? ? @binder.children.reject {|c| c.get_access(current_teacher.id) == 0} : @binder.children.reject {|c| c.get_access == 0}).sort_by {|c| c.order_index}

		@collaborators = Teacher.find(@binder.flatten_permissions.select{|h| h["type"] == 1}.map{|p| p["shared_id"]})

		error = false

		rescue BSON::InvalidObjectId
			error = true
			render "errors/not_found", :status => 404 and return
		rescue Mongoid::Errors::DocumentNotFound
			error = true
			render "errors/not_found", :status => 404 and return
		ensure
			if !error
				respond_to do |format|
				 	format.html
					format.json {render :json => @children.collect {|c| {"id" => c.id, "name" => c.title, "path" => named_binder_route(c), "type" => c.type}}.to_json}
				end
			end

	end

	def download

		@binder = Binder.find(params[:id])

		@access = teacher_signed_in? ? @binder.get_access(current_teacher.id) : 0

		if !binder_routing_ok?(@binder, params[:action])
			redirect_to named_binder_route(@binder, params[:action]) and return
		end

		render "errors/forbidden", :status => 403 and return if @access == 0

		# INCREMENT DOWNLOAD COUNT

		if @binder.format == 1

			@binder.inc(:download_count, 1)

			Mongo.log(	current_teacher.id.to_s,
						__method__.to_s,
						params[:controller].to_s,
						@binder.id.to_s,
						params)

			redirect_to @binder.current_version.file.url.sub(/https:\/\/#{@binder.current_version.file.fog_directory}.s3.amazonaws.com/, @binder.current_version.file.fog_host) and return
		end

		rescue BSON::InvalidObjectId
			render "errors/not_found", :status => 404 and return
		rescue Mongoid::Errors::DocumentNotFound
			render "errors/not_found", :status => 404 and return

	end

	def zenframe

		@binder = Binder.find(params[:id])

		if @binder.current_version.vidtype != "zen"
			render "errors/not_found", :status => 404 and return
		end

		render :layout => false

	end

	def regen

		@binder = Binder.find(params[:id])

		@binder.regen

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@binder.id.to_s,
					params)

		redirect_to named_binder_route(@binder)

		rescue BSON::InvalidObjectId
			render "errors/not_found", :status => 404 and return
		rescue Mongoid::Errors::DocumentNotFound
			render "errors/not_found", :status => 404 and return

	end

	#Add links function
	def createcontent

		@binder = Binder.create_content(params[:id], params, current_teacher)

		Mongo.log(	current_teacher.id.to_s,
			__method__.to_s,
			params[:controller].to_s,
			@binder.id.to_s,
			params)

		rescue Exception => ex
		ensure
		if request.get?
			redirect_to named_binder_route(@binder) and return
		else
			respond_to do |format|
				format.html {render :text => ex.nil? ? 1 : "<li>#{ex.to_s}</li>".html_safe}
			end
		end
	end

	def update

		@binder = Binder.find(params[:id])

		errors = []

		if params[:text] != "Type a note..."

			if teacher_signed_in? && @binder.get_access(current_teacher.id.to_s) == 2

				@binder.update_attributes(	:last_update		=> Time.now.to_i,
											:last_updated_by	=> current_teacher.id.to_s,
											:body				=> params[:text].gsub(/<br>/, "<br/>"))

			else

				errors << "You are not allowed to do that"

			end

		else

			@binder.update_attributes(	:last_update		=> Time.now.to_i,
										:last_updated_by	=> current_teacher.id.to_s,
										:body				=> "")

		end

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@binder.id.to_s,
					params)

		respond_to do |format|
			format.html {render :text => errors.empty? ? "1" : errors.map{|err| "<li>#{err}</li>"}.join.html_safe}
		end
	end


	def rename

		@binder = Binder.find(params[:id])

		@binder.update_attributes(	:title				=> params[:newtitle][0..49],
									:last_update		=> Time.now.to_i,
									:last_updated_by	=> current_teacher.id.to_s)

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@binder.id.to_s,
					params)

		@children = @binder.children.sort_by {|binder| binder.parents.length}

		@index = @binder.parents.length

		@children.each do |h|

			h.parent["title"] = params[:newtitle][0..49] if h.parent["id"] == params[:id]

			h.parents[@index]["title"] = params[:newtitle][0..49]

			h.save

		end

		respond_to do |format|
			format.html {render :text => "1"}
		end

	end

	def updatetags

		@binder = Binder.find(params[:id])

		#Rails.logger.debug params.to_s
		#Rails.logger.debug params["standards"].to_s

		@binder.tag.update_node_tags(params,current_teacher.id)

		src = Mongo.log(current_teacher.id.to_s,
						__method__.to_s,
						params[:controller].to_s,
						@binder.id.to_s,
						params)

		@binder.children.sort_by {|binder| binder.parents.length}.each do |h|

			h.tag = Tag.new if h.tag.nil?

			#Rails.logger.debug "child #{h.title}'s tags: #{h.tag.node_tags},#{h.tag.parent_tags}"

			h.update_parent_tags()

			Mongo.log(	current_teacher.id.to_s,
						__method__.to_s,
						params[:controller].to_s,
						h.id.to_s,
						params,
						{ :src => src })
			#h.save

		end

		respond_to do |format|
			format.html {render :text => "1"}
		end

	end

	def cf

		@nb = Binder.new

		@v = @nb.versions.new

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@nb.id.to_s,
					params,
					{:version => @v.id.to_s})

		@v.owner = current_teacher.id.to_s
		@v.timestamp = Time.now.to_i
		@v.data = Digest::MD5.hexdigest(@nb.id.to_s)

		@uploader = @v.file

		token = Digest::MD5.hexdigest(@v.data + "ekileromkoolodottnawogneveesuotdedicedsaneverafneebyllaerenoynasah")

		@uploader.success_action_redirect = "#{request.protocol}#{request.host_with_port}#{named_binder_route(params[:id], "createfile")}/#{@v.data}/#{@v.timestamp}/#{token}"

		render "cf", :layout => false

	end

	# Add file process
	def createfile

		errors = []

		if Binder.where("versions.data" => params[:data]).count == 0

			#Validate the request
			if params[:token] == Digest::MD5.hexdigest(params[:data] + "ekileromkoolodottnawogneveesuotdedicedsaneverafneebyllaerenoynasah")

				@inherited = inherit_from(params[:id])

				if @inherited[:parent].get_access(current_teacher.id.to_s) == 2

					@binder = Binder.new

					@parenthash = @inherited[:parenthash]
					@parentsarr = @inherited[:parentsarr]
					@parentperarr = @inherited[:parentperarr]

					@parent_child_count = @inherited[:parent_child_count]

					#@filedata = 6

					#@newfile = File.open(params[:binder][:versions][:file].path,"rb")

					@binder.set_owner(current_teacher)

					@binder.update_attributes(	:title				=> File.basename(	params[:key].split("/").last,
																						File.extname(params[:key].split("/").last)).strip[0..49],
												:parent				=> @parenthash,
												:parents			=> @parentsarr,
												:last_update		=> Time.now.to_i,
												:last_updated_by	=> current_teacher.id.to_s,
												#:body				=> params[:binder][:body],
												# :total_size			=> params[:file].size,
												# :pub_size			=> @inherited[:parent].is_pub? ? params[:file].size.to_i : 0,
												# :priv_size			=> @inherited[:parent].is_pub? ? 0 : params[:file].size.to_i,
												:order_index 		=> @parent_child_count,
												:parent_permissions	=> @parentperarr,
												:files				=> 1,
												:type				=> 2,
												:format				=> 1)


					# send file to crocodoc if the format is supported
					# if check_format_validity(File.extname(params[:binder][:versions][:file].original_filename))
					# 	filedata = upload(params[:binder][:versions][:file])

					# 	filedata = filedata["uuid"] if !filedata.nil?
					# end

					# this may work:
					# RestClient.post '/data', :myfile => File.new("/path/to/image.jpg", 'rb')

					#logger.debug DataUploader.new(params[:binder][:versions][:file]).current_path
					#temp.file = params[:binder][:versions][:file]

					#logger.debug(params[:binder][:versions][:file].class)

					@binder.versions.new

					# @binder.current_version.update_attributes(#:file		=> CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), "#{store_dir}/#{model.filename}"),
					# 								:filename	=> params[:key].split("/").last,
					# 								:file_hash	=> params[:etag].gsub("/", ""),
					# 								:ext		=> File.extname(params[:key].split("/").last),
					# 								:data		=> params[:data],
					# 								# :size		=> params[:file].size,
					# 								:timestamp	=> params[:timestamp],
					# 								:owner		=> current_teacher.id)#,

					@binder.current_version.filename = params[:key].split("/").last
					@binder.current_version.file_hash = params[:etag].gsub("/", "")
					@binder.current_version.ext = File.extname(params[:key].split("/").last)
					@binder.current_version.data = params[:data]
					@binder.current_version.timestamp = params[:timestamp]
					@binder.current_version.owner = current_teacher.id

					@binder.current_version.file.key = params[:key]
					# @binder.current_version.remote_file_url = @binder.current_version.file.direct_fog_url # THIS FKIN LINE

					# CarrierWave::Storage::Fog::File.new(@binder.current_version.file, CarrierWave::Storage::Fog.new(@binder.current_version.file), params[:key])

					# @binder.current_version.file.retrieve_from_store!(params[:key])
					# #debugger
					@binder.current_version.size = CarrierWave::Storage::Fog::File.new(@binder.current_version.file, CarrierWave::Storage::Fog.new(@binder.current_version.file), params[:key]).size
					@binder.total_size = @binder.current_version.size

					if @binder.save

						Mongo.log(	current_teacher.id.to_s,
									__method__.to_s,
									params[:controller].to_s,
									@binder.id.to_s,
									params)

						#logger.debug @binder.versions.last.file.url
						#logger.debug "current path: #{@binder.versions.last.file.current_path}"
						#logger.debug params[:binder][:versions][:file].current_path
						if CLACO_SUPPORTED_THUMBNAIL_FILETYPES.include? @binder.current_version.ext.downcase
							# send file to crocodoc if the format is supported
							if Crocodoc.check_format_validity(@binder.current_version.ext.downcase)

								#Rails.logger.debug "current path: #{@binder.current_version.file.current_path.to_s}"

								@binder.current_version.update_attributes( :thumbnailgen => 3 )

								#Rails.logger.debug "<<< URL: #{@binder.current_version.file.url.to_s} >>>"

								filedata = Crocodoc.upload(@binder.current_version.file.url)

								filedata = filedata["uuid"] if !filedata.nil?

								@binder.current_version.update_attributes(:croc_uuid => filedata)

								# delegate image fetch to Delayed Job worker
								#Binder.delay(:queue => 'thumbgen').get_croc_thumbnail(@binder.id,Crocodoc.get_thumbnail_url(filedata))

								# DELAYTAG
								# .delay(:queue => 'thumbgen')
								Binder.delay(:queue => 'thumbgen').get_croc_thumbnail(@binder.id, Crocodoc.get_thumbnail_url(filedata))

								Binder.delay.get_croc_doctext(@binder.id, Crocodoc.get_doctext_url(filedata))

								# delay(:queue => 'thumbgen').
								#Binder.delay(:queue => 'thumbgen').gen_croc_thumbnails(@binder.id)

							elsif CLACO_VALID_IMAGE_FILETYPES.include? @binder.current_version.ext.downcase
								# for now, image will be added as file AND as imgfile
								stathash = @binder.current_version.imgstatus#[:imgfile][:retrieved]
								stathash[:imgfile][:retrieved] = true

								imgfile = FilelessIO.new(RestClient.get(@binder.current_version.file.url).to_s)
								imgfile.original_filename = @binder.current_version.filename
								# upload image
								@binder.current_version.update_attributes( 	:imgfile => imgfile,
																			:imgclass => 0,
																			:imgstatus => stathash)

								#Binder.generate_folder_thumbnail(@binder.id)

								#GC.start

								#Rails.logger.debug ">>> About to call generate_folder_thumbnail on #{@binder.parent["id"].to_s}"
								#Rails.logger.debug ">>> Binder.inspect #{@binder.parent.to_s}"

								Binder.delay(:queue => 'thumbgen').gen_smart_thumbnails(@binder.id)

								# DELAYTAG
								#Binder.delay(:queue => 'thumbgen').generate_folder_thumbnail(@binder.parent["id"] || @binder.parent[:id])

							# elsif ZENCODER_SUPPORTED_VIDEO_EXTS.include? @binder.current_version.ext.downcase

							# 	Binder.delay(:queue => 'encode').encode(@binder.id.to_s)

							elsif @binder.current_version.ext.downcase == ".notebook"

								Binder.delay(:queue => 'thumbgen').gen_smartnotebook_thumbnail(@binder.id)

							end
						else
							stathash = @binder.current_version.imgstatus
							stathash[:imageable] = false

							# unable to derive iamge from filetype
							@binder.current_version.update_attributes(	:imgstatus => stathash,
																		:imgclass => 4 )
						end


						@binder.create_binder_tags(params,current_teacher.id)

						pids = @parentsarr.collect {|x| x["id"] || x[:id]}

						pids.each do |id|

							if id != "0"
								parent = Binder.find(id)
								parent.update_attributes(	:files		=> parent.files + 1,
															:total_size	=> parent.total_size + @binder.total_size)
							end
						end

						current_teacher.total_size += @binder.total_size
						current_teacher.pub_size += @binder.total_size if @binder.is_pub?
						current_teacher.priv_size += @binder.total_size unless @binder.is_pub?

						current_teacher.save

						Binder.find(pids.last).inc(:children,1) if pids.last != "0"

					else

						errors << "There was a problem saving this file"

					end

				else

					errors << "You do not have permissions to write to #{@inherited[:parent].title}"

				end

			else

				errors << "Invalid Callback"

			end

		else

			errors << "File Already in Database"

		end



		if errors.empty?
			redirect_to "#{named_binder_route(@inherited[:parent])}#rdir"
		else
			respond_to do |format|
				format.html {render :text => errors.empty? ? 1 : errors.map{|err| "<li>#{err}</li>"}.join.html_safe}
			end
		end

		rescue
			@binder.destroy
			redirect_to "#{named_binder_route(@inherited[:parent])}#uploaderror"

	end

	def reorderitem

		errors = []

		@children = Binder.where("parent.id" => params[:id])

		@ok = @children.size == params[:data].size

		if @ok

			@childids = @children.collect{|c| c.id.to_s}

			params[:data].each {|d| @ok = false if !@childids.include?(d)}

		else

			errors << "Invalid Request - Refresh the page?"

		end

		if @ok

			src = ""

			@children.each do |c|

				c.update_attributes(:order_index => params[:data].index(c.id.to_s))

				if src.nil?
					src = Mongo.log(current_teacher.id.to_s,
									__method__.to_s,
									params[:controller].to_s,
									c.id.to_s,
									params)
				else
					Mongo.log(current_teacher.id.to_s,
									__method__.to_s,
									params[:controller].to_s,
									c.id.to_s,
									params,
									{ :src => src })
				end

			end

		else

			errors << "Invalid Request"

		end

		rescue BSON::InvalidObjectId
			errors << "Invalid Request"
		rescue Mongoid::Errors::DocumentNotFound
			errors << "Invalid Request"
		ensure
			respond_to do |format|
				format.html {render :text => errors.empty? ? 1 : errors}
			end

	end

	#Process for moving any binders
	def moveitem

		errors = []

		@binder = Binder.find(params[:id])

		if params[:target] != params[:id]

			src = Mongo.log(current_teacher.id.to_s,
							__method__.to_s,
							params[:controller].to_s,
							@binder.id.to_s,
							params)

			@binder.sift_siblings()

			@inherited = inherit_from(params[:target])

			@parenthash = @inherited[:parenthash]
			@parentsarr = @inherited[:parentsarr]
			@parentperarr = @inherited[:parentperarr]

			@parent_child_count = @inherited[:parent_child_count]

			#nps = new parents, ops = old parents

			@nps = @parentsarr.collect {|x| x["id"] || x[:id]}


			if !@nps.include?(params[:id])

				@ops = @binder.parents.collect {|x| x["id"] || x[:id]}
				@ops.each do |opid|
					if opid != "0"
						op = Binder.find(opid)

						op.update_attributes(	:owned_fork_total => op.owned_fork_total - (@binder.fork_total+@binder.owned_fork_total),
												:files		=> op.files - @binder.files,
												:folders	=> op.folders - @binder.folders - (@binder.type == 1 ? 1 : 0),
												:total_size	=> op.total_size - @binder.total_size,
												:pub_size	=> op.pub_size - @binder.pub_size,
												:priv_size	=> op.priv_size - @binder.priv_size)
					end
				end

				#Binder.find(op.last).inc(:children,-1)

				# DELAYTAG
				Binder.delay(:queue => 'thumbgen').generate_folder_thumbnail(@binder.parent["id"] || @binder.parent[:id])

				#Save old permissions to remove childrens' inherited permissions
				@ppers = @binder.parent_permissions

				@binder.update_attributes(	:parent				=> @parenthash,
											:parents			=> @parentsarr,
											:parent_permissions	=> @parentperarr,
											:order_index		=> @parent_child_count)


				# DELAYTAG
				Binder.delay(:queue => 'thumbgen').generate_folder_thumbnail(@binder.parent["id"] || @binder.parent[:id])

				# must update the common ancestor of the children before
				@binder.update_parent_tags()

				#@binder is the object being moved
				#If directory, deal with the children
				if @binder.type == 1 #Eventually will apply to type == 3 too

					@children = @binder.subtree

					@children.each do |h|


						@current_parents = h.parents

						@size = @current_parents.size

						@npperarr = h.parent_permissions

						@ppers.each {|p| @npperarr.delete(p)}

						h.update_attributes(:parents			=> @parentsarr + @current_parents[(@current_parents.index({"id" => @binder.id.to_s, "title" => @binder.title}))..(@size - 1)],
											:parent_permissions	=> @parentperarr + @npperarr)

						h.update_parent_tags()

						Mongo.log(	current_teacher.id.to_s,
									__method__.to_s,
									params[:controller].to_s,
									h.id.to_s,
									params,
									{ :src => src })
					end

				end

				#Update new parents' folder/file/size counts
				@parents = @binder.parents.collect {|x| x["id"] || x[:id]}

				@parents.each do |pid|
					if pid != "0"
						parent = Binder.find(pid)

						parent.update_attributes(	:owned_fork_total => parent.owned_fork_total + (@binder.fork_total+@binder.owned_fork_total),
													:files		=> parent.files + @binder.files,
													:folders	=> parent.folders + @binder.folders + (@binder.type == 1 ? 1 : 0),
													:total_size	=> parent.total_size + @binder.total_size,
													:pub_size 	=> parent.pub_size + @binder.pub_size,
													:priv_size 	=> parent.priv_size + @binder.priv_size)
					end
				end

			else

				errors << "Invalid target location"

			end

		else

			errors << "You cannot put something inside itself"

		end

		rescue BSON::InvalidObjectId
			errors << "Invalid Request"
		rescue Mongoid::Errors::DocumentNotFound
			errors << "Invalid Request"
		ensure
			respond_to do |format|
				format.html {render :text => errors.empty? ? 1 : errors.map{|err| "<li>#{err}</li>"}.join.html_safe}
			end

	end

	#Copy Binders to new location
	def copyitem

		errors = []

		@binder = Binder.find(params[:id])

		@inherited = inherit_from(params[:folid])

		@parenthash = @inherited[:parenthash]
		@parentsarr = @inherited[:parentsarr]
		@parentperarr = @inherited[:parentperarr]

		# src = Mongo.log(current_teacher.id.to_s,
		# 				__method__.to_s,
		# 				params[:controller].to_s,
		# 				@binder.id.to_s,
		# 				params)

		if @inherited[:parent].get_access(current_teacher.id.to_s) == 2

			# fork will only be set if there is a teacher id mismatch
			fav = !params[:favorite].nil?
			fork = @inherited[:parent].owner != @binder.owner

			@parent_child_count = @inherited[:parent_child_count]

			@ppers = @binder.parent_permissions

			@new_parent = Binder.new(	:title				=> @binder.title,
										:body				=> @binder.body,
										:type				=> @binder.type,
										:format				=> @binder.type == 2 ? @binder.format : nil,
										:files				=> @binder.files,
										:folders			=> @binder.folders,
										:forked_from		=> fork ? @binder.id.to_s : nil,
										:fork_stamp			=> fork ? Time.now.to_i : nil,
										:total_size			=> @binder.total_size,
										:fav_total			=> @binder.fav_total,
										:pub_size			=> @binder.pub_size,
										:priv_size			=> @binder.priv_size,
										:order_index		=> @parent_child_count,
										:parent				=> (fav ? { 'id'=>'-2', 'title'=>'' } : @parenthash),#@parenthash,
										:parents			=> (fav ? [{ 'id'=>'-2', 'title'=>'' }] : @parentsarr),#@parentsarr,
										:permissions		=> (fav ? [{"type"=>3, "auth_level"=>1}] : @binder.permissions),#@binder.permissions,
										:parent_permissions	=> (fav ? [] : @parentperarr),#@parentperarr,
										:owner				=> current_teacher.id,
										:username			=> current_teacher.username,
										:fname				=> current_teacher.fname,
										:lname				=> current_teacher.lname,
										:last_update		=> Time.now.to_i,
										:last_updated_by	=> current_teacher.id,
										:thumbimgids		=> @binder.thumbimgids)

			#@new_parent.format = @binder.format if @binder.type == 2

			# @new_parent.versions << Version.new(:owner		=> @binder.current_version.owner,
			# 										:file_hash	=> @binder.current_version.file_hash,
			# 										:timestamp	=> @binder.current_version.timestamp,
			# 										:remote_imgfile_url	=> @binder.current_version.imgfile.url.to_s,
			# 										:size		=> @binder.current_version.size,
			# 										:ext		=> @binder.current_version.ext,
			# 										:data		=> @binder.current_version.data,
			# 										:croc_uuid 	=> @binder.current_version.croc_uuid,
			# 										:remote_file_url		=> @binder.format == 1 ? @binder.current_version.file.url.to_s : nil) if @binder.type == 2

			@new_parent.versions << @binder.current_version

			#TODO: copy related images?

			if @new_parent.save

				# due to shared functionality, define method var

				if fav
					method = "favorite"

					@binder.inc(:fav_total, 1)
				elsif fork
					method = "forkitem"
					# fork_total is
					@binder.inc(:fork_total, 1)

					Binder.delay(:queue => "email").sendforkemail(@binder.id.to_s, @new_parent.id.to_s)

					# cascade upwards
					@binder.parents.each do |f|
						Binder.find(f['id'].to_s).inc(:owned_fork_total,1) if f['id'].to_i>0
					end
				else
					method = __method__.to_s
				end

				src = Mongo.log(current_teacher.id.to_s,
								method.to_s,
								params[:controller].to_s,
								@binder.id.to_s,
								params)

				Mongo.log(	current_teacher.id.to_s,
							method.to_s,
							params[:controller].to_s,
							@new_parent.id.to_s,
							params,
							{ :copy => @binder.id.to_s, :src => src })

				@new_parent.tag = Tag.new(	:node_tags => @binder.tag.node_tags)

				@new_parent.update_parent_tags()

				#Hash table for oldid => newid lookups
				@hash_index = {params[:id] => @new_parent.id.to_s}


				#If directory, deal with the children
				if @binder.type == 1 #Eventually will apply to type == 3 too

					@index = @binder.parents.length

					#Select old children, order by parents.length
					@children = @binder.subtree.sort_by {|binder| binder.parents.length}.reject{|binder| binder.id == @new_parent.id}

					#Spawn new children, These children need to have updated parent ids
					@children.each do |h|

						Mongo.log(	current_teacher.id.to_s,
									method.to_s,
									params[:controller].to_s,
									h.id.to_s,
									params,
									{ :src => src })

						@node_parent = {"id"	=> @hash_index[h.parent["id"]],
										"title"	=> h.parent["title"]}

						@node_parents = Binder.find(@hash_index[h.parent["id"]]).parents << @node_parent

						@old_permissions = h.parent_permissions

						@ppers.each {|p| @old_permissions.delete(p)}

						#Swap old folder ids with new folder ids
						@old_permissions.each {|op| op["folder_id"] = @hash_index[op["folder_id"]]}

						h.inc(:fork_total, 1) if fork

						@new_node = Binder.new(	:title				=> h.title,
												:body				=> h.body,
												:parent				=> @node_parent,
												:parents			=> fav ? [{ 'id'=>'-2', 'title'=>'' }] + (h.parents - {'id'=>'0','title'=>''}) : @node_parents,
												:permissions		=> fav ? [] : h.permissions,
												:parent_permissions	=> fav ? @parentperarr : @parentperarr + @old_permissions,
												:owner				=> current_teacher.id,
												:username			=> current_teacher.username,
												:fname				=> current_teacher.fname,
												:lname				=> current_teacher.lname,
												:last_update		=> Time.now.to_i,
												:last_updated_by	=> current_teacher.id,
												:type				=> h.type,
												:format				=> (h.type != 1 ? h.format : nil),
												:files				=> h.files,
												:folders			=> h.folders,
												:forked_from		=> fork ? h.id.to_s : nil,
												:fork_stamp			=> fork ? Time.now.to_i : nil,
												:total_size			=> h.total_size,
												:pub_size			=> h.pub_size,
												:priv_size			=> h.priv_size,
												:fav_total			=> h.fav_total,
												:thumbimgids		=> @binder.thumbimgids,)

						# @new_node.versions << Version.new(	:owner		=> h.current_version.owner,
						# 									:file_hash	=> h.current_version.file_hash,
						# 									:timestamp	=> h.current_version.timestamp,
						# 									:size		=> h.current_version.size,
						# 									:ext		=> h.current_version.ext,
						# 									:data		=> h.current_version.data,
						# 									:croc_uuid	=> h.current_version.croc_uuid,
						# 									:imgfile	=> h.current_version.imgfile,
						# 									:file		=> h.format == 1 ? h.current_version.file : nil) if h.type == 2


						@new_node.versions << h.current_version

						#TODO: copy related images?

						@new_node.save

						Mongo.log(	current_teacher.id.to_s,
									method.to_s,
									params[:controller].to_s,
									@new_node.id.to_s,
									params,
									{ :copy => h.id.to_s, :src => src })

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
													:total_size	=> parent.total_size + @new_parent.total_size,
													:pub_size	=> parent.pub_size + @new_parent.pub_size,
													:priv_size	=> parent.priv_size + @new_parent.priv_size)
					end
				end

				# DELAYTAG
				Binder.delay(:queue => 'thumbgen').generate_folder_thumbnail(@new_parent.id)

			else

			end

		else

			errors << "You do not have permissions to write to #{@inherited[:parent].title}"

		end

		rescue BSON::InvalidObjectId
			errors << "Invalid Request"
		rescue Mongoid::Errors::DocumentNotFound
			errors << "Invalid Request"
		ensure
			respond_to do |format|
				format.html {render :text => errors.empty? ? 1 : errors.map{|err| "<li>#{err}</li>"}.join.html_safe}
			end
	end

	def createversion

		# TODO:
		# the current implementation will allow teachers to abuse their storage limits by
		# putting multiple versions on a file, and switching between them.  alter this to
		# take into account aggregate storage size

		@binder = Binder.find(params[:id])

		@old_size = @binder.total_size

		@binder.versions.each {|v| v.update_attributes(:active => false)}

		# send file to crocodoc if the format is supported
		#if check_format_validity(File.extname(params[:binder][:versions][:file].original_filename))
		#	filedata = upload(params[:binder][:versions][:file])
		#
		#	filedata = filedata["uuid"] if !filedata.nil?
		#end

		@binder.versions << Version.new(:file		=> params[:binder][:versions][:file],
										:file_hash	=> Digest::MD5.hexdigest(File.read(params[:binder][:versions][:file].path).to_s),
										:ext		=> (@binder.format == 1 ? File.extname(params[:binder][:versions][:file].original_filename) : nil),
										:size		=> (@binder.format == 1 ? params[:binder][:versions][:file].size : nil),
										#:croc_uuid	=> (@binder.format == 1 ? filedata : nil),
										:data		=> (@binder.format == 1 ? params[:binder][:versions][:file].path : params[:binder][:versions][:data]),
										:timestamp	=> Time.now.to_i,
										:active		=> true)



		@binder.save

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@binder.id.to_s,
					params)

		if Crocodoc.check_format_validity(@binder.current_version.ext)
			filedata = Crocodoc.upload(@binder.current_version.file.current_path)

			filedata = filedata["uuid"] if !filedata.nil?

			# create thumbnail!!!!
		end

		@binder.current_version.update_attributes(:croc_uuid => filedata)

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

		# DELAYTAG
		Binder.delay(:queue => 'thumbgen').generate_folder_thumbnail(@binder.parent["id"] || @binder.parent[:id])

		redirect_to named_binder_route(@parent || @binder.parent["id"])
	end

	def versions
		@binder = Binder.find(params[:id])

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@binder.id.to_s,
					params)

		redirect_to named_binder_route(@binder.parent["id"]) and return if @binder.type == 1 && @binder.parent["id"] != "0"

		redirect_to binders_path if @binder.type == 1
	end

	def swap
		@binder = Binder.find(params[:id])

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					@binder.id.to_s,
					params)

		@binder.versions.each {|v| v.update_attributes(:active => v.id.to_s == params[:version][:id])}

		redirect_to named_binder_route(@binder.parent["id"])
	end

	#This is so nasty.
	def setpub

		error = ""

		@binder = Binder.find(params[:id])

		# read/write access
		if @binder.get_access(current_teacher.id.to_s) == 2

			# check if parent binder has any type 3 permissions
			if @binder.parent_permissions.find {|p| p["type"] == 3}.nil?

				if @binder.permissions.find {|p| p["type"] == 3}.nil?

					# this binder has no existing type 3 permissions, inherit!
					@binder.permissions << {:type		=> 3,
											:auth_level	=> params[:enabled] == "true" ? 1 : 0}
					@binder.save

				else

					# set this binder's permissions
					@binder.permissions.find {|p| p["type"] == 3}["auth_level"] = params[:enabled] == "true" ? 1 : 0

				end

				if params[:enabled]=="true"
					@binder.pub_size = @binder.pub_size + @binder.priv_size
					@binder.priv_size = 0
				else
					@binder.priv_size = @binder.priv_size + @binder.pub_size
					@binder.pub_size = 0
				end

				@binder.save

				src = Mongo.log(current_teacher.id.to_s,
								__method__.to_s,
								params[:controller].to_s,
								@binder.id.to_s,
								params)

				# deal with the naughty children
				@binder.subtree.each do |h|

					h.permissions.find{|p| p["type"] == 3}["auth_level"] = params[:enabled] == "true" ? 1 : 0 if !h.permissions.find{|p| p["type"] == 3}.nil?


					if h.parent_permissions.find {|p| p["type"] == 3}.nil?

						h.parent_permissions << {	:type		=> 3,
													:folder_id => params[:id],
													:auth_level	=> params[:enabled] == "true" ? 1 : 0}

					else

						h.parent_permissions.find {|p| p["type"] == 3}["auth_level"] = params[:enabled] == "true" ? 1 : 0
						h.parent_permissions.find {|p| p["type"] == 3}["folder_id"] = params[:id]

					end

					if params[:enabled]=="true"
						h.pub_size = h.pub_size + h.priv_size
						current_teacher.pub_size += h.priv_size
						h.priv_size = 0
					else
						h.priv_size = h.priv_size + h.pub_size
						current_teacher.priv_size += h.pub_size
						h.pub_size = 0
					end

					current_teacher.save

					h.save

					Mongo.log(	current_teacher.id.to_s,
								__method__.to_s,
								params[:controller].to_s,
								h.id.to_s,
								params,
								{ :src => src })
				end

			else

				if @binder.parent_permissions.find {|p| p["type"] == 3}["auth_level"] == 1 && params[:enabled] == "false"

					error = "Oops! The parent is currently shared."

				else

					if @binder.permissions.find {|p| p["type"] == 3}.nil?

						@binder.permissions << {:type		=> 3,
												:auth_level	=> params[:enabled] == "true" ? 1 : 0}
						#@binder.save

					else

						@binder.permissions.find {|p| p["type"] == 3}["auth_level"] = params[:enabled] == "true" ? 1 : 0
						#@binder.save

					end

					if params[:enabled]=="true"
						@binder.pub_size = @binder.pub_size + @binder.priv_size
						@binder.priv_size = 0

						@binder.parents.each do |f|
							if f['id'].to_s!='0'
								g = Binder.find(f['id'].to_s)
								g.update_attributes(:pub_size => g.pub_size + @binder.priv_size,
													:priv_size => 0)
							end
						end
					else
						@binder.priv_size = @binder.priv_size + @binder.pub_size
						@binder.pub_size = 0

						@binder.parents.each do |f|
							if f['id'].to_s!='0'
								g = Binder.find(f['id'].to_s)
								g.update_attributes(:pub_size => 0,
													:priv_size => g.priv_size + @binder.pub_size)
							end
						end

					end

					@binder.save

					src = Mongo.log(current_teacher.id.to_s,
									__method__.to_s,
									params[:controller].to_s,
									@binder.id.to_s,
									params)

					# take care of the naughty children
					@binder.subtree.each do |h|

						h.permissions.find{|p| p["type"] == 3}["auth_level"] = params[:enabled] == "true" ? 1 : 0 if !h.permissions.find{|p| p["type"] == 3}.nil?

						if h.parent_permissions.find {|p| p["type"] == 3}.nil?

							h.parent_permissions << {	:type		=> 3,
														:folder_id => params[:id],
														:auth_level	=> params[:enabled] == "true" ? 1 : 0}
							#h.save

						else

							h.parent_permissions.find {|p| p["type"] == 3}["auth_level"] = params[:enabled] == "true" ? 1 : 0
							h.parent_permissions.find {|p| p["type"] == 3}["folder_id"] = params[:id]
							#h.save

						end

						if params[:enabled]=="true"
							h.pub_size = h.pub_size + h.priv_size
							current_teacher.pub_size += h.priv_size
							h.priv_size = 0
						else
							h.priv_size = h.priv_size + h.pub_size
							current_teacher.priv_size += h.pub_size
							h.pub_size = 0
						end

						current_teacher.save

						h.save

						Mongo.log(	current_teacher.id.to_s,
									__method__.to_s,
									params[:controller].to_s,
									h.id.to_s,
									params,
									{ :src => src })

					end

				end

			end

		else

			error = "You are not allowed to change permissions on this item."

		end

		rescue BSON::InvalidObjectId
			error = "Invalid Request"
		rescue Mongoid::Errors::DocumentNotFound
			error = "Invalid Request"
		ensure
			respond_to do |format|
				format.html {render :text => error.empty? ? 1 : error}
			end

	end

	def add_collaborator

		binder = Binder.find(params[:id])

		if binder.owner?(current_teacher.id)

			teacher = Teacher.find_by_username(params[:collab_user])

			if !teacher.has_explicit_access_to?(binder)

				if binder.add_collaborator!(teacher)

					src = Mongo.log(current_teacher.id.to_s,
									__method__.to_s,
									params[:controller].to_s,
									binder.id.to_s,
									params)

					binder.subtree.map(&:_id).each do |childid|

						Mongo.log(	current_teacher.id.to_s,
									__method__.to_s,
									params[:controller].to_s,
									childid.to_s,
									params,
									{ :src => src })

					end

				end

			else

				render :json => {"status" => "error", "message" => "#{teacher.first_last} is already a collaborator."}, :status => 422 and return

			end

		end

		render :json => {"status" => "success", "name" => teacher.first_last, "username" => teacher.username, "image" => Teacher.thumb_sm(teacher)}

		rescue Mongoid::Errors::DocumentNotFound
			render :json => {"status" => "error", "message" => "#{params[:collab_user]} was not found."}, :status => 422 and return
	end

	def destroypermission

		@binder = Binder.find(params[:id])

		if @binder.owner?(current_teacher.id.to_s)

			@teacher = Teacher.find_by_username(params[:collab_user])

			@binder.remove_access!(@teacher)

			src = Mongo.log(current_teacher.id.to_s,
							__method__.to_s,
							params[:controller].to_s,
							@binder.id.to_s,
							params)

			@binder.subtree.map(&:_id).each do |childid|

					Mongo.log(	current_teacher.id.to_s,
						__method__.to_s,
						params[:controller].to_s,
						childid.to_s,
						params,
						{ :src => src })

			end

		end

		Binder.generate_folder_thumbnail(@binder.parent['id'])

		respond_to do |format|

			format.html {render :text => 1}

		end

		# redirect_to named_binder_route(@binder, "permissions")
	end

	def trash
		@children = Binder.where(:owner => current_teacher.id, "parent.id" => "-1")

		Mongo.log(	current_teacher.id.to_s,
					__method__.to_s,
					params[:controller].to_s,
					nil,
					params)

		@tagset = []

		@tags = [[],[],[],[]]

		#render "errors/forbidden", :status => 403 and return if params[:username] != current_teacher.username

		@title = "#{current_teacher.fname} #{current_teacher.lname}'s Trash"
	end

	#More validation needed, Permissions
	def destroy

		#debugger

		errors = []

		@binder = Binder.find(params[:id])

		if @binder.get_access(current_teacher.id.to_s == 2)

			# preserve parent ID before writing over
			@parentid = @binder.parent["id"]

			@binder.sift_siblings()

			@parenthash = {	:id		=> "-1",
							:title	=> ""}

			@parentsarr = [@parenthash]

			#OP = Original Parent
			if @binder.parent["id"] != "0"
				@op = Binder.find(@binder.parent["id"])

				@op.update_attributes(	:owned_fork_total => @op.owned_fork_total - (@binder.fork_total+@binder.owned_fork_total),
										:files		=> @op.files - @binder.files,
										:folders	=> @op.folders - @binder.folders - (@binder.type == 1 ? 1 : 0),
										:total_size	=> @op.total_size - @binder.total_size,
										:pub_size	=> @op.pub_size - @binder.pub_size,
										:priv_size	=> @op.priv_size - @binder.priv_size)
			end

			@binder.update_attributes(	:parent		=> @parenthash,
										:parents	=> @parentsarr)

			src = Mongo.log(current_teacher.id.to_s,
							__method__.to_s,
							params[:controller].to_s,
							@binder.id.to_s,
							params)

			#If directory, deal with the children
			if @binder.type == 1 #Eventually will apply to type == 3 too

				@binder.subtree.each do |h|

					@current_parents = h.parents
					@size = @current_parents.size
					h.update_attributes(:parents => @parentsarr + @current_parents[(@current_parents.index({"id" => @binder.id.to_s, "title" => @binder.title}))..(@size - 1)])

					Mongo.log(	current_teacher.id.to_s,
								__method__.to_s,
								params[:controller].to_s,
								@binder.id.to_s,
								params,
								{ :src => src })
				end

			end


			@parents = @binder.parents.collect {|x| x["id"] || x[:id]}

			@parents.each do |pid|
				if pid != "-1"
					parent = Binder.find(pid)

					parent.update_attributes(	:owned_fork_total => parent.owned_fork_total + (@binder.fork_total+@binder.owned_fork_total),
												:files		=> parent.files + @binder.files,
												:folders	=> parent.folders + @binder.folders + (@binder.type == 1 ? 1 : 0),
												:total_size	=> parent.total_size + @binder.total_size,
												:pub_size	=> parent.pub_size + @binder.pub_size,
												:priv_size	=> parent.priv_size + @binder.priv_size)
				end
			end

			current_teacher.total_size -= @binder.total_size
			current_teacher.pub_size -= @binder.total_size if @binder.is_pub?
			current_teacher.priv_size -= @binder.total_size unless @binder.is_pub?

			current_teacher.save


			Rails.logger.debug "generating parent "

			Binder.delay(:queue => 'thumbgen').generate_folder_thumbnail(@parentid)

		else

			errors << "You do not have permissions to delete this item"

		end

		rescue BSON::InvalidObjectId
			errors << "Invalid Request"
		rescue Mongoid::Errors::DocumentNotFound
			errors << "Invalid Request"
		ensure
			respond_to do |format|
				format.html {render :text => errors.empty? ? 1 : errors.map{|err| "<li>#{err}</li>"}.join.html_safe}
			end

	end


	###############################################################################################

							#    #  ##### #     #####  ##### #####   ####
							#    #  #     #     #    # #     #    # #    #
							#    #  #     #     #    # #     #    # #
							######  ####  #     #####  ####  #####   ####
							#    #  #     #     #      #     #  #        #
							#    #  #     #     #      #     #   #  #    #
							#    #  ##### ##### #      ##### #    #  ####

	###############################################################################################

	module Mongo
		extend self

		def log(ownerid,method,model,modelid,params,data = {})

			log = Log.new( 	:ownerid => ownerid.to_s,
							:timestamp => Time.now.to_f,
							:method => method.to_s,
							:model => model.to_s,
							:modelid => modelid.to_s,
							:params => params,
							:data => data,
							:actionhash => Digest::MD5.hexdigest(ownerid.to_s+method.to_s+modelid.to_s))

			log.save

			return log.id.to_s

		end
	end

	def inherit_from(parentid)

		parenthash = {}
		parentsarr = []
		parentperarr = []
		parent_child_count = 0

		if parentid.to_s == "0"

			parenthash = {	:id		=> parentid,
							:title	=> ""}

			parentsarr = [parenthash]

			parent = "0"

		else

			parent = Binder.find(parentid)

			parent_child_count = parent.children.count

			parenthash = {	:id		=> parentid,
							:title	=> parent.title}

			parentsarr = parent.parents << parenthash

			parentperarr = parent.parent_permissions

			if !parentperarr.find{|p| p["type"] == 3}.nil? && !parent.permissions.find{|p| p["type"] == 3}.nil?

				parentperarr.delete(parentperarr.find{|p| p["type"] == 3})

				parent.permissions.each do |p|
					p["folder_id"] = parentid
					parentperarr << p
				end

			else

				parent.permissions.each do |p|
					p["folder_id"] = parentid
					parentperarr << p
				end

			end

		end

		return {:parenthash => parenthash,
				:parentsarr => parentsarr,
				:parentperarr => parentperarr,
				:parent => parent,
				:parent_child_count => parent_child_count}

	end


	#Because named_binder_route can accept an id or object, so can this check
	def binder_routing_ok?(binder, action)

		return request.path[0..named_binder_route(binder, action).size - 1] == named_binder_route(binder, action)

	end

	#Function that returns routing given a binder object and action
	#Only works for routes in the format of: /username/portfolio(/root)/title/id/action(s)
	#Binder objects preferred over ids
	def named_binder_route(binder, action = "show")

		if binder.class == Binder
			retstr = "/#{binder.handle}/portfolio"

			if binder.parents.length != 1
				retstr += "/#{CGI.escape(binder.root.gsub(" ", "-"))}"
			end

			retstr += "/#{CGI.escape(binder.title.gsub(" ", "-"))}/#{binder.id}"

			if action != "show"
				retstr += "/#{action}"
			end

			return retstr
		elsif binder.class == String
			return named_binder_route(Binder.find(binder), action)
		else
			return "/500.html"
		end

	end

end
