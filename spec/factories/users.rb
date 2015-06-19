# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :cf_user do
    username
    email
    password "some password"

    admin false
    active true
    confirmed_at DateTime.now
  end

  factory :cf_user_admin, parent: :cf_user do
    admin true
  end

  factory :cf_user_moderator, parent: :cf_user do
    badges { [create(:cf_badge, badge_type: RightsHelper::MODERATOR_TOOLS)] }
  end
end


# eof
