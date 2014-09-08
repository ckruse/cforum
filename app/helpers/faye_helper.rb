# -*- coding: utf-8 -*-

require 'net/http'

module FayeHelper

  def publish(channel, message)
    if @_faye_secret.blank?
      @_faye_secret = IO.read(Rails.root + 'config/faye.secret', coding: "utf-8")
    end

    message = {:channel => channel, :data => message, :ext => {:password => @_faye_secret}}
    uri = URI.parse(Rails.application.config.faye_url)

    Net::HTTP.post_form(uri, :message => message.to_json)
  rescue
  end

end

# eof
