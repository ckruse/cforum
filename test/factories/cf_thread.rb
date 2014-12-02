# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_thread do
    slug {
      n = DateTime.now
      n.strftime("/%Y/%b/").downcase + n.strftime("%d/").gsub('/^0+', '') + generate(:thread_slug)
    }

    association :forum, :factory => :cf_write_forum
    archived false
    latest_message { DateTime.now }
  end
end


# eof
