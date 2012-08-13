class Log
	include Mongoid::Document

	field :ownerid
	field :timestamp, :type => Integer
	# method and model are potentially redundant or unneeded fields
	# model is a lowercase string of the model name
	field :method
	field :model
	field :modelid
	field :params, :type => Hash
	# non-standard optional data hash
	field :data, :type => Hash, :default => {}

end
