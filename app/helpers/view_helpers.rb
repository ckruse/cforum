# -*- coding: utf-8 -*-

module ViewHelpers
  def message_header(thread, message, first = false)
    html = "<header>"

    if first
      html << "  <h2>" + link_to(message.subject, cf_message_path(thread, message)) + "</h2>"
    else
      html << "  <h3>" + link_to(message.subject, cf_message_path(thread, message)) + "</h3>"
    end

    html << %q{
  <details open>
    <summary>
      } + t("messages.by") + %q{
      } + (message.user_id ? link_to(message.author, user_path(message.owner)) : encode_entities(message.author)) + %q{,
      <time datetime="} + message.created_at.to_s + '">' + encode_entities(l(message.created_at))

    if current_user.admin? or current_user.moderate?(current_forum)
      html << " " + link_to('', cf_message_path(thread, message), data: {confirm: t('views.are_you_sure')}, :method => :delete, :class => 'icon icon-trash')
    end

    html << %q{</time>
    </summary>
  </details>
</header>}

    html.html_safe
  end

  def message_tree(thread, messages)
    html = "<ol>\n"
    messages.each do |message|
      html << "<li>"
      html << message_header(thread, message)
      html << message_tree(thread, message.messages) unless message.messages.blank?
      html << "</li>"
    end

    html << "\n</ol>"

    html.html_safe
  end
end

# eof