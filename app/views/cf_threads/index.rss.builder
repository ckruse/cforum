xml.instruct! :xml, :version => "1.0"
xml.rss :version => '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom' do
  xml.channel do
    xml.title current_forum ? current_forum.name : t('views.all_forums')
    xml.description current_forum ? current_forum.description : t('views.all_forums')
    xml.link cf_forum_url(current_forum || 'all')
    xml.tag! 'atom:link', :rel => 'self', :type => 'application/rss+xml', :href => cf_forum_url(current_forum || 'all') + '.json'

    for thread in @threads
      xml.item do
        xml.title thread.message.subject
        xml.description thread.message.to_html
        xml.pubDate thread.created_at.to_s(:rfc822)
        xml.link cf_message_url(thread, thread.message)
        xml.guid cf_message_url(thread, thread.message)
      end
    end
  end
end
