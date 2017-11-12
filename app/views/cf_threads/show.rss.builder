xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom' do
  xml.channel do
    xml.title @thread.message.subject + ' - ' + @thread.forum.name
    xml.description 'Thread-Feed' # TODO
    xml.link message_url(@thread, @thread.message)
    xml.tag!('atom:link',
             rel: 'self',
             type: 'application/rss+xml',
             href: message_url(@thread, @thread.message, format: :rss))

    @thread.sorted_messages.each do |msg|
      xml.item do
        xml.title msg.subject
        xml.description msg.to_html(@app_controller)
        xml.pubDate msg.created_at.to_s(:rfc822)
        xml.link message_url(@thread, msg)
        xml.guid message_url(@thread, msg)
      end
    end
  end
end
