class Feed
	include Mongoid::Document

	# integer timestamp used for acquiring a fresh logset from the ES server
	#field :timerange, :type => Hash, :default => {'lower' => nil,'upper' => nil} #, :type => Float, :default => 0.0
	# TODO: utilize fclass field to differentiate between existing feeds
	field :fclass, :type => Integer, :default => 0
	field :owner, :type => String, :default => ''
	field :mr_timestamp, :type => Float, :default => 0.0
	field :lr_timestamp, :type => Float, :default => 0.0
	field :mr_logid, :type => String, :default => ''
	field :lr_logid, :type => String, :default => ''
	field :actors, :type => Array, :default => []
	#field :cursor, :type => Float, :default => 0.0

	# TODO: make the feed a pseudo-linked list

	embeds_many :wrappers

	def total
		return self.wrappers.map{|f| f.objnum}.inject(:+)
	end

	def generate
		self.wrappers.each { |f| f.generate }
	end

	def disown(id)
		if self.wrappers.map{|f| f.whoid}.reject{|g| g!=id}.size < 2
			self.actors.delete(id)
			self.save
		end
	end

	# returns wrappers that occur after the provided logid
	def buffer(logid='')
		return self.wrappers if logid.to_s.empty?
		self.wrappers.where(:lr_timestamp.lt => Log.find(logid).timestamp)
	end

	# javascript will be making requests with the current user ID and a page index

	# for now, this remains class-invariant
	def html(teacherid,pagelogid='')#,last_refresh)

		# passed a logid of the last displayed item
		#   does not enact clearout measures
		#   

		#debugger

		# TODO: reset cursor to PROPER location instead of just to blank

		page = !pagelogid.to_s.empty?

		# if !page
		# 	self.cursor = ''
		# 	self.save
		# end

		@feed = []
		@subsfeed = []
		logs = []

		# i = 0

		retstr = ''
		lastlogid = ''
		retsize = 0

		most_recent_logid = self.mr_logid
		least_recent_logid = self.lr_logid
		most_recent_logtime = self.mr_timestamp
		least_recent_logtime = self.lr_timestamp

		feedblacklist = {}
		duplist = {}

		teacher = Teacher.find(teacherid) #self.id.to_s # teacherid.to_s

		#teacher = self # Teacher.find(teacherid)

		# pull logs of relevant content, sort them, iterate through them, break when 10 are found
		#logs = Log.where( :model => "binders", "data.src" => nil  ).in( method: FEED_METHOD_WHITELIST ).desc(:timestamp)
		#logs = Log.where( "data.src" => nil ).in( model: ['binders','teachers'] ).in( method: FEED_METHOD_WHITELIST ).desc(:timestamp)

		#debugger

		if !page || (self.buffer(pagelogid).size < MAIN_WRAP_LENGTH)

			# pull the current teacher's subscription IDs
			if [0].include? self.fclass
				subs = (teacher.relationships.where(:subscribed => true).entries).map { |r| r["user_id"].to_s } 
			else
				subs = []
			end

				# self.cursor = self.wrappers.to_a.sort_by{|f| f.mr_timestamp}.first.id.to_s

				# self.actors.uniq!

				# self.save

			logs = Tire.search 'logs' do |search|

				search.query do |query|
					query.all
				end

				# technically these should be cascaded to avoid cross-method name conflicts
				search.filter :terms, :model => ['binders','teachers']
				search.filter :terms, :method => FEED_METHOD_WHITELIST
				case self.fclass
				when 0
					search.filter :terms, :ownerid => subs + [teacherid]
				when 1
					search.filter :terms, :ownerid => [teacherid]
				end


				#debugger

				if page
					begin
						search.filter :range, :timestamp => { :lt => Log.find(pagelogid).timestamp.ceil }
					rescue
						if self.lr_timestamp!=0.0 #self.timerange['lower'].present?
							# TODO: throw out matching logids at head of list
							search.filter :range, :timestamp => { :lt => self.lr_timestamp.ceil } #self.timerange['lower'] }
						end
					end
				else
					if self.mr_timestamp!=0.0 #self.timerange['upper'].present?
						search.filter :range, :timestamp => { :gte => self.mr_timestamp.floor } #self.timerange['upper'].to_i }
					#else
						# this is to prevent multiple inclusion in the stacked feed object array
						#search.filter :range, :timestamp => { :gte => Time.now.to_i }
					end
				end


				#if self.timerange['lower'].present?
				#	search.filter :numeric_range, :lte => self.timerange['lower']
				#end

				# TODO: analyze later for retention in feed object
				search.size 100

				search.sort { by :timestamp, 'desc' }

			end

			#debugger

			logs = logs.results

		end

		#debugger

		if logs.any?

			if page && logs.map{|f| f[:id].to_s}.include?(self.lr_logid)
				toggle = true
			end

			logs.each do |f|

				if page && toggle
					toggle = false if f[:id].to_s == self.lr_logid
					next
				else
					break if f[:id].to_s == self.mr_logid
				end

				begin
					case f[:model].to_s
						when 'binders'
							model = Binder.find(f[:modelid].to_s)
						when 'teachers'
							model = Teacher.find(f[:modelid].to_s)
					end
				rescue
					Rails.logger.fatal "Invalid log model ID!"
					next
				end

				# the binder log entry:		should not be deleted
				# 							should not be private
				# 							should not be sourced from another log entry
				# 							should not have a blacklist entry
				# 							should not be a setpub -> private
				#
				# the teacher log entry: 	should not have a blacklist entry
				if 	(f[:model].to_s=='binders' && 
						model.parents[0]!={ "id" => "-1", "title" => "" } && 
						model.is_pub? && 
						(Binder.thumbready?(model) || model.type==1)&&
						!f[:data][:src] && 
						!(feedblacklist[f[:actionhash].to_s]) && 
						( f[:method] == "setpub" ? ( f[:params]["enabled"] == "true" ) : true )) || 
					(f[:model].to_s=='teachers' &&
						!(feedblacklist[f[:actionhash].to_s]))

					# calculate number of items contributed from this teacher
					c = (@subsfeed.flatten.reject { |h| h[:log][:ownerid].to_s!=f[:ownerid].to_s }).size

					# must be subscribed or owned
					# occupancy of up to 10 from any teacher
					if ((subs.include? f[:ownerid].to_s) || (f[:ownerid].to_s == teacherid)) && c<10

						# whether or not the item is included in the blacklist,
						# add the actionhash and annihilation IDs to the exclusion list
						feedblacklist[f[:actionhash].to_s] = true

						# enter all annihilation entries into blacklist hash
						f[:data][:annihilate].each { |a| feedblacklist[a.to_s] = true } if f[:data][:annihilate]

						# execute blacklist exclusion
						if !(FEED_DISPLAY_BLACKLIST.include? f[:method].to_s)# && 

							#retsize += 1

							if f[:timestamp] > most_recent_logtime
								most_recent_logtime = f[:timestamp]
								most_recent_logid = f[:id].to_s
							end

							if f[:timestamp] < least_recent_logtime || least_recent_logtime==0.0
								least_recent_logtime = f[:timestamp]
								least_recent_logid = f[:id].to_s
							end

							# create a key for an owner and an action
							# TODO: this will not scale when extra categories are added that don't gracefully recombine
							similar = Digest::MD5.hexdigest(f[:ownerid].to_s + f[:method].to_s).to_s

							# this can be cut down greatly
							f = { :model => model, :ownerid => f[:ownerid].to_s, :log => f, :similar => similar }	

							# if there are no members in the duplist, create a new action in each tracking hash
							if !(duplist[similar]) || ((duplist[similar]['timestamp'].to_i-f[:log][:timestamp].to_i) > FEED_COLLAPSE_TIME)	

								retsize += 1

								break if retsize==(MAIN_WRAP_LENGTH+1)

								# store the index at which the similar item resides, and the current time
								duplist[similar] = { 'index' => @subsfeed.size, 'blank_index' => 0, 'timestamp' => f[:log][:timestamp].to_i }

								# new array set for feed object type
								

								@subsfeed << [f]

							# there is a similar event, combine in feed array
							else	

								# expire_fragment(f[:log].id.to_s) if Rails.cache.read(f[:log].id.to_s) 

								# insert into array dependent on whether or not a thumbnail exists
								if (f[:log].model.to_s=='binders' && 
										(f[:model].thumbimgids[0].to_s.empty? || 
										!Binder.thumbready?(f[:model]))) || 
									(f[:log].model.to_s=='teachers' && 
										!Teacher.thumbready?(f[:model]))

									@subsfeed[duplist[similar]['index']] << f

								else

									@subsfeed[duplist[similar]['index']].insert(duplist[similar]['blank_index'],f)

									duplist[similar]['blank_index'] += 1

								end

								# update to the most recent time
								duplist[similar]['timestamp'] = f[:log][:timestamp].to_i

							end
						end
					end
				end
				# doing this calculation every iteration is inefficient
				#break if @subsfeed.flatten.size == SUBSC_FEED_LENGTH

				#if retsize == 21 #SUBSC_FEED_LENGTH
			end

			# keep aggregate count of most recent log ids

			#debugger

			if !most_recent_logid.empty?
				self.update_attributes(	:mr_logid => most_recent_logid,
										:lr_logid => least_recent_logid,
										:mr_timestamp => self.mr_timestamp==0.0 ? most_recent_logtime  : [self.mr_timestamp,most_recent_logtime].max,
										:lr_timestamp => self.lr_timestamp==0.0 ? least_recent_logtime : [self.lr_timestamp,least_recent_logtime].min,)
										# :timerange => {	'lower' => [least_recent_logtime,self.timerange['lower'].to_f].min,
										# 				'upper' => [most_recent_logtime,self.timerange['upper'].to_f].max })
			end

			# here, merge subsfeed with existing wrappers
			# if self.wrappers.any? && false
			# 	w = self.wrappers.to_a.sort_by { |f| -f.mr_timestamp }
			# 	@subsfeed.each do |f|
			# 		w.each do |g|
			# 			if f[:similar]==g[:similar] && (f.map{|h| h[:timestamp]}.min-g.mr_timestamp<FEED_COLLAPSE_TIME)
			# 				# move subsfeed data into wrapper, regenerate wrapper
			# 			end
			# 		end
			# 	end
			# end

			#TODO: cleanup on time delay

			#TODO: unsubscribing from teachers, removing binders should purge
		end

		#debugger

		@subsfeed.each do |f|

			self.actors << f.first[:ownerid]
			logarr = f.sort_by{|g| g[:log].timestamp}
			self.wrappers << Wrapper.new(	whoid: 			f.first[:ownerid],
											whatid: 		f.first[:log].modelid,
											mr_logid: 		logarr.first[:log].id.to_s,
											lr_logid: 		logarr.last[:log].id.to_s,
											mr_timestamp: 	logarr.first[:log].timestamp, #f.map{|g| g[:log].timestamp}.sort.first,
											lr_timestamp: 	logarr.last[:log].timestamp, #f.map{|g| g[:log].timestamp}.sort.last,
											logids: 		f.map{|g| g[:log].id.to_s},
											wclass: 		f.first[:log][:method],
											similar:  		f.first[:similar])
		end

		#debugger

		# TODO: update model attributes dependent on the annihilate wrappers
		#debugger
		if !page
			size = self.wrappers.size# do |size|
			if size > MAIN_WRAP_LENGTH
				w = self.wrappers.to_a.sort_by { |f| -f.mr_timestamp }
				((size-MAIN_WRAP_LENGTH)/2.0).ceil.times do
					w.pop.annihilate
				end
			end
				#self.wrappers.to_a.sort_by { |f| -f.mr_timestamp }.pop.annihilate
			#end
		end

		# self.cursor = self.wrappers.to_a.sort_by{|f| f.mr_timestamp}.first.id.to_s

		# self.actors.uniq!

		# self.save



		# imc = IndirectModelController.new()

		# # if page
		# 	self.buffer(pagelogid).to_a.sort_by { |f| -f.mr_timestamp }[0..(MAIN_WRAP_LENGTH-1)].each do |f|
		# 		retstr += f.html.sub('[[[TIMESTAMP]]]',imc.timewords(f.mr_timestamp)).html_safe
		# 	end



		# 		self.wrappers.where(:mr_timestamp.lt => self.wrappers.find(self.cursor).mr_timestamp).to_a.sort_by { |f| -f.mr_timestamp }[0..19].each do |f|
		# 			retstr += f.html.sub('[[[TIMESTAMP]]]',imc.timewords(f.mr_timestamp)).html_safe
		# 		end
		# 	self.cursor = self.wrappers.to_a.sort_by{|f| f.mr_timestamp}.first.id.to_s
		# else	
			# self.wrappers.to_a.sort_by { |f| -f.mr_timestamp }[0..19].each do |f|
			# 	retstr += f.html.sub('[[[TIMESTAMP]]]',imc.timewords(f.mr_timestamp)).html_safe
			# end
		# 	self.cursor = self.wrappers.to_a.sort_by{|f| f.mr_timestamp}.first.id.to_s
		# end

		self.actors.uniq!

		self.save
	#end


		imc = IndirectModelController.new()

		# if page
		self.buffer(pagelogid).to_a.sort_by { |f| -f.mr_timestamp }[0..(MAIN_WRAP_LENGTH-1)].each do |f|
			retstr += f.html.sub('[[[TIMESTAMP]]]',imc.timewords(f.mr_timestamp)).html_safe
			lastlogid = f.lr_logid
		end

		{'html' => retstr, 'logid' => lastlogid}
	end
end

class Wrapper
	include Mongoid::Document

	# model IDs for child invalidation
	field :teachers, 		:type => Array, 	:default => []
	field :binders, 		:type => Array, 	:default => []

	# used for self-referential identification
	# TODO: expand these fields
	field :whoid,			:type => String, 	:default => ''
	field :whatid,			:type => String, 	:default => ''
	field :whereid,			:type => String,	:default => ''

	# all feedobjects are references to the feedobject model
	field :mr_timestamp,	:type => Float,		:default => 0.0
	field :lr_timestamp,	:type => Float, 	:default => 0.0
	field :mr_logid, 		:type => String, 	:default => ''
	field :lr_logid, 		:type => String, 	:default => ''
	field :markup,	 		:type => String, 	:default => ""
	field :logids,			:type => Array, 	:default => []
	field :feedobjectids, 	:type => Array, 	:default => []
	field :wclass, 			:type => String, 	:default => ""
	field :similar,			:type => String, 	:default => ""

	embedded_in :feed

	before_destroy do
		self.feed.disown(self.whoid)
	end

	# only called when an element is removed being from
	def purge(id)
		self.feedobjectids.delete(id)
		Feedobject.find(id) do |f|
			if self.mr_logid==f.logid
				self.feedobjectids.map{|g| Log.find(Feedobject.find(g).logid)}.sort_by{|g| g.timestamp}.last do |g|
					self.mr_logid = g.id.to_s
					self.mr_timestamp = g.timestamp
					self.save
				end
			elsif self.lr_logid==f.logid
				self.feedobjectids.map{|g| Log.find(Feedobject.find(g).logid)}.sort_by{|g| g.timestamp}.first do |g|
					self.lr_logid = g.id.to_s
					self.lr_timestamp = g.timestamp
					self.save
				end
			end
			f.delete
		end
		if self.feedobjectids.empty?
			self.delete
		else
			self.generate
		end
	end

	def multiplicity?
		self.objnum > 1
	end

	def objnum
		self.feedobjectids.size
	end

	# called when retrieving or refreshing the feed
	def html

		# initially, don't cache any of this, generate on the fly
		html = Rails.cache.read("wrapper/#{self.id.to_s}")
		if html.nil?
			self.generate if self.markup.empty?
			html = self.markup
			self.feedobjectids.each { |f| html += Feedobject.find(f).html.html_safe }
			html = IndirectModelController.new.feedbox(Teacher.find(self.whoid),html).html_safe
			Rails.cache.write("wrapper/#{self.id.to_s}",html,:expires_in => 2.hours)
			#self.update_attributes(:markup => '')
		end
		html.html_safe	
	end

	# TODO: generate is already prepped to accept new logids and automatically generate them

	# this will be called on both new wrappers and already populated wrappers
	def generate

		if self.logids.any?
			# this is the first generate of the wrapper
			self.logids.each do |f|
				log = Log.find(f)
				feedobj = Feedobject.where(:logid => log.id.to_s).first
				case log.model
				when 'binders'
					self.binders << log.modelid
					if feedobj.nil?
						feedobj = Feedobject.new(	:superids => [{'feed' => self.feed.id.to_s,
						 										  'wrap' => self.id.to_s }],
													:binderid => log.modelid,
													:logid => log.id.to_s,
													:oclass => log.model)
					else
						feedobj.superids << {'feed' => self.feed.id.to_s,
						 					 'wrap' => self.id.to_s }
					end
					feedobj.save
				when 'teachers'
					self.teachers << log.modelid
					if feedobj.nil?
						feedobj = Feedobject.new(	:superids => [{'feed' => self.feed.id.to_s,
						 										  'wrap' => self.id.to_s }],
													:teacherid => log.modelid,
													:logid => log.id.to_s,
													:oclass => log.model)
					else
						feedobj.superids << {'feed' => self.feed.id.to_s,
						 					 'wrap' => self.id.to_s }
					end
					feedobj.save
				end
				self.feedobjectids << feedobj.id.to_s
			end
			self.save
			# exit unbuilt state
			self.update_attributes(:logids => [])
		end

		self.update_attributes(:markup => IndirectModelController.new.pseudorender(self).html_safe)
		Rails.cache.delete("wrapper/#{self.id.to_s}")

	end

	def annihilate

		# TODO: update FEED: actors, most recent timestamp, least recent timestamp

		# fix parent feed actors list, accounts for multiple inclusion corner case
		self.teachers.each do |f|
			if self.feed.wrappers.any_in(teachers: [f]).any?
				self.feed.actors.delete(f)
				self.feed.save
			end
		end

		# fix parent feed min/max timestamps, logids
		if (self.feedobjectids.to_a&(Feedobject.where(:logid => self.feed.mr_logid).map{|f| f.id.to_s})).any?
			#self.feed.wrappers.where(:id.ne => self.id).sort_by{|f| f.timestamp}.last.feedobjectids.map{|f| Feedobject.find(f)}
			self.feed.wrappers.where(:id.ne => self.id).sort_by{|f| f.mr_timestamp}.last do |f|
				self.feed.mr_logid = f.mr_logid
				self.feed.mr_timestamp = f.mr_timestamp
				self.feed.save
			end
		elsif (self.feedobjectids.to_a&(Feedobject.where(:logid => self.feed.lr_logid).map{|f| f.id.to_s})).any?
			self.feed.wrappers.where(:id.ne => self.id).sort_by{|f| f.mr_timestamp}.first do |f|
				self.feed.lr_logid = f.lr_logid
				self.feed.lr_timestamp = f.lr_timestamp
				self.feed.save
			end
		end

		self.feedobjectids.each do |f|
			Feedobject.find(f) do |g|
				if g.superids.size==1
					g.annihilate
				end
			end
		end
		Rails.cache.delete("wrapper/#{self.id.to_s}")
		self.delete
	end
end