# -*- coding: utf-8 -*-

module NewMessageHelper
  def new_message_saved(thread, message, parent, forum = current_forum, type = 'message')
    publish(type + ':create', { type: 'message', thread: thread,
                                message: message, parent: parent },
            '/forums/' + forum.slug)

    search_index_message(thread, message)
    autosubscribe_message(thread, parent, message)

    NotifyNewMessageJob.perform_later(thread.thread_id, message.message_id, type)
    NewMessageBadgesJob.perform_later(thread.thread_id, message.message_id)
  end
end
