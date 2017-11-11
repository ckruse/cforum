FactoryBot.define do
  factory :user do
    username
    email
    password 'some password'

    admin false
    active true
    confirmed_at DateTime.now
  end

  factory :user_admin, parent: :user do
    admin true
  end

  factory :user_moderator, parent: :user do
    badges do
      b = Badge.where(badge_type: Badge::MODERATOR_TOOLS).first
      b = create(:badge, badge_type: Badge::MODERATOR_TOOLS) if b.blank?
      [b]
    end
  end
end

# eof
