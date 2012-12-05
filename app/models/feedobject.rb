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

	# used to invalidate the cached parent wrapper
	field :superids, :type => Array, :default => []

	# storage of HTML
	field :markup, :type => String, :default => ''


	# implement state machine for feedobjects, returns html
	# this call should be as minimal as possible in size
	def html
		html = Rails.cache.read("feedobject/#{self.id.to_s}")
		if html.nil?
			self.generate if self.markup.empty?
			Rails.cache.write("feedobject/#{self.id.to_s}",self.markup,:expires_in => 2.hours)
			html = self.markup
			# this write only saves DB space, technically unnecessary
			# self.update_attributes(:markup => '')
		end
		html
	end

	# called synchronously on initialization & callbacks
	def generate(after_save=nil)
		# cannot assume state of feed object exists or is public

		if after_save.present? 
			if after_save == Binder && !self.binderid.empty?
				model = Binder.find(self.binderid)
				if model.parents[0]["id"]=="-1" || !model.is_pub?
					self.superids.each do |f|
						Feed.find(f['feed']).wrappers.find(f['wrap']).purge(self.id.to_s)
					end
				end
			# elsif after_save == Teacher && !self.teacherid.empty?
			# 	model = Teacher.find(self.teacherid)
			# 	if model.
			end
		end

		raise 'Undefined feedobject class!' if self.oclass.empty?
		self.update_attributes(:markup => IndirectModelController.new.pseudorender(self))
		Rails.cache.delete("feedobject/#{self.id.to_s}")
		# deleting the cache instance of the wrapper will force inclusion on next render
		self.superids.each do |f|
			Rails.cache.delete("wrapper/#{f['wrap']}")
		end
	end

	def annihilate
		Rails.cache.delete("feedobject/#{self.id.to_s}")
		self.delete
	end
end