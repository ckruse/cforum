FactoryBot.define do
  sequence(:random_cite) do |_n|
    Faker::Lorem.paragraphs.join("\n\n")
  end

  factory :cite do
    sequence(:author) { |n| "Author #{n}" }
    cite { generate(:random_cite) }
    url 'http://example.org/'
    cite_date { DateTime.now }
  end
end

# eof
