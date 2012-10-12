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

	validates_format_of :to, :with => /\A[^@]+@([^@\.]+\.)+[^@\.]+\z/
	validates_uniqueness_of :to, :case_sensitive => false

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

	after_create do

		Invitation.delay(:queue => "email").blast(self.id)
		# Invitation.blast(self.id)
		Invitation.delay(:queue => "email", :run_at => 3.days.from_now).schedule_nag(self.id)

	end

	def self.schedule_nag(id)

		invitation = Invitation.find(id)

		UserMailer.send_nag(invitation).deliver unless invitation.status["signed_up"]

	end

	#Delayed methods
	def self.blast(id)

		invitation = Invitation.find(id)

		invitation.getcode if invitation.code.nil?

		x = Setting.f("sys_inv_list").v

		y = x.find{|e| e["email"] == invitation.to}

		unless y.nil?
			y["invited"] = true
			y["invited_at"] = Time.now.to_i

			Setting.f("sys_inv_list").v = x
		end

		applicant = Applicant.where(:email => invitation.to).first

		applicant.set(:status, 1) unless applicant.nil?

		UserMailer.new_invite(invitation).deliver

	end

	def self.sysblast(num)

		x = Setting.f("sys_inv_list").v

		y = x.reject{|e| e["invited"] == true}[0..(num - 1)]

		y.each do |e|

			z = Invitation.new(	:from => "0",
								:to => e["email"],
								:submitted => Time.now.to_i)

			unless z.save
				p z.errors
			end

		end

	end

	#Not used
	def self.update_status(id, status, value)

		invitation = Invitation.find(id)

		invitation.status[status] = value

		invitation.save

	end

end