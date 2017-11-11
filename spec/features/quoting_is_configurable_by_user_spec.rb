require 'rails_helper'

RSpec.feature 'Quoting is configurable by user', type: :feature do
  include CForum::Tools
  include ApplicationHelper

  let(:message) { create(:message) }
  let(:user) { create(:user) }
  before(:each) { login_as(user, scope: :user) }

  def current_user
    user
  end

  def current_forum
    nil
  end

  scenario 'there is only one button when quote_by_default=yes' do
    Setting.create!(user_id: user.user_id, options: { 'quote_by_default' => 'yes' })

    visit message_path(message.thread, message)

    expect(page).to have_css('.btn-answer')
    expect(page).not_to have_css('.btn-answer.with-quote')
  end

  scenario 'there is only one button when quote_by_default=no' do
    Setting.create!(user_id: user.user_id, options: { 'quote_by_default' => 'no' })

    visit message_path(message.thread, message)

    expect(page).to have_css('.btn-answer')
    expect(page).not_to have_css('.btn-answer.with-quote')
  end

  scenario 'there are two buttons when quote_by_default=button' do
    Setting.create!(user_id: user.user_id, options: { 'quote_by_default' => 'button' })

    visit message_path(message.thread, message)

    expect(page).to have_css('.btn-answer')
    expect(page).to have_css('.btn-answer.with-quote')
  end

  scenario 'quote is inserted with quote_by_default=yes in answer forms' do
    Setting.create!(user_id: user.user_id, options: { 'quote_by_default' => 'yes' })
    visit new_message_path(message.thread, message)
    expect(page.find_field('message_input').value).to eq message.to_quote(self)
  end

  scenario 'quote isn\'t inserted with quote_by_default=no in inline forms' do
    Setting.create!(user_id: user.user_id, options: { 'quote_by_default' => 'no' })

    visit message_path(message.thread, message)
    expect(page.find_field('message_input').value).to eq ''
  end

  scenario 'quote is inserted with quote_by_default=yes in inline forms', js: true do
    Setting.create!(user_id: user.user_id, options: { 'quote_by_default' => 'yes' })

    visit message_path(message.thread, message)

    page.find('.btn-answer').click
    wait_for_ajax
    expect(page.find_field('message_input').value).to eq message.to_quote(self)
  end

  scenario 'quote isn\'t inserted with quote_by_default=no in inline forms', js: true do
    Setting.create!(user_id: user.user_id, options: { 'quote_by_default' => 'no' })

    visit message_path(message.thread, message)

    page.find('.btn-answer').click
    wait_for_ajax
    expect(page.find_field('message_input').value).to eq ''
  end
end

# eof
