# -*- coding: utf-8 -*-

FactoryGirl.define do
  sequence(:thread_slug) do |n|
    "thread-#{n}"
  end

  factory :cf_thread do
    slug {
      n = DateTime.now
      n.strftime("/%Y/%b/").downcase + n.day.to_s + "/" + generate(:thread_slug)
    }

    association :forum, factory: :write_forum
    archived false
    latest_message { DateTime.now }
  end
end


# eof
