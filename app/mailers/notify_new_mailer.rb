class NotifyNewMailer < ActionMailer::Base
  def new_message(user, thread, parent, message, url, txt_content)
    @user    = user
    @thread  = thread
    @parent  = parent
    @message = message
    @url     = url
    @txt     = txt_content

    headers['Message-Id'] = '<t' + @message.thread_id.to_s + 'm' +
                            @message.message_id.to_s + '@' +
                            Rails.application.config.mid_host + '>'
    headers['In-Reply-To'] = '<t' + @parent.thread_id.to_s + 'm' +
                             @parent.message_id.to_s + '@' +
                             Rails.application.config.mid_host + '>'

    mail(
      from: Rails.application.config.mail_sender,
      to: user.email,
      subject: 'RE: ' + @message.subject
    )
  end

  def new_answer(user, thread, parent, message, url, txt_content)
    @user    = user
    @thread  = thread
    @parent  = parent
    @message = message
    @url     = url
    @txt     = txt_content

    headers['Message-Id'] = '<t' + @message.thread_id.to_s + 'm' +
                            @message.message_id.to_s + '@' +
                            Rails.application.config.mid_host + '>'
    headers['In-Reply-To'] = '<t' + @parent.thread_id.to_s + 'm' +
                             @parent.message_id.to_s + '@' +
                             Rails.application.config.mid_host + '>'

    mail(
      from: Rails.application.config.mail_sender,
      to: user.email,
      subject: 'RE: ' + @message.subject
    )
  end

  def new_mention(user, thread, message, url, txt_content)
    @user    = user
    @thread  = thread
    @message = message
    @url     = url
    @txt     = txt_content

    headers['Message-Id'] = '<t' + @message.thread_id.to_s + 'm' +
                            @message.message_id.to_s + '@' +
                            Rails.application.config.mid_host + '>'

    mail(
      from: Rails.application.config.mail_sender,
      to: user.email,
      subject: 'RE: ' + @message.subject
    )
  end

  def new_cite(user, cite, url)
    @user  = user
    @cite  = cite
    @url   = url

    headers['Message-Id'] = '<cite' + @cite.cite_id.to_s + '@' + Rails.application.config.mid_host + '>'

    mail(
      from: Rails.application.config.mail_sender,
      to: user.email,
      subject: I18n.t('cites.new_cite_arrived')
    )
  end
end

# eof
