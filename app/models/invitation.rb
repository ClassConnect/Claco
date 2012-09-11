class Invitation
	include Mongoid::Document

	field :to, :type => String #Email
	field :from, :type => String #Id
	field :code, :type => String
	field :submitted, :type => Integer
	field :sent_at, :type => Integer
	field :status, :type => Hash, :default => {	"sent"		=> false,
												"clicked"	=> false,
												"signed_up"	=> false}


	#should only be called in a delayed method
	def getcode

		n = Ns.new

		n.code = Digest::MD5.hexdigest(n.id.to_s)

		if Ns.where(:code => n.code).count == 0

			if n.save
				self.code = n.code
			else
				self.getcode
			end

		else

			self.getcode

		end

	end

	#Delayed methods
	def self.blast(id)

		invitation = Invitation.find(id)

		invitation.getcode if invitation.code.nil?

		UserMailer.new_invite(invitation).deliver

	end

	def self.update_status(id, status, value)

		invitation = Invitation.find(id)

		invitation.status[status] = true

		invitation.save

	end

end