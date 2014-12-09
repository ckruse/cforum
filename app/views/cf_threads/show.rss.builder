xml.instruct! :xml, :version => "1.0"
xml.rss version: '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom' do
  xml.channel do
    xml.title @thread.message.subject + ' - ' + @thread.forum.name
    xml.description "Thread-Feed" # TODO
    xml.link cf_message_url(@thread, @thread.message)
    xml.tag! 'atom:link', rel: 'self', type: 'application/rss+xml', href: cf_message_url(@thread, @thread.message, format: :rss)

    for msg in @thread.sorted_messages
      xml.item do
        xml.title msg.subject
        xml.description msg.to_html(self)
        xml.pubDate msg.created_at.to_s(:rfc822)
        xml.link cf_message_url(@thread, msg)
        xml.guid cf_message_url(@thread, msg)
      end
    end
  end
end
