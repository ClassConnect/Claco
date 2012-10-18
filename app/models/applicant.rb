class Applicant
	include Mongoid::Document
	include Tire::Model::Search
	include Tire::Model::Callbacks

	field :title, :type => String
	field :fname, :type => String
	field :lname, :type => String
	field :email, :type => String
	field :body, :type => String
	field :timestamp, :type => Integer
	field :status, :type => Integer, :default => 0

	# Status field
	# 0 = Not yet touched
	# 1 = Accepted, Invite sent. (View Invitation)
	# -1 = Rejected

	validates_presence_of :fname, :message => "Please enter a first name."
	validates_presence_of :lname, :message => "Please enter a last name."
	validates_presence_of :email, :message => "Please enter an email."
	validates_presence_of :body, :message => "Please enter a few words about yourself."
	validates_uniqueness_of :email, :message => "We already have an applicant under the submitted email."

	def approve

		self.set(:status, 1)
		Invitation.new(	:from		=> "0",
						:to			=> self.email,
						:submitted	=> Time.now.to_i).save

	end

	def deny

		self.set(:status, -1)

	end

	def self.seedstatus

		Applicant.all.each do |app|

			inv = Invitation.where(:to => app.email).first

			usr = Teacher.where(:email => app.email).first

			unless inv.nil? || usr.nil?

				app.set(:status, 1)

			end

		end

	end

end