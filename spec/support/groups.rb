# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_group do
    name { generate(:group_name) }
  end

  factory :cf_forum_group_permission do
    permission CfForumGroupPermission::ACCESS_READ

    association :group, factory: :cf_group
    association :forum, factory: :cf_forum
  end

  factory :cf_forum_group_write_permission, class: CfForumGroupPermission do
    permission CfForumGroupPermission::ACCESS_WRITE

    association :group, factory: :cf_group
    association :forum, factory: :cf_forum
  end

  factory :cf_forum_group_moderate_permission, class: CfForumGroupPermission do
    permission CfForumGroupPermission::ACCESS_MODERATE

    association :group, factory: :cf_group
    association :forum, factory: :cf_forum
  end
end

# eof
