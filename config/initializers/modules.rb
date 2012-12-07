module Url
	extend self
	
	def follow(url, hop = 0)
	
		return url if hop == 5

		r = RestClient.get(url){|r1,r2,r3|r1}

		return follow(r.headers[:location], hop + 1) if r.code > 300 && r.code != 304 && r.code < 400

		return url if r.code == 200 || r.code == 304

		rescue

		return url

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

	def get_doctext_url(uuid,options = {})

		options = CROC_API_OPTIONS.merge(options).merge({:uuid => uuid})

		return "#{CROC_API_URL+PATH_TEXTGRAB}?#{URI.encode_www_form(options)}"

	end

	# passed the uuid of file
	# returns the session string to view the document
	def sessiongen(uuid)

		return JSON.parse(RestClient.post(CROC_API_URL + PATH_SESSION, :token => CROC_API_TOKEN, :uuid => uuid.to_s){ |response, request, result| response })

	end
end