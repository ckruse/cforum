# -*- coding: utf-8 -*-

module RightsHelper
  # this is the list of known rights/permissions
  UPVOTE                   = "upvote"
  DOWNVOTE                 = "downvote"
  FLAG                     = "flag"
  RETAG                    = "retag"
  VISIT_CLOSE_REOPEN       = "visit_close_reopen"
  CREATE_TAGS              = "create_tag"
  CREATE_TAG_SYNONYM       = "create_tag_synonym"
  EDIT_QUESTION            = "edit_question"
  EDIT_ANSWER              = "edit_answer"
  CREATE_CLOSE_REOPEN_VOTE = "create_close_reopen"
  MODERATOR_TOOLS          = "moderator_tools"


  def may?(badge_type, user = current_user)
    return false if user.blank?
    user = CfUser.find(user) unless user.is_a?(CfUser)
    return true if user.admin

    badge = user.badges.find { |b| b.badge_type == badge_type }

    return true unless badge.blank?
    return false
  end

  def std_conditions(conditions, tid = false)
    if conditions.is_a?(String)
      if tid
        conditions = {thread_id: conditions}
      else
        conditions = {slug: conditions}
      end
    end

    conditions[:messages] = {deleted: false} unless @view_all

    conditions
  end

  def get_thread
    tid = false
    id  = nil

    if params[:year] and params[:mon] and params[:day] and params[:tid]
      id = CfThread.make_id(params)
    else
      id = params[:id]
      tid = true
    end

    thread = CfThread.
             preload(:forum,
                     messages: [:owner, :tags,
                                {votes: :voters}]).
      includes(messages: :owner).
      where(std_conditions(id, tid)).
      references(messages: :owner).
      first
    raise CForum::NotFoundException.new if thread.blank?

    # sort messages
    sort_thread(thread)

    return thread, id
  end

  def get_thread_w_post
    thread, id = get_thread

    message = nil
    unless params[:mid].blank?
      message = thread.find_message(params[:mid].to_i)
      raise CForum::NotFoundException.new if message.nil?
    end

    return thread, message, id
  end

  def authorize_controller(&proc)
    @@authorize_controller_hooks ||= {}
    @@authorize_controller_hooks[controller_path] ||= []
    @@authorize_controller_hooks[controller_path] << proc
  end

  def authorize_action(actions, &proc)
    actions = [actions] unless actions.is_a?(Array)

    @@authorize_action_hooks ||= {}
    @@authorize_action_hooks[controller_path] ||= {}

    actions.each do |a|
      @@authorize_action_hooks[controller_path][a.to_sym] ||= []
      @@authorize_action_hooks[controller_path][a.to_sym] << proc
    end
  end

  def check_authorizations
    action = action_name.to_sym

    if defined?(@@authorize_controller_hooks) and
        @@authorize_controller_hooks[controller_path]
      @@authorize_controller_hooks[controller_path].each do |block|
        raise CForum::ForbiddenException.new unless self.instance_eval(&block)
      end
    end

    if defined?(@@authorize_action_hooks) and
        @@authorize_action_hooks[controller_path] and
        @@authorize_action_hooks[controller_path][action]
      @@authorize_action_hooks[controller_path][action].each do |block|
        raise CForum::ForbiddenException.new unless self.instance_eval(&block)
      end
    end

    return
  end

  def check_editable(thread, message, redirect = true)
    # editing is always possible when user is an admin
    return true if current_user and current_user.admin?

    # not possible if thread is archived
    if conf('use_archive') == 'yes' and thread.archived?
      if redirect
        flash[:error] = t('messages.editing_disabled')
        redirect_to cf_message_url(thread, message)
      end

      return
    end

    # editing isn't possible when disabled
    if conf('editing_enabled', 'yes') != 'yes'
      if redirect
        flash[:error] = t('messages.editing_disabled')
        redirect_to cf_message_url(thread, message)
      end

      return
    end

    @max_editable_age = conf('max_editable_age', 10).to_i

    edit_it = false

    if not message.open?
      raise CForum::ForbiddenException.new if redirect
      return
    end

    if conf('edit_until_has_answer', 'yes') == 'yes' and not message.messages.empty?
      if redirect
        flash[:error] = t('messages.editing_not_allowed_with_answer')
        redirect_to cf_message_url(thread, message)
      end

      return
    end

    if message.created_at <= @max_editable_age.minutes.ago
      if redirect
        flash[:error] = t('messages.message_too_old_to_edit',
                          minutes: @max_editable_age)
        redirect_to cf_message_url(thread, message)
      end

      return
    end

    if not current_user and
        not cookies[:cforum_user].blank? and
        message.uuid == cookies[:cforum_user]
      edit_it = true

    elsif current_user
      is_mod = current_forum.moderator?(current_user)
      is_owner = current_user.user_id == message.user_id
      is_thread_msg = message.message_id == thread.message.message_id

      if not is_mod and is_owner and is_thread_msg
        edit_it = true
      elsif may?(EDIT_QUESTION) and is_thread_msg
        edit_it = true
      elsif may?(EDIT_ANSWER)
        edit_it = true
      elsif is_mod
        edit_it = true
      end
    end

    unless edit_it
      if redirect
        flash[:error] = t('messages.only_author_or_mod_may_edit')
        redirect_to cf_message_url(thread, message)
      end

      return
    end

    return true
  end

  def authorize_admin
    return true if current_user and current_user.admin?
    return false
  end

  def authorize_user
    return !current_user.blank?
  end

  def authorize_forum(forum: nil, user: nil, permission: nil)
    forum = current_forum if forum.blank?
    user = current_user if user.blank?

    if params.has_key?(:view_all) and params[:view_all] != 'false'
      if forum.blank?
        @view_all = true if not user.blank? and user.admin?
      else
        @view_all = forum.moderator?(user)
      end

      set_url_attrib(:view_all, 'yes') if @view_all
    end

    return true if forum.blank?
    return forum.send(permission, current_user) if permission
    return false
  end

  def may_answer(m)
    return false if conf('use_archive') == 'yes' and m.thread.archived?
    return m.open?
  end

end

ApplicationController.extend RightsHelper

# eof
