FactoryBot.define do
  sequence(:section_name) { |n| "Search Section #{n}" }

  factory :search_section do
    name { generate(:section_name) }
    position 0
  end
end

# eof
