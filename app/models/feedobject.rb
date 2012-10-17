class Feedobject
	include Mongoid::Document

	field :teachers, :type => Array, :default => []
	field :binders, :type => Array, :default => []

	# this is the permanent reference to the log instance
	field :logid, :type => String, :default => ''
	# type of view feedpiece (matches controller method name)
	field :class, :type => String, :default => ''

	field :html, :type => String, :default => ''

	# returns plaintext HTML
	def build
		raise 'Undefined feedobject class!' if self.class.empty?
		self.update_attributes(html => IndirectModelController.new.build(self.class))
	end

	def wipe
		self.update_attributes(:html => '')
	end

	# implement state machine for feedobjects
	def get_feedobject
		if !Rails.cache.read("#{self.id.to_s}/feedobject").nil?
			# cache was invalidated, 

		else

		end

	end

end