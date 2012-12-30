# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_tag do
    tag_name { generate(:tag_name) }
    slug { tag_name.parameterize }

    association :forum, :factory => :cf_forum
  end
end


# eof
