FactoryBot.define do
  factory :priv_message do
    subject 'Use the force!'
    body { generate(:random_string) }

    association :sender, factory: :user
    association :recipient, factory: :user
    owner_id { sender_id }

    sender_name { sender.username }
    recipient_name { recipient.username }
  end
end

# eof
