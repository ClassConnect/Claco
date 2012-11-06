class Feedobject
	include Mongoid::Document

	# model checks against these fields when looking for invalidation candidates
	#field :teachers, :type => Array, :default => []
	#field :binders, :type => Array, :default => []
	field :teacherid, :type => String, :default => ''
	field :binderid, :type => String, :default => ''

	# this is the permanent reference to the log instance
	field :logid, :type => String, :default => ''
	# type of view feedpiece (matches controller method name)
	field :oclass, :type => String, :default => ''

	# storage of HTML
	field :markup, :type => String, :default => ''

	# after_initialize do
	# 	self.generate
	# end

	# called asynchronously on initialization & callbacks
	def generate
		raise 'Undefined feedobject class!' if self.oclass.empty?
		self.update_attributes(:markup => IndirectModelController.new.pseudorender(self))
		Rails.cache.delete("feedobject/#{self.id.to_s}")
	end

	def softwipe
		self.update_attributes(:markup => '')
	end

	# implement state machine for feedobjects, returns html
	def html
		html = Rails.cache.read("feedobject/#{self.id.to_s}")
		if html.nil?
			self.generate
			Rails.cache.write("feedobject/#{self.id.to_s}",self.markup)
			html = self.markup
			self.softwipe
		end
		html
	end
end