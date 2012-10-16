class Feed
	include Mongoid::Document

	def self.generate(teacherid)

		teacherid = teacherid.to_s

		teacher = Teacher.find(teacherid)

		# pull logs of relevant content, sort them, iterate through them, break when 10 are found
		#logs = Log.where( :model => "binders", "data.src" => nil  ).in( method: FEED_METHOD_WHITELIST ).desc(:timestamp)
		#logs = Log.where( "data.src" => nil ).in( model: ['binders','teachers'] ).in( method: FEED_METHOD_WHITELIST ).desc(:timestamp)


		# pull the current teacher's subscription IDs
		subs = (teacher.relationships.where(:subscribed => true).entries).map { |r| r["user_id"].to_s } 


		logs = Tire.search 'logs' do |search|

			search.query do |query|
				#query.string params[:q]

				query.all

				#search.size 40
			end

			# technically these should be cascaded to avoid cross-method name conflicts
			search.filter :terms, :model => ['binders','teachers']
			search.filter :terms, :method => FEED_METHOD_WHITELIST
			search.filter :terms, :ownerid => subs + [teacherid]

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

								expire_fragment(f[:log].id.to_s) if Rails.cache.read(f[:log].id.to_s) 

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
							if !Rails.cache.read(f[:log].id.to_s).nil? 
								expire_fragment(f[:log].id.to_s) 
								Rails.cache.delete(f[:log].id.to_s)
							end
						end
					end
				end
				break if @subsfeed.flatten.size == SUBSC_FEED_LENGTH
			end
		end
	end
end
