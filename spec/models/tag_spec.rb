# -*- coding: utf-8 -*-

require 'rails_helper'

RSpec.describe Tag, type: :model do
  it "is valid with forum_id, tag_name" do
    expect(Tag.new(forum_id: 1, tag_name: 'Rebellion')).to be_valid
  end

  it "is invalid wo forum_id" do
    expect(Tag.new(tag_name: 'Rebellion')).to be_invalid
  end

  it "is invalid wo tag_name" do
    expect(Tag.new(forum_id: 1)).to be_invalid
  end
end

# eof
