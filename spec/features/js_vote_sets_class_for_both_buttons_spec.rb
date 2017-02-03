# -*- coding: utf-8 -*-

require 'rails_helper'

describe 'marking as read uses JS' do
  let(:message) { create(:message) }
  let(:message1) { create(:message, parent_id: message.message_id, thread: message.thread, forum: message.forum) }
  let(:user) { create(:user_admin) }

  before(:each) do
    Score.create(user_id: user.user_id, value: 200)
    login_as(user, scope: :user)
  end

  include CForum::Tools

  it 'sets both classes when clicking upper vote up', js: true do
    visit message_path(message.thread, message)

    page.find('.thread-message:first-of-type .posting-header .icon-vote-up').click
    wait_for_ajax
    expect(page.body).to have_css('.thread-message:first-of-type .posting-header .icon-vote-up.active')
    expect(page.body).to have_css('.thread-message:first-of-type .posting-footer .icon-vote-up.active')
  end

  it 'sets both classes when clicking lower vote up', js: true do
    visit message_path(message.thread, message)

    page.find('.thread-message:first-of-type .posting-footer .icon-vote-up').click
    wait_for_ajax
    expect(page.body).to have_css('.thread-message:first-of-type .posting-header .icon-vote-up.active')
    expect(page.body).to have_css('.thread-message:first-of-type .posting-footer .icon-vote-up.active')
  end

  it 'sets both classes when clicking upper vote down', js: true do
    visit message_path(message.thread, message)

    page.find('.thread-message:first-of-type .posting-header .icon-vote-down').click
    wait_for_ajax
    expect(page.body).to have_css('.thread-message:first-of-type .posting-header .icon-vote-down.active')
    expect(page.body).to have_css('.thread-message:first-of-type .posting-footer .icon-vote-down.active')
  end

  it 'sets both classes when clicking lower vote down', js: true do
    visit message_path(message.thread, message)

    page.find('.thread-message:first-of-type .posting-footer .icon-vote-down').click
    wait_for_ajax
    expect(page.body).to have_css('.thread-message:first-of-type .posting-header .icon-vote-down.active')
    expect(page.body).to have_css('.thread-message:first-of-type .posting-footer .icon-vote-down.active')
  end

  it 'sets both classes when clicking upper accept', js: true do
    visit message_path(message1.thread, message1)

    page.find('.thread-message:first-of-type .posting-header .accept').click
    wait_for_ajax
    expect(page.body).to have_css('.thread-message:first-of-type .posting-header .accept.accepted-answer')
    expect(page.body).to have_css('.thread-message:first-of-type .posting-footer .accept.accepted-answer')
  end

  it 'sets both classes when clicking lower accept', js: true do
    visit message_path(message1.thread, message1)

    page.find('.thread-message:first-of-type .posting-footer .accept').click
    wait_for_ajax
    expect(page.body).to have_css('.thread-message:first-of-type .posting-header .accept.accepted-answer')
    expect(page.body).to have_css('.thread-message:first-of-type .posting-footer .accept.accepted-answer')
  end
end

# eof
