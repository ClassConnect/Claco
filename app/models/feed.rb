class Feed
	include Mongoid::Document

	# integer timestamp used for acquiring a fresh logset from the ES server
	field :timerange, :type => Hash, :default => {'lower' => nil,'upper' => nil} #, :type => Float, :default => 0.0
	field :fclass, :type => Integer, :default => 0
	field :owner, :type => String, :default => ''
	field :mr_logid, :type => String, :default => ''
	field :actors, :type => Array, :default => []

	embeds_many :wrappers

	def total
		return self.wrappers.size
	end

	def generate
		self.wrappers.each { |f| f.generate }
	end

	def disown(id)
		self.actors.delete(id)
		self.save
	end

	# for now, this remains class-invariant
	def html(teacherid)#,last_refresh)

		#debugger

		@feed = []
		@subsfeed = []

		# i = 0

		retstr = ''
		retsize = 0

		most_recent_logid = ''
		least_recent_logid = ''
		most_recent_logtime = 0.0
		least_recent_logtime = 0.0

		feedblacklist = {}
		duplist = {}

		teacher = Teacher.find(teacherid) #self.id.to_s # teacherid.to_s

		#teacher = self # Teacher.find(teacherid)

		# pull logs of relevant content, sort them, iterate through them, break when 10 are found
		#logs = Log.where( :model => "binders", "data.src" => nil  ).in( method: FEED_METHOD_WHITELIST ).desc(:timestamp)
		#logs = Log.where( "data.src" => nil ).in( model: ['binders','teachers'] ).in( method: FEED_METHOD_WHITELIST ).desc(:timestamp)


		# pull the current teacher's subscription IDs
		subs = (teacher.relationships.where(:subscribed => true).entries).map { |r| r["user_id"].to_s } 


		logs = Tire.search 'logs' do |search|

			search.query do |query|
				query.all
			end

			# technically these should be cascaded to avoid cross-method name conflicts
			search.filter :terms, :model => ['binders','teachers']
			search.filter :terms, :method => FEED_METHOD_WHITELIST
			search.filter :terms, :ownerid => subs + [teacherid]

			if self.timerange['upper'].present?
				search.filter :range, :timestamp => { :gte => self.timerange['upper'].to_i }
			#else
				# this is to prevent multiple inclusion in the stacked feed object array
				#search.filter :range, :timestamp => { :gte => Time.now.to_i }
			end

			#if self.timerange['lower'].present?
			#	search.filter :numeric_range, :lte => self.timerange['lower']
			#end

			# analyze later for retention in feed object
			search.size 100

			search.sort { by :timestamp, 'desc' }

		end

		logs = logs.results

		if logs.any?

			logs.each do |f|

				break if f[:id].to_s == self.mr_logid

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
						Binder.thumbready?(model) &&
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

							retsize += 1

							if f[:timestamp] > most_recent_logtime
								most_recent_logtime = f[:timestamp]
								most_recent_logid = f[:id].to_s
							end

							if f[:timestamp] < least_recent_logtime
								least_recent_logtime = f[:timestamp]
								least_recent_logid = f[:id].to_s
							end

							# create a key for an owner and an action
							similar = Digest::MD5.hexdigest(f[:ownerid].to_s + f[:method].to_s).to_s

							# this can be cut down greatly
							f = { :model => model, :ownerid => f[:ownerid].to_s, :log => f }	

							# if there are no members in the duplist, create a new action in each tracking hash
							if !(duplist[similar]) || ((duplist[similar]['timestamp'].to_i-f[:log][:timestamp].to_i) > FEED_COLLAPSE_TIME)	

								# store the index at which the similar item resides, and the current time
								duplist[similar] = { 'index' => @subsfeed.size, 'blank_index' => 0, 'timestamp' => f[:log][:timestamp].to_i }

								# new array set for feed object type
								@subsfeed << [f]

							# there is a similar event, combine in feed array
							else	

								# expire_fragment(f[:log].id.to_s) if Rails.cache.read(f[:log].id.to_s) 

								# insert into array dependent on whether or not a thumbnail exists
								if (f[:log].model.to_s=='binders' && 
										(f[:model].thumbimgids[0].nil? || 
										f[:model].thumbimgids[0].empty?)) || 
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

				break if retsize == SUBSC_FEED_LENGTH
			end

			# keep aggregate count of most recent log ids

			if !most_recent_logid.empty?
				self.update_attributes(	:mr_logid => most_recent_logid,
										:timerange => {	'lower' => [least_recent_logtime,self.timerange['lower'].to_f].min,
														'upper' => [most_recent_logtime,self.timerange['upper'].to_f].max })
			end

			arr = self.actors.clone

			@subsfeed.each do |f|

				arr << f.first[:ownerid]
				self.wrappers << Wrapper.new(	whoid: 		f.first[:ownerid],
												whatid: 	f.first[:log].modelid,
												timestamp: 	f.first[:log].timestamp,
												logids: 	f.map { |g| g[:log].id.to_s },
												wclass: 	f.first[:log][:method])
			end

			self.actors = arr.uniq!

			self.save

			imc = IndirectModelController.new()

			self.wrappers.to_a.sort_by { |f| -f.timestamp }.each do |f|
				retstr += f.html.sub('[[[TIMESTAMP]]]',imc.timewords(f.timestamp)).html_safe
			end
		end

		retstr
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
	field :timestamp,		:type => Float,		:default => 0.0
	field :markup,	 		:type => String, 	:default => ""
	field :logids,			:type => Array, 	:default => []
	field :feedobjectids, 	:type => Array, 	:default => []
	field :wclass, 			:type => String, 	:default => ""

	embedded_in :feed

	before_destroy do
		self.feed.disown(self.whoid)
	end

	# called when retrieving or refreshing the feed
	def html

		# initially, don't cache any of this, generate on the fly
		html = Rails.cache.read("wrapper/#{self.id.to_s}")
		if html.nil?
			self.generate
			Rails.cache.write("wrapper/#{self.id.to_s}",self.markup)
			html = self.markup
		end
		self.feedobjectids.each { |f| html += Feedobject.find(f).html.html_safe }
		html = IndirectModelController.new.feedbox(Teacher.find(self.whoid),html).html_safe
		html.html_safe	

	end

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

		raise 'Undefined wrapper class!' if self.wclass.empty?

		self.update_attributes(:markup => IndirectModelController.new.pseudorender(self).html_safe)
		Rails.cache.delete("wrapper/#{self.id.to_s}")

	end

	# only called when an element is being removed from
	def purge(id)
		self.feedobjectids.delete(id)
		Feedobject.find(id).delete
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
end