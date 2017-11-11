FactoryBot.define do
  factory :medium do
    filename Rails.root + 'public/images/medium/missing.png'
    orig_name 'foo.png'
    content_type 'image/png'
  end
end

# eof
