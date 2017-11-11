module SuspiciousHelper
  def check_threads_for_suspiciousness(threads)
    return if uconf('mark_suspicious') == 'no'

    threads.each do |t|
      t.sorted_messages.each do |m|
        m.attribs['classes'] << 'suspicious' if name_suspicious?(m.author)
      end
    end
  end

  def check_messages_for_suspiciousness(messages)
    return if uconf('mark_suspicious') == 'no'

    messages.each do |m|
      m.attribs['classes'] << 'suspicious' if name_suspicious?(m.author)
    end
  end

  def name_suspicious?(name)
    name.each_codepoint do |cp|
      return true if cp > 255 || cp < 32
    end

    false
  end
end

# eof
