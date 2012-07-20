class BindersController < ApplicationController

	before_filter :authenticate_teacher!, :except => [:show, :index]

	def index
		@owner = Teacher.where(:username => params[:username]).first || Teacher.find(params[:username])

		@children = Binder.where(:owner => @owner.id, "parent.id" => "0").sort_by { |binder| binder.order_index }

		@title = "#{@owner.fname} #{@owner.lname}'s Binders"

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

		#Must be logged in to write

		#Trim to 60 chars (old spec)
		if params[:binder][:title].length < 1
			redirect_to new_binder_path and return
		end

		@inherited = inherit_from(params[:binder][:parent])

		@parenthash = @inherited[:parenthash]
		@parentsarr = @inherited[:parentsarr]
		@parentperarr = @inherited[:parentperarr]

		@parent = @inherited[:parent]

		@parent_child_count = @inherited[:parent_child_count]

		# doesn't work
		#redirect_to "/403.html" and return if @parent.get_access(current_teacher.id) != 1

		#Update parents' folder counts
		if @parentsarr.size > 1
			pids = @parentsarr.collect {|p| p["id"] || p[:id]}
			
			pids.each do |pid| 
				if pid != "0"
					Binder.find(pid).inc(:folders, 1)
				end
				#Binder.find(pid).inc(:folders, 1) if pid != "0"
			end

			Binder.find(pids.last).inc(:children,1) if pids.last != "0"
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
								:order_index		=> @parent_child_count,
								:parent_permissions	=> @parentperarr,
								:last_update		=> Time.now.to_i,
								:last_updated_by	=> current_teacher.id.to_s,
								:type				=> 1)

		new_binder.save

		new_binder.create_binder_tags(params,current_teacher.id)

		# this line breaks creation of new leaf binders
		#redirect_to named_binder_route(@parent) and return if params[:binder][:parent] != "0"
		#redirect_to named_binder_route(params[:binder][:parent]) if params[:binder][:parent] != "0"

		redirect_to binders_path

	end

	def show

		# example sort:
		# @children = @binder.children.sort_by {|binder| binder.parents.length}

		@binder = Binder.find(params[:id])#.sort_by { |binder| binder.order_index }

		@access = teacher_signed_in? ? @binder.get_access(current_teacher.id) : 0

		redirect_to "/404.html" and return if !binder_routing_ok?(@binder, params[:action])

		redirect_to "/403.html" and return if @access == 0

		#redirect_to show_binder_path(@binder.owner, @binder.root, @binder.title, params[:id])

		#TODO: Verify permissions before rendering view

		redirect_to @binder.current_version.data and return if @binder.format == 2

		send_file @binder.current_version.file.path and return if @binder.format == 1

		@title = "Viewing: #{@binder.title}"

		@children = teacher_signed_in? ? @binder.children.reject {|c| c.get_access(current_teacher.id) == 0 } : @binder.children
		
		rescue BSON::InvalidObjectId
			redirect_to "/404.html" and return

	end

	def showcroc

		@binder = Binder.find(params[:id])

		#@uuid = @binder.versions.last.croc_uuid

		#@session = sessiongen(@binder.versions.last.croc_uuid)["session"]

		#@status = docstatus(@uuid)

		@croc_url = "https://crocodoc.com/view/" + Crocodoc.sessiongen(@binder.versions.last.croc_uuid)["session"]

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

		# TODO: check for URL validity
		# use structure presented below

		# require 'net/http'
		# Net::HTTP.new('www.twitter.com').request_head('/').class

		# determine format of image



		# require 'uri'

		# uri = URI("http://foo.com/posts?id=30&limit=5#time=1305298413")
		# #=> #<URI::HTTP:0x00000000b14880
		#       URL:http://foo.com/posts?id=30&limit=5#time=1305298413>
		# uri.scheme
		# #=> "http"
		# uri.host
		# #=> "foo.com"
		# uri.path
		# #=> "/posts"
		# uri.query
		# #=> "id=30&limit=5"
		# uri.fragment
		# #=> "time=1305298413"

		# uri.to_s
		# #=> "http://foo.com/posts?id=30&limit=5#time=1305298413"

		@binder = Binder.new

		#Trim to 60 chars (old spec)
		if params[:binder][:title].length < 1
			redirect_to new_binder_content_path and return
		end

		@inherited = inherit_from(params[:binder][:parent])

		@parenthash = @inherited[:parenthash]
		@parentsarr = @inherited[:parentsarr]
		@parentperarr = @inherited[:parentperarr]

		@parent_child_count = @inherited[:parent_child_count]

		#TODO: check for URL validity, repair 



		#head = open(params[:binder][:versions][:data].to_s, :method => :head)

		#Rails.logger.debug head



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
									:order_index		=> @parent_child_count,
									:parent_permissions	=> @parentperarr,
									:files				=> 1,
									:type				=> 2,
									:format				=> 2)

		@binder.versions << Version.new(:data		=> params[:binder][:versions][:data],
										:timestamp	=> Time.now.to_i,
										:owner		=> current_teacher.id)


		@binder.create_binder_tags(params,current_teacher.id)



		uri = URI(params[:binder][:versions][:data])

		#Rails.logger.debug uri.host
		#Rails.logger.debug uri.path

		# do not need to check for http, carrierwave handles this

		if (uri.host.to_s.include? 'youtube.com') && (uri.path.to_s.include? '/watch')
			# is a youtube URL
			@binder.versions.last.update_attributes( :remote_imgfile_url => Url.get_youtube_url(params[:binder][:versions][:data]))
		else
			# generic URL, grab Url2png
			@binder.versions.last.update_attributes( :remote_imgfile_url => Url.get_url2png_url(params[:binder][:versions][:data]))
		end









		# get image of URL
		#if head.meta['set-cookie'].to_s.include? 'youtube.com'
			# is a youtube link, extract the static images
			#vid_ext = CGI.parse(URI.parse(params[:binder][:versions][:data]).query)['v']

			#Rails.logger.debug get_youtube_url(CGI.parse(URI.parse(params[:binder][:versions][:data]).query)['v'].first).to_s

			#img = File.open( RestClient.get(get_youtube_url(CGI.parse(URI.parse(params[:binder][:versions][:data]).query)['v'].first).to_s) )



			#@binder.versions.last.update_attributes(:imgfile => open(get_youtube_url(CGI.parse(URI.parse(params[:binder][:versions][:data]).query)['v'].first).to_s))
			#@binder.versions.last.imgfile = File.open( RestClient.get(get_youtube_url(CGI.parse(URI.parse(params[:binder][:versions][:data]).query)['v'].first).to_s) )
			#@binder.versions.last.imgfile = open( get_youtube_url(CGI.parse(URI.parse(params[:binder][:versions][:data]).query)['v'].first).to_s)# { |f| f.read }
			#temp = open( get_youtube_url(CGI.parse(URI.parse(params[:binder][:versions][:data]).query)['v'].first).to_s)
			#@binder.versions.last.imgfile.store! temp
			#@binder.save

		#end

		pids = @parentsarr.collect {|x| x["id"] || x[:id]}

		pids.each {|pid| Binder.find(pid).inc(:files, 1) if pid != "0"}

		Binder.find(pids.last).inc(:children, 1) if pids.last != "0"

		redirect_to named_binder_route(params[:binder][:parent])

	end

	def update

		@binder = Binder.find(params[:id])

		@binder.update_attributes(	:title				=> params[:binder][:title][0..60],
									:last_update		=> Time.now.to_i,
									:last_updated_by	=> current_teacher.id.to_s,
									:body				=> params[:binder][:body])

		@binder.tag.update_node_tags(params,current_teacher.id)

		@children = @binder.children.sort_by {|binder| binder.parents.length}

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

		@inherited = inherit_from(params[:binder][:parent])

		@parenthash = @inherited[:parenthash]
		@parentsarr = @inherited[:parentsarr]
		@parentperarr = @inherited[:parentperarr]

		@parent_child_count = @inherited[:parent_child_count]

		#@filedata = 6

		#@newfile = File.open(params[:binder][:versions][:file].path,"rb")

		@binder.update_attributes(	:title				=> File.basename(	params[:binder][:versions][:file].original_filename,
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

		logger.debug DataUploader.new(params[:binder][:versions][:file]).current_path
		#temp.file = params[:binder][:versions][:file]
 
		logger.debug(params[:binder][:versions][:file].class)


		@binder.versions << Version.new(:file		=> params[:binder][:versions][:file],
										:file_hash	=> Digest::MD5.hexdigest(File.read(params[:binder][:versions][:file].path).to_s),
										:ext		=> File.extname(params[:binder][:versions][:file].original_filename),
										:data		=> params[:binder][:versions][:file].path,
										:size		=> params[:binder][:versions][:file].size,
										:timestamp	=> Time.now.to_i,
										:owner		=> current_teacher.id)#,
										#:croc_uuid => filedata)

		@binder.save

		logger.debug(@binder.versions.last.file.class)

		logger.debug @binder.versions.last.file.url
		logger.debug "current path: #{@binder.versions.last.file.current_path}"
		#logger.debug params[:binder][:versions][:file].current_path

		# send file to crocodoc if the format is supported
		if Crocodoc.check_format_validity(@binder.versions.last.ext)
			filedata = Crocodoc.upload("#{@binder.versions.last.file.current_path}")
				
			filedata = filedata["uuid"] if !filedata.nil?

			#OPENSSL::SSL::VERIFY_PEER = OPENSSL::SSL::VERIFY_NONE

			#sleep 10

			#Rails.logger.debug "filedata: #{filedata}"
			#Rails.logger.debug "croc url: [#{ Crocodoc.get_thumbnail(filedata,{ :size => '300x300' }) }]"
			#Rails.logger.debug "response: #{ RestClient.get(Crocodoc.get_thumbnail(filedata,{ :size => '300x300' })){ |response, request, result| response } }"

			#@binder.versions.last.imgfile.store! open(Crocodoc.get_thumbnail(filedata,{ :size => '300x300' }))

			croc_url = "https://crocodoc.com/view/" + Crocodoc.sessiongen(filedata)["session"]

			#Rails.logger.debug "croc png: #{Url.get_url2png_url(croc_url)}"
			#sleep 3

			sleep 6

			@binder.versions.last.update_attributes(:croc_uuid => filedata, 
													#:remote_imgfile_url => Url.get_url2png_url(croc_url))
													#:imgfile => open(Url.get_url2png_url(croc_url)))
													#:imgfile => open( Crocodoc.get_thumbnail(filedata) ))
													:remote_imgfile_url => Crocodoc.get_thumbnail(filedata) )

			#@binder.save

			# file = Tempfile.new
			# file.binmode
			# open(Crocodoc.get_thumbnail(filedata,{ :size => '300x300' })) { |data| file.write data.read }

			# @binder.versions.last.update_attributes(:croc_uuid => filedata,
			# 										:imgfile => file)

			

			# http = Net::HTTP.new('awebsite', 443)
			# http.use_ssl = true
			# http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			# http.start() { |http|
			#    req = Net::HTTP::Get.new("image.jpg")
			#    req.basic_auth login, password
			#    response = http.request(req)
			#    attachment = Attachment.new(:uploaded_data => response.body)
			#    attachement.save
			# }

			# File.open( "temp.png",'wb' ) do |f|
			# 	f << RestClient.get(Crocodoc.get_thumbnail(filedata,{ :size => '300x300' }))
			# end
			# 	#f << Crocodoc.thumbnail(filedata[:uuid], :size => "300x300")
			# 	#f << RestClient.get("#{API_URL + PATH_THUMBNAIL + '?' + params}")
			# 	f << RestClient.get(Crocodoc.get_thumbnail(filedata))
			# end

			# OPENSSL::SSL:VERIFY_NONE
			#Rails.logger.debug "thumbnail response:"
			#Rails.logger.debug logger.debug RestClient.get(Crocodoc.get_thumbnail(filedata,{ :size => '300x300' })){ |response, request, result| response }

			#@binder.versions.last.update_attributes(:croc_uuid => filedata,
													#:remote_imgfile_url => Crocodoc.get_thumbnail(filedata))
													#:imgfile => File.open( 'temp.png' ) { |f| f << RestClient.get(Crocodoc.get_thumbnail(filedata)) } )
													#:imgfile => open(Crocodoc.get_thumbnail(filedata)) { |f| f.read } )
			#										:remote_imgfile_url => Crocodoc.get_thumbnail(filedata,{ :size => '300x300' }))

			#tf.close!

			#OPENSSL::SSL::VERIFY_PEER = OPENSSL::SSL::VERIFY_PEER
		end








		@binder.create_binder_tags(params,current_teacher.id)
 
		#logger.debug RestClient.post(CROC_API_URL + PATH_UPLOAD, :token => "3QsGvCVcSyYuN9HM2edPh4ZD", :url => @newversion["file"].to_s){ |response, request, result| response }

		pids = @parentsarr.collect {|x| x["id"] || x[:id]}

		pids.each do |id|

			if id != "0"
				parent = Binder.find(id)
				parent.update_attributes(	:files		=> parent.files + 1,
											:total_size	=> parent.total_size + params[:binder][:versions][:file].size)
			end
		end

		Binder.find(pids.last).inc(:children,1) if pids.last != "0"

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

		#logger.debug "FUCKYOU NIGGER"

		@binder.sift_siblings()

		@inherited = inherit_from(params[:binder][:parent])

		@parenthash = @inherited[:parenthash]
		@parentsarr = @inherited[:parentsarr]
		@parentperarr = @inherited[:parentperarr]

		@parent_child_count = @inherited[:parent_child_count]

		@ops = @binder.parents.collect {|x| x["id"] || x[:id]}
		@ops.each do |opid|
			if opid != "0"
				op = Binder.find(opid)

				op.update_attributes(	:files		=> op.files - @binder.files,
										:folders	=> op.folders - @binder.folders - (@binder.type == 1 ? 1 : 0),
										:total_size	=> op.total_size - @binder.total_size)
			end
		end
 
		#Binder.find(op.last).inc(:children,-1)

		#Save old permissions to remove childrens' inherited permissions
		@ppers = @binder.parent_permissions

		@binder.update_attributes(	:parent				=> @parenthash,
									:parents			=> @parentsarr,
									:parent_permissions	=> @parentperarr,
									:order_index		=> @parent_child_count)


		# must update the common ancestor of the children before 
		@binder.update_parent_tags()

		#@binder is the object being moved
		#If directory, deal with the children
		if @binder.type == 1 #Eventually will apply to type == 3 too

			@children = @binder.children

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

		@inherited = inherit_from(params[:binder][:parent])

		@parenthash = @inherited[:parenthash]
		@parentsarr = @inherited[:parentsarr]
		@parentperarr = @inherited[:parentperarr]

		@parent_child_count = @inherited[:parent_child_count]

		@ppers = @binder.parent_permissions

		@new_parent = Binder.new(	:title				=> @binder.title,
									:body				=> @binder.body,
									:type				=> @binder.type,
									:format				=> @binder.type == 2 ? @binder.format : nil,
									:files				=> @binder.files,
									:folders			=> @binder.folders,
									:total_size			=> @binder.total_size,
									:order_index		=> @parent_child_count,
									:parent				=> @parenthash,
									:parents			=> @parentsarr,
									:permissions		=> @binder.permissions,
									:parent_permissions	=> @parentperarr,
									:owner				=> current_teacher.id,
									:last_update		=> Time.now.to_i,
									:last_updated_by	=> current_teacher.id)

		#@new_parent.format = @binder.format if @binder.type == 2

		@new_parent.versions << Version.new(:owner		=> @binder.current_version.owner,
											:file_hash	=> @binder.current_version.file_hash,
											:timestamp	=> @binder.current_version.timestamp,
											:size		=> @binder.current_version.size,
											:ext		=> @binder.current_version.ext,
											:data		=> @binder.current_version.data,
											:croc_uuid 	=> @binder.current_version.croc_uuid,
											:file		=> @binder.format == 1 ? @binder.current_version.file : nil) if @binder.type == 2


		#TODO: copy related images?

		@new_parent.save

		@new_parent.tag = Tag.new(	:node_tags => @binder.tag.node_tags)

		@new_parent.update_parent_tags()

		#Hash table for oldid => newid lookups
		@hash_index = {params[:id] => @new_parent.id.to_s}


		#If directory, deal with the children
		if @binder.type == 1 #Eventually will apply to type == 3 too

			@index = @binder.parents.length

			#Select old children, order by parents.length
			@children = @binder.children.sort_by {|binder| binder.parents.length}

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
														:file_hash	=> h.current_version.file_hash,
														:timestamp	=> h.current_version.timestamp,
														:size		=> h.current_version.size,
														:ext		=> h.current_version.ext,
														:data		=> h.current_version.data,
														:croc_uuid	=> h.current_version.croc_uuid,
														:file		=> h.format == 1 ? h.current_version.file : nil) if h.type == 2

				#TODO: copy related images?

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

		@inherited = inherit_from(params[:binder][:parent])

		@parenthash = @inherited[:parenthash]
		@parentsarr = @inherited[:parentsarr]
		@parentperarr = @inherited[:parentperarr]

		@parent_child_count = @inherited[:parent_child_count]

		@new_parent = Binder.new(	:title				=> @binder.title,
									:body				=> @binder.body,
									:type				=> @binder.type,
									:files				=> @binder.files,
									:folders			=> @binder.folders,
									:total_size			=> @binder.total_size,
									:order_index		=> @parent_child_count,
									:parent				=> @parenthash,
									:parents			=> @parentsarr,
									:owner				=> current_teacher.id,
									:last_update		=> Time.now.to_i,
									:last_updated_by	=> current_teacher.id,
									:format				=> @binder.type == 2 ? @binder.format : nil)


		@new_parent.versions << Version.new(:owner		=> @binder.current_version.owner,
												:file_hash	=> @binder.current_version.file_hash,
												:timestamp	=> @binder.current_version.timestamp,
												:size		=> @binder.current_version.size,
												:ext		=> @binder.current_version.ext,
												:data		=> @binder.current_version.data,
												:croc_uuid	=> @binder.current_version.croc_uuid,
												:file		=> @binder.format == 1 ? @binder.current_version.file : nil) if @binder.type == 2

		@new_parent.save

		@hash_index = {params[:id] => @new_parent.id.to_s}


		#If directory, deal with the children
		if @binder.type == 1 #Eventually will apply to type == 3 too

			@index = @binder.parents.length

			#Select old children, order by parents.length
			@children = @binder.children.sort_by {|binder| binder.parents.length}

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
														:file_hash	=> h.current_version.file_hash,
														:timestamp	=> h.current_version.timestamp,
														:size		=> h.current_version.size,
														:ext		=> h.current_version.ext,
														:data		=> h.current_version.data,
														:croc_uuid	=> h.current_version.croc_uuid,
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

		if Crocodoc.check_format_validity(@binder.versions.last.ext)
			filedata = Crocodoc.upload(@binder.versions.last.file.current_path)
				
			filedata = filedata["uuid"] if !filedata.nil?
		end

		@binder.versions.last.update_attributes(:croc_uuid => filedata)

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

		redirect_to "/403.html" and return if current_teacher.id.to_s != @binder.owner

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

		@binder.children.each {|c| c.update_attributes(:parent_permissions => c.parent_permissions << {:type => params[:type],
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

		@binder.children.each do |c|
			c.parent_permissions.delete(pper)
			c.save
		end

		@binder.save

		redirect_to named_binder_route(@binder, "permissions")
	end

	def trash
		@children = Binder.where(:owner => current_teacher.id, "parent.id" => "-1")

		redirect_to "/403.html" and return if params[:username] != current_teacher.username

		@title = "#{current_teacher.fname} #{current_teacher.lname}'s Trash"
	end

	#More validation needed, Permissions
	def destroy
		@binder = Binder.find(params[:id])

		@binder.sift_siblings()

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

			@binder.children.each do |h|
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



	#############################
	# 							#
	# 	 CONTROLLER HELPERS: 	#
	# 							#
	#############################

	# def get_youtube_url(url)

	# 	return "http://img.youtube.com/vi/#{CGI.parse(URI.parse(url).query)['v'].first.to_s}/0.jpg"

	# end

	module Url
		extend self

		def extract_youtube_extension(url)

			return CGI.parse(URI.parse(url).query)['v'].first.to_s
		end

		def get_youtube_url(url)

			return YOUTUBE_IMG_URL + CGI.parse(URI.parse(url).query)['v'].first.to_s + YOUTUBE_IMG_FILE

		end

		def get_url2png_url(url,options = {})

			if options.empty?
				bounds = URL2PNG_DEFAULT_BOUNDS
			else
				bounds = options[:bounds].to_s
			end

			sec_hash = Digest::MD5.hexdigest(URL2PNG_PRIVATE_KEY + '+' + url).to_s

			Rails.logger.debug "#{URL2PNG_API_URL + URL2PNG_API_KEY}/#{sec_hash}/#{bounds}/#{url}"

			#return RestClient.get(URL2PNG_API_URL + URL2PNG_API_KEY + '/' + sec_hash + '/' + bounds + '/' + url)
			return "#{URL2PNG_API_URL + URL2PNG_API_KEY}/#{sec_hash}/#{bounds}/#{url}"

		end

	end

	module Crocodoc
		extend self

		# passed file extension
		# returns whether crocodoc supports it
		def check_format_validity(extension)

			return CROC_VALID_FILE_FORMATS.include? extension.downcase

		end

		# passed opened file or url - user will never be providing direct file path
		# returns uuid of file
		def upload(filestring)

			#filedata = JSON.parse(RestClient.post(CROC_API_URL + PATH_UPLOAD, :token => CROC_API_TOKEN, :url => filestring.to_s){ |response, request, result| response })

			filedata = JSON.parse(RestClient.post(CROC_API_URL+PATH_UPLOAD, :token => CROC_API_TOKEN, 
																			:file => File.open("#{filestring}")){ |response, request, result| response })

			Rails.logger.debug "filedata: #{filedata.to_s}"
			Rails.logger.debug docstatus(filedata["uuid"])

			if filedata["error"].nil?
				# correctly uploaded
				return filedata#["uuid"]
			else
				# there was a problem, log the error
				Rails.logger.debug "#{filedata["error"]}"
				return nil
			end

		end

		# pass set of uuids to check the status of
		# returns uuid,status,viewable,error
		# QUEUED,PROCESSING,DONE,ERROR
		def docstatus(uuid)
			# this does not appear to work
			return JSON.parse(RestClient.get(CROC_API_URL + PATH_STATUS, :token => CROC_API_TOKEN, :uuids => uuid ){ |response, request, result| response })
			
		end

		 # passed uuid of file
		 # returns fullsize thumbnail
		def get_thumbnail(uuid,options = {})

			options = CROC_API_OPTIONS.merge(options).merge({:uuid => uuid})

			# # timeout 
			# timeout = 30

			# resp = 400

			# while [400,401,404,500].include? resp.to_i #"{\"error\": \"internal error\"}"
			# 	#puts "waiting..."
			# 	sleep 0.1
			# 	timeout -= 1
			# 	if timeout==0
			# 		return nil
			# 	end

			# 	#resp = RestClient.get("#{CROC_API_URL + PATH_THUMBNAIL + '?' + URI.encode_www_form(options)}"){|response, request, result| response.code }
			# 	resp = RestClient.get(CROC_API_URL+PATH_THUMBNAIL,options){|response, request, result| response.code }

			# 	Rails.logger.debug "thumbnail response: #{resp},#{timeout}"

			# 	#resp = resp.code
			# end

			# # only request thumbnail once file can be accessed 
			# RestClient.get("#{CROC_API_URL + PATH_THUMBNAIL + '?' + URI.encode_www_form(options)}")

			return "#{CROC_API_URL+PATH_THUMBNAIL}?#{URI.encode_www_form(options)}"
			#return RestClient.get(CROC_API_URL+PATH_THUMBNAIL,options)

		end

		# passed the uuid of file
		# returns the session string to view the document
		def sessiongen(uuid)

			return JSON.parse(RestClient.post(CROC_API_URL + PATH_SESSION, :token => CROC_API_TOKEN, :uuid => uuid.to_s){ |response, request, result| response })

		end
	end

	def inherit_from(parentid)

		parenthash = {}
		parentsarr = []
		parentperarr = []

		if parentid.to_s == "0"

			parenthash = {	:id		=> parentid,
							:title	=> ""}

			parentsarr = [parenthash]

		else

			parent = Binder.find(parentid)

			parenthash = {	:id		=> parentid,
							:title	=> parent.title}

			parentsarr = parent.parents << parenthash

			parentperarr = parent.parent_permissions

			parent.permissions.each do |p|
				p["folder_id"] = parentid
				parentperarr << p
			end

		end

		return {:parenthash => parenthash, 
				:parentsarr => parentsarr,
				:parentperarr => parentperarr, 
				:parent => parent, 
				:parent_child_count => Binder.where("parent.id" => parentid.to_s).count }

	end


	#Because named_binder_route can accept an id or object, so can this check
	def binder_routing_ok?(binder, action)

		return request.fullpath == named_binder_route(binder, action)

	end

	#Function that returns routing given a binder object and action
	#Only works for routes in the format of: /username/portfolio(/root)/title/id/action(s)
	#Binder objects preferred over ids
	def named_binder_route(binder, action = "show")

		if binder.class == Binder
			retstr = "/#{binder.handle}/portfolio"

			if binder.parents.length != 1 
				retstr += "/#{CGI.escape(binder.root)}" 
			end

			retstr += "/#{CGI.escape(binder.title)}/#{binder.id}"

			if action != "show" 
				retstr += "/#{action}" 
			end

			return retstr
		elsif binder.class == String 
			return named_binder_route(Binder.find(binder), action)
		else
			return "/500.html"
		end

		#return "/#{binder.handle}/portfolio#{binder.parents.length == 1 ? String.new : "/" + CGI.escape(binder.root)}/#{CGI.escape(binder.title)}/#{binder.id}#{action == "show" ? String.new : "/#{action}"}" if binder.class == Binder

		#return named_binder_route(Binder.find(binder), action) if binder.class == String

		#return "/500.html"

	end

end