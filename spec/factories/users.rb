# -*- coding: utf-8 -*-

FactoryGirl.define do
  factory :user do
    username
    email
    password "some password"

    admin false
    active true
    confirmed_at DateTime.now
  end

  factory :user_admin, parent: :user do
    admin true
  end

  factory :user_moderator, parent: :user do
    badges { [create(:badge, badge_type: Badge::MODERATOR_TOOLS)] }
  end
end


# eof
