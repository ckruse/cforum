require 'rails_helper'

describe 'opening/closing threads uses JS' do
  let(:message) { create(:message) }
  let(:user) { create(:user) }

  before(:each) { login_as(user, scope: :user) }

  include CForum::Tools

  it "doesn't reload when clicking the open/close icon", js: true do
    visit forum_path(message.forum)

    page.find('#t' + message.thread_id.to_s + ' .icon-thread.open').click
    wait_for_ajax
    expect(page.body).to have_css('#t' + message.thread_id.to_s + ' .icon-thread.closed')

    page.find('#t' + message.thread_id.to_s + ' .icon-thread.closed').click
    wait_for_ajax
    expect(page.body).to have_css('#t' + message.thread_id.to_s + ' .icon-thread.open')
  end
end

# eof
