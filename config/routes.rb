Claco::Application.routes.draw do


	##################
	# DEVISE ROUTING #
	##################

	devise_for :teachers, :path => "", :skip => [:sessions, :registrations, :passwords], controllers: {omniauth_callbacks: "omniauth_callbacks"}

	as :teacher do

		# get		'/auth/:provider'

		get		'/login'			=> 'devise/sessions#new',			:as => :new_teacher_session
		post	'/login'			=> 'devise/sessions#create',		:as => :teacher_session
		delete	'/logout'			=> 'devise/sessions#destroy',		:as => :destroy_teacher_session

		post	'/account'			=> 'registrations#create',			:as => :teacher_registration
		get		'/join'				=> 'registrations#new',				:as => :new_teacher_registration

		post	'/password'			=> 'passwords#create',				:as => :teacher_password
		get		'/password/new'		=> 'passwords#new',					:as => :new_teacher_password
		get		'/password/edit'	=> 'passwords#edit',				:as => :edit_teacher_password
		put		'/password'			=> 'passwords#update'

	end

	#############
	# HOME PAGE #
	#############

	#Root to home
	root	:to																=> 'home#index'
	get		'/homebase'														=> 'home#index'
	get		'/autocomplete'													=> 'home#auto'
	get		'/dj'															=> 'home#dj'
	get		'/search'														=> 'home#search'
	get		'/about'														=> 'home#about'
	get		'/about/team'													=> 'home#team'
	get		'/unitedweteach'												=> 'home#united'

	get		'/teachersearch'												=> 'home#teachersearch'
	get		'/subscribedlog'												=> 'home#subscribedlog'
	# get		'/invite'														=> 'invitations#invite'
	# post	'/invite'														=> 'invitations#create'

	#################
	# ADMIN ROUTING #
	#################

	get		'/admin'														=> 'admin#index'
	get		'/admin/apps'													=> 'admin#apps'
	get		'/admin/users'													=> 'admin#users'
	get		'/admin/fpfeatured'												=> 'admin#choosefpfeatured',	:as => 'fpfeatured'
	post	'/admin/fpfeatured'												=> 'admin#setfpfeatured'
	get		'/admin/featured'												=> 'admin#choosefeatured',		:as => 'featured'
	post	'/admin/featured'												=> 'admin#setfeatured'
	# get		'/admin/invite'													=> 'admin#invite'
	# post	'/admin/sendinvite'												=> 'admin#sendinvite'
	# get		'/admin/invites'												=> 'admin#invites'

	##################
	# TEACHER ROUTING#
	##################

	#Edit Info Form/Process
	get		'/editinfo'														=> "teachers#editinfo"
	put		'/editinfo'														=> "teachers#updatepass"
	post	'/updateprefs'													=> "teachers#updateprefs"
	post	'/updateinfo'													=> "teachers#updateinfo"

	# resources :teachers, :only => [:show, :index]

	post	'/utils/fetchtitle'												=> 'home#fetchtitle'

	get		'/legal/tos'													=> 'home#tos'
	get		'/legal/privacy'												=> 'home#privacy'

	#####################
	# APPLICANT ROUTING #
	#####################

	get		'/apply'														=> 'applicants#apply'
	post	'/apply'														=> 'applicants#create',				:as => 'applicants'

	get		'/gs/:provider'													=> 'home#gs'
	post	'/done'															=> 'teachers#done'

	###################
	# MESSAGE ROUTING #
	###################

	#Inbox
	get		'/messages'																				=> 'teachers#conversations',		:as => 'conversations'

	#New conversation
	get		'/messages/new'																			=> 'conversations#new',				:as => 'new_conversation'
	post	'/messages/new'																			=> 'conversations#create'

	#New message/reply
	get		'/messages/:id'																			=> 'conversations#show',			:as => 'show_conversation'
	get		'/messages/:id/add'																		=> 'conversations#newmessage',		:as => 'add_message'
	put		'/messages/:id/add'																		=> 'conversations#createmessage'

	post	'/zcb'																					=> 'zencoder_callbacks#processed'

	constraints(:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/) do

		#Subscribe/unsubscribe
		put		'/:username/subscribe'																=> 'teachers#sub'
		put		'/:username/unsubscribe'															=> 'teachers#unsub'
		get		'/:username/subscribers'															=> 'teachers#subscribers'
		get		'/:username/subscriptions'															=> 'teachers#subscriptions'

		post	'/:username/message'																=> 'conversations#createmessage'

		##################
		# BINDER ROUTING #
		##################


		#Binder Index
		get		'/:username/portfolio'																=> 'binders#index',					:as => 'binders'

		#New
		get		'/:username/portfolio/new'															=> 'binders#new',					:as => 'new_binder'
		post	'/:username/portfolio'																=> 'binders#create'
		
		#Trash folder
		get		'/trash'																			=> 'binders#trash',					:as => 'trash'

		post	'/:username/portfolio(/:root)/:title/:id/reorder'									=> 'binders#reorderitem'

		get		'/:username/portfolio(/:root)/:title/:id/regen'										=> 'binders#regen'

		################################################
		# Paths handled by named_binder_route function #
		################################################

		# post	'/:username/portfolio(/:root)/:title/:id/favorite'									=> 'binders#create'

		#New
		post	'/:username/portfolio(/:root)/:title/:id/create'									=> 'binders#create'
		get		'/:username/portfolio(/:root)/:title/:id/cf'										=> 'binders#cf'
		get		'/:username/portfolio(/:root)/:title/:id/createfile/:data/:timestamp/:token'		=> 'binders#createfile'
		# post	'/:username/portfolio(/:root)/:title/:id/createfile'								=> 'binders#createfile'
		post	'/:username/portfolio(/:root)/:title/:id/createcontent'								=> 'binders#createcontent'

		#Move
		put		'/:username/portfolio(/:root)/:title/:id/move'										=> 'binders#moveitem'

		#Copy
		put		'/:username/portfolio(/:root)/:title/:id/copy'										=> 'binders#copyitem'

		#Versioning
		put		'/:username/portfolio(/:root)/:title/:id/update'									=> 'binders#createversion'

		# #Permissions
		# put		'/:username/portfolio(/:root)/:title/:id/permissions'								=> 'binders#createpermission'
		# delete	'/:username/portfolio(/:root)/:title/:id/permissions/:pid'							=> 'binders#destroypermission'
		# get		'/:username/portfolio(/:root)/:title/:id/permissions/:pid'				=> redirect("/%{username}/portfolio/%{root}/%{title}/%{id}/permissions")
		post	'/:username/portfolio(/:root)/:title/:id/setpub'									=> 'binders#setpub'

		#Edit
		put		'/:username/portfolio(/:root)/:title/:id/rename'									=> 'binders#rename'
		post	'/:username/portfolio(/:root)/:title/:id/tags'										=> 'binders#updatetags'

		#Show
		get		'/:username/portfolio(/:root)/:title/:id/download'									=> 'binders#download'
		get		'/:username/portfolio(/:root)/:title/:id'											=> 'binders#show'
		delete	'/:username/portfolio(/:root)/:title/:id'											=> 'binders#destroy'
		
		#Update :body
		put		'/:username/portfolio(/:root)/:title/:id'											=> 'binders#update'



		#Profile Page
		get		'/:username'																		=> 'teachers#show'
	
	end

end