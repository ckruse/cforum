# -*- coding: utf-8 -*-

FactoryGirl.define do
  sequence(:tag_name) { |n| "Tag #{n}" }

  factory :cf_tag do
    tag_name { generate(:tag_name) }
    association :forum
  end
end


# eof
