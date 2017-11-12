module MentionsHelper
  def find_mentions(msg)
    return [] if msg.blank? || msg.content.blank?

    doc = StringScanner.new(msg.content)
    users = []
    in_cite = false
    last_char = nil

    until doc.eos?
      if doc.scan(/^> /)
        in_cite = true
        last_char = ' '

      elsif doc.scan(/\n/)
        in_cite = false
        last_char = "\n"

      elsif doc.scan(/\\@/)
        last_char = '\\'

      elsif doc.scan(/@([^@\n]+)/)
        next if last_char.present? && last_char =~ /[a-zäöüß0-9_.@-]/
        nick = doc[1].strip[0..60]

        while (nick.length >= 2) && (user = User.where(username: nick).first).blank?
          nick.gsub!(/\s*\w+$/, '') unless nick.gsub!(/[^\w]+$/, '')
        end

        users << [user, in_cite] if user.present?

      else doc.scan(/./m)
           last_char = doc.matched
      end
    end

    users
  end

  def save_mentions(msg)
    mentions = find_mentions(msg)
    msg.flags['mentions'] = mentions.map { |user| [user.first.username, user.first.user_id, user.second] }
  end
end

# eof
