class Ns
	include Mongoid::Document

	field :code, :type => String
	field :active, :type => Boolean, :default => true
	field :given, :type => Boolean, :default => false
	field :timestamp, :type => Integer

	def self.seed
		10000.times do
			ns = Ns.new
			ns.code = Digest::MD5.hexdigest(ns.id.to_s)
			ns.save
		end
	end

	def use
		self.active = false
		self.timestamp = Time.now.to_i
		self.save
	end
end