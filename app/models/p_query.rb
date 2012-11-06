class PQuery
	include Mongoid::Document

	# NOTE:
	#
	# the entire structure of this model assumes that a chain of group calculations leading
	# to a single criteria will be able to assume all complex queries

	field :name, :type => String, :default => ''
	field :description, :type => String, :default => ''
	field :type, :type => String, :default => "query" # can also be for a group
	field :query, :type => Hash, :default => {}
	field :kollection
	field :public, :type => Boolean, :default => true
	field :groupid, :type => String
	# field for storing the group function data
	#   :group => {:key, :cond, :initial, :reduce}
	#   :fields => []
	#   :range => {:start, :end}   (inclusive)

	field :grouphash, :type => Hash

	# this creates a new criteria generator
	def self.gen_from_criteria(criteria,groupid=nil,name='',desc='')
		raise 'Invalid criteria class' if criteria.class != Mongoid::Criteria

		if (old_pq = PQuery.where(:query => criteria.as_conditions).first).present?
			return old_pq.id.to_s
		end
		pq = PQuery.new(:name => name, 
						:description => desc, 
						:query => criteria.as_conditions, 
						:kollection => criteria.klass.to_s,
						:groupid => groupid)
		pq.save
		pq.id.to_s
	end

	# regrettably, the complexity of this model delegates most of the intricacy to the controller
	# TODO: match group criteria with existing groups
	def self.gen_from_groupdata(model,groupvals,fields,range,groupid=nil,name='',desc='')

		pq = PQuery.new(:name => name,
						:description => desc,
						:type => "group",
						:kollection => model.to_s,
						:groupid => groupid,
						:grouphash => { 'groupvals' => groupvals,
										'fields' => fields,
										'range' => range.to_s.split('..') })
		pq.save
		pq.id.to_s
	end

	def generate
		#case type
		#when "query"
			
		#when "group"

		#end
		if type=='group' # type.present?
			self.to_criteria.any_in(id: PQuery.find(groupid).to_list)
		elsif type=='query'
			self.to_criteria
		end

		#self.to_criteria
	end

	#private
	#protected

	def to_criteria
		raise 'Invalid PQuery type' if type != "query"
		Mongoid::Criteria.new(kollection.to_s.titleize.constantize).fuse(query)
	end

	# returns an array of IDs that exist within the range
	def to_list
		# Binder.collection.group(key: :owner, cond: {}, initial: {count: 0}, reduce: "function(doc,prev) {prev.count += +1;}")
		# <query>.selector inserted into conditions field
		range = Range.new(grouphash['range'].first.to_i,grouphash['range'].last.to_i)
		raw = kollection.titleize.constantize.collection.group(	:key => grouphash['groupvals']['key'],
																:cond => grouphash['groupvals']['cond'],
																:initial => grouphash['groupvals']['initial'],
																:reduce => grouphash['groupvals']['reduce'])
		raw = raw.map{ |f| { f['owner'] => f['count'].to_i } }
		raw = raw.reject{ |f| range.cover?(f.first[1]) }
		raw.map{ |f| f.first[0] }
	end
end
