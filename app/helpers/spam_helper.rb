module SpamHelper
  def spam?(msg)
    subject_black_list = conf('subject_black_list').to_s.split(/\015\012|\015|\012/)
    content_black_list = conf('content_black_list').to_s.split(/\015\012|\015|\012/)
    nick_black_list = conf('nick_black_list').to_s.split(/\015\012|\015|\012/)

    subject_black_list.each do |expr|
      next if expr =~ /^#/ || expr =~ /^\s*$/
      return true if Regexp.new(expr, Regexp::IGNORECASE).match?(msg.subject)
    end

    content_black_list.each do |expr|
      next if expr =~ /^#/ || expr =~ /^\s*$/
      return true if Regexp.new(expr, Regexp::IGNORECASE).match?(msg.content)
    end

    nick_black_list.each do |expr|
      next if expr =~ /^#/ || expr =~ /^\s*$/
      return true if Regexp.new(expr, Regexp::IGNORECASE).match?(msg.author)
    end

    false
  end
end

# eof
