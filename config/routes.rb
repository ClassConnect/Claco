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
	put		'/confsub/:id'													=> 'teachers#confsub',		:as => 'confsub'
	post	'/confsub/:id'													=> 'teachers#confsub',		:as => 'confsub'

	#Unsubscribed to :id
	put		'/confunsub/:id'												=> 'teachers#confunsub',	:as => 'confunsub'
	post	'/confunsub/:id'												=> 'teachers#confunsub',	:as => 'confunsub'

	#Add :id as colleague
	put		'/confadd/:id'													=> 'teachers#confadd',		:as => 'confadd'
	post	'/confadd/:id'													=> 'teachers#confadd',		:as => 'confadd'

	#Remove :id as colleague
	put		'/confremove/:id'												=> 'teachers#confremove',	:as => 'confremove'
	post	'/confremove/:id'												=> 'teachers#confremove',	:as => 'confremove'
	get		'/confremove/:id'												=> 'teachers#confremove',	:as => 'confremove'

	#subscriptions
	get		'/subs'															=> 'teachers#subs'


	get		'/teachers/:id/binder/:binder_id'								=> 'teachers#showbinder',	:as => 'show_binder'

	resources :teachers, :only => [:show, :index]

	##################
	# BINDER ROUTING #
	##################

	#Binder Index
	get		'/:username/portfolio'											=> 'binders#index',			:as => 'binders'

	#New
	get		'/:username/portfolio/new'										=> 'binders#new',			:as => 'new_binder'
	post	'/:username/portfolio'											=> 'binders#create'
	
	#Adding Content
	get		'/:username/portfolio/newcontent'								=> 'binders#newcontent',	:as => 'new_binder_content'
	post	'/:username/portfolio/newcontent'								=> 'binders#createcontent'

	#Uploading File
	get		'/:username/portfolio/newfile'									=> 'binders#newfile',		:as => 'new_binder_file'
	post	'/:username/portfolio/newfile'									=> 'binders#createfile'

	#Trash folder
	get		'/:username/trash'												=> 'binders#trash',			:as => 'trash'

	################################################
	# Paths handled by named_binder_route function #
	################################################

	#Move
	get		'/:username/portfolio(/:root)/:title/:id/move'					=> 'binders#move'#,	:as => 'move_binder_path'
	put		'/:username/portfolio(/:root)/:title/:id/move'					=> 'binders#moveitem'

	#Copy
	get		'/:username/portfolio(/:root)/:title/:id/copy'					=> 'binders#copy'
	put		'/:username/portfolio(/:root)/:title/:id/copy'					=> 'binders#copyitem'

	#Fork (Snap)
	get		'/:username/portfolio(/:root)/:title/:id/fork'					=> 'binders#fork'
	put		'/:username/portfolio(/:root)/:title/:id/fork'					=> 'binders#forkitem'

	#Versioning
	get		'/:username/portfolio(/:root)/:title/:id/versions'				=> 'binders#versions'
	get		'/:username/portfolio(/:root)/:title/:id/swap'					=> 'binders#swap'
	get		'/:username/portfolio(/:root)/:title/:id/update'				=> 'binders#newversion'
	put		'/:username/portfolio(/:root)/:title/:id/update'				=> 'binders#createversion'

	#Permissions
	get		'/:username/portfolio(/:root)/:title/:id/permissions'			=> 'binders#permissions'
	put		'/:username/portfolio(/:root)/:title/:id/permissions'			=> 'binders#createpermission'
	delete	'/:username/portfolio(/:root)/:title/:id/permissions/:pid'		=> 'binders#destroypermission'
	get		'/:username/portfolio(/:root)/:title/:id/permissions/:pid'		=> redirect("/%{username}/portfolio/%{root}/%{title}/%{id}/permissions")

	#Edit
	get		'/:username/portfolio(/:root)/:title/:id/edit'					=> 'binders#edit'
	put		'/:username/portfolio(/:root)/:title/:id'						=> 'binders#update'

	#Show
	get		'/:username/portfolio(/:root)/:title/:id'						=> 'binders#show'
	delete	'/:username/portfolio(/:root)/:title/:id'						=> 'binders#destroy'

	#Temporary crocodoc view
	get		'/:username/portfolio(/:root)/:title/:id/croc'					=> 'binders#showcroc'

	get		'/assets'														=> 'binders#catcherr'

end