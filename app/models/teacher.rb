class Teacher
	include Mongoid::Document

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
	field :username, :type => String, :unique => true
	field :lower_username, :type => String, :unique => true

	field :omnihash, :type => Hash

	field :allow_short_username, :type => Boolean, :default => false

	embeds_one :info#, autobuild: true #, validate: false

	embeds_one :tag#, autobuild: true #, validate: false

	embeds_many :relationships#, validate: false

	attr_accessible :username, :email, :password, :password_confirmation, :remember_me, :login, :fname, :lname, :title
	
	validate :username_blacklist

	validates_format_of :username, without: /\s/, :message => "can't have spaces."
	validates_length_of :username, minimum: 5, maximum: 16, :message => "must be at least 5 characters", :unless => Proc.new {|user| user.allow_short_username == true}
	validates_presence_of :fname, :message => "Please enter a first name."
	validates_presence_of :lname, :message => "Please enter a last name."
	
	attr_accessor :login

	## Token authenticatable
	# field :authentication_token, :type => String

	# Class Methods


	# regenerate all thumbnails for a teacher's content
	# incomplete method
	# def self.regen_thumbnails(id)

	# 	Binder.where( :owner => id.to_s ).each do |f|

	# 		f.regen_thumbnails

	# 	end

	# end

	# Mr. John Smith
	def full_name
		return "#{title} #{fname} #{lname}"
	end

	# Mr. Smith
	def formal_name
		return "#{title} #{lname}"
	end

	# Relationship Class Method Wrappers

	# this is not formal MVC style, but I wasn't able to successfully move this
	# function down to the Relationship class
	def relationship_by_teacher_id(teacher_id)
		#self.relationships.by_teacher_id(params)
		self.relationships.find_or_initialize_by(:user_id => teacher_id)
	end

	def get_incoming_colleague_requests
		self.relationships.where(:colleague_status => 2)
		#self.relationships.find_by(colleague_status: 2)
	end

	def subscribed_to?(id)
		return self.relationships.find_or_initialize_by(:user_id => id).subscribed
	end

	def colleague_status(id)
		return self.relationships.find_or_initialize_by(:user_id => id).colleague_status
	end

	def self.get_subscribers
		Relationship.where(:subscribed => true)
	end

	def self.find_first_by_auth_conditions(warden_conditions)
		conditions = warden_conditions.dup
		if login = conditions.delete(:login)
			self.any_of({ :username =>  /^#{Regexp.escape(login)}$/i }, { :email =>  /^#{Regexp.escape(login)}$/i }).first
		else
			super
		end
	end

	def to_param
		username
	end

	before_save do 
		self.lower_username = self.username.downcase
	end

	def self.find_for_authentication(conditions) 
		conditions[:login].downcase!
		super(conditions)
	end 

	def self.from_omniauth(auth, teacher)
		# where(auth.slice(:provider, :uid)).first_or_create do |teacher|
			teacher.omnihash["provider"] = auth.provider
			teacher.omnihash["uid"] = auth.uid
			teacher.omnihash["username"] = auth.info.nickname
		# end
	end

	def self.new_with_session(params, session)
		if session["devise.user_attributes"]
			new(session["devise.user_attributes"], without_protection: true) do |user|
				user.attributes = params
				user.valid?
			end
		else
			super
		end
	end

	private
	@@username_blacklist = nil

	# checks if the username is on a blacklist
	def username_blacklist
		unless @@username_blacklist
			@@username_blacklist = Set.new [] # Put in any additional words in this array
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
	#field :avatar_width,		:type => Integer, :default => 0
	#field :avatar_height,		:type => Integer, :default => 0

	field :bio, 				:type => String, :default => ""
	field :website,				:type => String, :default => ""
	field :city,				:type => String, :default => ""
	field :state,				:type => String, :default => ""
	field :country,				:type => String, :default => ""
	field :twitterhandle,		:type => String, :default => ""
	field :facebookurl,			:type => String, :default => ""
	#field :profile_picture, 	:type => String, :default => ""

	#field :debug_data,			:type => Array, :default => []

	embedded_in :teacher

	# Class Methods

	def fulllocation
		"#{city}, #{state}, #{country}"
	end

	# def update_info_fields(params)

	# 	#self.debug_data = []
	# 	#.save

	# 	#avatar = MiniMagick::Image.open(params[:info][:avatar].path)

	# 	if params[:info][:avatar].nil?

	# 		Rails.logger.debug "No avatar chosen! <#{params[:info][:avatar].to_s}>"

	# 		self.update_attributes( :bio => params[:info][:bio],
	# 								:website => params[:info][:website] )
	# 	else

	# 	Rails.logger.debug "Got to UPDATE INFO FIELDS!!!!!"

	# 		self.update_attributes(	:bio 				=> params[:info][:bio],
	# 								:avatar 			=> params[:info][:avatar],
	# 								:size 				=> params[:info][:avatar].size,
	# 								:ext 				=> File.extname(params[:info][:avatar].original_filename),
	# 								:data 				=> params[:info][:avatar].path,
	# 								#:avatar_width		=> avatar[:width],
	# 								#:avatar_height		=> avatar[:height],
	# 								:website 			=> params[:info][:website])
	# 	end

	# end
end
