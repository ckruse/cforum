# -*- coding: utf-8 -*-

require 'rails_helper'

RSpec.describe CfGroup, type: :model do
  it "is valid with a name" do
    expect(CfGroup.new(name: 'Rebellion')).to be_valid
  end

  it "is invalid wo a name" do
    expect(CfGroup.new).to be_invalid
  end

  it "is invalid with a too long name" do
    expect(CfGroup.new(name: 'Rebellion' * 255)).to be_invalid
  end

  it "is invalid with a duplicate name" do
    CfGroup.create!(name: 'Rebellion')
    expect(CfGroup.new(name: 'Rebellion')).to be_invalid
  end
end

# eof
