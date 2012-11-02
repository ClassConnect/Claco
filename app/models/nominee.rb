class Nominee
	include Mongoid::Document
	
	field :from, :type => String
	field :email, :type => String
	field :timestamp, :type => Integer
	field :status, :type => Integer, :default => 0

	# Status field
	# 0 = Not yet touched
	# 1 = Accepted, Invite sent. (View Invitation)
	# -1 = Rejected

	validates_presence_of :email, :message => "Please enter an email."
	validates_uniqueness_of :email, :message => "We already have an applicant under the submitted email."

	after_create do

		self.update_attributes(timestamp: Time.now.to_i)

	end

	def approve

		self.set(:status, 1)
		Invitation.new(	:from		=> "0",
						:to			=> self.email,
						:submitted	=> Time.now.to_i).save

	end

	def deny

		self.set(:status, -1)

	end

end