# -*- coding: utf-8 -*-

module MailsHelper
  def index_mail_link(dir, col)
    if @user
      user_mails_path(@user, sort: col, dir: dir)
    else
      mails_path(sort: col, dir: dir)
    end
  end

  def has_unread?(mails_group)
    m = mails_group.find { |mail| not mail.is_read }
    not m.blank?
  end
end

# eof
