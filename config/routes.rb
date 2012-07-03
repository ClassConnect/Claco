Claco::Application.routes.draw do
  devise_for :teachers

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.


#Eventually we will need routes that give context, i.e.
#get '/binders/:id'
#Should be:

get '/:username/binders/:greatest_parent/:title/:id' => 'binders#nshow', :as =>'show_binder'

#Root to home
root :to => 'home#index'

#Edit Info Form/Process
get '/editinfo'       => "teachers#editinfo"
put '/updateinfo'     => "teachers#updateinfo"
post '/updateinfo'     => "teachers#updateinfo"

#Profile Page
get '/teachers/:id'   => 'teachers#show'

#Edit Tags Form/Process
get '/tags'           => "teachers#tags"
put '/updatetags'     => "teachers#updatetags"

#Subscribe to :id
#get '/sub/:id'        => 'teachers#sub'
put '/confsub/:id'    => 'teachers#confsub', :as => 'confsub'
post '/confsub/:id'    => 'teachers#confsub', :as => 'confsub'

#Unsubscribed to :id
#get '/unsub/:id'      => 'teachers#unsub'
put '/confunsub/:id'   => 'teachers#confunsub', :as => 'confunsub'
post '/confunsub/:id'   => 'teachers#confunsub', :as => 'confunsub'

#Add :id as colleague
#get '/add/:id'        => 'teachers#add'
put '/confadd/:id'    => 'teachers#confadd', :as => 'confadd'
post '/confadd/:id'    => 'teachers#confadd', :as => 'confadd'

#Remove :id as colleague
#get '/remove/:id'     => 'teachers#remove'
put  '/confremove/:id' => 'teachers#confremove', :as => 'confremove'
post '/confremove/:id' => 'teachers#confremove', :as => 'confremove'
get  '/confremove/:id' => 'teachers#confremove', :as => 'confremove'

#subscriptions
get '/subs'	      => 'teachers#subs'

resources :teachers, :only => [:show, :index]

#Adding Content
get '/binders/newcontent'      => 'binders#newcontent',         :as => 'new_binder_content'
post '/binders/newcontent'    => 'binders#createcontent'

#Uploading File
get '/binders/newfile'          => 'binders#newfile'
post '/binders/newfile'         => 'binders#createfile'

#Add new version of file
get '/binders/:id/update'       =>  'binders#newversion',       :as => 'new_binder_version'
put '/binders/:id/update'       =>  'binders#createversion',    :as => 'create_binder_version'
get '/binders/:id/versions'     =>  'binders#versions',         :as => 'binder_versions'
put '/binders/:id/swap'         =>  'binders#swap',             :as => 'swap_binder'

#Handling permissions
#Viewing current permissions w/ form at bottom for adding a new permission
get '/binders/:id/permissions'          => 'binders#permissions',        :as => 'binder_permissions'
put '/binders/:id/permissions'          => 'binders#createpermission',   :as => 'create_binder_permission'
delete '/binders/:id/permissions/:pid'  => 'binders#destroypermission',  :as => 'destroy_binder_permission'
get '/binders/:id/permissions/:pid'     => redirect("/binders/%{id}/permissions")

#Moving a binder object (File, folder, content)
get '/binders/:id/move'     => 'binders#move',            :as => 'move_binder'
put '/binders/:id/move'     => 'binders#moveitem',        :as => 'move_binder'

#Copying a binder object
get '/binders/:id/copy'     => 'binders#copy',            :as => 'copy_binder'
put '/binders/:id/copy'     => 'binders#copyitem',        :as => 'copy_binder'

#Forking a binder object
get '/binders/:id/fork'     => 'binders#fork',            :as => 'fork_binder'
put '/binders/:id/fork'     => 'binders#forkitem',        :as => 'fork_binder'

#Trash folder
get '/binders/trash'        => 'binders#trash',           :as => 'trash'

# rename route
#get '/teachers/:id/binder/:binder_id' => 'teachers#showbinder', :as => 'show_binder'

resources :binders


  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
