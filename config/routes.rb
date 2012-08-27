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
	get		'/teachersearch'												=> 'home#teachersearch'

	##################
	# TEACHER ROUTING#
	##################

	#Edit Info Form/Process
	get		'/editinfo'														=> "teachers#editinfo"
	put		'/editinfo'														=> "teachers#updatepass"
	post	'/updateinfo'													=> "teachers#updateinfo"

	#Subscribe/unsubscribe
	put		'/:username/subscribe'											=> 'teachers#sub'
	put		'/:username/unsubscribe'										=> 'teachers#unsub'

	# resources :teachers, :only => [:show, :index]

	post	'utils/fetchtitle'												=> 'home#fetchtitle'

	#####################
	# APPLICANT ROUTING #
	#####################

	get		'/apply'														=> 'applicants#apply'
	post	'/apply'														=> 'applicants#create',				:as => 'applicants'
	get		'/viewapps'														=> 'applicants#viewapps'

	get		'/gs/:provider'													=> 'omniauth_callbacks#gs'
	post	'/done'															=> 'teachers#done'

	###################
	# MESSAGE ROUTING #
	###################

	#Inbox
	get		'/messages'												=> 'teachers#conversations',		:as => 'conversations'

	#New conversation
	get		'/messages/new'											=> 'conversations#new',				:as => 'new_conversation'
	post	'/messages/new'											=> 'conversations#create'

	#New message/reply
	get		'/messages/:id'											=> 'conversations#show',			:as => 'show_conversation'
	get		'/messages/:id/add'										=> 'conversations#newmessage',		:as => 'add_message'
	put		'/messages/:id/add'										=> 'conversations#createmessage'


	constraints(:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/) do

		post '/:username/message'											=> 'conversations#createmessage'

		##################
		# BINDER ROUTING #
		##################


		#Binder Index
		get		'/:username/portfolio'											=> 'binders#index',					:as => 'binders'

		#New
		get		'/:username/portfolio/new'										=> 'binders#new',					:as => 'new_binder'
		post	'/:username/portfolio'											=> 'binders#create'
		
		#Trash folder
		get		'/trash'														=> 'binders#trash',					:as => 'trash'

		post	'/:username/portfolio(/:root)/:title/:id/reorder'				=> 'binders#reorderitem'

		get		'/:username/portfolio(/:root)/:title/:id/regen'					=> 'binders#regen'

		################################################
		# Paths handled by named_binder_route function #
		################################################

		#New
		post	'/:username/portfolio(/:root)/:title/:id/create'				=> 'binders#create'
		post	'/:username/portfolio(/:root)/:title/:id/createfile'			=> 'binders#createfile'
		post	'/:username/portfolio(/:root)/:title/:id/createcontent'			=> 'binders#createcontent'

		#Move
		put		'/:username/portfolio(/:root)/:title/:id/move'					=> 'binders#moveitem'

		#Copy
		put		'/:username/portfolio(/:root)/:title/:id/copy'					=> 'binders#copyitem'

		#Versioning
		put		'/:username/portfolio(/:root)/:title/:id/update'				=> 'binders#createversion'

		#Permissions
		put		'/:username/portfolio(/:root)/:title/:id/permissions'			=> 'binders#createpermission'
		delete	'/:username/portfolio(/:root)/:title/:id/permissions/:pid'		=> 'binders#destroypermission'
		get		'/:username/portfolio(/:root)/:title/:id/permissions/:pid'		=> redirect("/%{username}/portfolio/%{root}/%{title}/%{id}/permissions")
		post	'/:username/portfolio(/:root)/:title/:id/setpub'				=> 'binders#setpub'

		#Edit
		put		'/:username/portfolio(/:root)/:title/:id/rename'				=> 'binders#rename'
		post	'/:username/portfolio(/:root)/:title/:id/tags'					=> 'binders#updatetags'

		#Show
		get		'/:username/portfolio(/:root)/:title/:id/download'				=> 'binders#download'
		get		'/:username/portfolio(/:root)/:title/:id'						=> 'binders#show'
		delete	'/:username/portfolio(/:root)/:title/:id'						=> 'binders#destroy'
		
		#Update :body
		put		'/:username/portfolio(/:root)/:title/:id'						=> 'binders#update'

		#Profile Page
		get		'/:username'													=> 'teachers#show'
	
	end

end