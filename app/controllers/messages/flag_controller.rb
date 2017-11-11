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

    if @message.open_moderation_queue_entry.present?
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
      NotifyModerationQueueJob.perform_later(@moderation_queue_entry.moderation_queue_entry_id)
      redirect_to message_url(@thread, @message), notice: t('plugins.flag_plugin.flagged')

    else
      render :flag
    end
  end

  private

  def moderation_queue_params
    params.require(:moderation_queue_entry).permit(:reason, :duplicate_url, :custom_reason)
  end
end

# eof
