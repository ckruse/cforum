# -*- coding: utf-8 -*-

require "rails_helper"

include Warden::Test::Helpers
Warden.test_mode!

describe "opening/closing threads uses JS" do
  let(:message) { create(:cf_message) }
  let(:user) { create(:cf_user) }

  before(:each) { login_as(user , scope: :user) }

  include CForum::Tools

  it "doesn't reload when clicking the open/close icon", js: true do
    visit cf_forum_path(message.forum)

    page.find('#t' + message.thread_id.to_s + ' .icon-thread.open').click
    sleep 0.5
    expect(page.body).to have_css('#t' + message.thread_id.to_s + ' .icon-thread.closed')

    page.find('#t' + message.thread_id.to_s + ' .icon-thread.closed').click
    sleep 0.5
    expect(page.body).to have_css('#t' + message.thread_id.to_s + ' .icon-thread.open')
  end

end

# eof
