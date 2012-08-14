class Applicant
	include Mongoid::Document

	field :title, :type => String
	field :fname, :type => String
	field :lname, :type => String
	field :email, :type => String
	field :body, :type => String
	field :timestamp, :type => Integer
	field :status, :type => Integer, :default => 0

	mount_uploader :file, ApplicantUploader

	validates_presence_of :fname, :message => "Please enter a first name."
	validates_presence_of :lname, :message => "Please enter a last name."
	validates_uniqueness_of :email, :message => "Please enter an email."
	validates_presence_of :body, :message => "Please enter a few words about yourself."
	validates_uniqueness_of :email, :message => "We already have an applicant under the submitted email."

end