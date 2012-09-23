class Teacher
	include Mongoid::Document
	include Tire::Model::Search
	include Tire::Model::Callbacks

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

	field :omnihash, :type => Hash, :default => {}

	field :emailconfig, :type => Hash, :default => {"msg" => true,
													"col" => true,
													"sub" => true}

	field :allow_short_username, :type => Boolean, :default => false
	field :getting_started, :type => Boolean, :default => true

	field :admin, :type => Boolean, :default => false

	embeds_one :info#, autobuild: true #, validate: false

	embeds_one :tag#, autobuild: true #, validate: false

	has_one :feed

	embeds_many :relationships#, validate: false

	attr_accessible :username, :email, :password, :password_confirmation, :remember_me, :login, :fname, :lname, :title, :getting_started, :emailconfig, :pub_size, :priv_size, :total_size
	
	validate :username_blacklist

	validates_uniqueness_of :username, :case_sensitive => false
	validates_format_of :username, with: /[-a-z0-9]/i, :message => "has invalid characters."
	validates_length_of :username, minimum: 5, maximum: 16, :message => "must be at least 5 characters", :unless => Proc.new {|user| user.allow_short_username == true}
	validates_presence_of :fname, :message => "Please enter a first name."
	validates_presence_of :lname, :message => "Please enter a last name."
	
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



	settings analysis: {
		filter: {
			ngram_filter: {
				type: 		"nGram",
				min_gram: 	1,
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
			#indexes :_id,		:type => 'string',	:index => 'not_analyzed', :include_in_all => false
			indexes :fname, 	:type => 'string', 	:analyzer => 'ngram_analyzer', :boost => 200.0
			indexes :lname, 	:type => 'string', 	:analyzer => 'ngram_analyzer', :boost => 300.0
			indexes :username, 	:type => 'string', 	:analyzer => 'ngram_analyzer', :boost => 100.0
			indexes :info, :type => 'object', :properties => { 	:avatar 		=> { :type => 'object',	:enabled => false },
																:size 			=> { :type => 'object', :enabled => false },
																:ext 			=> { :type => 'object', :enabled => false },
																:data 			=> { :type => 'object', :enabled => false },
																:facebookurl	=> { :type => 'object', :enabled => false },
																:grades 		=> { :type => 'string', :analyzer => 'ngram_analyzer', :default => [] },
																:subjects 		=> { :type => 'string', :analyzer => 'ngram_analyzer', :default => [] },
																:bio 			=> { :type => 'string', :analyzer => 'snowball', :boost => 50.0 },
																:website 		=> { :type => 'string', :analyzer => 'ngram_analyzer' },
																:city			=> { :type => 'string', :analyzer => 'ngram_analyzer' },
																:state 			=> { :type => 'string', :analyzer => 'ngram_analyzer' },
																:country		=> { :type => 'string', :analyzer => 'ngram_analyzer' },
																:twitterhandle 	=> { :type => 'string', :analyzer => 'ngram_analyzer' },
																:location		=> { :type => 'geo_point', :default => [] } }#, :enabled => 'false'
		end
	end

	# Class Methods

	# used for elasticsearch
	def self
    	#to_indexed_json.as_json
    	to_indexed_json.to_json
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
		[{:type => 'subjects', 	:content => info.subjects},
		{:type => 'location', 	:content => "#{info.city+', ' if !info.city.nil? && !info.city.empty?}#{info.state+', ' if !info.state.nil? && !info.state.empty?}#{info.country if !info.country.nil? && !info.country.empty?}"},
		{:type => 'subjects', 	:content => info.subjects},
		{:type => 'grades', 	:content => info.grades},
		{:type => 'website', 	:content => info.website}].each do |f|

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

	def subs_of_subs

		sos = [] #{"id" => id, "count" => count}

		subs = relationships.where(:subscribed => true).entries.map {|r| Teacher.find(r["user_id"])}

		subs.each do |sub|

			e = sos.find{|s| s["id"] == sub.id.to_s}

			if e.nil?

				sos << {"id" => sub.id.to_s, "count" => 1}

			else

				e["count"] += 1

			end

		end

		return sos

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

			Teacher.where(:'omnihash.twitter.uid'.in => fids).each do |fteacher|

				teacher.relationship_by_teacher_id(fteacher.id).subscribe

				Teacher.delay(:queue => "email").newsub_email(teacher.id.to_s, fteacher.id.to_s)

			end

			auth.extra.delete("access_token")
			teacher.omnihash[auth.provider]["data"] = auth

		elsif auth.provider == "facebook"
			teacher.omnihash[auth.provider]["username"] = auth.info.nickname if !auth.info.nickname.empty?
			teacher.omnihash[auth.provider]["profile"] = auth.info.urls.Facebook
			teacher.omnihash[auth.provider]["data"] = auth

			fids = JSON.parse(RestClient.get("https://graph.facebook.com/#{teacher.omnihash["facebook"]["data"]["uid"]}/friends?access_token=#{teacher.omnihash["facebook"]["data"]["credentials"]["token"]}"))["data"].collect{|f| f["id"]}

			teacher.omnihash[auth.provider]["fids"] = fids

			Teacher.where(:'omnihash.facebook.uid'.in => fids).each do |fteacher|

				teacher.relationship_by_teacher_id(fteacher.id).subscribe

				Teacher.delay(:queue => "email").newsub_email(teacher.id.to_s, fteacher.id.to_s)

			end

		end
		teacher
		# end
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

	after_create do

		self.info = Info.new

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

class Feed
	include Mongoid::Document


	# elements that appear in this teacher's main feed
	field :main_feed, :type => Array, :default => []

	# elements that appear in this teacher's subscribed feed
	field :subsc_feed, :type => Array, :default => []

	# elements that appear in this teacher's profile feed
	field :personal_feed, :type => Array, :default => []


	belongs_to :teacher

	# passed an array of new log values, and the identifier for which feed to push it on
	def multipush(newvals,feedid = 0)

		# bail if a nonexistant feed field is specified
		raise "Invalid feed identifier!" and return if !([0,1,2].include? feedid)

		feedlength = (feedid==0 ? MAIN_FEED_STORAGE : feedid==1 ? SUBSC_FEED_STORAGE : PERSONAL_FEED_STORAGE)

		# retrieve old values
		case feedid
			when 0
				oldvals = self.main_feed.clone#.sort_by{ |f| f['timestamp'] }.reverse
			when 1
				oldvals = self.subsc_feed.clone#.sort_by{ |f| f['timestamp'] }.reverse
			when 2
				oldvals = self.personal_feed.clone#.sort_by{ |f| f['timestamp'] }.reverse
		end

		# assume that newvals are sorted in descending order by time
		feedarr = []

		feedarr = ((newvals.map{ |f| [f[0].peel,f[1]] }) + ((oldvals.map{ |f| [f,Binder.find(f['modelid'].to_s)] }).sort_by{ |f| f[0]['timestamp'] }.reverse)).reject{ |f| !(f[1].is_pub?) || !(f[1].parent!={'id'=>'0','title'=>''}) }.uniq.first(feedlength)#.reverse

		#feedarr.reverse!

		case feedid
			when 0
				self.update_attributes( :main_feed => feedarr.map{ |f| f[0] })
			when 1
				self.update_attributes( :subsc_feed => feedarr.map{ |f| f[0] })
			when 2
				self.update_attributes( :personal_feed => feedarr.map{ |f| f[0] })
		end			

		# return array to be used in the view
		return feedarr#.reverse

	end

	# returns the timestamp of the head of the queue (most recent time)
	def headtime(feedid = 0)

		case feedid
			when 0
				size = self.main_feed.size
			when 1
				size = self.subsc_feed.size
			when 2
				size = self.personal_feed.size
			else
				raise "Invalid feed identifier!" and return
		end

		if size < 1
			return -1
		else
			case feedid
				when 0
					#return self.main_feed[0].timestamp.to_i
					#return self.main_feed[0]['timestamp']
					#return self.main_feed.last['timestamp']
					return self.main_feed.first['timestamp']
				when 1
					#return self.subsc_feed[0].timestamp.to_i
					#return self.subsc_feed[0]['timestamp']
					#return self.subsc_feed.last['timestamp']
					return self.subsc_feed.first['timestamp']
				when 2
					#return self.personal_feed[0].timestamp.to_i
					#return self.personal_feed[0]['timestamp']
					#return self.personal_feed.last['timestamp']
					return self.personal_feed.first['timestamp']
			end
		end
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

	# Class Methods

	# updates all data within the Tag class
	# def update_tag_fields(params)

	# 	# array to be eventually passed into the :grade_levels field
	# 	#true_checkbox_array = Array.new(20, false)
	# 	grade_levels_checkbox_array = Array.new
	# 	subjects_checkbox_array = Array.new
	# 	#zero_count = 0

	# 	# update grade_levels array
	# 	(1..(params[:tag][:grade_levels].length-1)).each do |i|
	# 		#if params[:tag][:grade_levels][i] == "0"
	# 		#	zero_count += 1
	# 		#else
	# 		#	true_checkbox_array[zero_count] = true
	# 		#end
	# 		grade_levels_checkbox_array << params[:tag][:grade_levels][i] if params[:tag][:grade_levels][i] != "0"
	# 	end

	# 	# update subjects array
	# 	(1..(params[:tag][:subjects].length-1)).each do |i|
	# 		subjects_checkbox_array << params[:tag][:subjects][i] if params[:tag][:subjects][i] != "0"
	# 	end


	# 	self.update_attributes(	:grade_levels => grade_levels_checkbox_array,
	# 							#:subjects => params[:tag][:subjects].downcase.split.uniq,
	# 							:subjects => subjects_checkbox_array,
	# 							:standards => params[:tag][:standards].downcase.split.uniq,
	# 							:other => params[:tag][:other].downcase.split.uniq)
	# 	#self.save
	# end

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
	# include Tire::Model::Search
	# include Tire::Model::Callbacks
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

	mount_uploader :avatar, AvatarUploader

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
	field :location,			:type => Array
	field :twitterhandle,		:type => String, :default => ""
	field :facebookurl,			:type => String, :default => ""

	embedded_in :teacher

	# after_save do
	# 	Rails.logger.debug "AFTER_SAVE_INFO"
	# 	tire.update_index
	# end

	# mapping do
	# 	indexes :bio
	# end

	# # Class Methods

	# def self
 #    	to_indexed_json.as_json
	# end
	
	# def self
 #    	#to_indexed_json.as_json
 #    	to_indexed_json.to_json
	# end
	
	# def to_indexed_json
 #    	self.as_json
	# end

	def fulllocation
		"#{city}, #{state}, #{country}"
	end

end
