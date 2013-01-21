# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_vote do
    vtype CfVote::UPVOTE

    association :user, :factory => :cf_user
    association :message, :factory => :cf_message
  end
end


# eof
