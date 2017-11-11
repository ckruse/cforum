require 'rails_helper'

RSpec.describe Badge, type: :model do
  it 'is valid with name, slug, score_needed, badge_type, badge_medal_type' do
    expect(Badge.new(name: 'Golden Star',
                     score_needed: 10_000,
                     slug: 'golden-star',
                     badge_type: 'custom',
                     badge_medal_type: 'gold')).to be_valid
  end

  it 'is invalid wo name' do
    expect(Badge.new(score_needed: 10_000,
                     slug: 'golden-star',
                     badge_type: 'custom',
                     badge_medal_type: 'gold')).to be_invalid
  end

  it 'is invalid wo slug' do
    expect(Badge.new(name: 'Golden Star',
                     score_needed: 10_000,
                     badge_type: 'custom',
                     badge_medal_type: 'gold')).to be_invalid
  end

  it 'is valid wo score_needed' do
    expect(Badge.new(name: 'Golden Star',
                     slug: 'golden-star',
                     badge_type: 'custom',
                     badge_medal_type: 'gold')).to be_valid
  end

  it 'is invalid wo badge_type' do
    expect(Badge.new(name: 'Golden Star',
                     score_needed: 10_000,
                     slug: 'golden-star',
                     badge_medal_type: 'gold')).to be_invalid
  end

  it 'is invalid wo badge_medal_type' do
    expect(Badge.new(name: 'Golden Star',
                     score_needed: 10_000,
                     slug: 'golden-star',
                     badge_type: 'custom',
                     badge_medal_type: nil)).to be_invalid
  end

  it 'is invalid with a float as score_needed' do
    expect(Badge.new(name: 'Golden Star',
                     score_needed: 10.3,
                     slug: 'golden-star',
                     badge_type: 'custom',
                     badge_medal_type: 'gold')).to be_invalid
  end

  it 'is invalid with a to long name' do
    expect(Badge.new(name: 'Golden Star' * 255,
                     score_needed: 10_000,
                     slug: 'golden-star',
                     badge_type: 'custom',
                     badge_medal_type: 'gold')).to be_invalid
  end

  it 'is invalid with an invalid badge_type' do
    expect(Badge.new(name: 'Golden Star',
                     score_needed: 10_000,
                     slug: 'golden-star',
                     badge_type: 'wefwefwef',
                     badge_medal_type: 'gold')).to be_invalid
  end

  it 'is invalid with an invalid badge_medal_type' do
    expect(Badge.new(name: 'Golden Star',
                     score_needed: 10_000,
                     slug: 'golden-star',
                     badge_type: 'custom',
                     badge_medal_type: 'red')).to be_invalid
  end
end

# eof
