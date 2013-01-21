# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_score do
    value 10

    association :user, :factory => :cf_user
    association :vote, :factory => :cf_vote
  end
end


# eof
