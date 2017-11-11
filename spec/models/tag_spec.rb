require 'rails_helper'

RSpec.describe Tag, type: :model do
  it 'is valid with forum_id, tag_name' do
    expect(Tag.new(forum_id: 1, tag_name: 'Rebellion')).to be_valid
  end

  it 'is invalid wo forum_id' do
    expect(Tag.new(tag_name: 'Rebellion')).to be_invalid
  end

  it 'is invalid wo tag_name' do
    expect(Tag.new(forum_id: 1)).to be_invalid
  end

  it 'returns the slug for to_param' do
    tag = build(:tag)
    expect(tag.to_param).to eq tag.slug
  end

  it 'generates the slug by the tag name' do
    f = create(:forum)
    t = Tag.create!(forum_id: f.forum_id, tag_name: 'Rebellion')
    expect(t.slug).to eq 'Rebellion'.to_url
  end
end

# eof
