require 'rails_helper'

RSpec.describe 'highlights users when configured' do
  let(:user) { create(:user, username: 'foo') }
  let(:user1) { create(:user, username: 'bar') }
  let(:message) do
    create(:message,
           content: 'blah blub bar @bar',
           author: 'bar',
           owner: user1,
           flags: { mentions: [['bar', user1.user_id, false]] })
  end
  before(:each) do
    login_as(user)
    Setting.create!(user_id: user.user_id, options: { 'highlighted_users' => 'foo,bar' })
  end

  include ApplicationHelper

  it 'highlights self in message' do
    visit(message_path(message.thread, message))
    expect(page.find('.root')).to have_css('.highlighted-user.' + user_to_class_name(message.author))
    expect(page.find('.thread-message:not(.preview) .posting-content'))
      .to have_css('.highlighted-user.' + user_to_class_name(message.author))
  end
  it 'highlights self in thread tree' do
    visit(forum_path(message.forum))
    expect(page.find('.root')).to have_css('.highlighted-user.' + user_to_class_name(message.author))
  end
end
