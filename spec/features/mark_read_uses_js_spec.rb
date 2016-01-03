# -*- coding: utf-8 -*-

require "rails_helper"

include Warden::Test::Helpers
Warden.test_mode!

describe "marking as read uses JS" do
  let(:message) { create(:cf_message) }
  let(:user) { create(:cf_user) }

  before(:each) { login_as(user , scope: :user) }

  include CForum::Tools

  it "doesn't reload when clicking the mark read icon", js: true do
    visit cf_forum_path(message.forum)

    page.find('#t' + message.thread_id.to_s + ' .icon-thread.mark-thread-read').click
    wait_for_ajax
    expect(page.body).to have_css('#m' + message.message_id.to_s + '.visited')
  end

end

# eof
