FactoryBot.define do
  factory :mod_queue_entry, class: ModerationQueueEntry do
    reason 'off-topic'
    reported 1
    association :message, factory: :message
  end

  factory :mod_queue_entry_cleared, class: ModerationQueueEntry do
    reason 'off-topic'
    reported 1
    closer_name { closer.username }
    cleared true
    resolution_action 'close'
    resolution Faker::Lorem.paragraph

    association :message, factory: :message
    association :closer, factory: :user_moderator
  end
end

# eof
