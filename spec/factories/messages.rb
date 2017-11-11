FactoryBot.define do
  sequence(:random_string) do |_n|
    Faker::Lorem.paragraphs.join("\n\n")
  end

  factory :message do
    subject 'Use the force!'
    content { generate(:random_string) }
    author 'Obi-Wan'
    deleted false

    association :thread, factory: :cf_thread
    association :owner, factory: :user
    forum { |m| m.thread.forum }
  end
end

# eof
