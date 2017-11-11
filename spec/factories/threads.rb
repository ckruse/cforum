FactoryBot.define do
  sequence(:thread_slug) do |n|
    "thread-#{n}"
  end

  factory :cf_thread do
    slug do
      n = DateTime.now
      n.strftime('/%Y/%b/').downcase + n.day.to_s + '/' + generate(:thread_slug)
    end

    association :forum, factory: :write_forum
    archived false
    latest_message { DateTime.now }
  end
end

# eof
