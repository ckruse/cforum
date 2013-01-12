# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_thread do
    slug { generate :thread_slug }
    association :forum, :factory => :cf_write_forum
    archived false
  end
end


# eof
