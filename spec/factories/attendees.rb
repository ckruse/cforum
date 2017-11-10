FactoryBot.define do
  sequence(:attendee_name) do |n|
    "Attendee #{n}"
  end

  factory :attendee do
    name { generate(:attendee_name) }
    planned_arrival { Time.zone.now }

    association :event, factory: :event
  end
end
