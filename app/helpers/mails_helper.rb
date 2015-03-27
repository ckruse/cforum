# -*- coding: utf-8 -*-

module MailsHelper
  def index_mail_link(dir, col)
    if @user
      user_mails_path(@user.username, sort: col, dir: dir)
    else
      mails_path(sort: col, dir: dir)
    end
  end
end
