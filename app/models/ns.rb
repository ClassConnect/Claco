class Ns
	include Mongoid::Document

	field :code, :type => String
	field :active, :type => Boolean, :default => true

	def self.seed
		10000.times do
			ns = Ns.new
			ns.code = Digest::MD5.hexdigest(ns.id.to_s)
			ns.save
		end
	end
end