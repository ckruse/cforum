# -*- coding: utf-8 -*-

module ReferencesHelper
  def mid_from_uri(uri)
    uri = uri.gsub(/#.*$/, '')
    return Regexp.last_match(1).to_i if uri =~ /\/m?(\d+)$/
    nil
  end

  def find_links(content)
    doc = Nokogiri::HTML(content)

    doc.css('span.signature').remove
    doc.css('blockquote').remove

    links = doc.xpath('//a')
    links = links.select { |l| !l['href'].blank? }
    links.map { |l| l['href'] }
  end

  def is_reference_uri(uri, hosts)
    parsed_uri = URI.parse(uri)
    hosts.include?(parsed_uri.host) && (parsed_uri.path =~ /^\/[\w-]+\/\d{4}\/\w{3}\/\d+\/[\w-]+\/\d+$/ || parsed_uri.path =~ /^\/m\d+$/)
  end

  def find_references(content, hosts)
    hosts = [hosts] unless hosts.is_a?(Array)
    links = find_links(content)

    links.select do |l|
      begin
        is_reference_uri(l, hosts)
      rescue
        false
      end
    end
  end

  def save_references(message)
    MessageReference.where(src_message_id: message.message_id).delete_all unless message.message_id.blank?
    references = find_references(message.to_html(self), URI.parse(root_url).hostname)

    return if references.blank?

    already_referenced = []

    references.each do |ref|
      mid = mid_from_uri(ref)
      next if mid.blank?
      next if already_referenced.include?(mid)
      next unless Message.where(message_id: mid).exists?

      MessageReference.create!(src_message_id: message.message_id,
                               dst_message_id: mid,
                               created_at: DateTime.now,
                               updated_at: DateTime.now)
      already_referenced << mid
    end
  end
end

# eof
