# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_forum do
    name { generate(:forum_name) }
    short_name { name }
    slug { name.downcase.gsub(/ /, '-') }
    description { generate(:forum_name) }
  end
end


# eof
