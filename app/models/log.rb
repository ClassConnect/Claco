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

	# returns hash of object's fields
	def peel

		return {:id => self.id.to_s,
				:ownerid => self.ownerid, 
				:timestamp => self.timestamp, 
				:method => self.method, 
				:controller => self.controller,
				:modelid => self.modelid,
				:params => self.params,
				:data => self.data,
				'id' => self.id.to_s,
				'ownerid' => self.ownerid, 
				'timestamp' => self.timestamp, 
				'method' => self.method, 
				'controller' => self.controller,
				'modelid' => self.modelid,
				'params' => self.params,
				'data' => self.data }

	end

	def self.by_id_cache_key(id)
		"log_by_id=#{id}"
	end

	def self.find(*args)
		if args.length == 1 && (args[0].is_a?(String) || args[0].is_a?(BSON::ObjectId))
			Rails.cache.fetch(Log.by_id_cache_key(args[0].to_s)) { super(*args) }
		else
			super(*args)
		end
	end

	def self.memwhere(*args)
		arr = self.only(:_id).where(*args).map(&:_id) # <= Array of id's from criteria
		retarr = []
		arr.each{|id| retarr << self.find(id)}
		retarr
	end

end