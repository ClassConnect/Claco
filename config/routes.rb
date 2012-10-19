BASE_BINDER_ROUTE = '/:username/portfolio(/:root)/:title/:id'

Claco::Application.routes.draw do


	##################
	# DEVISE ROUTING #
	##################

	devise_for :teachers, :path => "", :skip => [:sessions, :registrations, :passwords], controllers: {omniauth_callbacks: "omniauth_callbacks"}

	as :teacher do

		# get		'/auth/:provider'

		get		'/login'			=> 'devise/sessions#new',					:as => :new_teacher_session
		post	'/login'			=> 'devise/sessions#create',			:as => :teacher_session
		delete	'/logout'		=> 'devise/sessions#destroy',			:as => :destroy_teacher_session

		post	'/account'		=> 'registrations#create',				:as => :teacher_registration
		get		'/join'				=> 'registrations#new',						:as => :new_teacher_registration

		post	'/password'				=> 'passwords#create',				:as => :teacher_password
		get		'/password/new'		=> 'passwords#new',						:as => :new_teacher_password
		get		'/password/edit'	=> 'passwords#edit',					:as => :edit_teacher_password
		put		'/password'				=> 'passwords#update'

	end

	#############
	# HOME PAGE #
	#############

	#Root to home
	root	:to																	=> 'home#index'
	get		'/homebase'													=> 'home#index'
	get		'/autocomplete'											=> 'home#auto'
	get		'/dj'																=> 'home#dj'
	get		'/search'															=> 'home#search'
	get		'/about'															=> 'home#about'

	get		'/explore'															=> 'home#explore'
	
	get		'/about/team'														=> 'home#team'
	get		'/unitedweteach'													=> 'home#united'
	get		'/goodies'															=> 'home#goodies'
	get		'/post'																=> 'home#bookmarklet'

	get		'/teachersearch'										=> 'home#teachersearch'
	get		'/subscribedlog'										=> 'home#subscribedlog'
	get		'/educators'												=> 'home#educators'

	get		'/mediaservertest'									=> 'media_server_api#mediaserver'
	post	'/mediaserver/thumbs'								=> 'media_server_api#addthumbs'

	get		'/invite'														=> 'invitations#invite'
	post	'/invite'														=> 'invitations#create'

	#################
	# ADMIN ROUTING #
	#################

	get		'/admin'																=> 'admin#index'
	get		'/admin/apps'														=> 'admin#apps',						:as => 'apps'
	get		'/admin/apps/:id/approve'								=> 'applicants#approve',		:as => 'approve'
	get		'/admin/apps/:id/deny'									=> 'applicants#deny',				:as => 'deny'
	get		'/admin/users'													=> 'admin#users'
	get		'/admin/fpfeatured'											=> 'admin#choosefpfeatured',:as => 'fpfeatured'
	post	'/admin/fpfeatured'											=> 'admin#setfpfeatured'
	get		'/admin/featured'												=> 'admin#choosefeatured',	:as => 'featured'
	post	'/admin/featured'												=> 'admin#setfeatured'
	get		'/admin/invite'													=> 'admin#invite'
	post	'/admin/sendinvite'											=> 'admin#sendinvite'
	get		'/admin/invites'												=> 'admin#invites'
	get		'/admin/invite/:id'											=> 'admin#showinv'
	get		'/admin/sysinvlist'											=> 'admin#sysinvlist'
	post	'/admin/invite/:to'											=> 'admin#sendinvite',			:constraints => {:to => /[^\/]+/}
	get		'/admin/pioneer'												=> 'admin#choosepibinder'
	post	'/admin/pioneer'												=> 'admin#setpibinder',			:as => 'pioneer'
	get		'/admin/ghost/:id'											=> 'admin#ghost',						:as => 'ghost'
	get 	'/admin/updatethumbnails'								=> 'admin#choosethumbnails'	 
	post 	'/admin/updatethumbnails'								=> 'admin#setthumbnails',		:as => 'updatethumbnails'
	get		'/admin/getthumbnails'									=> 'admin#getthumbnails'

	##################
	# TEACHER ROUTING#
	##################

	#Edit Info Form/Process
	get		'/editinfo'															=> "teachers#editinfo"
	put		'/editinfo'															=> "teachers#updatepass"
	post	'/updateprefs'													=> "teachers#updateprefs"
	post	'/updateinfo'														=> "teachers#updateinfo"
	get		'/editavatar'														=> "teachers#editavatar"
	get		'/editavatar/:data/:token'							=> "teachers#createavatar"


	# resources :teachers, :only => [:show, :index]

	post	'/utils/fetchtitle'											=> 'home#fetchtitle'

	get		'/legal/tos'														=> 'home#tos'
	get		'/legal/privacy'												=> 'home#privacy'

	#####################
	# APPLICANT ROUTING #
	#####################

	get		'/apply'															=> 'applicants#apply'
	post	'/apply'															=> 'applicants#create',				:as => 'applicants'

	get		'/gs/:provider'												=> 'home#gs'
	post	'/done'																=> 'teachers#done'

	###################
	# MESSAGE ROUTING #
	###################

	#Inbox
	get		'/messages'															=> 'teachers#conversations',		:as => 'conversations'

	#New conversation
	get		'/messages/new'														=> 'conversations#new',				:as => 'new_conversation'
	post	'/messages/new'														=> 'conversations#create'

	#New message/reply
	get		'/messages/:id'														=> 'conversations#show',			:as => 'show_conversation'
	get		'/messages/:id/add'													=> 'conversations#newmessage',		:as => 'add_message'
	put		'/messages/:id/add'													=> 'conversations#createmessage'

	post	'/zcb'																=> 'zencoder_callbacks#processed'

	constraints(:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/) do

		#########################
		# PIONEER CHATS ROUTING #
		#########################

		get		'/pioneers'														=> 'pioneers#index'
		get		'/pioneers/:title/:id'											=> 'pioneers#show'

		#Subscribe/unsubscribe
		put		'/:username/subscribe'											=> 'teachers#sub'
		put		'/:username/unsubscribe'										=> 'teachers#unsub'
		get		'/:username/subscribers'										=> 'teachers#subscribers'
		get		'/:username/subscriptions'										=> 'teachers#subscriptions'

		post	'/:username/message'											=> 'conversations#createmessage'

		##################
		# BINDER ROUTING #
		##################

		#New
		get		'/:username/portfolio/new'										=> 'binders#new',					:as => 'new_binder'
		post	'/:username/portfolio'											=> 'binders#create',				:as => 'binders'
		
		#Trash folder
		get		'/trash'														=> 'binders#trash',					:as => 'trash'

		post	"#{BASE_BINDER_ROUTE}/reorder"									=> 'binders#reorderitem'

		get		"#{BASE_BINDER_ROUTE}/regen"									=> 'binders#regen'

		################################################
		# Paths handled by named_binder_route function #
		################################################

		# post	"#{BASE_BINDER_ROUTE}/favorite"									=> 'binders#create'

		#New
		post	"#{BASE_BINDER_ROUTE}/create"									=> 'binders#create'
		get		"#{BASE_BINDER_ROUTE}/cf"										=> 'binders#cf'
		get		"#{BASE_BINDER_ROUTE}/createfile/:data/:timestamp/:token"		=> 'binders#createfile'
		# post	"#{BASE_BINDER_ROUTE}/createfile"								=> 'binders#createfile'
		post	"#{BASE_BINDER_ROUTE}/createcontent"							=> 'binders#createcontent'

		#Move
		put		"#{BASE_BINDER_ROUTE}/move"										=> 'binders#moveitem'

		#Copy
		put		"#{BASE_BINDER_ROUTE}/copy"										=> 'binders#copyitem'

		#Versioning
		put		"#{BASE_BINDER_ROUTE}/update"									=> 'binders#createversion'

		# #Permissions
		# put		"#{BASE_BINDER_ROUTE}/permissions"								=> 'binders#createpermission'
		# delete	"#{BASE_BINDER_ROUTE}/permissions/:pid"							=> 'binders#destroypermission'
		# get		"#{BASE_BINDER_ROUTE}/permissions/:pid"				=> redirect("/%{username}/portfolio/%{root}/%{title}/%{id}/permissions")
		post	"#{BASE_BINDER_ROUTE}/setpub"									=> 'binders#setpub'

		#Edit
		put		"#{BASE_BINDER_ROUTE}/rename"									=> 'binders#rename'
		post	"#{BASE_BINDER_ROUTE}/tags"										=> 'binders#updatetags'

		#Show
		get		"#{BASE_BINDER_ROUTE}/download"									=> 'binders#download'
		get		"#{BASE_BINDER_ROUTE}/video"									=> 'binders#zenframe'
		get		"#{BASE_BINDER_ROUTE}"											=> 'binders#show'
		delete	"#{BASE_BINDER_ROUTE}"											=> 'binders#destroy'
		
		#Update :body
		put		"#{BASE_BINDER_ROUTE}"											=> 'binders#update'



		#Profile Page
		get		'/:username'													=> 'teachers#show'
	
	end

end