# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_user do
    username
    email
    password "some password"

    admin true
    active true
    confirmed_at DateTime.now
  end
end


# eof
