# -*- coding: utf-8 -*-

module RightsHelper
  # this is the list of known rights/permissions
  RIGHT_TO_UPVOTE                       = "right_upvote"
  RIGHT_TO_DOWNVOTE                     = "right_downvote"
  RIGHT_TO_RETAG                        = "right_retag"
  RIGHT_TO_FLAG                         = "right_flag"
  RIGHT_TO_VISIT_CLOSE_AND_REOPEN_VOTES = "right_visit_close_reopen"
  RIGHT_TO_CREATE_TAGS                  = "right_create_tag"
  RIGHT_TO_EDIT_QUESTIONS               = "right_edit_question"
  RIGHT_TO_EDIT_ANSWERS                 = "right_edit_answer"
  RIGHT_TO_CREATE_TAG_SYNONYMS          = "right_tag_synonym"
  RIGHT_TO_CREATE_CLOSE_REOPEN_VOTES    = "right_create_close_reopen"
  RIGHT_TO_ACCESS_MODERATOR_TOOLS       = "right_moderator"

  DEFAULT_SCORES = {
    RIGHT_TO_UPVOTE                       => 50,
    RIGHT_TO_DOWNVOTE                     => 200,
    RIGHT_TO_FLAG                         => 500,
    RIGHT_TO_RETAG                        => 1000,
    RIGHT_TO_VISIT_CLOSE_AND_REOPEN_VOTES => 1000,
    RIGHT_TO_CREATE_TAGS                  => 1000,
    RIGHT_TO_CREATE_TAG_SYNONYMS          => 1500,
    RIGHT_TO_EDIT_QUESTIONS               => 1500,
    RIGHT_TO_EDIT_ANSWERS                 => 2000,
    RIGHT_TO_CREATE_CLOSE_REOPEN_VOTES    => 2500,
    RIGHT_TO_ACCESS_MODERATOR_TOOLS       => 3000
  }

  ALL_RIGHTS = DEFAULT_SCORES.keys

  def may?(right, user = current_user)
    @cache ||= {}

    return false if user.blank?

    if user.is_a?(CfUser)
      return true if user.admin
      user = user.user_id
    end

    @cache[user] = CfScore.where(user_id: user).sum(:value) if @cache[user].blank?
    return true if @cache[user] >= conf(right, DEFAULT_SCORES[right] || 50000)
    return
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
      preload(:forum, messages: [:owner, :tags, {close_vote: :voters}]).
      includes(messages: :owner).
      where(std_conditions(id, tid)).
      references(messages: :owner).
      first
    raise CForum::NotFoundException.new if thread.blank?

    # sort messages
    thread.message

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

  def authorize_action(actions, &proc)
    actions = [actions] unless actions.is_a?(Array)

    @@authorizatian_hooks ||= {}

    actions.each do |a|
      @@authorizatian_hooks[a.to_sym] ||= []
      @@authorizatian_hooks[a.to_sym] << proc
    end
  end

  def check_authorizations
    action = action_name.to_sym

    if defined?(@@authorizatian_hooks) and @@authorizatian_hooks[action]
      @@authorizatian_hooks[action].each do |block|
        raise CForum::ForbiddenException.new unless self.instance_eval(&block)
      end
    end

    return true
  end
end

ApplicationController.extend RightsHelper

# eof
