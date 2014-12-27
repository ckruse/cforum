# -*- coding: utf-8 -*-

module SortingHelper
  def sort_thread(thread, message = nil, direction = nil)
    direction = uconf('sort_messages', 'ascending') if direction.blank?

    if message.blank?
      thread.gen_tree
      message = thread.sorted_messages[0]
    end

    unless message.messages.blank?
      if direction == 'ascending'
        message.messages.sort! { |a,b| a.created_at <=> b.created_at }
      else
        message.messages.sort! { |a,b| b.created_at <=> a.created_at }
      end

      message.messages.each do |m|
        sort_thread(thread, m, direction)
      end
    end
  end
end

# eof
