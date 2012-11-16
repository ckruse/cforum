# -*- coding: utf-8 -*-

FactoryGirl.define do
  sequence :forum_name do |n|
    "Forum #{n}"
  end

  sequence(:random_string) do |n|
    LoremIpsum.generate
  end

  sequence :email do |n|
    "person#{n}@example.com"
  end

  sequence :username do |n|
    "user#{n}"
  end

end

# eof
