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

	# returns plaintext HTML
	def build
		raise 'Undefined feedobject class!' if self.oclass.empty?
		self.update_attributes(:markup => IndirectModelController.new.pseudorender(self))
		Rails.cache.delete("#{self.id.to_s}/feedobject")
	end

	def wipe
		self.update_attributes(:markup => '')
	end

	# implement state machine for feedobjects, returns html
	def html
		html = Rails.cache.read("#{self.id.to_s}/feedobject")
		if html.nil?
			self.build
			Rails.cache.write("#{self.id.to_s}/feedobject",self.markup)
			html = self.markup
			self.wipe
		end
		html
	end
end