class Setting
	include Mongoid::Document

	field :setting, :type => String
	field :value

	def self.find(s)
		Setting.where(:setting => s).first
	end

end