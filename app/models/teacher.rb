class Teacher
	include Mongoid::Document
	include Mongoid::Spacial::Document
	include Tire::Model::Search
	include Tire::Model::Callbacks
	include Sprockets::Helpers::RailsHelper
	include Sprockets::Helpers::IsolatedHelper

	class FilelessIO < StringIO
		attr_accessor :original_filename

		def set_filename(name = "")
			@original_filename = name
			return self
		end
	end

	# Include default devise modules. Others available are:
	# :token_authenticatable, :confirmable,
	# :lockable, :timeoutable and :omniauthable
	devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :authentication_keys => [:login]

	## Database authenticatable
	field :email,              :type => String, :null => false, :default => "", :unique => true
	field :encrypted_password, :type => String, :null => false, :default => ""

	## Recoverable
	field :reset_password_token,   :type => String
	field :reset_password_sent_at, :type => Time

	## Rememberable
	field :remember_created_at, :type => Time

	## Trackable
	field :sign_in_count,      :type => Integer, :default => 0
	field :current_sign_in_at, :type => Time
	field :last_sign_in_at,    :type => Time
	field :current_sign_in_ip, :type => String
	field :last_sign_in_ip,    :type => String

	field :registered_at,		:type => Time
	field :registered_ip,		:type => String

	## Confirmable
	# field :confirmation_token,   :type => String
	# field :confirmed_at,         :type => Time
	# field :confirmation_sent_at, :type => Time
	# field :unconfirmed_email,    :type => String # Only if using reconfirmable

	## Lockable
	# field :failed_attempts, :type => Integer, :default => 0 # Only if lock strategy is :failed_attempts
	# field :unlock_token,    :type => String # Only if unlock strategy is :email or :both
	# field :locked_at,       :type => Time

	#Exclusive beta signup code used to sign up
	field :code, :type => String

	field :title, :type => String
	field :fname, :type => String
	field :lname, :type => String
	field :username, :type => String
	field :pub_size, :type => Integer, :default => 0
	field :priv_size, :type => Integer, :default => 0
	field :total_size, :type => Integer, :default => 0
	field :size_cap, :type => Integer, :default => 300.megabytes

	field :omnihash, :type => Hash, :default => {}

	field :emailconfig, :type => Hash, :default => {"msg" => true,
													"col" => true,
													"sub" => true}

	field :allow_short_username, :type => Boolean, :default => false
	field :getting_started, :type => Boolean, :default => true

	field :admin, :type => Boolean, :default => false

	embeds_one :info#, autobuild: true #, validate: false

	embeds_one :tag#, autobuild: true #, validate: false

	#has_one :feed

	embeds_many :relationships#, validate: false

	attr_accessible :username, :email, :password, :password_confirmation, :remember_me, :login, :fname, :lname, :title, :getting_started, :emailconfig, :pub_size, :priv_size, :total_size, :avatarstatus, :thumbnails
	
	validate :username_blacklist

	validates_uniqueness_of :username, :case_sensitive => false
	validates_format_of :username, with: /[-a-z0-9]+/i, :message => "has invalid characters."
	validates_format_of :username, without: /\s/, :message => "has invalid characters."
	validates_length_of :username, minimum: 5, maximum: 16, :message => "must be at least 5 characters", :unless => Proc.new {|user| user.allow_short_username == true}
	validates_presence_of :fname, :message => "Please enter a first name."
	validates_presence_of :lname, :message => "Please enter a last name."
	validates_numericality_of :size_cap, less_than_or_equal_to: 10.gigabytes
	
	attr_accessor :login

	index [["info.location", Mongo::GEO2D]]

	## Token authenticatable
	# field :authentication_token, :type => String


	# after_save do
	# 	debugger
	# 	#Rails.logger.debug "AFTER_SAVE got here!"
	# 	self.tire.update_index
	# 	#self.tire.index.delete
	# 	#self.tire.index.create
	# end


	# DO NOT DELETE:

	# The Brown-Cow's Part_No. #A.BC123-456 joe@bloggs.com
	# keyword:    			The Brown-Cow's Part_No. #A.BC123-456 joe@bloggs.com
	# whitespace:   		The, 	Brown-Cow's, 			Part_No., 		#A.BC123-456, 				joe@bloggs.com
	# simple:    			the, 	brown, 			cow, s, part, 		no, a, 				bc, 		joe, 			bloggs, 	com
	# standard:    					brown, 			cow's, 	part_no, 		a.bc123, 			456, 	joe, 			bloggs.com
	# snowball (English):   		brown, 			cow, 	part_no, 		a.bc123, 			456, 	joe, 			bloggs.com

	after_save do

		#self.update_index

		keys = Rails.cache.read(self.id.to_s)

		if !keys.nil?

			keys.each do |f|
				#Rails.cache.delete(f.to_s)
				#Rails.cache.expire_fragment(f.to_s)
				Rails.cache.write(f.to_s,true)			
			end

			Rails.cache.delete(self.id.to_s)

			Rails.cache.write("#{self.id.to_s}educobj",true)

		end

	end


	settings analysis: {
		filter: {
			ngram_filter: {
				type: 		"nGram",
				min_gram: 	3,
				max_gram: 	6
			}
		},
		analyzer: {
			ngram_analyzer: {
				tokenizer: "standard",
				filter: ["ngram_filter"],
				type: "custom"
				#tokenizer: "snowball",
				#filter: ["lowercase","ngram_filter"]
			}
		}
	} 	do
		mapping do
			indexes :fname, 	:type => 'string', 	:analyzer => 'ngram_analyzer', :boost => 200.0
			indexes :lname, 	:type => 'string', 	:analyzer => 'ngram_analyzer', :boost => 300.0
			indexes :username, 	:type => 'string', 	:analyzer => 'ngram_analyzer', :boost => 100.0
			indexes :omnihash, 	:type => 'object', 	:properties => {:twitter 			=> { :type => 'object', :properties => { :username 	=> 	{ :type => 'string', :analyzer => 'ngram_analyzer' },
																															 	 :uid 		=> 	{ :type => 'object', :enabled => false },
																																 :profile 	=> 	{ :type => 'object', :enabled => false },
																																 :fids 		=> 	{ :type => 'object', :enabled => false },
																																 :data 		=> 	{ :type => 'object', :enabled => false }}},
																	:facebook 			=> { :type => 'object', :enabled => false }}
			indexes :info, 		:type => 'object', 	:properties => {:thumbnails			=> { :type => 'object', :enabled => false, :store => "yes" },
																	:avatar 			=> { :type => 'object',	:enabled => false },
																	:avatar_thumb_lg	=> { :type => 'object',	:enabled => false }, 
																	:avatar_thumb_mg	=> { :type => 'object',	:enabled => false }, 
																	:avatar_thumb_md	=> { :type => 'object',	:enabled => false }, 
																	:avatar_thumb_sm	=> { :type => 'object',	:enabled => false }, 
																	:size 				=> { :type => 'object', :enabled => false },
																	:ext 				=> { :type => 'object', :enabled => false },
																	:data 				=> { :type => 'object', :enabled => false },
																	:grades 			=> { :type => 'string', :analyzer => 'ngram_analyzer', :default => [] },
																	:subjects 			=> { :type => 'string', :analyzer => 'ngram_analyzer', :default => [] },
																	:bio 				=> { :type => 'string', :analyzer => 'snowball', :boost => 50.0 },
																	:website 			=> { :type => 'string', :analyzer => 'ngram_analyzer' },
																	:city				=> { :type => 'string', :analyzer => 'ngram_analyzer' },
																	:state 				=> { :type => 'string', :analyzer => 'ngram_analyzer' },
																	:country			=> { :type => 'string', :analyzer => 'ngram_analyzer' },
																	:location			=> { :type => 'geo_point', :default => [] } }
		end
	end

	# Class Methods

	# used for elasticsearch
	def self
    	#to_indexed_json.as_json
    	to_indexed_json.to_json
	end

	# these clases are not defined on instances of Teacher because they are not available to ElasticSearch result objects,
	# which are indistinguishable from mongo result objects

	def self.thumbready? (teacher)

		# return 	!teacher.nil? && 
		# 		!teacher.info.nil? && 
		# 		!teacher.info.thumbnails.nil? && 
		# 		!teacher.info.thumbnails.first.nil? && 
		# 		!teacher.info.thumbnails.first.empty?

		return 	!teacher.nil? &&
				!teacher.info.nil? && 
				!teacher.info.avatar.nil? &&
				!teacher.info.avatarstatus.nil? && 
				!teacher.info.avatarstatus['avatar_thumb_lg'].nil? && 
				teacher.info.avatarstatus['avatar_thumb_lg']['generated'] # &&
				#teacher.info.avatarstatus['avatar_thumb_lg']['generated']
				#!teacher.info.avatar.url(:thumb_sm).to_s.empty?
				#!teacher.info.avatar_thumb_sm.url.to_s.empty?

	end

	def self.thumbscheduled? (teacher,thumb)

		return false if teacher.info.nil? || teacher.info.avatarstatus.nil? || teacher.info.avatarstatus[thumb].nil?
		return teacher.info.avatarstatus[thumb]['scheduled']

	end

	def self.thumb_lg (teacher)

		return Teacher.thumbready?(teacher) ? teacher.info.thumbnails[0] : nil #teacher.info.avatar.url(:thumb_lg) : nil #asset_path("placer.png")
		#return Teacher.thumbready?(teacher) ? teacher.info.thumbnails[0] : (teacher.info.avatar.nil?||teacher.info.avatar.url.nil?) ? "/assets/placer.png" : teacher.info.avatar.url.to_s

	end

	def self.thumb_mg (teacher)

		return Teacher.thumbready?(teacher) ? teacher.info.thumbnails[1] : nil #teacher.info.avatar.url(:thumb_mg).to_s : nil #asset_path("placer.png")
		#return Teacher.thumbready?(teacher) ? teacher.info.thumbnails[1] : (teacher.info.avatar.nil?||teacher.info.avatar.url.nil?) ? "/assets/placer.png" : teacher.info.avatar.url.to_s

	end

	def self.thumb_md (teacher)

		return Teacher.thumbready?(teacher) ? teacher.info.thumbnails[2] : nil #teacher.info.avatar.url(:thumb_md).to_s : nil #asset_path("placer.png")
		#return Teacher.thumbready?(teacher) ? teacher.info.thumbnails[2] : (teacher.info.avatar.nil?||teacher.info.avatar.url.nil?) ? "/assets/placer.png" : teacher.info.avatar.url.to_s

	end

	def self.thumb_sm (teacher)

		return Teacher.thumbready?(teacher) ? teacher.info.thumbnails[3] : nil #teacher.info.avatar.url(:thumb_sm).to_s : nil #asset_path("placer.png")
		#return Teacher.thumbready?(teacher) ? teacher.info.thumbnails[3] : (teacher.info.avatar.nil?||teacher.info.avatar.url.nil?) ? "/assets/placer.png" : teacher.info.avatar.url.to_s

	end

	def self.gen_thumbnails(teacherid)

			teacher = Teacher.find(teacherid.to_s)

			# create versions of avatar
			#include Magick

			#debugger

			origimg = Magick::ImageList.new

			# retrieve fullsize image from S3 store, read into an ImageList object
			open(URI.escape(teacher.info.avatar.url.to_s)) do |f|
				origimg.from_blob(f.read)
			end

	        origimg.format = BLOB_FILETYPE

			if (origimg.columns.to_i > IMGSCALE || origimg.rows.to_i > IMGSCALE)
				origimg.resize_to_fit!(IMGSCALE,IMGSCALE)
			end

			GC.start

			stathash = teacher.info.avatarstatus
			stathash['avatar_thumb_lg']['scheduled'] = false
			stathash['avatar_thumb_mg']['scheduled'] = false
			stathash['avatar_thumb_md']['scheduled'] = false
			stathash['avatar_thumb_sm']['scheduled'] = false
			stathash['avatar_thumb_lg']['generated'] = true
			stathash['avatar_thumb_mg']['generated'] = true
			stathash['avatar_thumb_md']['generated'] = true
			stathash['avatar_thumb_sm']['generated'] = true

			#debugger

			teacher.info.update_attributes(	:avatarstatus => stathash,
											:avatar_thumb_lg => FilelessIO.new(origimg.resize_to_fill!(AVATAR_LDIM, AVATAR_LDIM, Magick::CenterGravity).to_blob).set_filename(LG_AVATAR_FILENAME),
											:avatar_thumb_mg => FilelessIO.new(origimg.resize_to_fill!(AVATAR_MGDIM,AVATAR_MGDIM,Magick::CenterGravity).to_blob).set_filename(MG_AVATAR_FILENAME),
											:avatar_thumb_md => FilelessIO.new(origimg.resize_to_fill!(AVATAR_MDIM, AVATAR_MDIM, Magick::CenterGravity).to_blob).set_filename(MD_AVATAR_FILENAME),
											:avatar_thumb_sm => FilelessIO.new(origimg.resize_to_fill!(AVATAR_SDIM, AVATAR_SDIM, Magick::CenterGravity).to_blob).set_filename(SM_AVATAR_FILENAME))

			teacher.info.update_attributes( :thumbnails => [teacher.info.avatar_thumb_lg.url.to_s,
															teacher.info.avatar_thumb_mg.url.to_s,
															teacher.info.avatar_thumb_md.url.to_s,
															teacher.info.avatar_thumb_sm.url.to_s])

			origimg.destroy!

			GC.start

	end

	def shift_thumb_urls

		#debugger

		return if self.info.nil? || !self.info.avatarstatus['avatar_thumb_sm']['generated'] #|| !self.info.avatarstatus['avatar_thumb_sm']['scheduled']

		self.info.update_attributes( :thumbnails => [self.info.avatar_thumb_lg.url.to_s,
													 self.info.avatar_thumb_mg.url.to_s,
													 self.info.avatar_thumb_md.url.to_s,
													 self.info.avatar_thumb_sm.url.to_s])

	end

	# def to_indexed_json
 #    	self.as_json
	# end

	# field :size, 				:type => Integer, :default => 0
	# field :ext, 				:type => String, :default => ""
	# field :data, 				:type => String, :default => "" #URL, path to file

	# field :grades,				:type => Array, :default => []
	# field :subjects,			:type => Array, :default => []
	# field :bio, 				:type => String, :default => ""
	# field :website,				:type => String, :default => ""
	# field :city,				:type => String, :default => ""
	# field :state,				:type => String, :default => ""
	# field :country,				:type => String, :default => ""
	# field :location,			:type => Array, :default => []
	# field :twitterhandle,		:type => String, :default => ""
	# field :facebookurl,			:type => String, :default => ""

	# returns best info for an at-a-glance panel
	def glance_info(lines = 2)

		return [] if info.nil?

		retarr = []

		if !info.bio.nil? && !info.bio.empty?
			if info.bio.size > 100
				# if bio is present and of sufficient length, this is the full infoset
				return [{:type => 'bio', :content => info.bio}] 
			else
				retarr << {:type => 'bio', :content => info.bio}
			end
		end

		# iterate through single-line content items
		[{:type => 'location', 	:content => info.fulllocation == ', , ' ? '' : "From: #{info.fulllocation}"},
		{:type => 'subjects', 	:content => info.subjects.empty? ? '' : "Subjects taught: #{info.subjects.join(', ')}"},
		{:type => 'grades', 	:content => info.grades.empty? ? '' : "Grades taught: #{info.grades.join(', ')}"},
		{:type => 'website', 	:content => info.website.empty? ? '' : "Website: #{info.website}"}].each do |f|

			retarr << f if !f[:content].nil? && !f[:content].empty?

			break if retarr.size==2
		end

		return retarr
	end

	# Mr. John Smith
	def full_name
		return "#{title} #{fname} #{lname}"
	end

	def first_last
		return "#{fname} #{lname}"
	end

	# Mr. Smith
	def formal_name
		return "#{title} #{lname}"
	end

	def relationship_by_teacher_id(teacher_id)
		self.relationships.find_or_initialize_by(:user_id => teacher_id)
	end

	def get_incoming_colleague_requests
		self.relationships.where(:colleague_status => 2)
	end

	def subscribed_to?(id)
		return self.relationships.find_or_initialize_by(:user_id => id).subscribed
	end

	def colleague_status(id)
		return self.relationships.find_or_initialize_by(:user_id => id).colleague_status
	end

	def self.find_first_by_auth_conditions(warden_conditions)
		conditions = warden_conditions.dup
		if login = conditions.delete(:login)
			self.any_of({ :username =>  /^#{Regexp.escape(login)}$/i }, { :email =>  /^#{Regexp.escape(login)}$/i }).first
		else
			super
		end
	end

	def get_unread_count

		Conversation.where(:members => self.id.to_s, :"unread.#{self.id.to_s}".gte => 1).count

	end

	def to_param
		username
	end

	def binders
		Binder.where(:owner => self.id.to_s)
	end

	# recursively aggregates teacher subscription network
	# degree of 1 represents teacher's immediate subscriptions
	def subscriptions (degree = 1)

		ret = {}
		if degree>0
			self.relationships.where(:subscribed => true).entries.map { |r| Teacher.find(r["user_id"]) }.each do |f|
				ret[f.id.to_s] = ret[f.id.to_s] ? ret[f.id.to_s]+1 : 1
				f.subscriptions(degree-1).each do |g|
					ret[g[0].to_s] = (ret[g[0].to_s] ? g[1]+1 : 1)
				end
			end
		end
		ret
	end

	#TODO: convert these to ElasticSearch queries!
	def self.vectors (id, degree = 1, vec = {}, ids = [])

		#debugger
		# determine vec.size

		if degree!=0
			id = id.to_s
			ids = []
			teacher = Teacher.find(id.to_s)
			if !teacher.code.nil? && !teacher.code.empty? && teacher.code.to_s!="0"
				t_id = nil
				if teacher.code.to_s.length==24
					t_id = teacher.code.to_s
				else
					invitation = Invitation.where(:code => teacher.code.to_s).first
					t_id = Teacher.find(invitation.from.to_s).id.to_s if !invitation.nil? && !invitation.from.nil? && invitation.from.to_s!="0"
				end
				if !t_id.nil? && !t_id.empty?
					if !vec[id]
						vec[id] = { t_id => ~INVITE_BITMAP }
						ids << t_id
					elsif !vec[id][t_id]
						vec[id][t_id] = ~INVITE_BITMAP
						ids << t_id
					else
						vec[id][t_id] &= ~INVITE_BITMAP
					end
					#ids.each { |g| vec = Teacher.vectors(g,degree-1,vec) }
					#ids = []
				end
			end
			if 	!teacher.omnihash.nil? && 
				!teacher.omnihash.empty? &&
				!teacher.omnihash['twitter'].nil? && 
				!teacher.omnihash['twitter'].empty? && 
				!teacher.omnihash['twitter']['fids'].nil? &&
				!teacher.omnihash['twitter']['fids'].empty?
				Teacher.any_in('omnihash.twitter.uid' => teacher.omnihash['twitter']['fids'].map { |e| e.to_s }).each do |f|
					next if f.id.to_s==id
					if !vec[id]
						vec[id] = { f.id.to_s => ~TWITTER_BITMAP }
						ids << f.id.to_s
					elsif !vec[id][f.id.to_s]
						vec[id][f.id.to_s] = ~TWITTER_BITMAP
						ids << f.id.to_s
					else
						vec[id][f.id.to_s] &= ~TWITTER_BITMAP
					end 
				end
				#ids.each { |g| vec = Teacher.vectors(g,degree-1,vec) }
				#ids = []
			end
			if 	!teacher.omnihash.nil? && 
				!teacher.omnihash.empty? && 
				!teacher.omnihash['facebook'].nil? && 
				!teacher.omnihash['facebook'].empty? && 
				!teacher.omnihash['facebook']['fids'].nil? &&
				!teacher.omnihash['facebook']['fids'].empty?
				Teacher.any_in('omnihash.facebook.uid' => teacher.omnihash['facebook']['fids'].map { |e| e.to_s }).each do |f|
					next if f.id.to_s==id
					if !vec[id]
						vec[id] = { f.id.to_s => ~FACEBOOK_BITMAP }
						ids << f.id.to_s
					elsif !vec[id][f.id.to_s]
						vec[id][f.id.to_s] = ~FACEBOOK_BITMAP
						ids << f.id.to_s
					else
						vec[id][f.id.to_s] &= ~FACEBOOK_BITMAP
					end
				end
				#ids.each { |g| vec = Teacher.vectors(g,degree-1,vec) }
				#ids = []
			end
			if !teacher.info.nil? && !teacher.info.grades.nil? && !teacher.info.grades.empty?
				Teacher.any_in(:'info.grades' => teacher.info.grades).any_in(:'info.subjects' => teacher.info.subjects).each do |f|
					next if f.id.to_s==id
					if !vec[id]
						vec[id] = { f.id.to_s => ~GRADE_BITMAP }
						ids << f.id.to_s
					elsif !vec[id][f.id.to_s]
						vec[id][f.id.to_s] = ~GRADE_BITMAP
						ids << f.id.to_s
					else
						vec[id][f.id.to_s] &= ~GRADE_BITMAP
					end
				end
				#ids.each { |g| vec = Teacher.vectors(g,degree-1,vec) }
				#ids = []
			end
			if !teacher.info.nil? && !teacher.info.subjects.nil? && !teacher.info.subjects.empty?
				Teacher.any_in(:'info.subjects' => teacher.info.subjects).each do |f|
					next if f.id.to_s==id
					if !vec[id]
						vec[id] = { f.id.to_s => ~SUBJECT_BITMAP }
						ids << f.id.to_s
					elsif !vec[id][f.id.to_s]
						vec[id][f.id.to_s] = ~SUBJECT_BITMAP
						ids << f.id.to_s
					else
						vec[id][f.id.to_s] |= ~SUBJECT_BITMAP
					end
				end
				#ids.each { |g| vec = Teacher.vectors(g,degree-1,vec) }
				#ids = []
			end
			if degree > 0
				teacher.relationships.where(:subscribed => true).entries.map { |r| Teacher.find(r["user_id"]) }.each do |f|
					next if f.id.to_s==id
					if !vec[id]
						vec[id] = { f.id.to_s => ~SUBSC_BITMAP }
						ids << f.id.to_s
					elsif !vec[id][f.id.to_s]
						vec[id][f.id.to_s] = ~SUBSC_BITMAP
						ids << f.id.to_s
					else
						vec[id][f.id.to_s] &= ~SUBSC_BITMAP
					end
				end
			end
			#ids.each { |g| vec = Teacher.vectors(g,degree-1,vec) }
			#ids = []
			# if !teacher.info.nil? && !teacher.info.location.nil? && teacher.info.location!={:lng=>0.0, :lat=>0.0}
			# 	Teacher.geo_near(teacher.info.location, :max_distance => 50, :unit => :mi, :spherical => true).each do |f|
			# 		next if f.id.to_s==id
			# 		if !vec[id]
			# 			vec[id] = { f.id.to_s => ~GEO_BITMAP }
			# 			ids << f.id.to_s
			# 		elsif !vec[id][f.id.to_s]
			# 			vec[id][f.id.to_s] = ~GEO_BITMAP
			# 			ids << f.id.to_s
			# 		else
			# 			vec[id][f.id.to_s] |= ~GEO_BITMAP
			# 		end
			# 	end
			# 	ids.each { |g| vec = Teacher.vectors(g,degree-1,vec) }
			# 	ids = []
			# end

			if degree>0
				ids.clone.each do |f|
					break if ids.size > 250
					temp = Teacher.vectors(f,degree-1,vec,ids)
					vec = temp[0]
					ids = (ids + temp[1]).flatten.uniq
				end
			end
		end

		[vec,ids]
		#vec

	end

	def self.add_path(src_id,dest_id,network,bitmap)

		neighbors.each do |f|
			if !network[self.id.to_s]
				network[self.id.to_s] = { "#{f.id.to_s}" => bitmap }
			else
				network[self.id.to_s][f.id.to_s] |= bitmap
			end
		end
		network
	end

	def twitter_friends (degree = 1)

		ret = {}
		if degree>0 && self.omnihash['twitter']
			Teacher.any_in('omnihash.twitter.uid' => self.omnihash['twitter']['fids'].map { |e| e.to_s }).each do |f|
				ret[f.id.to_s] = ret[f.id.to_s] ? ret[f.id.to_s]+1 : 1
				f.twitter_friends(degree-1).each do |g|
					ret[g[0].to_s] = (ret[g[0].to_s] ? g[1]+1 : 1)
				end
			end
		end
		ret

	end

	def facebook_friends (degree = 1)

		ret = {}
		if degree>0 && self.omnihash['facebook']
			Teacher.any_in('omnihash.facebook.uid' => self.omnihash['facebook']['fids'].map { |e| e.to_s }).each do |f|
				ret[f.id.to_s] = ret[f.id.to_s] ? ret[f.id.to_s]+1 : 1
				f.facebook_friends(degree-1).each do |g|
					ret[g[0].to_s] = (ret[g[0].to_s] ? g[1]+1 : 1)
				end
			end
		end
		ret

	end

	# returns ordered list of teacher IDs
	#def self.dijkstra (network_orig,tid)
	def self.dijkstra (network,tid)


		# debugger

		#network = network_orig.clone

		#if invert
		#network_orig.each do |f|
		# network.each do |f|
		# 	f[1].each do |g|
		# 		network[f[0].to_s][g[0].to_s] = (128-g[1]).to_i
		# 		#g[1] = (16-g[1]).to_i
		# 	end
		# end
		#end

		pathhash = {}

		#debugger

		(network.map { |f| f[1].map { |g| g[0].to_s } } + network.map{ |f| f[0].to_s }).flatten.uniq.each { |f| pathhash[f.to_s] = { :dist => INFINITY, :visited => false, :from => nil } if f.to_s!= tid }
		#network.map { |f| f[1].map { |g| g[0].to_s } }.flatten.uniq.each { |f| pathhash[f.to_s] = { :dist => INFINITY, :visited => false, :from => nil } if f.to_s!= tid }

		#debugger

		current_nodeid = tid
		last_nodeid = nil

		pathhash.size.times do

			if !network[current_nodeid].nil? || current_nodeid==tid

				pathhash_copy = pathhash.clone
				network[current_nodeid].each do |g|

					if g[0].to_s==tid
						next
					end

					#debugger if g[0].to_s=='502d3d5c2fc6100002000084'

					lastdist = lastdistance(pathhash_copy,last_nodeid)
					lastdist = 0 if lastdist == INFINITY

					newdist = g[1] +  lastdist#ance(pathhash_copy,last_nodeid)

					if (current_nodeid==tid || newdist < lastdistance(pathhash_copy,g[0].to_s))# && g[0].to_s!=tid 

						pathhash[g[0].to_s][:dist] = newdist
						pathhash[g[0].to_s][:from] = current_nodeid

					end
				end
			end

			min = minpath(pathhash,current_nodeid)[0].to_s

			pathhash[min][:visited] = true# if !pathhash[min][:from].nil?
			last_nodeid = current_nodeid
			current_nodeid = min
		end		

		pathhash

	end

	# returns the minimum distance for the given src_id
	# if no instance exists, return an infinite distance
	def self.lastdistance(network,src_id)

		return 0 if src_id.nil?

		#debugger if src_id=="502ca22b6cd2cb0002000011"

		min = nil
		network.each do |f|
			#min = f if ((min.nil?) || (f[1][:dist]<min[1][:dist] && !f[1][:visited])) && src_id.to_s==f[0].to_s
			min = f if (min.nil? || f[1][:dist]<min[1][:dist]) && src_id.to_s==f[0].to_s#f[1][:from].to_s
		end
		(min.nil? ? INFINITY : min[1][:dist])
	end

	# returns the minimum node
	def self.minpath (network,src_id)

		

		min = nil #network.first
		network.each do |f|
			#debugger
			min = f if (min.nil? || f[1][:dist]<min[1][:dist]) && !f[1][:visited] && src_id.to_s!=f[0].to_s #&& !f[1][:from].nil? # && (id.empty? || id.to_s==f[0].to_s)
		end
		#debugger
		min
	end

	def recommends (count = 5)

		#subs = self.subscriptions(2) - self.subscriptions(1)

		# pre-seed!

		# keys = Rails.cache.read("self.id.to_s}recs")

		# return if keys.nil?

		# Rails.cache.delete("self.id.to_s}recs")
		#debugger

		if Rails.cache.read("#{self.id.to_s}recs").nil?

			subs = (self.relationships.where(:subscribed => true).entries).map { |r| r["user_id"].to_s } 		

			#debugger

			vectors = Teacher.vectors(self.id.to_s,2)[0]

			recs = (Teacher.dijkstra(vectors,self.id.to_s).sort_by { |e| e[1][:dist] }.map { |f| f[0] })# - subs

			recs = Teacher.vectors(self.id.to_s,-1)[1] + recs

			# steven : 503bfe25fafac30002000011
			# jerry  : 502d3b822fc6100002000012
			# erin   : 502d3edd2fc61000020000bf
			# joan   : 5049718bf5d9ab00020000a7
			# spang  : 505ce7fae274d70002000019
			# NASA   : 502cab3378de86000200006d

			# (['503bfe25fafac30002000011','502d3b822fc6100002000012','502d3edd2fc61000020000bf','5049718bf5d9ab00020000a7','505ce7fae274d70002000019','502cab3378de86000200006d'] + recs).flatten.uniq-subs

			#debugger

			#TODO: migrate this into the algorithm
			# if !self.code.nil? && !self.code.empty? && self.code.to_s!="0"
			# 	t_id = nil
			# 	case self.code.to_s.length.to_i
			# 	when 24
			# 		t_id = self.code.to_s
			# 	when 32
			# 		invitation = Invitation.where(:code => self.code.to_s).first
			# 		t_id = Teacher.find(invitation.from.to_s).id.to_s if !invitation.nil? && !invitation.from.nil? && invitation.from.to_s!="0"
			# 	end
			# end

			#debugger

			#recs = (t_id.to_a + recs) if (!t_id.nil? && !t_id.empty?)

			recs = recs.flatten.uniq - subs

			if recs.size < 5
				if Rails.env.production?
					recs = (['503bfe25fafac30002000011',
							'502d3b822fc6100002000012',
							'502d3edd2fc61000020000bf',
							'5049718bf5d9ab00020000a7',
							'505ce7fae274d70002000019',
							'502cab3378de86000200006d'] + recs).flatten.uniq-subs
				end
			end

			Rails.cache.write("#{self.id.to_s}recs",recs[0..60])

			#debugger

			return recs[0..60]

		else

			return Rails.cache.read("#{self.id.to_s}recs")

		end

	end

	def self.find_for_authentication(conditions) 
		conditions[:login].downcase!
		super(conditions)
	end

	def self.from_omniauth(auth, teacher)
		# where(auth.slice(:provider, :uid)).first_or_create do |teacher|
		teacher.omnihash[auth.provider] = {} if teacher.omnihash[auth.provider].nil?
		teacher.omnihash[auth.provider]["uid"] = auth.uid
		if auth.provider == "twitter"
			teacher.omnihash[auth.provider]["username"] = auth.info.nickname
			teacher.omnihash[auth.provider]["profile"] = auth.info.urls.Twitter

			Twitter.oauth_token = auth.credentials.token
			Twitter.oauth_token_secret = auth.credentials.secret

			fids = Twitter.friend_ids(auth.info.nickname).all

			teacher.omnihash[auth.provider]["fids"] = fids

			auth.extra.delete("access_token")
			teacher.omnihash[auth.provider]["data"] = auth

		elsif auth.provider == "facebook"
			teacher.omnihash[auth.provider]["username"] = auth.info.nickname if !auth.info.nickname.empty?
			teacher.omnihash[auth.provider]["profile"] = auth.info.urls.Facebook
			teacher.omnihash[auth.provider]["data"] = auth

			fids = JSON.parse(RestClient.get("https://graph.facebook.com/#{teacher.omnihash["facebook"]["data"]["uid"]}/friends?access_token=#{teacher.omnihash["facebook"]["data"]["credentials"]["token"]}"))["data"].collect{|f| f["id"]}

			teacher.omnihash[auth.provider]["fids"] = fids

		end
		teacher
		# end
	end

	def avatar_from_omnihash

		if  !self.omnihash.nil? && 
			!self.info.avatarstatus['avatar_thumb_sm']['scheduled'] && 
			!self.info.avatarstatus['avatar_thumb_sm']['generated']

			url = ''

			if 	!self.omnihash['twitter'].nil? && 
				!self.omnihash['twitter']['data'].nil? &&
				!self.omnihash['twitter']['data']['extra'].nil? &&
				!self.omnihash['twitter']['data']['extra']['raw_info'].nil? && 
				!self.omnihash['twitter']['data']['extra']['raw_info']['profile_image_url'].nil? &&
				!self.omnihash['twitter']['data']['extra']['raw_info']['profile_image_url'].empty?

				url = self.omnihash['twitter']['data']['extra']['raw_info']['profile_image_url'].sub('_normal','')

			elsif !self.omnihash['facebook'].nil? &&
				!self.omnihash['facebook']['data'].nil? &&
				!self.omnihash['facebook']['data']['info'].nil? &&
				!self.omnihash['facebook']['data']['info']['image'].nil? &&
				!self.omnihash['facebook']['data']['info']['image'].empty?

				url = self.omnihash['facebook']['data']['info']['image'].sub('square','large')

			end

			if !url.empty?

				stathash = self.info.avatarstatus
				stathash['avatar_thumb_lg']['scheduled'] = true
				stathash['avatar_thumb_mg']['scheduled'] = true
				stathash['avatar_thumb_md']['scheduled'] = true
				stathash['avatar_thumb_sm']['scheduled'] = true

				self.info.update_attributes(:data => url.to_s,
											:size => 0,
											:remote_avatar_url => url.to_s,
											:avatarstatus => stathash)


				storedir = Digest::MD5.hexdigest(self.id.to_s + self.info.size.to_s + self.info.data.to_s)

				datahash = Digest::MD5.hexdigest(storedir + 'avatar' + url.to_s + [self.id.to_s].to_s + TX_PRIVATE_KEY)

				#debugger

				begin
					response = RestClient.post(MEDIASERVER_API_URL,{:storedir => storedir.to_s,
																	:class => 'avatar',
																	:url => url.to_s,
																	:model => [self.id.to_s],
																	:datahash => datahash.to_s,
																	:origin => ENV['SERVERCLASS']=='staging' })

					raise "Submission error" if response!="{\"status\":1}"
				rescue
					Teacher.delay(:queue => 'thumbgen').gen_thumbnails(self.id.to_s)				
				end
			end
		end
	end

	#DELAYED JOB
	def self.newsub_email(subscriber, subscribee)

		UserMailer.new_sub(subscriber, subscribee).deliver if Log.first_subsc?(subscriber, subscribee) && Teacher.find(subscribee).emailconfig["sub"]

	end

	def self.seedsizes

		Teacher.all.each do |teacher|

			teacher.binders.sort_by{|binder| binder.parents.length}.reverse.each do |binder|

				binder_total_size = 0
				binder_pub_size = 0
				binder_priv_size = 0

				binder.children.each do |b|

					if b.parents.first["id"] == "0"

						if b.type == 2

							b.total_size = b.current_version.file.size

							b.pub_size = b.total_size if b.is_pub?
							b.priv_size = b.total_size unless b.is_pub?

							b.save

						end

						binder_total_size += b.total_size
						binder_pub_size += b.pub_size
						binder_priv_size += b.priv_size

					end

				end

				binder.total_size = binder_total_size
				binder.pub_size = binder_pub_size
				binder.priv_size = binder_priv_size

				binder.save

			end

			teacher_total_size = 0
			teacher_pub_size = 0
			teacher_priv_size = 0

			teacher.binders.root_binders.each do |binder|

				teacher_total_size += binder.total_size
				teacher_pub_size += binder.pub_size
				teacher_priv_size += binder.priv_size

			end
			
			teacher.total_size = teacher_total_size
			teacher.pub_size = teacher_pub_size
			teacher.priv_size = teacher_priv_size

			teacher.save

		end

	end

	def incsizecap(size_in_mb = SIZE_PER_INVITE)

		self.size_cap += size_in_mb
		self.save

	end

	after_create do

		if self.code.length == 24

			inviter = Teacher.find(self.code)

		elsif self.code.length == 32

			invitation = Invitation.where(:code => self.code).first

			inviter = invitation.from == "0" ? nil : Teacher.find(invitation.from)

		end

		unless inviter.nil?

			inviter.incsizecap
			self.incsizecap

		end

	end

	private
	@@username_blacklist = nil

	# checks if the username is on a blacklist
	def username_blacklist
		unless @@username_blacklist
			@@username_blacklist = Set.new ["signup"] # Put in any additional words in this array
			Rails.application.routes.routes.each do |r|
				words = r.path.spec.to_s.gsub(/(\(\.:format\)|[:()])/, "").split('/')
				words.each {|reserved_word| @@username_blacklist << reserved_word if !reserved_word.empty?}
			end
		end

	  errors.add(:username, "is restricted") if @@username_blacklist.include?(username)
	end

end


class Tag
	include Mongoid::Document

	# presently, array undergoes batch replacements only
	# PS, PK, K
	# 1,2,3,4,5,6,7,8,9,10,11,12
	# Prep, BS/BA, masters, PhD, Post Doc
	#field :grade_levels, :type => Array, :default => [false, false, false, false, false,
	#						false, false, false, false, false,
	#						false, false, false, false, false,
	#						false, false, false, false, false]
	field :grade_levels, 	:type => Array, :default => [""]
	field :subjects, 		:type => Array, :default => [""]
	field :standards, 		:type => Array, :default => [""]
	field :other, 			:type => Array, :default => [""]

	embedded_in :teacher

end

class Relationship
	include Mongoid::Document

	#scope :find_by_id, find_or_initialize_by(:user_id => params[:id])
	#scope :find_by_id, lambda { |teacher_id| find_or_initialize_by(":user_id => ?", teacher_id) }
	#def self.find_by_id(teacher_id)
	#	find_or_initialize_by(:user_id => teacher_id)
	#end

	#def self.find_by_id(teacher_id)
	#def self.find_by_id(teacher_id)
	#	return self.find_or_initialize_by(user_id: teacher_id)
	#end

	#scope :named, ->(name){ where(name: name) }
	#scope :teacher_by_id, ->(teacher_id){ find_or_initialize_by(user_id: teacher_id) }

	#scope :find_unsubscribed, where(subscribed: false)

	field :user_id, :type => String, :unique => true
	field :subscribed, :type => Boolean, :default => false
	field :colleague_status, :type => Integer, :default => 0

	embedded_in :teacher

	# after_create do

	# 	debugger
	# 	Rails.cache.write("self.teacher.id.to_s}recs",true)

	# end

	after_save do

		#debugger
		Rails.cache.delete("#{self.teacher.id.to_s}recs")



	end

	# after_create do

	# 	keys = Rails.cache.read("self.teacher.id.to_s}recs")

	# 	return if keys.nil?

	# 	Rails.cache.delete("self.teacher.id.to_s}recs")

	# end

	# Class Methods

	def subscribe
		self.update_attributes(:subscribed => true)
		#self.save
	end

	def unsubscribe
		self.update_attributes(:subscribed => false)
		#self.save
	end

	def set_colleague_status(newstatus)
		self.update_attributes(:colleague_status => newstatus)
		#self.save
	end

end

class Info
	include Mongoid::Document
	#include Tire::Model::Search
	#include Tire::Model::Callbacks
	# include Mongoid::Spacial::Document
	#include ActiveModel::Validations
	#include CarrierWave::MiniMagick

	#require 'carrierwave/processing/mini_magick'

  #require 'mini_magick'
	#require

	# none of these fields required when updating

	#validates :profile_picture, 	:format => { :with => image_regex ,
	#				:message => "field does not appear to be an image" }#,
	#				#:presence => true

	#validates_with InfoValidator

	attr_accessible :avatarstatus, :thumbnails, :website, :grades, :subjects, :bio, :city, :state, :country, :location 

	field :avatarstatus, :type => Hash, :default => { 	"avatar_thumb_lg" => { "generated" => false, "scheduled" => false },
													 	"avatar_thumb_mg" => { "generated" => false, "scheduled" => false },
													 	"avatar_thumb_md" => { "generated" => false, "scheduled" => false },
														"avatar_thumb_sm" => { "generated" => false, "scheduled" => false } }

	mount_uploader :avatar, AvatarUploader
	mount_uploader :avatar_thumb_lg, AvatarthumbUploader
	mount_uploader :avatar_thumb_mg, AvatarthumbUploader
	mount_uploader :avatar_thumb_md, AvatarthumbUploader
	mount_uploader :avatar_thumb_sm, AvatarthumbUploader

	field :thumbnails, :type => Array, :default => [nil,nil,nil,nil]

	field :size, 				:type => Integer, :default => 0
	field :ext, 				:type => String, :default => ""
	field :data, 				:type => String, :default => "" #URL, path to file

	field :grades,				:type => Array, :default => []
	field :subjects,			:type => Array, :default => []
	field :bio, 				:type => String, :default => ""
	field :website,				:type => String, :default => ""
	field :city,				:type => String, :default => ""
	field :state,				:type => String, :default => ""
	field :country,				:type => String, :default => ""
	field :location,			:type => Array#,  spacial: {lat: :latitude, lng: :longitude, return_array: true }#  				spacial: true
	field :twitterhandle,		:type => String, :default => ""
	field :facebookurl,			:type => String, :default => ""

	validates_format_of :website, with: URI::regexp(%w(http https)), message: "The website entered is invalid", allow_blank: true

	embedded_in :teacher

	after_save do

		# triggers reindexing from parent document
		#self.teacher.save

		keys = Rails.cache.read(self.teacher.id.to_s)

		if !keys.nil?

			keys.each do |f|
				#Rails.cache.delete(f.to_s)
				#Rails.cache.expire_fragment(f.to_s)			
				Rails.cache.write(f.to_s,true)
			end

			Rails.cache.delete(self.teacher.id.to_s)

			Rails.cache.write("#{self.teacher.id.to_s}educobj",true)

		end

	end

	# after_save do
	# 	Rails.logger.debug "AFTER_SAVE_INFO"
	# 	tire.update_index
	# end

	# # Class Methods

	def fulllocation
		"#{city}, #{state}, #{country}"
	end

end
