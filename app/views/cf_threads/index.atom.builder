atom_feed do |feed|
  feed.title current_forum ? current_forum.name : t('forums.all_forums')
  feed.updated(@threads[0].created_at) if @threads.length > 0

  @threads.each do |thread|
    feed.entry(thread) do |entry|
      entry.title(thread.message.subject)
      entry.content(thread.message.to_html, :type => 'html')

      entry.author do |author|
        author.name thread.message.author
        author.email thread.message.email unless thread.message.email.blank?
      end
    end
  end
end
