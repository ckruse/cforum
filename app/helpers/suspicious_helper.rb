# -*- coding: utf-8 -*-

module SuspiciousHelper
  def check_threads_for_suspiciousness(threads)
    return if not current_user.blank? and uconf('mark_suspicious') == 'no'

    threads.each do |t|
      t.sorted_messages.each do |m|
        m.attribs["classes"] << 'suspicious' if name_suspicious?(m.author)
      end
    end
  end

  def check_messages_for_suspiciousness(messages)
    return if not current_user.blank? and uconf('mark_suspicious') == 'no'

    messages.each do |m|
      m.attribs['classes'] << 'suspicious' if name_suspicious?(m.author)
    end
  end

  def name_suspicious?(name)
    name.each_codepoint do |cp|
      return true if cp > 255
    end

    return false
  end
end

# eof
