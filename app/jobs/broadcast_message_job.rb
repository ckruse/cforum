class BroadcastMessageJob < ApplicationJob
  queue_as :default

  def perform(message_id, type, event)
    message = Message.preload(:thread, :forum).find(message_id)
    the_channel = if type == 'message'
                    "messages/#{message.forum.slug}"
                  else
                    "threads/#{message.forum.slug}"
                  end

    ActionCable
      .server
      .broadcast(the_channel,
                 type: event,
                 thread: message.thread,
                 message: message)
  end
end

# eof
