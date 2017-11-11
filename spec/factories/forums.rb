FactoryBot.define do
  factory :forum do
    name { generate(:forum_name) }
    short_name { name }
    slug { name.downcase.tr(' ', '-') }
    description { generate(:forum_name) }
    standard_permission 'private'
  end

  factory :read_forum, parent: :forum do
    standard_permission ForumGroupPermission::READ
  end

  factory :known_read_forum, parent: :forum do
    standard_permission ForumGroupPermission::KNOWN_READ
  end

  factory :write_forum, parent: :forum do
    standard_permission ForumGroupPermission::WRITE
  end

  factory :known_write_forum, parent: :forum do
    standard_permission ForumGroupPermission::KNOWN_WRITE
  end

  factory :moderate_forum, parent: :forum do
    standard_permission ForumGroupPermission::MODERATE
  end
end

# eof
