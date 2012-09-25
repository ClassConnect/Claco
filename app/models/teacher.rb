class Teacher
	include Mongoid::Document
	include Tire::Model::Search
	include Tire::Model::Callbacks

	# Include default devise modules. Others available are:
	# :token_authenticatable, :confirmable,
	# :lockable, :timeoutable and :omniauthable
	devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :authentication_keys => [:login]

	## Database authenticatable
	field :email,              :type => String, :null => false, :default => "", :unique => true
	field :encrypted_password, :type => String, :null => false, :default => ""

	## Recoverable
	field :reset_password_token,   :type => String
	field :reset_password_sent_at, :type => Time

	## Rememberable
	field :remember_created_at, :type => Time

	## Trackable
	field :sign_in_count,      :type => Integer, :default => 0
	field :current_sign_in_at, :type => Time
	field :last_sign_in_at,    :type => Time
	field :current_sign_in_ip, :type => String
	field :last_sign_in_ip,    :type => String

	field :registered_at,		:type => Time
	field :registered_ip,		:type => String

	## Confirmable
	# field :confirmation_token,   :type => String
	# field :confirmed_at,         :type => Time
	# field :confirmation_sent_at, :type => Time
	# field :unconfirmed_email,    :type => String # Only if using reconfirmable

	## Lockable
	# field :failed_attempts, :type => Integer, :default => 0 # Only if lock strategy is :failed_attempts
	# field :unlock_token,    :type => String # Only if unlock strategy is :email or :both
	# field :locked_at,       :type => Time

	#Exclusive beta signup code used to sign up
	field :code, :type => String

	field :title, :type => String
	field :fname, :type => String
	field :lname, :type => String
	field :username, :type => String

	field :omnihash, :type => Hash, :default => {}

	field :emailconfig, :type => Hash, :default => {"msg" => true,
													"col" => true,
													"sub" => true}

	field :allow_short_username, :type => Boolean, :default => false
	field :getting_started, :type => Boolean, :default => true

	field :admin, :type => Boolean, :default => false

	embeds_one :info#, autobuild: true #, validate: false

	embeds_one :tag#, autobuild: true #, validate: false

	#has_one :feed

	embeds_many :relationships#, validate: false

	attr_accessible :username, :email, :password, :password_confirmation, :remember_me, :login, :fname, :lname, :title, :getting_started, :emailconfig
	
	validate :username_blacklist

	validates_uniqueness_of :username, :case_sensitive => false
	validates_format_of :username, with: /[-a-z0-9]+/i, :message => "has invalid characters."
	validates_format_of :username, without: /\s/, :message => "has invalid characters."
	validates_length_of :username, minimum: 5, maximum: 16, :message => "must be at least 5 characters", :unless => Proc.new {|user| user.allow_short_username == true}
	validates_presence_of :fname, :message => "Please enter a first name."
	validates_presence_of :lname, :message => "Please enter a last name."
	
	attr_accessor :login

	index [["info.location", Mongo::GEO2D]]

	## Token authenticatable
	# field :authentication_token, :type => String


	# after_save do
	# 	debugger
	# 	#Rails.logger.debug "AFTER_SAVE got here!"
	# 	self.tire.update_index
	# 	#self.tire.index.delete
	# 	#self.tire.index.create
	# end


	# DO NOT DELETE:

	# The Brown-Cow's Part_No. #A.BC123-456 joe@bloggs.com
	# keyword:    			The Brown-Cow's Part_No. #A.BC123-456 joe@bloggs.com
	# whitespace:   		The, 	Brown-Cow's, 			Part_No., 		#A.BC123-456, 				joe@bloggs.com
	# simple:    			the, 	brown, 			cow, s, part, 		no, a, 				bc, 		joe, 			bloggs, 	com
	# standard:    					brown, 			cow's, 	part_no, 		a.bc123, 			456, 	joe, 			bloggs.com
	# snowball (English):   		brown, 			cow, 	part_no, 		a.bc123, 			456, 	joe, 			bloggs.com



	settings analysis: {
		filter: {
			ngram_filter: {
				type: 		"nGram",
				min_gram: 	1,
				max_gram: 	6
			}
		},
		analyzer: {
			ngram_analyzer: {
				tokenizer: "standard",
				filter: ["ngram_filter"],
				type: "custom"
				#tokenizer: "snowball",
				#filter: ["lowercase","ngram_filter"]
			}
		}
	} 	do
		mapping do
			indexes :fname, 	:type => 'string', 	:analyzer => 'ngram_analyzer', :boost => 200.0
			indexes :lname, 	:type => 'string', 	:analyzer => 'ngram_analyzer', :boost => 300.0
			indexes :username, 	:type => 'string', 	:analyzer => 'ngram_analyzer', :boost => 100.0
			indexes :omnihash, 	:type => 'object', 	:properties => {:twitter 		=> { :type => 'object', :properties => { :username => { :type => 'string', :analyzer => 'ngram_analyzer' }}}}
			indexes :info, 		:type => 'object', 	:properties => {:thumbnails		=> { :type => 'object', :enabled => false, :store => "yes" },
																	:avatar 		=> { :type => 'object',	:enabled => false },
																	:size 			=> { :type => 'object', :enabled => false },
																	:ext 			=> { :type => 'object', :enabled => false },
																	:data 			=> { :type => 'object', :enabled => false },
																	:grades 		=> { :type => 'string', :analyzer => 'ngram_analyzer', :default => [] },
																	:subjects 		=> { :type => 'string', :analyzer => 'ngram_analyzer', :default => [] },
																	:bio 			=> { :type => 'string', :analyzer => 'snowball', :boost => 50.0 },
																	:website 		=> { :type => 'string', :analyzer => 'ngram_analyzer' },
																	:city			=> { :type => 'string', :analyzer => 'ngram_analyzer' },
																	:state 			=> { :type => 'string', :analyzer => 'ngram_analyzer' },
																	:country		=> { :type => 'string', :analyzer => 'ngram_analyzer' },
																	:location		=> { :type => 'geo_point', :default => [] } }
		end
	end

	# Class Methods

	# used for elasticsearch
	def self
    	#to_indexed_json.as_json
    	to_indexed_json.to_json
	end

	# these clases are not defined on instances of Teacher because they are not available to ElasticSearch result objects,
	# which are indistinguishable from mongo result objects

	def self.thumbready? (teacher)

		return 	!teacher.nil? && 
				!teacher.info.nil? && 
				!teacher.info.thumbnails.nil? && 
				!teacher.info.thumbnails.first.nil? && 
				!teacher.info.thumbnails.first.empty?

	end

	def self.thumb_lg (teacher)

		return Teacher.thumbready?(teacher) ? teacher.info.thumbnails[0] : (teacher.info.avatar.nil?||teacher.info.avatar.url.nil?) ? "/assets/placer.png" : teacher.info.avatar.url.to_s

	end

	def self.thumb_mg (teacher)

		return Teacher.thumbready?(teacher) ? teacher.info.thumbnails[1] : (teacher.info.avatar.nil?||teacher.info.avatar.url.nil?) ? "/assets/placer.png" : teacher.info.avatar.url.to_s

	end

	def self.thumb_md (teacher)

		return Teacher.thumbready?(teacher) ? teacher.info.thumbnails[2] : (teacher.info.avatar.nil?||teacher.info.avatar.url.nil?) ? "/assets/placer.png" : teacher.info.avatar.url.to_s

	end

	def self.thumb_sm (teacher)

		return Teacher.thumbready?(teacher) ? teacher.info.thumbnails[3] : (teacher.info.avatar.nil?||teacher.info.avatar.url.nil?) ? "/assets/placer.png" : teacher.info.avatar.url.to_s

	end

	# def to_indexed_json
 #    	self.as_json
	# end

	# field :size, 				:type => Integer, :default => 0
	# field :ext, 				:type => String, :default => ""
	# field :data, 				:type => String, :default => "" #URL, path to file

	# field :grades,				:type => Array, :default => []
	# field :subjects,			:type => Array, :default => []
	# field :bio, 				:type => String, :default => ""
	# field :website,				:type => String, :default => ""
	# field :city,				:type => String, :default => ""
	# field :state,				:type => String, :default => ""
	# field :country,				:type => String, :default => ""
	# field :location,			:type => Array, :default => []
	# field :twitterhandle,		:type => String, :default => ""
	# field :facebookurl,			:type => String, :default => ""

	# returns best info for an at-a-glance panel
	def glance_info(lines = 2)

		return [] if info.nil?

		retarr = []

		if !info.bio.nil? && !info.bio.empty?
			if info.bio.size > 100
				# if bio is present and of sufficient length, this is the full infoset
				return [{:type => 'bio', :content => info.bio}] 
			else
				retarr << {:type => 'bio', :content => info.bio}
			end
		end

		# iterate through single-line content items
		[{:type => 'location', 	:content => "From #{info.city+', ' if !info.city.nil? && !info.city.empty?}#{info.state+', ' if !info.state.nil? && !info.state.empty?}#{info.country if !info.country.nil? && !info.country.empty?}"},
		{:type => 'subjects', 	:content => "Subjects taught: #{info.subjects.join(', ')}"},
		{:type => 'grades', 	:content => "Grades taught: #{info.grades.join(', ')}"},
		{:type => 'website', 	:content => "Website: #{info.website}"}].each do |f|

			retarr << f if !f[:content].nil? && !f[:content].empty?

			break if retarr.size==2
		end

		return retarr
	end

	# Mr. John Smith
	def full_name
		return "#{title} #{fname} #{lname}"
	end

	def first_last
		return "#{fname} #{lname}"
	end

	# Mr. Smith
	def formal_name
		return "#{title} #{lname}"
	end

	def relationship_by_teacher_id(teacher_id)
		self.relationships.find_or_initialize_by(:user_id => teacher_id)
	end

	def get_incoming_colleague_requests
		self.relationships.where(:colleague_status => 2)
	end

	def subscribed_to?(id)
		return self.relationships.find_or_initialize_by(:user_id => id).subscribed
	end

	def colleague_status(id)
		return self.relationships.find_or_initialize_by(:user_id => id).colleague_status
	end

	def self.find_first_by_auth_conditions(warden_conditions)
		conditions = warden_conditions.dup
		if login = conditions.delete(:login)
			self.any_of({ :username =>  /^#{Regexp.escape(login)}$/i }, { :email =>  /^#{Regexp.escape(login)}$/i }).first
		else
			super
		end
	end

	def get_unread_count

		Conversation.where(:members => self.id.to_s, :"unread.#{self.id.to_s}".gte => 1).count

	end

	def to_param
		username
	end

	def binders
		Binder.where(:owner => self.id.to_s)
	end

	# recursively aggregates teacher subscription network
	# degree of 1 represents teacher's immediate subscriptions
	def subscriptions (degree = 1)

		ret = {}
		if degree>0
			self.relationships.where(:subscribed => true).entries.map { |r| Teacher.find(r["user_id"]) }.each do |f|
				ret[f.id.to_s] = ret[f.id.to_s] ? ret[f.id.to_s]+1 : 1
				f.subscriptions(degree-1).each do |g|
					ret[g[0].to_s] = (ret[g[0].to_s] ? g[1]+1 : 1)
				end
			end
		end
		ret
	end

	# convert these to ElasticSearch queries!
	def self.vectors (id, degree = 1, vec = {})

		if degree>0
			id = id.to_s
			ids = []
			teacher = Teacher.find(id.to_s)
			teacher.relationships.where(:subscribed => true).entries.map { |r| Teacher.find(r["user_id"]) }.each do |f|
				next if f.id.to_s==id
				if !vec[id]
					vec[id] = { f.id.to_s => 0x8 }
					ids << f.id.to_s
				elsif !vec[id][f.id.to_s]
					vec[id][f.id.to_s] = 0x8
					ids << f.id.to_s
				else
					vec[id][f.id.to_s] |= 0x8
				end
			end
			ids.each { |g| vec = Teacher.vectors(g,degree-1,vec) }
			ids = []
			if teacher.omnihash && teacher.omnihash['twitter'] && teacher.omnihash['twitter']['fids']
				Teacher.any_in('omnihash.twitter.uid' => teacher.omnihash['twitter']['fids'].map { |e| e.to_s }).each do |f|
					next if f.id.to_s==id
					if !vec[id]
						vec[id] = { f.id.to_s => 0x4 }
						ids << f.id.to_s
					elsif !vec[id][f.id.to_s]
						vec[id][f.id.to_s] = 0x4
						ids << f.id.to_s
					else
						vec[id][f.id.to_s] |= 0x4
					end
				end
				ids.each { |g| vec = Teacher.vectors(g,degree-1,vec) }
				ids = []
			end
			if teacher.omnihash && teacher.omnihash['facebook'] && teacher.omnihash['facebook']['fids']
				Teacher.any_in('omnihash.facebook.uid' => teacher.omnihash['facebook']['fids'].map { |e| e.to_s }).each do |f|
					next if f.id.to_s==id
					if !vec[id]
						vec[id] = { f.id.to_s => 0x2 }
						ids << f.id.to_s
					elsif !vec[id][f.id.to_s]
						vec[id][f.id.to_s] = 0x2
						ids << f.id.to_s
					else
						vec[id][f.id.to_s] |= 0x2
					end
				end
				ids.each { |g| vec = Teacher.vectors(g,degree-1,vec) }
				ids = []
			end
		end
		vec

	end

	def self.add_path(src_id,dest_id,network,bitmap)

		neighbors.each do |f|
			if !network[self.id.to_s]
				network[self.id.to_s] = { "#{f.id.to_s}" => bitmap }
			else
				network[self.id.to_s][f.id.to_s] |= bitmap
			end
		end
		network
	end

	def twitter_friends (degree = 1)

		ret = {}
		if degree>0 && self.omnihash['twitter']
			Teacher.any_in('omnihash.twitter.uid' => self.omnihash['twitter']['fids'].map { |e| e.to_s }).each do |f|
				ret[f.id.to_s] = ret[f.id.to_s] ? ret[f.id.to_s]+1 : 1
				f.twitter_friends(degree-1).each do |g|
					ret[g[0].to_s] = (ret[g[0].to_s] ? g[1]+1 : 1)
				end
			end
		end
		ret

	end

	def facebook_friends (degree = 1)

		ret = {}
		if degree>0 && self.omnihash['facebook']
			Teacher.any_in('omnihash.facebook.uid' => self.omnihash['facebook']['fids'].map { |e| e.to_s }).each do |f|
				ret[f.id.to_s] = ret[f.id.to_s] ? ret[f.id.to_s]+1 : 1
				f.facebook_friends(degree-1).each do |g|
					ret[g[0].to_s] = (ret[g[0].to_s] ? g[1]+1 : 1)
				end
			end
		end
		ret

	end

	# returns ordered list of teacher IDs
	# def dijkstra (network)

	# 	network.each do |f|
	# 		f[1].each do |g|
	# 			network[f[0].to_s][g[0].to_s] = (16-g[1]).to_i
	# 			#g[1] = (16-g[1]).to_i
	# 		end
	# 	end

	# 	pathhash = {}
	# 	uniques = network.map { |f| f[1].map { |g| g[0].to_s } }.flatten.uniq

	# 	#debugger

	
	# 	# set initial distances 
	# 	uniques.each { |f| pathhash[f.to_s] = { :dist => INFINITY, :visited => false, :from => nil } if f.to_s!= self.id.to_s }

	# 	# import first layer of distance data
	# 	#network[self.id.to_s].each { |f| pathhash[f[0].to_s][:distance] = 16-(f[1].to_i) }

	# 	#debugger

	# 	current_nodeid = self.id.to_s
	# 	last_nodeid = nil

	# 	# will be performing exactly pathhash.size minpath reductions
	# 	pathhash.size.times do
	# 		# iterate through next node's outgoing links

	# 		if !network[current_nodeid].nil? || current_nodeid==self.id.to_s

	# 			pathhash_copy = pathhash.clone

	# 			#begin

	# 			network[current_nodeid].each do |g|

	# 				# pathhash[nextid] 	-> 	set of node's outgoing links
	# 				# g[0] 				-> 	id of destination node
	# 				# g[1] 				-> 	the inverse distance to that path
	# 				# 

	# 				# conditional if a link to it exists
	# 				#newdist = #[:dist]  #Teacher.minsrcpath(pathhash,current_nodeid)[1][:dist] #16-pathhash[g[0]][:dist]+g[1]

	# 				#lastdist = 
	# 				newdist = 16-g[1] + Teacher.lastdistance(pathhash_copy,last_nodeid)

	# 				if (current_nodeid==self.id.to_s || newdist < Teacher.lastdistance(pathhash_copy,current_nodeid)) && g[0].to_s!=self.id.to_s #|| pathhash[current_nodeid][:from].nil? #|| newdist < pathhash[] #(16-Teacher.minsrcpath(pathhash,g[0].to_s))
	# 					pathhash[g[0].to_s][:dist] = newdist
	# 					pathhash[g[0].to_s][:from] = current_nodeid #g[0].to_s
	# 				end
	# 			end
	# 		end

	# 		#rescue 
	# 		#	debugger
	# 		#end

	# 		#debugger

	# 		min = Teacher.minpath(pathhash)[0].to_s
	# 		pathhash[min][:visited] = true
	# 		last_nodeid = current_nodeid
	# 		current_nodeid = min
	# 	end		

	# 	pathhash

	# end

	# returns ordered list of teacher IDs
	def self.dijkstra (network,tid)

		# debugger

		#if invert
		network.each do |f|
			f[1].each do |g|
				network[f[0].to_s][g[0].to_s] = (16-g[1]).to_i
				#g[1] = (16-g[1]).to_i
			end
		end
		#end

		pathhash = {}

		#debugger

		(network.map { |f| f[1].map { |g| g[0].to_s } } + network.map{ |f| f[0].to_s }).flatten.uniq.each { |f| pathhash[f.to_s] = { :dist => INFINITY, :visited => false, :from => nil } if f.to_s!= tid }
		#network.map { |f| f[1].map { |g| g[0].to_s } }.flatten.uniq.each { |f| pathhash[f.to_s] = { :dist => INFINITY, :visited => false, :from => nil } if f.to_s!= tid }

		#debugger

		current_nodeid = tid
		last_nodeid = nil

		p "pathhash of size #{pathhash.size}"

		pathhash.size.times do

			#pathhash[current_nodeid][:visited]==true if current_nodeid!=tid

			#debugger if current_nodeid == '502d3d5c2fc6100002000084'

			#debugger

			p "now operating on node #{current_nodeid}"
			p ""
			p "network[current_nodeid]:"
			p "#{network[current_nodeid]}"
			p ""

			if !network[current_nodeid].nil? || current_nodeid==tid

				pathhash_copy = pathhash.clone
				network[current_nodeid].each do |g|

					#debugger if g[0].to_s == '502d3d5c2fc6100002000084'

					p "    now operating on connection #{g}"

					if g[0].to_s==tid
						p "        g[0] matches tid, skip! (#{g[0]},#{tid})}"
						next
					end

					#debugger if g[0].to_s=='502d3d5c2fc6100002000084'

					lastdist = lastdistance(pathhash_copy,last_nodeid)
					lastdist = 0 if lastdist == INFINITY

					newdist = g[1] +  lastdist#ance(pathhash_copy,last_nodeid)

					#debugger if newdist == 14
					#p newdist

					p "        shortest path calculation:"
					p "        newdist = g[1] +  lastdistance(pathhash_copy,last_nodeid)"
					p "        g[1]:     #{g[1]}" 
					p "        lastnode: #{lastdistance(pathhash_copy,last_nodeid)}"
					p ""
					p "        newdist:  #{newdist}"
					p "        g[0]dist: #{lastdistance(pathhash_copy,g[0].to_s)}"
					p ""
					p "        update if newdist < g[0]dist"

					if (current_nodeid==tid || newdist < lastdistance(pathhash_copy,g[0].to_s))# && g[0].to_s!=tid 

						p "            passed! updating shortest path"
						p "            old: #{pathhash[g[0].to_s]}"

						pathhash[g[0].to_s][:dist] = newdist
						pathhash[g[0].to_s][:from] = current_nodeid
						
						p "            new: #{pathhash[g[0].to_s]}"
					end
				end
			end

			min = minpath(pathhash,current_nodeid)[0].to_s

			p "pathhash: "
			p "-----------------------"
			pp pathhash
			p "-----------------------"
			p "min: #{min}"
			p "pathhash[min] will be set to visited"
			p ""
			p ""
			p ""

			pathhash[min][:visited] = true# if !pathhash[min][:from].nil?
			last_nodeid = current_nodeid
			current_nodeid = min
		end		

		pathhash

	end

	# returns the minimum distance for the given src_id
	# if no instance exists, return an infinite distance
	def self.lastdistance(network,src_id)

		return 0 if src_id.nil?

		#debugger if src_id=="502ca22b6cd2cb0002000011"

		min = nil
		network.each do |f|
			#min = f if ((min.nil?) || (f[1][:dist]<min[1][:dist] && !f[1][:visited])) && src_id.to_s==f[0].to_s
			min = f if (min.nil? || f[1][:dist]<min[1][:dist]) && src_id.to_s==f[0].to_s#f[1][:from].to_s
		end
		(min.nil? ? INFINITY : min[1][:dist])
	end

	# returns the minimum node
	def self.minpath (network,src_id)

		

		min = nil #network.first
		network.each do |f|
			#debugger
			min = f if (min.nil? || f[1][:dist]<min[1][:dist]) && !f[1][:visited] && src_id.to_s!=f[0].to_s #&& !f[1][:from].nil? # && (id.empty? || id.to_s==f[0].to_s)
		end
		#debugger
		min
	end

	def recommends (count = 5)

		#subs = self.subscriptions(2) - self.subscriptions(1)

		network = Teacher.vectors(self.id.to_s,2)



	end



	# this does not work
	# def subs_of_subs

	# 	sos = [] #{"id" => id, "count" => count}

	# 	subs = relationships.where(:subscribed => true).entries.map {|r| Teacher.find(r["user_id"])}

	# 	debugger

	# 	subs.each do |sub|

	# 		e = sos.find{|s| s["id"] == sub.id.to_s}

	# 		if e.nil?

	# 			sos << {"id" => sub.id.to_s, "count" => 1}

	# 		else

	# 			e["count"] += 1

	# 		end

	# 	end

	# 	return sos

	# end

	def self.find_for_authentication(conditions) 
		conditions[:login].downcase!
		super(conditions)
	end

	def self.from_omniauth(auth, teacher)
		# where(auth.slice(:provider, :uid)).first_or_create do |teacher|
		teacher.omnihash[auth.provider] = {} if teacher.omnihash[auth.provider].nil?
		teacher.omnihash[auth.provider]["uid"] = auth.uid
		if auth.provider == "twitter"
			teacher.omnihash[auth.provider]["username"] = auth.info.nickname
			teacher.omnihash[auth.provider]["profile"] = auth.info.urls.Twitter

			Twitter.oauth_token = auth.credentials.token
			Twitter.oauth_token_secret = auth.credentials.secret

			fids = Twitter.friend_ids(auth.info.nickname).all

			teacher.omnihash[auth.provider]["fids"] = fids

			Teacher.where(:'omnihash.twitter.uid'.in => fids).each do |fteacher|

				teacher.relationship_by_teacher_id(fteacher.id).subscribe

				Teacher.delay(:queue => "email").newsub_email(teacher.id.to_s, fteacher.id.to_s)

			end

			auth.extra.delete("access_token")
			teacher.omnihash[auth.provider]["data"] = auth

		elsif auth.provider == "facebook"
			teacher.omnihash[auth.provider]["username"] = auth.info.nickname if !auth.info.nickname.empty?
			teacher.omnihash[auth.provider]["profile"] = auth.info.urls.Facebook
			teacher.omnihash[auth.provider]["data"] = auth

			fids = JSON.parse(RestClient.get("https://graph.facebook.com/#{teacher.omnihash["facebook"]["data"]["uid"]}/friends?access_token=#{teacher.omnihash["facebook"]["data"]["credentials"]["token"]}"))["data"].collect{|f| f["id"]}

			teacher.omnihash[auth.provider]["fids"] = fids

			Teacher.where(:'omnihash.facebook.uid'.in => fids).each do |fteacher|

				teacher.relationship_by_teacher_id(fteacher.id).subscribe

				Teacher.delay(:queue => "email").newsub_email(teacher.id.to_s, fteacher.id.to_s)

			end

		end
		teacher
		# end
	end

	#DELAYED JOB
	def self.newsub_email(subscriber, subscribee)

		UserMailer.new_sub(subscriber, subscribee).deliver if Log.first_subsc?(subscriber, subscribee) && Teacher.find(subscribee).emailconfig["sub"]

	end

	after_create do

		self.info = Info.new

	end

	private
	@@username_blacklist = nil

	# checks if the username is on a blacklist
	def username_blacklist
		unless @@username_blacklist
			@@username_blacklist = Set.new ["signup"] # Put in any additional words in this array
			Rails.application.routes.routes.each do |r|
				words = r.path.spec.to_s.gsub(/(\(\.:format\)|[:()])/, "").split('/')
				words.each {|reserved_word| @@username_blacklist << reserved_word if !reserved_word.empty?}
			end
		end

	  errors.add(:username, "is restricted") if @@username_blacklist.include?(username)
	end

end


class Tag
	include Mongoid::Document

	# presently, array undergoes batch replacements only
	# PS, PK, K
	# 1,2,3,4,5,6,7,8,9,10,11,12
	# Prep, BS/BA, masters, PhD, Post Doc
	#field :grade_levels, :type => Array, :default => [false, false, false, false, false,
	#						false, false, false, false, false,
	#						false, false, false, false, false,
	#						false, false, false, false, false]
	field :grade_levels, 	:type => Array, :default => [""]
	field :subjects, 		:type => Array, :default => [""]
	field :standards, 		:type => Array, :default => [""]
	field :other, 			:type => Array, :default => [""]

	embedded_in :teacher

	# Class Methods

	# updates all data within the Tag class
	# def update_tag_fields(params)

	# 	# array to be eventually passed into the :grade_levels field
	# 	#true_checkbox_array = Array.new(20, false)
	# 	grade_levels_checkbox_array = Array.new
	# 	subjects_checkbox_array = Array.new
	# 	#zero_count = 0

	# 	# update grade_levels array
	# 	(1..(params[:tag][:grade_levels].length-1)).each do |i|
	# 		#if params[:tag][:grade_levels][i] == "0"
	# 		#	zero_count += 1
	# 		#else
	# 		#	true_checkbox_array[zero_count] = true
	# 		#end
	# 		grade_levels_checkbox_array << params[:tag][:grade_levels][i] if params[:tag][:grade_levels][i] != "0"
	# 	end

	# 	# update subjects array
	# 	(1..(params[:tag][:subjects].length-1)).each do |i|
	# 		subjects_checkbox_array << params[:tag][:subjects][i] if params[:tag][:subjects][i] != "0"
	# 	end


	# 	self.update_attributes(	:grade_levels => grade_levels_checkbox_array,
	# 							#:subjects => params[:tag][:subjects].downcase.split.uniq,
	# 							:subjects => subjects_checkbox_array,
	# 							:standards => params[:tag][:standards].downcase.split.uniq,
	# 							:other => params[:tag][:other].downcase.split.uniq)
	# 	#self.save
	# end

end

class Relationship
	include Mongoid::Document

	#scope :find_by_id, find_or_initialize_by(:user_id => params[:id])
	#scope :find_by_id, lambda { |teacher_id| find_or_initialize_by(":user_id => ?", teacher_id) }
	#def self.find_by_id(teacher_id)
	#	find_or_initialize_by(:user_id => teacher_id)
	#end

	#def self.find_by_id(teacher_id)
	#def self.find_by_id(teacher_id)
	#	return self.find_or_initialize_by(user_id: teacher_id)
	#end

	#scope :named, ->(name){ where(name: name) }
	#scope :teacher_by_id, ->(teacher_id){ find_or_initialize_by(user_id: teacher_id) }

	#scope :find_unsubscribed, where(subscribed: false)

	field :user_id, :type => String, :unique => true
	field :subscribed, :type => Boolean, :default => false
	field :colleague_status, :type => Integer, :default => 0

	embedded_in :teacher

	# Class Methods

	def subscribe
		self.update_attributes(:subscribed => true)
		#self.save
	end

	def unsubscribe
		self.update_attributes(:subscribed => false)
		#self.save
	end

	def set_colleague_status(newstatus)
		self.update_attributes(:colleague_status => newstatus)
		#self.save
	end

end

class Info
	include Mongoid::Document
	include Tire::Model::Search
	include Tire::Model::Callbacks
	#include ActiveModel::Validations
	#include CarrierWave::MiniMagick

	#require 'carrierwave/processing/mini_magick'

  #require 'mini_magick'
	#require

	# none of these fields required when updating

	#validates :profile_picture, 	:format => { :with => image_regex ,
	#				:message => "field does not appear to be an image" }#,
	#				#:presence => true

	#validates_with InfoValidator

	mount_uploader :avatar, AvatarUploader

	field :thumbnails, :type => Array, :default => [nil,nil,nil,nil]

	field :size, 				:type => Integer, :default => 0
	field :ext, 				:type => String, :default => ""
	field :data, 				:type => String, :default => "" #URL, path to file

	field :grades,				:type => Array, :default => []
	field :subjects,			:type => Array, :default => []
	field :bio, 				:type => String, :default => ""
	field :website,				:type => String, :default => ""
	field :city,				:type => String, :default => ""
	field :state,				:type => String, :default => ""
	field :country,				:type => String, :default => ""
	field :location,			:type => Array
	field :twitterhandle,		:type => String, :default => ""
	field :facebookurl,			:type => String, :default => ""

	embedded_in :teacher

	# after_save do
	# 	Rails.logger.debug "AFTER_SAVE_INFO"
	# 	tire.update_index
	# end

	# mapping do
	# 	indexes :bio
	# end

	# # Class Methods

	# def self
 #    	to_indexed_json.as_json
	# end
	
	# def self
 #    	#to_indexed_json.as_json
 #    	to_indexed_json.to_json
	# end
	
	# def to_indexed_json
 #    	self.as_json
	# end

	def fulllocation
		"#{city}, #{state}, #{country}"
	end

end
