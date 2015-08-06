# -*- coding: utf-8 -*-

module MentionsHelper
  def find_mentions(msg)
    doc = StringScanner.new(msg.content)
    users = []
    in_cite = false

    while not doc.eos?
      if doc.scan(/^> /)
        in_cite = true

      elsif doc.scan(/\n/)
        in_cite = false

      elsif doc.scan(/(?:\A|[^a-zäöüß0-9_.@-])@([^@\n]+)/)
        nick = doc[1].strip[0..60]

        while nick.length > 2 and (user = CfUser.where(username: nick).first).blank?
          unless nick.gsub!(/[^\w]+$/, "")
            nick.gsub!(/\s*\w+$/, '')
          end
        end

        users << [user, in_cite] if not user.blank?

      else doc.scan(/./m)

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
