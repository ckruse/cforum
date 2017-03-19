# -*- coding: utf-8 -*-

module UserDataHelper
  def gen_content(content, name, std_replacement = '')
    content ||= ''

    if current_user
      greeting  = uconf('greeting')
      farewell  = uconf('farewell')
      signature = uconf('signature')

      unless greeting.blank?
        if name.blank?
          greeting.gsub!(/\s*\{\$name\}/, std_replacement)
          greeting.gsub!(/\s*\{\$vname\}/, std_replacement)
        else
          greeting.gsub!(/\{\$name\}/, name)
          greeting.gsub!(/\{\$vname\}/, name.gsub(/\s.*/, ''))
        end

        content = greeting + "\n" + content
      end

      content = content + "\n" + farewell unless farewell.blank?
      content = content + "\n-- \n" + signature unless signature.blank?
    end

    content
  end

  def set_user_data_vars(msg, parent = nil)
    if user = current_user
      msg.email    ||= user.conf('email')
      msg.homepage ||= user.conf('url')

      msg.content = gen_content(msg.content, parent.try(:author),
                                ' ' + I18n.t('plugins.user_data.all'))

    else
      msg.author    ||= cookies[:cforum_author]
      msg.email     ||= cookies[:cforum_email]
      msg.homepage  ||= cookies[:cforum_homepage]
    end
  end
end

# eof
