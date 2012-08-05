Claco::Application.routes.draw do
	devise_for :teachers

	#Root to home
	root	:to																=> 'home#index'
	get		'/homebase'														=> 'home#index'

	#Edit Info Form/Process
	get		'/editinfo'														=> "teachers#editinfo"
	put		'/updateinfo'													=> "teachers#updateinfo"
	post	'/updateinfo'													=> "teachers#updateinfo"

	#Profile Page
	get		'/teachers/:id'													=> 'teachers#show'

	#Edit Tags Form/Process
	get		'/tags'															=> "teachers#tags"
	put		'/updatetags'													=> "teachers#updatetags"

	#Subscribe to :id
	put		'/confsub/:id'													=> 'teachers#confsub',				:as => 'confsub'
	post	'/confsub/:id'													=> 'teachers#confsub',				:as => 'confsub'

	#Unsubscribed to :id
	put		'/confunsub/:id'												=> 'teachers#confunsub',			:as => 'confunsub'
	post	'/confunsub/:id'												=> 'teachers#confunsub',			:as => 'confunsub'

	#Add :id as colleague
	put		'/confadd/:id'													=> 'teachers#confadd',				:as => 'confadd'
	post	'/confadd/:id'													=> 'teachers#confadd',				:as => 'confadd'

	#Remove :id as colleague
	put		'/confremove/:id'												=> 'teachers#confremove',			:as => 'confremove'
	post	'/confremove/:id'												=> 'teachers#confremove',			:as => 'confremove'
	get		'/confremove/:id'												=> 'teachers#confremove',			:as => 'confremove'

	#subscriptions
	get		'/subs'															=> 'teachers#subs'

	get		'/teachers/:id/binder/:binder_id'								=> 'teachers#showbinder',			:as => 'show_binder'

	resources :teachers, :only => [:show, :index]

	post	'utils/fetchtitle'												=> 'home#fetchtitle'

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
	
	#Adding Content
	get		'/:username/portfolio/newcontent'								=> 'binders#newcontent',			:as => 'new_binder_content'
	post	'/:username/portfolio/newcontent'								=> 'binders#createcontent'

	#Uploading File
	get		'/:username/portfolio/newfile'									=> 'binders#newfile',				:as => 'new_binder_file'
	post	'/:username/portfolio/newfile'									=> 'binders#createfile'

	#Trash folder
	get		'/:username/trash'												=> 'binders#trash',					:as => 'trash'

	post	'/:username/portfolio(/:root)/:title/:id/reorder'				=> 'binders#reorderitem',			:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	################################################
	# Paths handled by named_binder_route function #
	################################################

	#New
	post	'/:username/portfolio(/:root)/:title/:id/create'				=> 'binders#create',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	post	'/:username/portfolio(/:root)/:title/:id/createfile'			=> 'binders#createfile',			:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	post	'/:username/portfolio(/:root)/:title/:id/createcontent'			=> 'binders#createcontent',			:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#Move
	#get		'/:username/portfolio(/:root)/:title/:id/move'					=> 'binders#move',					:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	put		'/:username/portfolio(/:root)/:title/:id/move'					=> 'binders#moveitem',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#Copy
	#get		'/:username/portfolio(/:root)/:title/:id/copy'					=> 'binders#copy',					:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	put		'/:username/portfolio(/:root)/:title/:id/copy'					=> 'binders#copyitem',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#Fork (Snap)
	#get		'/:username/portfolio(/:root)/:title/:id/fork'					=> 'binders#fork',					:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	put		'/:username/portfolio(/:root)/:title/:id/fork'					=> 'binders#forkitem',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#Versioning
	#get		'/:username/portfolio(/:root)/:title/:id/versions'				=> 'binders#versions',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	#get		'/:username/portfolio(/:root)/:title/:id/swap'					=> 'binders#swap',					:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	#get		'/:username/portfolio(/:root)/:title/:id/update'				=> 'binders#newversion',			:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	put		'/:username/portfolio(/:root)/:title/:id/update'				=> 'binders#createversion',			:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#Permissions
	#get		'/:username/portfolio(/:root)/:title/:id/permissions'			=> 'binders#permissions',			:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	put		'/:username/portfolio(/:root)/:title/:id/permissions'			=> 'binders#createpermission',		:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	delete	'/:username/portfolio(/:root)/:title/:id/permissions/:pid'		=> 'binders#destroypermission',		:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	get		'/:username/portfolio(/:root)/:title/:id/permissions/:pid'		=> redirect("/%{username}/portfolio/%{root}/%{title}/%{id}/permissions"), :constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	post	'/:username/portfolio(/:root)/:title/:id/setpub'				=> 'binders#setpub',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#Edit
	#get		'/:username/portfolio(/:root)/:title/:id/edit'					=> 'binders#edit',					:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	put		'/:username/portfolio(/:root)/:title/:id/rename'				=> 'binders#rename',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	post	'/:username/portfolio(/:root)/:title/:id/tags'					=> 'binders#updatetags',			:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	put		'/:username/portfolio(/:root)/:title/:id'						=> 'binders#update',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#Show
	get		'/:username/portfolio(/:root)/:title/:id/download'				=> 'binders#download',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	get		'/:username/portfolio(/:root)/:title/:id'						=> 'binders#show',					:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}
	delete	'/:username/portfolio(/:root)/:title/:id'						=> 'binders#destroy',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#Temporary crocodoc view
	get		'/:username/portfolio(/:root)/:title/:id/croc'					=> 'binders#showcroc',				:constraints => {:root => /[^\/]+/, :title => /[^\/]+/}

	#get		'/assets'														=> 'binders#catcherr'

	#Soulmate
	mount Soulmate::Server, :at => "/sm"



end