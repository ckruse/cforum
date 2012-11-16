# -*- coding: utf-8 -*-

FactoryGirl.define do
  sequence :email do |n|
    "person#{n}@example.com"
  end

  sequence :username do |n|
    "user#{n}"
  end

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