# rubocop:disable Style/ClassVars
module RightsHelper
  def may?(badge_type, user = current_user)
    return false if user.blank?
    user = User.find(user) unless user.is_a?(User)
    return true if user.admin

    badge = user.badges.find { |b| b.badge_type == badge_type }

    return true if badge.present?
    false
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

    if defined?(@@authorize_controller_hooks) &&
       @@authorize_controller_hooks[controller_path]
      @@authorize_controller_hooks[controller_path].each do |block|
        raise CForum::ForbiddenException unless instance_eval(&block)
      end
    end

    if defined?(@@authorize_action_hooks) &&
       @@authorize_action_hooks[controller_path] &&
       @@authorize_action_hooks[controller_path][action]
      @@authorize_action_hooks[controller_path][action].each do |block|
        raise CForum::ForbiddenException unless instance_eval(&block)
      end
    end

    nil
  end

  def check_editable(thread, message, redirect = true)
    # editing is always possible when user is an admin
    return true if current_user&.admin?

    # editing isn't possible when disabled
    if conf('editing_enabled') != 'yes'
      if redirect
        flash[:error] = t('messages.editing_disabled')
        redirect_to message_url(thread, message)
      end

      return
    end

    # not possible if thread is archived
    if thread.archived?
      if redirect
        flash[:error] = t('messages.editing_disabled')
        redirect_to message_url(thread, message)
      end

      return
    end

    return true if current_forum.moderator?(current_user)

    @max_editable_age = conf('max_editable_age').to_i

    edit_it = false

    if !message.open? || !may_answer?(message)
      raise CForum::ForbiddenException if redirect
      return
    end

    if (conf('edit_until_has_answer') == 'yes') && !message.messages.empty?
      if redirect
        flash[:error] = t('messages.editing_not_allowed_with_answer')
        redirect_to message_url(thread, message)
      end

      return
    end

    check_age = false

    if !current_user &&
       cookies[:cforum_user].present? &&
       (message.uuid == cookies[:cforum_user])
      edit_it = true
      check_age = true

    elsif current_user
      is_owner = current_user.user_id == message.user_id
      is_thread_msg = message.message_id == thread.message.message_id

      if is_owner
        edit_it = true
        check_age = true
      elsif may?(Badge::EDIT_QUESTION) && is_thread_msg
        edit_it = true
      elsif may?(Badge::EDIT_ANSWER)
        edit_it = true
      end
    end

    if check_age && (message.created_at <= @max_editable_age.minutes.ago)
      if redirect
        flash[:error] = t('messages.message_too_old_to_edit',
                          minutes: @max_editable_age)
        redirect_to message_url(thread, message)
      end

      return
    end

    unless edit_it
      if redirect
        flash[:error] = t('messages.only_author_or_mod_may_edit')
        redirect_to message_url(thread, message)
      end

      return
    end

    true
  end

  def authorize_admin
    return true if current_user&.admin?
    false
  end

  def authorize_user
    current_user.present?
  end

  def authorize_forum(forum: nil, user: nil, permission: nil)
    forum = current_forum if forum.blank?
    user = current_user if user.blank?

    return true if forum.blank?
    return forum.send(permission, user) if permission
    false
  end

  def may_answer?(m)
    return false if m.thread.archived?
    m.open?
  end

  def may_vote?(m, right, u = current_user)
    return t('messages.login_to_vote') if u.blank?
    return t('messages.do_not_vote_yourself') if m.user_id == u.user_id
    return t('messages.not_enough_score') unless may?(right, u)

    false
  end

  def may_read?(message, user = current_user)
    message.forum.read?(user) && (!message.deleted || message.forum.moderator?(user))
  end
end

ApplicationController.extend RightsHelper

# eof
