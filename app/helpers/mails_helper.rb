module MailsHelper
  def index_mail_link(dir, col)
    if @user
      user_mails_path(@user, sort: col, dir: dir)
    else
      mails_path(sort: col, dir: dir)
    end
  end

  def unread?(mails_group)
    m = mails_group.find { |mail| !mail.is_read }
    m.present?
  end
end

# eof
