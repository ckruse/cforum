# -*- coding: utf-8 -*-

Cforum::Application.routes.draw do
  devise_for(:users, class_name: 'CfUser', path_names: {sign_in: 'login',
                                                        sign_out: 'logout'},
             skip: :registration,
             controllers: {confirmations: "users/confirmations"})

  devise_scope :user do
    get '/users/registration/cancel' => 'users/registrations#cancel',
        as: :cancel_user_registration
    post '/users/registration' => 'users/registrations#create',
         as: :user_registration
    get '/users/registration' => 'users/registrations#new',
        as: :new_user_registration
  end

  get "/search" => "cf_search#show", as: :search
  post "/search" => "cf_search#show"

  get 'cites/old/:id' => 'cites#redirect'
  get 'cites/voting' => 'cites#vote_index', as: :cites_vote
  post 'cites/:id/vote' => 'cites#vote', as: :cite_vote
  resources 'cites'

  get "/forums" => "cf_forums#redirector", as: :forum_redirector
  get '/forums_titles' => "cf_forums#title"

  # we use a custom url style for mails to achieve grouping
  get '/mails' => 'mails#index', as: :mails
  post '/mails' => 'mails#create'
  get '/mails/new' => 'mails#new', as: :new_mail
  get '/mails/:user' => 'mails#index', as: :user_mails
  get '/mails/:user/:id' => 'mails#show', as: :mail
  delete '/mails/:user/:id' => 'mails#destroy'
  delete '/mails' => 'mails#batch_destroy'
  post '/mails/:user/:id' => 'mails#mark_read_unread'

  get '/badges' => 'badges#index', as: :cf_badges
  get '/badges/:slug' => 'badges#show', as: :cf_badge

  get '/users/:id/destroy' => 'users#confirm_destroy', as: :users_confirm_destroy
  get '/users/:id/scores' => 'users#show_scores', as: :user_scores
  resources :users, except: [:new, :create]

  resources :notifications, except: [:edit, :new, :create]
  delete 'notifications' => 'notifications#batch_destroy'

  namespace 'admin' do
    resources :users, controller: :cf_users, except: :show
    resources :groups, controller: :cf_groups, except: :show
    resources :forums, controller: :cf_forums, except: :show
    resources :badges, controller: :cf_badges, except: :show
    resources :search_sections, except: :show

    get 'settings' => 'cf_settings#edit', as: 'cf_settings'
    post 'settings' => 'cf_settings#update'

    get '/forums/:id/merge' => 'cf_forums#merge', as: 'forums_merge'
    post '/forums/:id/merge' => 'cf_forums#do_merge', as: 'forums_do_merge'

    get '/audit' => 'audit#index'
    get '/audit/:id' => 'audit#show'

    root to: "cf_users#index"
  end

  get '/all' => 'cf_threads#index'

  get '/interesting' => 'cf_messages/interesting#list_interesting_messages',
      as: :interesting_messages
  get '/invisible' => 'cf_threads/invisible#list_invisible_threads',
      as: :hidden_threads

  get '/choose_css' => 'css_chooser#choose_css',
      as: :choose_css
  post '/choose_css' => 'css_chooser#css_chosen'

  resources 'images', except: [:new, :edit, :update]

  # old archive url
  get '/archiv' => 'cf_forums#redirect_archive'
  get '/archiv/:year' => 'cf_forums#redirect_archive_year', year: /\d{4}/
  get '/archiv/:year/:mon' => 'cf_forums#redirect_archive_mon', year: /\d{4}/, mon: /\d{1,2}/
  get '/archiv/:year/:mon/:tid' => 'cf_forums#redirect_archive_thread', year: /\d{4}/, mon: /\d{1,2}/, tid: /t\d+/


  scope ":curr_forum" do
    get 'tags/autocomplete' => 'tags#autocomplete'
    post 'tags/suggestions' => 'tags#suggestions'
    get 'tags/:id/merge' => 'tags#merge', as: :merge_tag
    post 'tags/:id/merge' => 'tags#do_merge'
    resources :tags do
      resources :synonyms, except: [:show, :index]
    end

    get '/redirect-to-page' => 'cf_threads#redirect_to_page'

    get '/' => 'cf_threads#index', as: 'cf_threads'

    post '/mark_all_visited' => 'cf_messages/mark_read#mark_all_read',
         as: 'mark_all_read'

    post '/close_all' => 'cf_threads/open_close#close_all',
         as: 'close_all_threads'
    post '/open_all' => 'cf_threads/open_close#open_all',
         as: 'open_all_threads'

    get '/archive' => 'cf_archive#years', as: :cf_archive
    get '/:year' => 'cf_archive#year', as: :cf_archive_year, year: /\d{4}/
    get '/:year/:month' => 'cf_archive#month', as: :cf_archive_month, year: /\d{4}/, mon: /\w{3}/

    #
    # thread urls
    #
    post '/' => 'cf_threads#create'
    get '/new' => 'cf_threads#new', as: 'new_cf_thread'

    get '/:year/:mon/:day/:tid' => 'cf_threads#show', year: /\d{4}/,
        mon: /\w{3}/, day: /\d{1,2}/, as: 'show_cf_thread_feed'

    get '/:year/:mon/:day/:tid/move' => 'cf_threads#moving', year: /\d{4}/,
        mon: /\w{3}/, day: /\d{1,2}/, as: 'move_cf_thread'
    post '/:year/:mon/:day/:tid/move' => 'cf_threads#move', year: /\d{4}/,
         mon: /\w{3}/, day: /\d{1,2}/
    post '/:year/:mon/:day/:tid/sticky' => 'cf_threads#sticky', year: /\d{4}/,
         mon: /\w{3}/, day: /\d{1,2}/
    post '/:year/:mon/:day/:tid/no_archive' => 'cf_threads/no_answer_no_archive#no_archive',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'no_archive_cf_thread'
    post '/:year/:mon/:day/:tid/mark_read' => 'cf_messages/mark_read#mark_thread_read', year: /\d{4}/,
         mon: /\w{3}/, day: /\d{1,2}/, as: :mark_thread_read

    post '/:year/:mon/:day/:tid/open' => 'cf_threads/open_close#open',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'open_cf_thread'
    post '/:year/:mon/:day/:tid/close' => 'cf_threads/open_close#close',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'close_cf_thread'

    post '/:year/:mon/:day/:tid/hide' => 'cf_threads/invisible#hide_thread',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'hide_cf_thread'
    post '/:year/:mon/:day/:tid/unhide' => 'cf_threads/invisible#unhide_thread',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: :unhide_cf_thread

    #
    # message urls
    #
    get '/:year/:mon/:day/:tid/:mid' => 'cf_messages#show', year: /\d{4}/,
        mon: /\w{3}/, day: /\d{1,2}/, as: 'cf_message'
    get '/:year/:mon/:day/:tid/:mid/edit' => 'cf_messages#edit',
        year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'edit_cf_message'
    patch '/:year/:mon/:day/:tid/:mid/edit' => 'cf_messages#update',
          year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/
    delete '/:year/:mon/:day/:tid/:mid' => 'cf_messages#destroy',
           year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/
    get '/:year/:mon/:day/:tid/:mid/retag' => 'cf_messages#show_retag',
        year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'retag_cf_message'
    post '/:year/:mon/:day/:tid/:mid/retag' => 'cf_messages#retag',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/

    post '/:year/:mon/:day/:tid/:mid/vote' => 'cf_messages/vote#vote',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'vote_cf_message'

    post '/:year/:mon/:day/:tid/:mid/interesting' => 'cf_messages/interesting#mark_interesting',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'interesting_cf_message'
    post '/:year/:mon/:day/:tid/:mid/boring' => 'cf_messages/interesting#mark_boring',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'boring_cf_message'


    #
    # admin actions
    #
    post '/:year/:mon/:day/:tid/:mid/restore' => 'cf_messages#restore',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'restore_cf_message'
    post '/:year/:mon/:day/:tid/:mid/no_answer' => 'cf_threads/no_answer_no_archive#no_answer',
         year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'no_answer_cf_message'

    #
    # Plugins
    #
    post '/:year/:mon/:day/:tid/:mid/accept' => 'cf_messages/accept#accept',
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


    get '/:year/:mon/:day/:tid/:mid/flag' => 'cf_messages/flag#flag',
        year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'flag_cf_message'
    put '/:year/:mon/:day/:tid/:mid/flag' => 'cf_messages/flag#flagging',
        year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/
    delete '/:year/:mon/:day/:tid/:mid/unflag' => 'cf_messages/flag#unflag',
           year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/

    get '/:year/:mon/:day/:tid/:mid/versions' => 'cf_messages#versions',
        year: /\d{4}/, mon: /\w{3}/, day: /\d{1,2}/, as: 'cf_message_versions'

    #
    # new and create messages
    #
    get '/:year/:mon/:day/:tid/:mid/new' => 'cf_messages#new', year: /\d{4}/,
        mon: /\w{3}/, day: /\d{1,2}/, as: 'new_cf_message'
    post '/:year/:mon/:day/:tid/:mid' => 'cf_messages#create', year: /\d{4}/,
         mon: /\w{3}/, day: /\d{1,2}/
  end

  # show forum index in root
  root to: 'cf_forums#index'
end

# eof
