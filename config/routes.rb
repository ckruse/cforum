# -*- coding: utf-8 -*-

Cforum::Application.routes.draw do
  devise_for :users, class_name: 'CfUser', path_names: {sign_in: 'login',
                                                        sign_out: 'logout'}, skip: :registration

  devise_scope :user do
    get '/users/registration/cancel' => 'devise/registrations#cancel',
        as: :cancel_user_registration
    post '/users/registration' => 'devise/registrations#create',
         as: :user_registration
    get '/users/registration' => 'devise/registrations#new',
        as: :new_user_registration
  end

  get "/forums" => "cf_forums#redirector", as: :forum_redirector

  # we use a custom url style for mails to achieve grouping
  get '/mails' => 'mails#index', as: :mails
  post '/mails' => 'mails#create'
  get '/mails/new' => 'mails#new', as: :new_mail
  get '/mails/:user' => 'mails#index', as: :user_mails
  get '/mails/:user/:id' => 'mails#show', as: :mail
  delete '/mails/:user/:id' => 'mails#destroy'
  delete '/mails' => 'mails#batch_destroy'

  get '/badges' => 'badges#index', as: :cf_badges
  get '/badges/:slug' => 'badges#show', as: :cf_badge

  resources :users, except: [:new, :create]
  resources :notifications, except: [:show, :edit, :new, :create]
  delete 'notifications' => 'notifications#batch_destroy'

  namespace 'admin' do
    resources :users, controller: :cf_users, except: :show
    resources :groups, controller: :cf_groups, except: :show
    resources :forums, controller: :cf_forums, except: :show
    resources :badges, controller: :cf_badges, except: :show

    get 'settings' => 'cf_settings#edit', as: 'cf_settings'
    post 'settings' => 'cf_settings#update'

    get '/forums/:id/merge' => 'cf_forums#merge', as: 'forums_merge'
    post '/forums/:id/merge' => 'cf_forums#do_merge', as: 'forums_do_merge'

    root to: "cf_users#index"
  end

  get '/all' => 'cf_threads#index'

  get '/interesting' => 'interesting_threads_plugin#list_threads',
      as: :interesting_threads
  get '/invisible' => 'invisible_threads_plugin#list_threads',
      as: :hidden_threads
  post '/invisible/:id' => 'invisible_threads_plugin#unhide_thread',
       as: :unhide_thread

  get '/choose_css' => 'css_chooser_plugin#choose_css',
      as: :choose_css
  post '/choose_css' => 'css_chooser_plugin#css_chosen'


  scope ":curr_forum" do
    get 'tags/autocomplete' => 'tags#autocomplete'
    post 'tags/suggestions' => 'tags#suggestions'
    get 'tags/:id/merge' => 'tags#merge', as: :merge_tag
    post 'tags/:id/merge' => 'tags#do_merge'
    resources :tags do
      resources :synonyms, except: [:show, :index]
    end

    get '/' => 'cf_threads#index', as: 'cf_threads'

    post '/mark_all_visited' => 'mark_read_plugin#mark_all_read',
         as: 'mark_all_read'

    #
    # thread urls
    #
    post '/' => 'cf_threads#create'
    get '/new' => 'cf_threads#new', as: 'new_cf_thread'

    get '/:year/:mon/:day/:tid' => 'cf_threads#show', year: /\d{4}/,
        mon: /\w{3}/, day: /\d{1,2}/, format: /rss|atom/, as: 'show_cf_thread_feed'

    get '/:year/:mon/:day/:tid/move' => 'cf_threads#moving', year: /\d{4}/,
        mon: /\w{3}/, day: /\d{1,2}/, as: 'move_cf_thread'
    post '/:year/:mon/:day/:tid/move' => 'cf_threads#move', year: /\d{4}/,
         mon: /\w{3}/, day: /\d{1,2}/
    post '/:year/:mon/:day/:tid/sticky' => 'cf_threads#sticky', year: /\d{4}/,
         mon: /\w{3}/, day: /\d{1,2}/
    post '/:year/:mon/:day/:tid/no_archive' => 'no_answer_no_archive_plugin#no_archive',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'no_archive_cf_thread'
    post '/:year/:mon/:day/:tid/mark_read' => 'mark_read_plugin#mark_thread_read', year: /\d{4}/,
         mon: /\w{3}/, day: /\d{1,2}/, as: :mark_thread_read

    post '/:year/:mon/:day/:tid/interesting' => 'interesting_threads_plugin#mark_interesting',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'interesting_cf_thread'
    post '/:year/:mon/:day/:tid/boring' => 'interesting_threads_plugin#mark_boring',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'boring_cf_thread'

    #
    # message urls
    #
    get '/:year/:mon/:day/:tid/:mid' => 'cf_messages#show', year: /\d{4}/,
        mon: /\w{3}/, day: /\d{1,2}/, as: 'cf_message'
    get '/:year/:mon/:day/:tid/:mid/edit' => 'cf_messages#edit',
        year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'edit_cf_message'
    patch '/:year/:mon/:day/:tid/:mid' => 'cf_messages#update',
          year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/
    delete '/:year/:mon/:day/:tid/:mid' => 'cf_messages#destroy',
           year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/
    get '/:year/:mon/:day/:tid/:mid/retag' => 'cf_messages#show_retag',
        year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'retag_cf_message'
    post '/:year/:mon/:day/:tid/:mid/retag' => 'cf_messages#retag',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/

    post '/:year/:mon/:day/:tid/:mid/vote' => 'vote_plugin#vote',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'vote_cf_message'
    post '/:year/:mon/:day/:tid/:mid/unread' => 'mark_read_plugin#mark_unread',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'unread_cf_message'

    #
    # admin actions
    #
    post '/:year/:mon/:day/:tid/:mid/restore' => 'cf_messages#restore',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'restore_cf_message'
    post '/:year/:mon/:day/:tid/:mid/no_answer' => 'no_answer_no_archive_plugin#no_answer',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'no_answer_cf_message'

    #
    # Plugins
    #
    post '/:year/:mon/:day/:tid/:mid/accept' => 'accept_plugin#accept',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'accept_cf_message'

    get '/:year/:mon/:day/:tid/:mid/close' => 'close_vote#new',
        year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'close_cf_message'
    put '/:year/:mon/:day/:tid/:mid/close' => 'close_vote#create',
        year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/
    patch '/:year/:mon/:day/:tid/:mid/close' => 'close_vote#vote',
          year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/

    get '/:year/:mon/:day/:tid/:mid/open' => 'close_vote#new_open',
        year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'open_cf_message'
    put '/:year/:mon/:day/:tid/:mid/open' => 'close_vote#create_open',
        year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/
    patch '/:year/:mon/:day/:tid/:mid/open' => 'close_vote#vote_open',
          year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/


    get '/:year/:mon/:day/:tid/:mid/flag' => 'flag_plugin#flag',
        year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'flag_cf_message'
    put '/:year/:mon/:day/:tid/:mid/flag' => 'flag_plugin#flagging',
        year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/


    #
    # new and create messages
    #
    get '/:year/:mon/:day/:tid/:mid/new' => 'cf_messages#new', year: /\d{4}/,
        mon: /\w{3}/, day: /\d{1,2}/, as: 'new_cf_message'
    post '/:year/:mon/:day/:tid/:mid' => 'cf_messages#create', year: /\d{4}/,
         mon: /\w{3}/, day: /\d{1,2}/
  end

  # old archive url
  get '/archiv/:year/:mon/:tid' => 'cf_forums#redirect_archive'

  # show forum index in root
  root to: 'cf_forums#index'

  # 404  handling
  if Rails.env == 'production'
    # default route to catch 404s
    match '*a', to: 'application#render_404', via: [:get, :post, :put,
                                                    :delete, :patch]
  end

end

# eof
