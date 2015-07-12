# -*- coding: utf-8 -*-

require 'rails_helper'

RSpec.describe CfTag, type: :model do
  it "is valid with forum_id, tag_name" do
    expect(CfTag.new(forum_id: 1, tag_name: 'Rebellion')).to be_valid
  end

  it "is invalid wo forum_id" do
    expect(CfTag.new(tag_name: 'Rebellion')).to be_invalid
  end

  it "is invalid wo tag_name" do
    expect(CfTag.new(forum_id: 1)).to be_invalid
  end
end

# eof
