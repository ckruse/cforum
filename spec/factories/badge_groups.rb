# -*- coding: utf-8 -*-

FactoryBot.define do
  factory :badge_group do
    name { generate(:badge_group_name) }
  end
end

# eof
