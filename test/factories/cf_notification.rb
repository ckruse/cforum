# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_notification do
    subject "Use the force!"
    path '/some/path'
    is_read false

    association :recipient, :factory => :cf_user
  end
end


# eof
