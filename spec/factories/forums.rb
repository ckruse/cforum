# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_forum do
    name { generate(:forum_name) }
    short_name { name }
    slug { name.downcase.gsub(/ /, '-') }
    description { generate(:forum_name) }
    standard_permission 'private'
  end

  factory :cf_read_forum, parent: :cf_forum do
    standard_permission CfForumGroupPermission::ACCESS_READ
  end

  factory :cf_known_read_forum, parent: :cf_forum do
    standard_permission CfForumGroupPermission::ACCESS_KNOWN_READ
  end

  factory :cf_write_forum, parent: :cf_forum do
    standard_permission CfForumGroupPermission::ACCESS_WRITE
  end

  factory :cf_known_write_forum, parent: :cf_forum do
    standard_permission CfForumGroupPermission::ACCESS_KNOWN_WRITE
  end

end


# eof
