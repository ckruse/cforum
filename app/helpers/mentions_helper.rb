# -*- coding: utf-8 -*-

module MentionsHelper
  def find_mentions(msg)
    return [] if msg.blank? or msg.content.blank?

    doc = StringScanner.new(msg.content)
    users = []
    in_cite = false
    last_char = nil

    while not doc.eos?
      if doc.scan(/^> /)
        in_cite = true
        last_char = " "

      elsif doc.scan(/\n/)
        in_cite = false
        last_char = "\n"

      elsif doc.scan(/@([^@\n]+)/)
        next if not last_char.blank? and last_char =~ /[a-zäöüß0-9_.@-]/
        nick = doc[1].strip[0..60]

        while nick.length >= 2 and (user = User.where(username: nick).first).blank?
          unless nick.gsub!(/[^\w]+$/, "")
            nick.gsub!(/\s*\w+$/, '')
          end
        end

        users << [user, in_cite] if not user.blank?

      else doc.scan(/./m)
        last_char = doc.matched
      end
    end

    users
  end

  def set_mentions(msg)
    mentions = find_mentions(msg)
    msg.flags['mentions'] = mentions.map { |user| [user.first.username, user.first.user_id, user.second] }
  end
end

# eof
