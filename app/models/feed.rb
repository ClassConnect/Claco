class Feed
	include Mongoid::Document

	# integer timestamp used for acquiring a fresh logset from the ES server
	field :last_retrieve, :type => Float, :default => 0.0
	field :fclass, :type => Integer, :default => 0
	field :owner, :type => String, :default => ''

	embeds_many :wrappers

	def size
		return self.wrappers.size
	end

	#def 

	def generate

		retstr = ''

		self.wrappers.each do |f|
			retstr += f.retrieve
		end

	end

	# for now, this remains class-invariant
	def html(teacherid)#,last_refresh)

		@feed = []
		@subsfeed = []

		# i = 0

		retstr = ''

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
			# search.filter :range, :timestamp => { 	:from => last_refresh.to_f,													:include_upper => false }
			# 										:include_lower => true,
			# 										:include_upper => false }
			#search.filter :terms, :logid => self.parentid.to_s

			# analyze later for retention in feed object
			search.size 100

			search.sort { by :timestamp, 'desc' }

		end

		logs = logs.results

		#debugger

		if logs.any?
			logs.each do |f|

				#debugger

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

							# create a key for an owner and an action
							similar = Digest::MD5.hexdigest(f[:ownerid].to_s + f[:method].to_s).to_s

							f = { :model => model, :owner => Teacher.find(f[:ownerid].to_s), :log => f }	

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
							# if !Rails.cache.read(f[:log].id.to_s).nil? 
							# 	expire_fragment(f[:log].id.to_s) 
							# 	Rails.cache.delete(f[:log].id.to_s)
							# end
						end
					end
				end
				break if @subsfeed.flatten.size == SUBSC_FEED_LENGTH
			end

			self.wrappers.delete_all

			@subsfeed.each do |f|
				#self.wrappers << Wrapper.new()#.generate(f))
				#f = [f] if f.size==1
				debugger
				self.wrappers << Wrapper.new(	timestamp: 	f.first[:log].timestamp,
												logids: 	f.map { |g| g[:log].id.to_s },
												wclass: 	f.first[:log][:method])
												# :logids => (f.class==Array ? (f.map { |g| g[:log].id.to_s }) : ([f[:log].id.to_s])),
												# :wclass => (f.class==Array ? f.first[:log][:method] : f[:method]))
				self.save
				self.wrappers.last.generate#(f)
				#self.wrappers.last.generate(f)
				#debugger
				retstr += self.wrappers.last.html
			end
		end

		retstr
	end
end

class Wrapper
	include Mongoid::Document

	# model IDs
	field :teachers, 		:type => Array, 	:default => []
	field :binders, 		:type => Array, 	:default => []

	# used for self-referential identification
	field :ownerid,			:type => String, 	:default => ''

	# all feedobjects are references to the feedobject model
	field :timestamp,		:type => Float,		:default => 0.0
	field :content, 		:type => String, 	:default => ""
	field :logids,			:type => Array, 	:default => []
	field :feedobjectids, 	:type => Array, 	:default => []
	field :wclass, 			:type => String, 	:default => ""

	embedded_in :feed


	# called when retrieving or refreshing the feed
	def html

		# cachedata = Rails.cache.read("feedwrapper/#{self.id.to_s}")

		# if cachedata.nil?
		# 	# wrapper does not exist in cache!  
		# 	cachedata = self.generate
		# 	Rails.cache.write("feedwrapper/#{self.id.to_s}",cachedata)
		# end

		# initially, don't cache any of this, generate on the fly
		retstr = ''
		#retstr = IndirectModelController.new.pseudorender(self)
		#self.update_attributes(:content => retstr)
		debugger
		self.feedobjectids.each { |f| retstr += Feedobject.find(f).html }
		retstr	

	end

	# this will be called on both new wrappers and already populated wrappers
	def generate#(a=nil,b=nil,c=nil) #(feedobj)

		# wrapper is not being stored 
		# extract IDs, generate wrapper, generate feedobject(s) 
		# if feedobj.class==Array
		# 	self.update_attributes(	:wclass => feedobj.first[:method].to_s,
		# 							:feedobjectids => (feedobj.map { |f| f[:log].id.to_s }))
		# else
		# 	self.update_attributes(	:wclass => feedobj[:method].to_s,
		# 							:feedobjectids => [feedobj[:log].id.to_s] )
		# end

		#debugger

		if self.logids.any?
			# this is the first generate of the wrapper
			self.logids.each do |f|
				log = Log.find(f)
				feedobj = Feedobject.where(:logid => log.id.to_s).first
				case log.model
				when 'binders'
					self.binders << log.modelid
					if feedobj.nil?
						feedobj = Feedobject.new(	:binderid => log.modelid,
													:logid => log.id.to_s,
													:oclass => log.model)
						feedobj.save
					end
				when 'teachers'
					self.teachers << log.modelid
					if feedobj.nil?
						feedobj = Feedobject.new(	:teacherid => log.modelid,
													:logid => log.id.to_s,
													:oclass => log.model)
						feedobj.save
					end
				end
				self.feedobjectids << feedobj.id.to_s
			end
			self.save
			# exit unbuilt state, presently unused
			self.update_attributes(:logids => [])
		#else
			# this
		end

		#debugger

		return if false

		# these are pre-generate on class initialization

		# self.feedobjects.each do |f|
		# 	#create feedobject from log object
		# 	Feedobject.find(f).generate
		# end
	end

	def multiplicity?
		self.feedobjectids.size > 1
	end
end