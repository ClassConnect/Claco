class BindersController < ApplicationController
	before_filter :authenticate_teacher!, :except => [:show, :index]

	class FilelessIO < StringIO
		attr_accessor :original_filename
	end

	def index
		@owner = Teacher.where(:username => /^#{Regexp.escape(params[:username])}$/i).first || Teacher.find(params[:username])

		@children = Binder.where(:owner => @owner.id, "parent.id" => "0").sort_by { |binder| binder.order_index }

		@title = "#{@owner.fname} #{@owner.lname}'s Binders"

		# these are temporary fixes:

		@tagset = []

		@tags = [[],[],[],[]]
	end

	#Add Folder Function
	def create

		#Must be logged in to write

		#Trim to 60 chars (old spec)

		errors = []

		if params[:foldertitle].strip.length > 0

			if params[:id].nil?
				@inherited = inherit_from("0")
			else
				@inherited = inherit_from(params[:id])
			end

			@parenthash = @inherited[:parenthash]
			@parentsarr = @inherited[:parentsarr]
			@parentperarr = @inherited[:parentperarr]

			@parent = @inherited[:parent]

			@parent_child_count = @inherited[:parent_child_count]

			if @parent == "0" || @parent.get_access(current_teacher.id) == 2

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
										:title				=> params[:foldertitle].strip[0..49],
										:parent				=> @parenthash,
										:parents			=> @parentsarr,
										:body				=> params[:body],
										# :permissions		=> (params[:public] == "on" ? [{:type		=> 3,
										# 													:auth_level	=> params[:public] == "on" ? 1 : 0}] : []),
										:order_index		=> @parent_child_count,
										:parent_permissions	=> @parentperarr,
										:last_update		=> Time.now.to_i,
										:last_updated_by	=> current_teacher.id.to_s,
										:type				=> 1)

				new_binder.permissions = [{:type => 3, :auth_level => params[:public] == "on" ? 1 : 0}] if @parent == "0"

				#Rails.logger.debug "METHOD got here! #{__method__}"

				new_binder.save

				Mongo.log(	current_teacher.id.to_s,
							__method__.to_s,
							params[:controller].to_s,
							new_binder.id.to_s,
							params)

				new_binder.create_binder_tags(params,current_teacher.id)

			else

				errors << "You do not have permissions to write to #{@parent.title}"

			end

		else

			errors << "Please enter a title"

		end

		rescue BSON::InvalidObjectId
			errors << "Invalid Request"
		rescue Mongoid::Errors::DocumentNotFound
			errors << "Invalid Request"
		ensure
			if @parent == "0" || params[:id].nil?
				respond_to do |format|
					format.html {render :text => errors.empty? ? {"success" => 1, "data" => named_binder_route(new_binder)}.to_json : {"success" => 2, "data" => errors.map{|err| "<li>#{err}</li>"}.join.html_safe}.to_json}
				end
			else
				respond_to do |format|
					format.html {render :text => errors.empty? ?  1 : errors.map{|err| "<li>#{err}</li>"}.join.html_safe}
				end
			end

	end

	def show

		@binder = Binder.find(params[:id])

		@root = signed_in? ? Binder.where("parent.id" => "0", :owner => current_teacher.id.to_s) : []

		@access = signed_in? ? @binder.get_access(current_teacher.id) : @binder.get_access
		
		@is_self = signed_in? ? current_teacher.username.downcase == params[:username].downcase : false

		if !binder_routing_ok?(@binder, params[:action])
			error = true
			redirect_to named_binder_route(@binder, params[:action]) and return
		end

		if @access == 0
			error = true
			render "public/403.html", :status => 403 and return
		end

		#TODO: Verify permissions before rendering view

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

		#Rails.logger.debug @tags

		@title = "Viewing: #{@binder.title}"

		@children = (teacher_signed_in? ? @binder.children.reject {|c| c.get_access(current_teacher.id) == 0} : @binder.children.reject {|c| c.get_access == 0}).sort_by {|c| c.order_index}

		error = false

		rescue BSON::InvalidObjectId
			error = true
			render "public/404.html", :status => 404 and return
		rescue Mongoid::Errors::DocumentNotFound
			error = true
			render "public/404.html", :status => 404 and return
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

		render "public/403.html", :status => 403 and return if @access == 0

		# INCREMENT DOWNLOAD COUNT

		#TODO: Verify permissions before rendering view
		if @binder.format == 1

			@binder.update_attributes( 	:download_count => @binder.download_count.to_i+1)

			Mongo.log(	current_teacher.id.to_s,
						__method__.to_s,
						params[:controller].to_s,
						@binder.id.to_s,
						params)

			redirect_to @binder.current_version.file.url.sub(/https:\/\/cdn.cla.co.s3.amazonaws.com/, "http://cdn.cla.co") and return 
		end

		rescue BSON::InvalidObjectId
			render "public/404.html", :status => 404 and return
		rescue Mongoid::Errors::DocumentNotFound
			render "public/404.html", :status => 404 and return

	end

	#Add links function
	def createcontent

		#TODO: if the URL is to a document, ask if they want to upload it as a document instead

		################## URI REFERENCE - DO NOT DELETE! #####################


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


		#######################################################################


		#respcode = RestClient.get(params[:binder][:versions][:data]) { |response, request, result| response.code }.to_i
	
			# This will catch flawed URL structure, as well as bad HTTP response codes

		# the RestClient object will catch most of the error codes before getting to here
		#if ![200,301,302].include? respcode
		#	raise "Invalud URL! Response code: #{respcode}" and return
		#end

		#@binder = Binder.new

		errors = []

		#Trim to 60 chars (old spec)
		if params[:webtitle].strip.length > 0

			embed = false
			url = false
			embedtourl = false

			doc = Nokogiri::HTML(params[:weblink])

			if !doc.at('iframe').nil?

				uri = URI.parse(doc.at('iframe')['src'])

				if uri.host.include?('youtube.com') && uri.path.include?('embed')

					embedtourl = true
					uri = "http://www.youtube.com/watch?v=#{uri.path.split('/').last}"

				elsif uri.host.include?('educreations.com') && uri.path.include?('lesson/embed')

					embedtourl = true
					uri = "http://www.educreations.com/lesson/view/claco/#{uri.path.split('/').last}"

				elsif uri.host.include?('player.vimeo.com') && uri.path.include?('video')

					embedtourl = true
					uri = "http://vimeo.com/#{uri.path.split('/').last}"

				elsif uri.host.include?('schooltube.com') && uri.path.include?('embed')

					embedtourl = true
					uri = "http://www.schooltube.com/video/#{uri.path.split('/').last}"

				elsif uri.host.include?('showme.com') && uri.path.include?('sma/embed')

					embedtourl = true
					uri = "http://www.showme.com/sh/?h=#{CGI.parse(uri.query)['s'].first}"

				else

					embed = true

				end

			elsif !doc.at('embed').nil?

				embed = true

			end

			if !embed && !embedtourl
				RestClient.get(params[:weblink]) # This line throws an exception if the url is invalid
				url = true
			end

			if url || embed || embedtourl

				@inherited = inherit_from(params[:id])

				@parenthash = @inherited[:parenthash]
				@parentsarr = @inherited[:parentsarr]
				@parentperarr = @inherited[:parentperarr]

				@parent_child_count = @inherited[:parent_child_count]

				if @inherited[:parent].get_access(current_teacher.id.to_s) == 2

					link = Addressable::URI.heuristic_parse(Url.follow(params[:weblink])).to_s if url
					link = Addressable::URI.heuristic_parse(Url.follow(uri)).to_s if embedtourl

					raise "Invalid URL" if (url || embedtourl) && link.empty?

					raise "Sorry, you can't link to this site. Please download any files and upload them to Claco." if URI.parse(link).host.include?("teacherspayteachers.com")

					@binder = Binder.new(	:title				=> params[:webtitle].strip[0..49],
											:owner				=> current_teacher.id,
											:username			=> current_teacher.username,
											:fname				=> current_teacher.fname,
											:lname				=> current_teacher.lname,
											:parent				=> @parenthash,
											:parents			=> @parentsarr,
											:last_update		=> Time.now.to_i,
											:last_updated_by	=> current_teacher.id.to_s,
											:body				=> params[:body],
											:order_index		=> @parent_child_count,
											:parent_permissions	=> @parentperarr,
											:files				=> 1,
											:type				=> 2,
											:format				=> 2)


					@binder.versions << Version.new(:data		=> url || embedtourl ? link : params[:weblink],
													:thumbnailgen => 1, #video
													:embed		=> embed,
													:timestamp	=> Time.now.to_i,
													:owner		=> current_teacher.id)


					#@binder.create_binder_tags(params,current_teacher.id)

					@binder.save

					Mongo.log(	current_teacher.id.to_s,
								__method__.to_s,
								params[:controller].to_s,
								@binder.id.to_s,
								params)

					if url || embedtourl

						uri = URI.parse(link)

						stathash = @binder.current_version.imgstatus
						stathash[:imgfile][:retrieved] = true

						if (uri.host.to_s.include? 'youtube.com') && (uri.path.to_s.include? '/watch')

							# YOUTUBE
							# DELAYTAG
							Binder.delay(:queue => 'thumbgen').get_thumbnail_from_url(@binder.id,Url.get_youtube_url(uri.to_s))

							#Binder.delay(:queue => 'thumbgen').gen_video_thumbnails(@binder.id)

						elsif (uri.host.to_s.include? 'vimeo.com') && (uri.path.to_s.length > 0)# && (uri.path.to_s[-8..-1].join.to_i > 0)

							# VIMEO
							# DELAYTAG
							Binder.delay(:queue => 'thumbgen').get_thumbnail_from_api(@binder.id,uri.to_s,{:site => 'vimeo'})

							#Binder.delay(:queue => 'thumbgen').gen_video_thumbnails(@binder.id)

						elsif (uri.host.to_s.include? 'educreations.com') && (uri.path.to_s.length > 1)

							# EDUCREATIONS
							# DELAYTAG
							Binder.delay(:queue => 'thumbgen').get_thumbnail_from_url(@binder.id,Url.get_educreations_url(uri.to_s))

							#Binder.delay(:queue => 'thumbgen').gen_video_thumbnails(@binder.id)

						elsif (uri.host.to_s.include? 'schooltube.com') && (uri.path.to_s.length > 0)

							# SCHOOLTUBE
							# DELAYTAG
							Binder.delay(:queue => 'thumbgen').get_thumbnail_from_api(@binder.id,uri.to_s,{:site => 'schooltube'}) 

							#Binder.delay(:queue => 'thumbgen').gen_video_thumbnails(@binder.id)

						elsif (uri.host.to_s.include? 'showme.com') && (uri.path.to_s.include? '/sh')

							# SHOWME
							# DELAYTAG
							Binder.delay(:queue => 'thumbgen').get_thumbnail_from_api(@binder.id,uri.to_s,{:site => 'showme'})

							#Binder.delay(:queue => 'thumbgen').gen_video_thumbnails(@binder.id)

						else
							@binder.versions.last.update_attributes( :thumbnailgen => 2 )
							# generic URL, grab Url2png
							# DELAYTAG
							Binder.delay(:queue => 'thumbgen').get_thumbnail_from_url(@binder.id,Url.get_url2png_url(uri.to_s))

							#Binder.delay(:queue => 'thumbgen').gen_url_thumbnails(@binder.id)
						end

					end

					@binder.create_binder_tags(params,current_teacher.id)

					pids = @parentsarr.collect {|x| x["id"] || x[:id]}

					pids.each {|pid| Binder.find(pid).inc(:files, 1) if pid != "0"}

					Binder.find(pids.last).inc(:children, 1) if pids.last != "0"

				else

					errors << "You do not have permissions to write to #{@inherited[:parent].title}"

				end

			else

				errors << "Invalid input data"

			end

		else

			errors << "You must enter a title"

		end

		rescue BSON::InvalidObjectId
			errors << "Invalid Request"
		rescue Mongoid::Errors::DocumentNotFound
			errors << "Invalid Request"
		rescue Exception => e
			errors << e
		ensure
			respond_to do |format|
				format.html {render :text => errors.empty? ? 1 : errors.map{|err| "<li>#{err}</li>"}.join.html_safe}
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

	#Add file process
	def createfile

		#@teststr = "1234567890"

		#debugger

		errors = []

		@inherited = inherit_from(params[:id])

		if @inherited[:parent].get_access(current_teacher.id.to_s)
			
			@binder = Binder.new

			@parenthash = @inherited[:parenthash]
			@parentsarr = @inherited[:parentsarr]
			@parentperarr = @inherited[:parentperarr]

			@parent_child_count = @inherited[:parent_child_count]

			#@filedata = 6

			#@newfile = File.open(params[:binder][:versions][:file].path,"rb")
			
			@binder.update_attributes(	:title				=> File.basename(	params[:file].original_filename,
																				File.extname(params[:file].original_filename)).strip[0..49],
										:owner				=> current_teacher.id,
										:fname				=> current_teacher.fname,
										:lname				=> current_teacher.lname,
										:username			=> current_teacher.username,
										:parent				=> @parenthash,
										:parents			=> @parentsarr,
										:last_update		=> Time.now.to_i,
										:last_updated_by	=> current_teacher.id.to_s,
										#:body				=> params[:binder][:body],
										:total_size			=> params[:file].size,
										:pub_size			=> @inherited[:parent].is_pub? ? params[:file].size.to_i : 0, 
										:priv_size			=> @inherited[:parent].is_pub? ? 0 : params[:file].size.to_i,
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

			@binder.versions << Version.new(:file		=> params[:file],
											:file_hash	=> Digest::MD5.hexdigest(File.read(params[:file].path).to_s),
											:ext		=> File.extname(params[:file].original_filename),
											:data		=> params[:file].original_filename,
											:size		=> params[:file].size,
											:timestamp	=> Time.now.to_i,
											:owner		=> current_teacher.id)#,
											#:croc_uuid => filedata)

			if @binder.save

				Mongo.log(	current_teacher.id.to_s,
							__method__.to_s,
							params[:controller].to_s,
							@binder.id.to_s,
							params.to_s)

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

						# delay(:queue => 'thumbgen').
						#Binder.delay(:queue => 'thumbgen').gen_croc_thumbnails(@binder.id)

					elsif CLACO_VALID_IMAGE_FILETYPES.include? @binder.current_version.ext.downcase
						# for now, image will be added as file AND as imgfile
						stathash = @binder.current_version.imgstatus#[:imgfile][:retrieved]
						stathash[:imgfile][:retrieved] = true

						# upload image
						@binder.current_version.update_attributes( 	:imgfile => params[:file],
																	:imgclass => 0,
																	:imgstatus => stathash)

						#Binder.generate_folder_thumbnail(@binder.id)

						#GC.start

						#Rails.logger.debug ">>> About to call generate_folder_thumbnail on #{@binder.parent["id"].to_s}"
						#Rails.logger.debug ">>> Binder.inspect #{@binder.parent.to_s}"

						Binder.delay(:queue => 'thumbgen').gen_smart_thumbnails(@binder.id)

						# DELAYTAG
						#Binder.delay(:queue => 'thumbgen').generate_folder_thumbnail(@binder.parent["id"] || @binder.parent[:id])

					elsif @binder.current_version.ext.downcase == ".notebook"

						#This job should probably be delayed

						zip = Zip::ZipFile.open(params[:file].path)

						if !zip.find_entry('preview.png').nil?

							png = FilelessIO.new(zip.read('preview.png'))

							png.original_filename = 'preview.png'

							stathash = @binder.current_version.imgstatus
							stathash[:imgfile][:retrieved] = true

							@binder.current_version.update_attributes(:imgfile => png)

							Binder.delay(:queue => 'thumbgen').gen_croc_thumbnails(@binder.id)
						end

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
													:total_size	=> parent.total_size + params[:file].size)
					end
				end

				Binder.find(pids.last).inc(:children,1) if pids.last != "0"

			else

				errors << ""

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

						parent.update_attributes(	:owned_fork_total => op.owned_fork_total + (@binder.fork_total+@binder.owned_fork_total),
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

			# due to shared functionality, define method var
			
			if fav
				method = "favorite"

				@binder.inc(:fav_total, 1)
			elsif fork
				method = "forkitem"
				# fork_total is 
				@binder.inc(:fork_total, 1)

				# cascade upwards
				@binder.parents.each do |f|
					Binder.find(f['id'].to_s).inc(:owned_fork_total,1) if f['id'].to_i>0
				end
			else
				method = __method__.to_s
			end

			#@binder.inc(:fork_total, 1) if fork

			#recurse upwards

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
										:username			=> @binder.username,
										:fname				=> @binder.fname,
										:lname				=> @binder.lname,
										:last_update		=> Time.now.to_i,
										:last_updated_by	=> current_teacher.id)

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

			@new_parent.save

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
											:username			=> h.username,
											:fname				=> h.fname,
											:lname				=> h.lname,
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
											:fav_total			=> h.fav_total)

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

		redirect_to named_binder_route(@binder.parent["id"]) and return if @binder.type == 1 && @binder.parent["id"] != "0"

		redirect_to binders_path if @binder.type == 1
	end

	def swap
		@binder = Binder.find(params[:id])

		@binder.versions.each {|v| v.update_attributes(:active => v.id.to_s == params[:version][:id])}

		redirect_to named_binder_route(@binder.parent["id"])
	end

	#Only owner can set permissions
	# def permissions
	# 	@binder = Binder.find(params[:id])

	# 	render "public/403.html", :status => 403 and return if current_teacher.id.to_s != @binder.owner

	# 	@title = "Permissions for #{@binder.title}"

	# 	#To be replaced with current_teacher.colleagues
	# 	@colleagues = Teacher.all.reject {|t| t == current_teacher}
	# end

	#This is so nasty.
	def setpub

		@binder = Binder.find(params[:id])

		error = ""

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
						h.priv_size = 0
					else
						h.priv_size = h.priv_size + h.pub_size
						h.pub_size = 0
					end

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
							h.priv_size = 0
						else
							h.priv_size = h.priv_size + h.pub_size
							h.pub_size = 0
						end

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

	# def createpermission
	# 	@binder = Binder.find(params[:id])

	# 	@new = false

	# 	src = Mongo.log(current_teacher.id.to_s,
	# 					__method__.to_s,
	# 					params[:controller].to_s,
	# 					@binder.id.to_s,
	# 					params)

	# 	@binder.permissions.each {|p| @new = true if p["shared_id"] == params[:shared_id]}

	# 	@binder.parent_permissions.each {|pp| @new = true if pp["shared_id"] == params[:shared_id]} 

	# 	@binder.permissions << {:type		=> params[:type],
	# 							:shared_id	=> (params[:type] == "1" ? params[:shared_id] : "0"),
	# 							:auth_level	=> params[:auth_level]} if !@new

	# 	@binder.save

	# 	@binder.subtree.each do |c| 

	# 		if !@new

	# 			c.update_attributes(:parent_permissions => c.parent_permissions << {:type => params[:type],
	# 																				:shared_id => params[:shared_id],
	# 																				:auth_level => params[:auth_level],
	# 																				:folder_id => params[:id]}) 
	# 			Mongo.log(	current_teacher.id.to_s,
	# 						__method__.to_s,
	# 						params[:controller].to_s,
	# 						c.id.to_s,
	# 						params,
	# 						{ :src => src })

	# 		end
	# 	end

	# 	redirect_to named_binder_route(@binder, "permissions")
	# end

	# def destroypermission
	# 	@binder = Binder.find(params[:id])

	# 	src = Mongo.log(current_teacher.id.to_s,
	# 					__method__.to_s,
	# 					params[:controller].to_s,
	# 					@binder.id.to_s,
	# 					params)

	# 	pper = @binder.permissions[params[:pid].to_i]

	# 	pper["folder_id"] = params[:id]

	# 	@binder.permissions.delete_at(params[:pid].to_i)

	# 	@binder.subtree.each do |c|
	# 		c.parent_permissions.delete(pper)
	# 		c.save

	# 		Mongo.log(	current_teacher.id.to_s,
	# 					__method__.to_s,
	# 					params[:controller].to_s,
	# 					c.id.to_s,
	# 					params,
	# 					{ :src => src })

	# 	end

	# 	@binder.save

	# 	#Binder.delay(:queue => 'thumbgen').generate_folder_thumbnail(params[:id])
	# 	#Binder.generate_folder_thumbnail(params[:id])
	# 	Binder.generate_folder_thumbnail(@binder.parent['id'])

	# 	redirect_to named_binder_route(@binder, "permissions")
	# end

	def trash
		@children = Binder.where(:owner => current_teacher.id, "parent.id" => "-1")

		@tagset = []

		@tags = [[],[],[],[]]

		#render "public/403.html", :status => 403 and return if params[:username] != current_teacher.username

		@title = "#{current_teacher.fname} #{current_teacher.lname}'s Trash"
	end

	#More validation needed, Permissions
	def destroy
		@binder = Binder.find(params[:id])

		errors = []

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

	# def seedbinder

	# 	Binder.seedbinder(current_teacher.to_s) if !current_teacher.nil?

	# 	redirect_to root_path

	# end

	def catcherr

		# why in fuck's sake is the server trying to fetch a directory?
		raise 'Bad Fetch'

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

	# def get_youtube_url(url)

	# 	return "http://img.youtube.com/vi/#{CGI.parse(URI.parse(url).query)['v'].first.to_s}/0.jpg"

	# end

	module Mongo
		extend self

		def log(ownerid,method,model,modelid,params,data = {})

			log = Log.new( 	:ownerid => ownerid.to_s,
							:timestamp => Time.now.to_i,
							:method => method.to_s,
							:model => model.to_s,
							:modelid => modelid.to_s,
							:params => params,
							:data => data)

			log.save

			return log.id.to_s

		end

		# this method is unused
		def method_index(method)

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

			#Rails.logger.debug "Method: #{method.to_s}"

			method = method.to_s

			return 0 if ( method=="createcontent" || method=="createfile" || method=="create" )
			return 1 if ( method=="update" )
			return 2 if ( method=="createversion" )
			return 3 if ( method=="rename" )
			return 4 if ( method=="updatetags" )
			return 5 if ( method=="moveitem" )
			return 6 if ( method=="copyitem" )
			return 7 if ( method=="delete" )
			return 8 if ( method=="setpub" || method=="createpermission" || method=="destroypermission" )
			return 9 if ( method=="reorder" )
			return 10 if ( method=="download" )
			#return 11 if ( method== )			

			# if this point is reached, the method is unknown
			raise "Method not recognized!"

		end

	end

	module Url
		extend self
		
		def follow(url, hop = 0)
		
			return nil if hop == 5

			r = RestClient.get(url){|r1,r2,r3| r1}

			return follow(r.headers[:location], hop + 1) if r.code > 300 && r.code != 304 && r.code < 400

			return url if r.code == 200 || r.code == 304

		end

		def get_youtube_url(url)

			return YOUTUBE_IMG_URL + CGI.parse(URI.parse(url).query)['v'].first.to_s + YOUTUBE_IMG_FILE

		end

		def get_educreations_url(url)

			url = URI(url)

			educr_id = -1

			# pull out educr video ID
			url.path.split('/').each do |f|
				if f.to_i.to_s.length==6
					educr_id = f.to_i
					break
				end
			end

			if educr_id < 0
				raise "Could not extract video ID from url" and return
			end

			imgkey = Digest::MD5.hexdigest(educr_id.to_s)[0..2]

			return "http://media.educreations.com/recordings/#{imgkey}/#{educr_id}/thumbnail.280x175.png"

		end

		def get_url2png_url(url,options = {})

			if options.empty?
				bounds = URL2PNG_DEFAULT_BOUNDS
			else
				bounds = options[:bounds].to_s
			end

			sec_hash = Digest::MD5.hexdigest(URL2PNG_PRIVATE_KEY + '+' + URI.encode(url)).to_s

			Rails.logger.debug "#{URL2PNG_API_URL + URL2PNG_API_KEY}/#{sec_hash}/#{bounds}/#{url}"

			#return RestClient.get(URL2PNG_API_URL + URL2PNG_API_KEY + '/' + sec_hash + '/' + bounds + '/' + url)
			return "#{URL2PNG_API_URL + URL2PNG_API_KEY}/#{sec_hash}/#{bounds}/#{URI.encode(url)}"

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

			require 'open-uri'

			#filedata = JSON.parse(RestClient.post(CROC_API_URL + PATH_UPLOAD, :token => CROC_API_TOKEN, :url => filestring.to_s){ |response, request, result| response })

			Rails.logger.debug filestring

			filedata = JSON.parse(RestClient.post(CROC_API_URL+PATH_UPLOAD, :token => CROC_API_TOKEN, 
																			#:file => File.open("#{filestring}")){ |response, request, result| response })
																			:url => filestring.sub(/https:\/\/cdn.cla.co.s3.amazonaws.com/, "http://cdn.cla.co")))#open(filestring)){ |response, request, result| response })

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
			#return JSON.parse(RestClient.get(CROC_API_URL + PATH_STATUS, :token => CROC_API_TOKEN, :uuids => uuid ){ |response, request, result| response })
			
			return JSON.parse(RestClient.get("https://crocodoc.com/api/v2/document/status?token=#{CROC_API_TOKEN}&uuids=#{uuid.to_s}"))

		end

		 # passed uuid of file
		 # returns fullsize thumbnail
		def get_thumbnail_url(uuid,options = {})

			options = CROC_API_OPTIONS.merge(options).merge({:uuid => uuid, :size => '300x300'})

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

	end

end