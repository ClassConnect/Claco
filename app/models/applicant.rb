class Applicant
	include Mongoid::Document

	field :fname, :type => String
	field :lname, :type => String
	field :email, :type => String, :unique => true
	field :body, :type => String
	field :timestamp, :type => Integer
	field :status, :type => Integer, :default => 0

	mount_uploader :file, ApplicantUploader

	validates_presence_of :fname, :lname, :body

end