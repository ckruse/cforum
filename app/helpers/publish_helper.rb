# -*- coding: utf-8 -*-

require 'net/http'

module PublishHelper
  def publish(event, message, recipient = :all)
    if @_faye_secret.blank?
      @_faye_secret = IO.read(Rails.root + 'config/faye.secret', coding: 'utf-8')
    end

    message = { event: event, data: message, secret: @_faye_secret, for: recipient }
    uri = URI.parse(Rails.application.config.internal_faye_url)

    http = Net::HTTP.new(uri.host, uri.port)
    post = Net::HTTP::Post.new(uri.request_uri)
    post.body = message.to_json
    post['Content-Type'] = 'application/json'
    http.request(post)
  rescue
  end
end

# eof
