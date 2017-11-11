FactoryBot.define do
  sequence(:notification_subject) do |n|
    "Subject #{n}"
  end

  factory :notification do
    subject { generate(:notification_subject) }
    path '/foo/bar'
    association :recipient, factory: :user
    oid 0
    otype 'none'
  end
end

# eof
