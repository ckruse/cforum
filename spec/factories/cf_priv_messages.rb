# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_priv_message do
    subject "Use the force!"
    body { generate(:random_string) }

    association :sender, factory: :cf_user
    association :recipient, factory: :cf_user
    owner_id { sender_id }

    sender_name { sender.username }
    recipient_name { recipient.username }
  end
end


# eof
