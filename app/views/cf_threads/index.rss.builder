xml.instruct! :xml, version: '1.0'
xml.rss :version => '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom' do
  xml.channel do
    xml.title current_forum ? current_forum.name : t('forums.all_forums')
    xml.description current_forum ? current_forum.description : t('forums.all_forums')
    xml.link forum_url(current_forum)
    xml.tag! 'atom:link', rel: 'self', type: 'application/rss+xml', href: forum_url(current_forum, format: :rss)

    @threads.each do |thread|
      xml.item do
        xml.title thread.message.subject
        xml.description thread.message.to_html(@app_controller)
        xml.pubDate thread.created_at.to_s(:rfc822)
        xml.link message_url(thread, thread.message)
        xml.guid message_url(thread, thread.message)
      end
    end
  end
end
