Cforum::Application.routes.draw do
  # thread urls
  get '/' => 'cf_threads#index', as: 'cf_threads'
  post '/' => 'cf_threads#create'
  get '/new' => 'cf_threads#new', as: 'new_cf_thread'
  get '/:year/:mon/:day/:tid' => 'cf_threads#show', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/, as: 'cf_thread'
  delete '/:year/:mon/:day/:tid' => 'cf_threads#destroy', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/

  # message urls
  get '/:year/:mon/:day/:tid/:mid' => 'cf_messages#show', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/, as: 'cf_message'
  get '/:year/:mon/:day/:tid/:mid/edit' => 'cf_messages#edit', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/, as: 'edit_cf_message'
  put '/:year/:mon/:day/:tid/:mid' => 'cf_messages#update', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/
  delete '/:year/:mon/:day/:tid/:mid' => 'cf_messages#destroy', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/

  get '/:year/:mon/:day/:tid/:mid/new' => 'cf_messages#new', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/, as: 'new_cf_message'
  post '/:year/:mon/:day/:tid/:mid' => 'cf_messages#create', :year => /\d{4}/, :mon => /\w{3}/, :day => /\d{1,2}/

  resources :users

  match '/login' => 'application#login_from_http_basic'

  root to: 'cf_threads#index'
end
