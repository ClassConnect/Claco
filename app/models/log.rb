class Log
	include Mongoid::Document

	field :ownerid
	field :timestamp, :type => Integer
	# method and model are potentially redundant or unneeded fields
	# model is a lowercase string of the model name
	field :method
	field :controller
	field :modelid
	field :params, :type => Hash

	# non-standard optional data hash
	# :copy - this is a copy, and was copied from the binder ID specified by :copy
	# :src - this log is part of a logset, src is the ID of the 'parent' log
	field :data, :type => Hash, :default => {}

end
