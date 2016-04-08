# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :group do
    name { generate(:group_name) }
  end

  factory :forum_group_permission do
    permission ForumGroupPermission::ACCESS_READ

    association :group, factory: :group
    association :forum, factory: :forum
  end

  factory :forum_group_write_permission, class: ForumGroupPermission do
    permission ForumGroupPermission::ACCESS_WRITE

    association :group, factory: :group
    association :forum, factory: :forum
  end

  factory :forum_group_moderate_permission, class: ForumGroupPermission do
    permission ForumGroupPermission::ACCESS_MODERATE

    association :group, factory: :group
    association :forum, factory: :forum
  end
end

# eof
