# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_group do
    name { generate(:group_name) }
  end
end


# eof
