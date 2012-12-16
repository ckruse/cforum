# -*- coding: utf-8 -*-

class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    begin
      uri  = URI.parse(value)
      resp = true
    rescue URI::InvalidURIError
      resp = false
    end

    record.errors[attribute] << (options[:message] || "is not an url") unless resp
  end
end

# eof