module UserDataHelper
  def gen_content(content, name, std_replacement = '')
    content ||= ''

    if current_user.present?
      greeting  = uconf('greeting')
      farewell  = uconf('farewell')
      signature = uconf('signature')

      if greeting.present?
        if name.blank?
          greeting.gsub!(/\s*\{\$name\}/, std_replacement)
          greeting.gsub!(/\s*\{\$vname\}/, std_replacement)
        else
          greeting.gsub!(/\{\$name\}/, name)
          greeting.gsub!(/\{\$vname\}/, name.gsub(/\s.*/, ''))
        end

        content = greeting + "\n" + content
      end

      content = content + "\n" + farewell if farewell.present?
      content = content + "\n-- \n" + signature if signature.present?
    end

    content
  end

  def set_user_data_vars(msg, parent = nil)
    if current_user.present?
      msg.email    ||= current_user.conf('email')
      msg.homepage ||= current_user.conf('url')

      msg.content = gen_content(msg.content, parent.try(:author), ' ' + I18n.t('plugins.user_data.all'))

    else
      msg.author    ||= cookies[:cforum_author]
      msg.email     ||= cookies[:cforum_email]
      msg.homepage  ||= cookies[:cforum_homepage]
    end
  end
end

# eof
