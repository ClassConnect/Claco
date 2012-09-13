class Setting
	include Mongoid::Document

	field :setting, :type => String
	field :value

	def self.f(s)
		Setting.where(:setting => s).first || Setting.new(:setting => s)
	end

	def v=(v)
		self.update_attribute(:value, v)
	end

	def v
		self.value
	end

end