# -*- coding: utf-8 -*-

class HttpUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    begin
      uri  = URI.parse(value)
      resp = uri.kind_of?(URI::HTTP)
    rescue URI::InvalidURIError
      resp = false
    end

    record.errors[attribute] << (options[:message] || "is not an url") unless resp
  end
end

# eof