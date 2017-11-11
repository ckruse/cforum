atom_feed do |feed|
  feed.title current_forum ? current_forum.name : t('forums.all_forums')
  feed.updated(@threads[0].created_at) unless @threads.empty?

  @threads.each do |thread|
    feed.entry(thread, id: message_url(thread, thread.message),
                       url: message_url(thread, thread.message),
                       published: thread.created_at,
                       updated: thread.sorted_messages.last.updated_at) do |entry|
      entry.title(thread.message.subject)
      entry.content(thread.message.to_html(@app_controller), type: 'html')

      entry.author do |author|
        author.name thread.message.author
        author.email thread.message.email if thread.message.email.present?
      end
    end
  end
end
