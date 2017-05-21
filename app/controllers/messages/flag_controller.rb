# -*- coding: utf-8 -*-

class Messages::FlagController < ApplicationController
  authorize_controller { authorize_forum(permission: :read?) }
  authorize_action(:unflag) { authorize_forum(permission: :moderator?) }

  #
  # flagging
  #

  def flag
    @thread, @message, @id = get_thread_w_post
    @moderation_queue_entry = ModerationQueueEntry.new(message_id: @message.message_id)

    respond_to do |format|
      format.html
    end
  end

  def flagging
    @thread, @message, @id = get_thread_w_post

    unless @message.open_moderation_queue_entry.blank?
      @message.open_moderation_queue_entry.reported += 1
      @message.open_moderation_queue_entry.save!
      redirect_to message_url(@thread, @message), notice: t('plugins.flag_plugin.flagged')
      return
    end

    @moderation_queue_entry = ModerationQueueEntry.new(moderation_queue_params)
    @moderation_queue_entry.message_id = @message.message_id
    @moderation_queue_entry.reported = 1

    has_error = false

    if @moderation_queue_entry == 'duplicate' && (@moderation_queue_entry.duplicate_url.blank? ||
                                                  (@moderation_queue_entry.duplicate_url !~ %r{^https?://}))
      flash.now[:error] = t('plugins.flag_plugin.dup_url_needed')
      has_error = true
    end

    if !has_error && @moderation_queue_entry.save
      audit(@message, 'flagged-' + @moderation_queue_entry.reason, nil)
      notify_admins_and_moderators
      redirect_to message_url(@thread, @message), notice: t('plugins.flag_plugin.flagged')

    else
      render :flag
    end
  end

  private

  def moderation_queue_params
    params.require(:moderation_queue_entry).permit(:reason, :duplicate_url, :custom_reason)
  end

  def admins_and_moderators(forum_id)
    User.where('admin = true OR user_id IN ( ' \
               '  SELECT user_id FROM forums_groups_permissions ' \
               '    INNER JOIN groups_users USING(group_id) ' \
               '    WHERE forum_id = ? AND permission = ?' \
               ') OR user_id IN (' \
               '  SELECT user_id FROM badges_users ' \
               '    INNER JOIN badges USING(badge_id) ' \
               '    WHERE badge_type = ?)',
               forum_id, ForumGroupPermission::ACCESS_MODERATE,
               Badge::MODERATOR_TOOLS)
  end

  def notify_admins_and_moderators
    unread = ModerationQueueEntry.where(cleared: false).count
    users = admins_and_moderators(@message.forum_id)

    users.each do |user|
      BroadcastUserJob.perform_later({ type: 'moderation_queue:create',
                                       entry: @moderation_queue_entry, unread: unread },
                                     user.user_id)
    end
  end
end

# eof
