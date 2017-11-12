class ModerationQueueController < ApplicationController
  authorize_controller { current_user.try(:moderator?) }

  before_action(-> { @view_all = true && set_url_attrib(:view_all, 'yes') })

  def index
    @limit = conf('pagination').to_i
    @moderation_queue_entries = ModerationQueueEntry
                                  .preload(message: :thread)
                                  .order(:cleared, created_at: :desc)
                                  .page(params[:page])
                                  .per(@limit)

    if !current_user.admin? && !current_user.badge?(Badge::MODERATOR_TOOLS)
      forums_w_access = ForumGroupPermission
                          .select(:forum_id)
                          .where('group_id IN (SELECT group_id FROM groups_users WHERE user_id = ?) ' \
                                 'AND permission = ?', current_user.user_id, ForumGroupPermission::MODERATE)

      @moderation_queue_entries = @moderation_queue_entries
                                    .joins(:message)
                                    .where('forum_id IN (?)', forums_w_access)
    end

    respond_to do |format|
      format.html
    end
  end

  def edit
    @moderation_queue_entry = ModerationQueueEntry
                                .preload(message: :forum)
                                .where(moderation_queue_entry_id: params[:id])
                                .first

    raise Cforum::NotAllowedException unless current_user.moderate?(@moderation_queue_entry.message.forum)

    Notification
      .where(recipient_id: current_user.user_id,
             otype: 'moderation_queue_entry:created',
             oid: @moderation_queue_entry.moderation_queue_entry_id)
      .delete_all

    respond_to do |format|
      format.html
    end
  end

  def update
    @moderation_queue_entry = ModerationQueueEntry
                                .preload(message: :forum)
                                .where(moderation_queue_entry_id: params[:id])
                                .first

    raise Cforum::NotAllowedException unless current_user.moderate?(@moderation_queue_entry.message.forum)

    @moderation_queue_entry.attributes = moderation_queue_params
    @moderation_queue_entry.closer_id = current_user.user_id
    @moderation_queue_entry.closer_name = current_user.username
    @moderation_queue_entry.cleared = true

    saved = false
    ModerationQueueEntry.transaction do
      if @moderation_queue_entry.save
        execute_moderation_action(@moderation_queue_entry)
        saved = true
      end

      raise ActiveRecord::Rollback unless saved
    end

    if saved
      redirect_to moderation_queue_index_path, notice: t('moderation_queue.successfully_cleared_case')
    else
      render :edit
    end
  end

  def execute_moderation_action(mod_queue_entry)
    thread, message, = get_thread_w_post(mod_queue_entry.message.thread_id, mod_queue_entry.message_id)

    case mod_queue_entry.resolution_action
    when 'close'
      message.flag_with_subtree('no-answer-admin', 'yes')
      audit(message, 'no-answer-admin-yes')

    when 'delete'
      message.delete_with_subtree
      audit(message, 'delete')

    when 'no-archive'
      thread.flags_will_change!
      thread.flags['no-archive'] = 'yes'
      audit(thread, 'no-archive-yes')
      thread.save!
    end
  end

  def moderation_queue_params
    params
      .require(:moderation_queue_entry)
      .permit(:resolution_action, :resolution)
  end
end

# eof
