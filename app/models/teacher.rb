class Teacher
  include Mongoid::Document
  ## Database authenticatable
  field :email,              :type => String, :null => false, :default => ""
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

  ## Token authenticatable
  # field :authentication_token, :type => String
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

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

embeds_one :info, validate: false

embeds_one :tag, validate: false

embeds_many :relationships, validate: false

  ## Token authenticatable
  # field :authentication_token, :type => String

def subscribed_to?(id)
  return self.relationships.find_or_initialize_by(:user_id => id).subscribed
end

def colleague_status(id)
  return self.relationships.find_or_initialize_by(:user_id => id).colleague_status
end

end

class Tag
  include Mongoid::Document

  field :grade_levels, :type => Array
  field :subjects, :type => Array
  field :standards, :type => Array
  field :other, :type => Array

  embedded_in :teacher
end

class Relationship
  include Mongoid::Document

  field :user_id, :type => String, :unique => true
  field :subscribed, :type => Boolean, :default => false
  field :colleague_status, :type => Integer, :default => 0

  embedded_in :teacher
end

class Info
  include Mongoid::Document

  field :bio, :type => String
  field :website, :type => String
  field :profile_picture, :type => String

  embedded_in :teacher
end