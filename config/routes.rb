Claco::Application.routes.draw do

	##################
	# DEVISE ROUTING #
	##################

	devise_for :teachers, :skip => [:sessions, :registration]

	as :teacher do

		get		'/login'			=> 'devise/sessions#new',			:as => :new_teacher_session
		post	'/login'			=> 'devise/sessions#create',		:as => :teacher_session
		delete	'/logout'			=> 'devise/sessions#destroy',		:as => :destroy_teacher_session

		post	'/account'			=> 'devise/registrations#create',	:as => :teacher_registration
		get		'/sign_up'			=> 'devise/registrations#new',		:as => :new_teacher_registration

	end


	#############
	# HOME PAGE #
	#############

	#Root to home
	root	:to																=> 'home#index'
	get		'/homebase'														=> 'home#index'


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

	#Add :username as colleague
	put		'/:username/add'												=> 'teachers#add'

	# #Edit Tags Form/Process
	# get		'/tags'															=> "teachers#tags"
	# put		'/updatetags'													=> "teachers#updatetags"

	#Subscribe to :id
	# put		'/confsub/:id'													=> 'teachers#confsub',				:as => 'confsub'
	# post	'/confsub/:id'													=> 'teachers#confsub',				:as => 'confsub'

	# #Unsubscribed to :id
	# put		'/confunsub/:id'												=> 'teachers#confunsub',			:as => 'confunsub'
	# post	'/confunsub/:id'												=> 'teachers#confunsub',			:as => 'confunsub'

	# #Add :id as colleague
	# put		'/confadd/:id'													=> 'teachers#confadd',				:as => 'confadd'
	# post	'/confadd/:id'													=> 'teachers#confadd',				:as => 'confadd'

	# #Remove :id as colleague
	# put		'/confremove/:id'												=> 'teachers#confremove',			:as => 'confremove'
	# post	'/confremove/:id'												=> 'teachers#confremove',			:as => 'confremove'
	# get		'/confremove/:id'												=> 'teachers#confremove',			:as => 'confremove'

	# subscriptions
	# get		'/subs'															=> 'teachers#subs'

	# get		'/teachers/:id/binder/:binder_id'								=> 'teachers#showbinder',			:as => 'show_binder'






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

	post	'/:username/portfolio(/:root)/:title/:id/reorder'				=> 'binders#reorderitem',			:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}


	################################################
	# Paths handled by named_binder_route function #
	################################################

	#New
	post	'/:username/portfolio(/:root)/:title/:id/create'				=> 'binders#create',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	post	'/:username/portfolio(/:root)/:title/:id/createfile'			=> 'binders#createfile',			:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	post	'/:username/portfolio(/:root)/:title/:id/createcontent'			=> 'binders#createcontent',			:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#Move
	put		'/:username/portfolio(/:root)/:title/:id/move'					=> 'binders#moveitem',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#Copy
	put		'/:username/portfolio(/:root)/:title/:id/copy'					=> 'binders#copyitem',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#Versioning
	put		'/:username/portfolio(/:root)/:title/:id/update'				=> 'binders#createversion',			:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#Permissions
	put		'/:username/portfolio(/:root)/:title/:id/permissions'			=> 'binders#createpermission',		:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	delete	'/:username/portfolio(/:root)/:title/:id/permissions/:pid'		=> 'binders#destroypermission',		:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	get		'/:username/portfolio(/:root)/:title/:id/permissions/:pid'		=> redirect("/%{username}/portfolio/%{root}/%{title}/%{id}/permissions"), :constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	post	'/:username/portfolio(/:root)/:title/:id/setpub'				=> 'binders#setpub',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#Edit
	put		'/:username/portfolio(/:root)/:title/:id/rename'				=> 'binders#rename',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	post	'/:username/portfolio(/:root)/:title/:id/tags'					=> 'binders#updatetags',			:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#Show
	get		'/:username/portfolio(/:root)/:title/:id/download'				=> 'binders#download',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	get		'/:username/portfolio(/:root)/:title/:id'						=> 'binders#show',					:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	delete	'/:username/portfolio(/:root)/:title/:id'						=> 'binders#destroy',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	
	#Update :body
	put		'/:username/portfolio(/:root)/:title/:id'						=> 'binders#update',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#get		'/assets'														=> 'binders#catcherr'
	get		'/seedbinder'													=> 'binders#seedbinder'

	#Profile Page
	get		'/:username'													=> 'teachers#show'
	
	#Soulmate
	mount Soulmate::Server, :at => "/sm"



end