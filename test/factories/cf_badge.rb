# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_badge do
    score_needed { 10 }
    name { generate(:badge_name) }
    slug { name.parameterize }
    badge_type { RightsHelper::UPVOTE }
    badge_medal_type { "bronze" }
  end
end


# eof
