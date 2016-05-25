# -*- coding: utf-8 -*-

class Messages::InterestingController < ApplicationController
  authorize_controller { authorize_user && authorize_forum(permission: :read?) }

  include SuspiciousHelper
  include HighlightHelper
  include InterestingHelper
  include LinkTagsHelper

  def mark_interesting
    if current_user.blank?
      flash[:error] = t('global.only_as_user')
      redirect_to cf_return_url
      return
    end

    @thread, @message, @id = get_thread_w_post

    begin
      InterestingMessage.create!(message_id: @message.message_id,
                                 user_id: current_user.user_id)
    rescue ActiveRecord::RecordNotUnique
    end

    respond_to do |format|
      format.html { redirect_to cf_return_url(@thread, @message),
                                notice: t('plugins.interesting_messages.marked_interesting') }
      format.json { render json: {status: :success, slug: @thread.slug } }
    end
  end

  def mark_boring
    if current_user.blank?
      flash[:error] = t('global.only_as_user')
      redirect_to cf_return_url
      return
    end

    @thread, @message, @id = get_thread_w_post

    im = InterestingMessage.where(message_id: @message.message_id,
                                  user_id: current_user.user_id).first!

    im.destroy

    respond_to do |format|
      format.html { redirect_to cf_return_url(@thread, @message),
                                notice: t('plugins.interesting_messages.unmarked_interesting') }
      format.json { render json: {status: :success, slug: @thread.slug } }
    end
  end

  def list_interesting_messages
    @limit = conf('pagination').to_i

    @messages = Message.
                preload(:owner, :tags, thread: :forum, votes: :voters).
                includes(:thread).
                joins('INNER JOIN interesting_messages im ON im.message_id = messages.message_id').
                where('im.user_id = ?', current_user.user_id).
                where(deleted: false, threads: {deleted: false}).
                page(params[:page]).per(@limit)

    @messages = sort_query(%w(created_at), @messages,
                           {created_at: 'messages.created_at'},
                           {dir: :desc})

    ret = []
    ret << check_messages_for_suspiciousness(@messages)
    ret << check_messages_for_highlight(@messages)
    ret << mark_messages_interesting(@messages)
    ret << are_read(@messages)
    ret << thread_list_link_tags

    unless ret.include?(:redirected)
      respond_to do |format|
        format.html
        format.json { render @messages }
      end
    end
  end
end

# eof
