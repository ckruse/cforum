Cforum::Application.routes.draw do
  devise_for :users, class_name: 'CfUser', path_names: {sign_in: 'login', sign_out: 'logout'}, :skip => :registration

  devise_scope :user do
    get '/users/registration/cancel' => 'devise/registrations#cancel', :as => :cancel_user_registration
    post '/users/registration' => 'devise/registrations#create', :as => :user_registration
    get '/users/registration' => 'devise/registrations#new', :as => :new_user_registration
  end


  # we use a custom url style for mails to achieve grouping
  get '/mails' => 'mails#index', :as => :mails
  post '/mails' => 'mails#create'
  get '/mails/new' => 'mails#new', :as => :new_mail
  get '/mails/:user' => 'mails#index', :as => :user_mails
  get '/mails/:user/:id' => 'mails#show', :as => :mail
  delete '/mails/:user/:id' => 'mails#destroy'
  delete '/mails' => 'mails#batch_destroy'


  resources :users
  resources :notifications, except: [:show, :edit, :new, :update, :create]
  delete 'notifications' => 'notifications#batch_destroy'

  namespace 'admin' do
    resources :users, :controller => :cf_users, :except => :show
    resources :groups, :controller => :cf_groups, :except => :show
    resources :forums, :controller => :cf_forums, :except => :show

    get 'settings' => 'cf_settings#edit', as: 'cf_settings'
    post 'settings' => 'cf_settings#update'

    get '/forums/:id/merge' => 'cf_forums#merge', as: 'forums_merge'
    post '/forums/:id/merge' => 'cf_forums#do_merge', as: 'forums_do_merge'

    root to: "cf_users#index"
  end

  get '/all' => 'cf_threads#index'

  scope ":curr_forum" do
    resources :tags, except: [:new, :create, :edit, :update, :destroy]

    get '/' => 'cf_threads#index', as: 'cf_threads'

    # thread urls
    post '/' => 'cf_threads#create'
    get '/new' => 'cf_threads#new', as: 'new_cf_thread'
    delete '/:year/:mon/:day/:tid' => 'cf_threads#destroy', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/
    get '/:year/:mon/:day/:tid/move' => 'cf_threads#moving', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/, as: 'move_cf_thread'
    post '/:year/:mon/:day/:tid/move' => 'cf_threads#move', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/
    post '/:year/:mon/:day/:tid/sticky' => 'cf_threads#sticky', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/

    # message urls
    get '/:year/:mon/:day/:tid/:mid' => 'cf_messages#show', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/, as: 'cf_message'
    get '/:year/:mon/:day/:tid/:mid/edit' => 'cf_messages#edit', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/, as: 'edit_cf_message'
    put '/:year/:mon/:day/:tid/:mid' => 'cf_messages#update', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/
    delete '/:year/:mon/:day/:tid/:mid' => 'cf_messages#destroy', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/

    post '/:year/:mon/:day/:tid/:mid/vote' => 'cf_messages#vote', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/, as: 'vote_cf_message'
    post '/:year/:mon/:day/:tid/:mid/restore' => 'cf_messages#restore', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/, as: 'restore_cf_message'

    get '/:year/:mon/:day/:tid/:mid/new' => 'cf_messages#new', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/, as: 'new_cf_message'
    post '/:year/:mon/:day/:tid/:mid' => 'cf_messages#create', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/
  end

  get '/archiv/:year/:mon/:tid' => 'cf_forums#redirect_archive'
  root to: 'cf_forums#index'

  if Rails.env == 'production'
    # default route to catch 404s
    match '*a', :to => 'application#render_404'
  end

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
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
