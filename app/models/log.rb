class Log
	include Mongoid::Document
	include Mongoid::Paranoia
	include Tire::Model::Search
	include Tire::Model::Callbacks

	field :ownerid
	field :timestamp, :type => Float
	# method and model are potentially redundant or unneeded fields
	# model is a lowercase string of the model name
	field :method
	field :modelid
	field :params, :type => Hash

	# non-standard optional data hash
	# :copy - this is a copy, and was copied from the binder ID specified by :copy
	# :src - this log is part of a logset, src is the ID of the 'parent' log
	field :data, :type => Hash, :default => {}

	#
	field :actionhash, :type => String#, :default => ""
	#field :feedhash, :type => String

	# mapping do
	# 	indexes :ownerid, 	:type => 'string'
	# 	indexes :timestamp, :type => 'float'
	# 	indexes :method,	:type => 'string'
	# 	indexes :modelid,	:type => 'string'
	# 	indexes :params,	:type => 'hash'
	# end

	# used for elasticsearch
	def self
    	#to_indexed_json.as_json
    	to_indexed_json.to_json
	end

	# determine whether an unsubscription has occured before to this teacher
	def self.first_subsc?(subscriber_id,subscribee_id)

		logs = Tire.search 'logs' do |search|

			search.query do |query|
				query.all
			end

			search.filter :terms, :model => ['teachers']
			search.filter :terms, :modelid => [subscribee_id.to_s]
			search.filter :terms, :method => ['unsub']
			search.filter :terms, :ownerid => [subscriber_id.to_s]
		end

		logs.results.size==0

	end

	# queries the db; cannot be certain of concurrent indexing in ES
	def self.last_action_time(teacherid)

		action = Log.where(:ownerid => teacherid.to_s).desc(:timestamp).limit(1).first

		return action.nil? ? -1 : action.timestamp.to_i

	end

	def hashgen

		md5 = Digest::MD5.hexdigest(ownerid.to_s+method.to_s+modelid.to_s)

		update_attributes(:actionhash => md5)

		return md5.to_s

	end

	# def self.by_id_cache_key(id)
	# 	"log_by_id=#{id}"
	# end

	# def self.find(*args)
	# 	if args.length == 1 && (args[0].is_a?(String) || args[0].is_a?(BSON::ObjectId))
	# 		Rails.cache.fetch(Log.by_id_cache_key(args[0].to_s)) { super(*args) }
	# 	else
	# 		super(*args)
	# 	end
	# end

	# def self.memwhere(*args)
	# 	arr = self.only(:_id).where(*args).map(&:_id) # <= Array of id's from criteria
	# 	retarr = []
	# 	arr.each{|id| retarr << self.find(id)}
	# 	retarr
	# end

end
