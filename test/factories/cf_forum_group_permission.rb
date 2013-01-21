# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_forum_group_permission do
    permission CfForumGroupPermission::ACCESS_READ

    association :group, :factory => :cf_group
    association :forum, :factory => :cf_forum
  end
end

# eof
