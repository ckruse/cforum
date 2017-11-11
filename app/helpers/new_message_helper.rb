module NewMessageHelper
  def new_message_saved(thread, message, parent, _forum = current_forum, type = 'message')
    BroadcastMessageJob.perform_later(message.message_id, type, 'create')

    search_index_message(thread, message)
    autosubscribe_message(thread, parent, message)

    NotifyNewMessageJob.perform_later(thread.thread_id, message.message_id, type)
    NewMessageBadgesJob.perform_later(thread.thread_id, message.message_id)
  end
end
