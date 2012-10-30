class PQuery
	include Mongoid::Document

	field :name, :type => String, :default => ''
	field :description, :type => String, :default => ''
	field :query, :type => Hash, :default => {}
	field :kollection

	def self.gen_from_criteria(criteria,name='',desc='')
		raise 'Invalid criteria class' if criteria.class != Mongoid::Criteria
		pq = PQuery.new(:name => name, :description => desc, :query => criteria.as_conditions, :kollection => criteria.klass.to_s)
		pq.save
		pq.id.to_s
	end

	def to_criteria
		Mongoid::Criteria.new(kollection.to_s.titleize.constantize).fuse(query)
	end
end
