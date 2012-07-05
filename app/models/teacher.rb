# custom validation classes
class InfoValidator < ActiveModel::Validator

	#image_regex = [a-z\d\-.]+\.(jpg|jpeg|png|gif)
	image_regex = /(.*?)\.(jpg|jpeg|png|gif)/

	def validate(record)
		if !record.profile_picture.blank?
			unless record.profile_picture =~ /(.*?)\.(jpg|jpeg|png|gif)/
				record.errors[:profile_picture] << "is an invalid file format"
			end
		end
	end
end

# model classes
class Teacher
	include Mongoid::Document

	# Include default devise modules. Others available are:
	# :token_authenticatable, :confirmable,
	# :lockable, :timeoutable and :omniauthable
	devise :database_authenticatable, :registerable,
	 :recoverable, :rememberable, :trackable, :validatable

	mount_uploader :avatar, AvatarUploader

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

	field :title, :type => String
	field :fname, :type => String
	field :lname, :type => String
	field :username, :type => String, :default => nil, :allow_nil => true, :unique => true

	embeds_one :info#, validate: false

	embeds_one :tag#, validate: false

	embeds_many :relationships#, validate: false

	## Token authenticatable
	# field :authentication_token, :type => String

	# Class Methods

	# Mr. John Smith
	def full_name
		return title + " " + fname + " " + lname
	end

	# Mr. Smith
	def formal_name
		return title + " " + lname
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
	field :subjects, 	:type => Array, :default => [""]
	field :standards, 	:type => Array, :default => [""]
	field :other, 		:type => Array, :default => [""]

	embedded_in :teacher

	# Class Methods

	# updates all data within the Tag class
	def update_tag_fields(params)

		# array to be eventually passed into the :grade_levels field
		#true_checkbox_array = Array.new(20, false)
		grade_levels_checkbox_array = Array.new
		subjects_checkbox_array = Array.new
		#zero_count = 0

		# update grade_levels array
		(1..(params[:tag][:grade_levels].length-1)).each do |i|
			#if params[:tag][:grade_levels][i] == "0"
			#	zero_count += 1
			#else
			#	true_checkbox_array[zero_count] = true
			#end
			grade_levels_checkbox_array << params[:tag][:grade_levels][i] if params[:tag][:grade_levels][i] != "0"
		end

		# update subjects array
		(1..(params[:tag][:subjects].length-1)).each do |i|
			subjects_checkbox_array << params[:tag][:subjects][i] if params[:tag][:subjects][i] != "0"
		end


		self.update_attributes(	:grade_levels => grade_levels_checkbox_array,
					#:subjects => params[:tag][:subjects].downcase.split.uniq,
					:subjects => subjects_checkbox_array,
					:standards => params[:tag][:standards].downcase.split.uniq,
					:other => params[:tag][:other].downcase.split.uniq)
		#self.save
	end

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

#	def by_teacher_id(params)
#		self.find_or_initialize_by(:user_id => params[:id])
#	end

#	def add_colleague(params)

#		teacher = Teacher.find(params[:id])

#		relationship = current_teacher.relationship_by_teacher_id(params[:id])

#		if relationship.colleague_status == 0 #Then the colleague_status for @teacher should also be 0

#			relationship.set_colleague_status(1)

#			#affected_relationship =

#			teacher.relationship_by_teacher_id(current_teacher.id).set_colleague_status(2)

#			#@affected_relationship

#		end

#		#if adding colleage due to incoming request, create colleague relationshikp
#		if relationship.colleague_status == 2

#			relationship.set_colleague_status(3)

#			#affected_relationship =

#			teacher.relationship_by_teacher_id(current_teacher.id).set_colleague_status(3)

#			#@affected_relationship.set_colleague_status(3)
#		end
#	end

#	def remove_colleague(params)



#	end

#	def subscribe_to_teacher(params)

#	end

#	def unsubscribe_from_colleague(params)

#	end

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
	include ActiveModel::Validations

	# none of these fields required when updating

	#validates :profile_picture, 	:format => { :with => image_regex ,
	#				:message => "field does not appear to be an image" }#,
	#				#:presence => true

	validates_with InfoValidator

	field :bio, :type => String, :default => ""
	field :website, :type => String, :default => ""
	field :profile_picture, :type => String, :default => ""

	embedded_in :teacher

	# Class Methods

	def update_info_fields(params)
		self.update_attributes(:bio => params[:info][:bio],
					:website => params[:info][:website],
					:profile_picture => params[:info][:profile_picture])
		#self.save
	end
end
