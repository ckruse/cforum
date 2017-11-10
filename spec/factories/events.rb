
FactoryBot.define do
  sequence(:random_event_desc) do |_n|
    Faker::Lorem.paragraphs.join("\n\n")
  end

  factory :event do
    sequence(:name) { |n| "Event #{n}" }
    start_date Time.zone.now.to_date
    end_date Time.zone.now.to_date
    visible true
    description { generate(:random_event_desc) }
  end
end
