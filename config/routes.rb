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


	###################
	# MESSAGE ROUTING #
	###################

	#Inbox
	get		'/conversations'												=> 'teachers#conversations',		:as => 'conversations'

	#New conversation
	get		'/conversations/new'											=> 'conversations#new',				:as => 'new_conversation'
	post	'/conversations/new'											=> 'conversations#create'

	#New message/reply
	get		'/conversations/:id'											=> 'conversations#show',			:as => 'show_conversation'
	get		'/conversations/:id/add'										=> 'conversations#newmessage',		:as => 'add_message'
	put		'/conversations/:id/add'										=> 'conversations#createmessage'


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

	post	'/:username/portfolio(/:root)/:title/:id/reorder'				=> 'binders#reorderitem',			:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}

	get		'/:username/portfolio(/:root)/:title/:id/regen'					=> 'binders#regen',					:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}

	################################################
	# Paths handled by named_binder_route function #
	################################################

	#New
	post	'/:username/portfolio(/:root)/:title/:id/create'				=> 'binders#create',				:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}
	post	'/:username/portfolio(/:root)/:title/:id/createfile'			=> 'binders#createfile',			:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}
	post	'/:username/portfolio(/:root)/:title/:id/createcontent'			=> 'binders#createcontent',			:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}

	#Move
	put		'/:username/portfolio(/:root)/:title/:id/move'					=> 'binders#moveitem',				:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}

	#Copy
	put		'/:username/portfolio(/:root)/:title/:id/copy'					=> 'binders#copyitem',				:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}

	#Versioning
	put		'/:username/portfolio(/:root)/:title/:id/update'				=> 'binders#createversion',			:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}

	#Permissions
	put		'/:username/portfolio(/:root)/:title/:id/permissions'			=> 'binders#createpermission',		:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}
	delete	'/:username/portfolio(/:root)/:title/:id/permissions/:pid'		=> 'binders#destroypermission',		:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}
	get		'/:username/portfolio(/:root)/:title/:id/permissions/:pid'		=> redirect("/%{username}/portfolio/%{root}/%{title}/%{id}/permissions"), :constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}
	post	'/:username/portfolio(/:root)/:title/:id/setpub'				=> 'binders#setpub',				:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}

	#Edit
	put		'/:username/portfolio(/:root)/:title/:id/rename'				=> 'binders#rename',				:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}
	post	'/:username/portfolio(/:root)/:title/:id/tags'					=> 'binders#updatetags',			:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}

	#Show
	get		'/:username/portfolio(/:root)/:title/:id/download'				=> 'binders#download',				:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}
	get		'/:username/portfolio(/:root)/:title/:id'						=> 'binders#show',					:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}
	delete	'/:username/portfolio(/:root)/:title/:id'						=> 'binders#destroy',				:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}
	
	#Update :body
	put		'/:username/portfolio(/:root)/:title/:id'						=> 'binders#update',				:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}

	#Profile Page
	get		'/:username'													=> 'teachers#show', 				:constraints => {:username => /[^\/]+/, :root => /[^\/]+/, :title => /[^\/]+/, :format => /json|html/}
	
	#Soulmate
	# mount Soulmate::Server, :at => "/sm"



end