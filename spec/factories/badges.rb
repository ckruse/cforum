FactoryBot.define do
  factory :badge do
    score_needed { 10 }
    name { generate(:badge_name) }
    slug { name.parameterize }
    badge_type { Badge::UPVOTE }
    badge_medal_type { 'bronze' }
  end
end

# eof
