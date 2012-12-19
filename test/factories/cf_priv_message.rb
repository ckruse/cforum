# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_priv_message do
    subject "Use the force!"
    body { generate(:random_string) }
    is_read false

    association :sender, :factory => :cf_user
    association :recipient, :factory => :cf_user
  end
end


# eof
