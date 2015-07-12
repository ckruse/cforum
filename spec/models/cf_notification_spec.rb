# -*- coding: utf-8 -*-

require 'rails_helper'

RSpec.describe CfNotification, type: :model do
  it "is valid with subject, path, recipient_id, oid and otype" do
    expect(CfNotification.new(subject: "Attack on Alderan",
                              path: '/alderan',
                              recipient_id: 0,
                              oid: 0,
                              otype: 'attack')).to be_valid
  end

  it "is invalid wo subject" do
    expect(CfNotification.new(path: '/alderan',
                              recipient_id: 0,
                              oid: 0,
                              otype: 'attack')).to be_invalid
  end

  it "is invalid wo path" do
expect(CfNotification.new(subject: "Attack on Alderan",
                              recipient_id: 0,
                              oid: 0,
                              otype: 'attack')).to be_invalid
  end

  it "is invalid wo recipient_id" do
    expect(CfNotification.new(subject: "Attack on Alderan",
                              path: '/alderan',
                              oid: 0,
                              otype: 'attack')).to be_invalid
  end

  it "is invalid wo oid" do
expect(CfNotification.new(subject: "Attack on Alderan",
                              path: '/alderan',
                              recipient_id: 0,
                              otype: 'attack')).to be_invalid
  end

  it "is invalid wo otype" do
    expect(CfNotification.new(subject: "Attack on Alderan",
                              path: '/alderan',
                              recipient_id: 0,
                              oid: 0)).to be_invalid
  end
end

# eof
