atom_feed do |feed|
  feed.title current_forum ? current_forum.name : t('views.all_forums')
  feed.updated(@threads[0].created_at) if @threads.length > 0

  @threads.each do |thread|
    feed.entry(thread) do |entry|
      entry.title(thread.message.subject)
      entry.content(message_to_html(thread.message.content), :type => 'html')

      entry.author do |author|
        author.name thread.message.author
        author.email thread.message.email unless thread.message.email.blank?
      end
    end
  end
end