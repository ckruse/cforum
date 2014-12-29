# -*- coding: utf-8 -*-

FactoryGirl.define do
  sequence :forum_name do |n|
    "Forum #{n}"
  end

  sequence :badge_name do |n|
    "Badge #{n}"
  end

  sequence :tag_name do |n|
    "tag #{n}"
  end

  sequence(:random_string) do |n|
    Faker::Lorem.paragraphs.join("\n\n")
  end

  sequence :email do |n|
    "person#{n}@example.com"
  end

  sequence :username do |n|
    "user#{n}"
  end

  sequence(:thread_slug) do |n|
    "thread-#{n}"
  end

  sequence :group_name do |n|
    "Group #{n}"
  end
end

# eof
