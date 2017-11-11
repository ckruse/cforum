FactoryBot.define do
  sequence :username do |n|
    "user#{n}"
  end

  sequence :email do |n|
    "person#{n}@example.com"
  end

  sequence :forum_name do |n|
    "Forum #{n}"
  end

  sequence :badge_name do |n|
    "Badge #{n}"
  end

  sequence :group_name do |n|
    "Group #{n}"
  end

  sequence :badge_group_name do |n|
    "Badge Group #{n}"
  end
end

# eof
