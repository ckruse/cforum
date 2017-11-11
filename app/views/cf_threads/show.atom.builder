atom_feed do |feed|
  feed.title @thread.message.subject + ' - ' + @thread.forum.name
  feed.updated(@thread.sorted_messages.last.created_at)

  @thread.sorted_messages.each do |msg|
    feed.entry(msg, id: message_url(@thread, msg),
                    url: message_url(@thread, msg),
                    published: msg.created_at,
                    updated: msg.updated_at) do |entry|
      entry.title(msg.subject)
      entry.content(msg.to_html(@app_controller), type: 'html')

      entry.author do |author|
        author.name msg.author
        author.email msg.email if msg.email.present?
      end
    end
  end
end
