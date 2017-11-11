FactoryBot.define do
  factory :group do
    name { generate(:group_name) }
  end

  factory :forum_group_permission do
    permission ForumGroupPermission::READ

    association :group, factory: :group
    association :forum, factory: :forum
  end

  factory :forum_group_write_permission, class: ForumGroupPermission do
    permission ForumGroupPermission::WRITE

    association :group, factory: :group
    association :forum, factory: :forum
  end

  factory :forum_group_moderate_permission, class: ForumGroupPermission do
    permission ForumGroupPermission::MODERATE

    association :group, factory: :group
    association :forum, factory: :forum
  end
end

# eof
