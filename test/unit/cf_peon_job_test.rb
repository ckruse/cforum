# -*- coding: utf-8 -*-

require 'test_helper'

class CfPeonJobTest < ActiveSupport::TestCase
  test "test validations" do
    job = CfPeonJob.new

    assert !job.save

    job.queue_name = 'test'
    assert !job.save

    job.class_name = "lulu"
    assert !job.save

    job.arguments = '{}'
    assert job.save
  end
end


# eof
