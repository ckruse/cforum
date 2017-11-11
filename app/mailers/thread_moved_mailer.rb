class ThreadMovedMailer < ActionMailer::Base
  def thread_moved(user, thread, old_forum, new_forum, url)
    @user      = user
    @thread    = thread
    @old_forum = old_forum
    @new_forum = new_forum
    @url       = url

    mail(
      from: Rails.application.config.mail_sender,
      to: user.email,
      subject: I18n.t('notifications.thread_moved',
                      subject: @thread.messages.first.subject,
                      old_forum: @old_forum.name,
                      new_forum: @new_forum.name)
    )
  end
end

# eof
