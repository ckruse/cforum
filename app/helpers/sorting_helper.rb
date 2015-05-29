# -*- coding: utf-8 -*-

module SortingHelper
  def sort_thread(thread, message = nil, direction = nil)
    direction = uconf('sort_messages') if direction.blank?

    if message.blank?
      thread.gen_tree(direction)
      return
    end

    unless message.messages.blank?
      if direction == 'ascending'
        message.messages.sort! { |a,b| a.created_at <=> b.created_at }
      else
        message.messages.sort! { |a,b| b.created_at <=> a.created_at }
      end

      for m in message.messages
        sort_thread(thread, m, direction)
      end
    end
  end
end

# eof
