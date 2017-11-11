require 'rails_helper'

RSpec.describe 'login works' do
  let(:user) { create(:user, password: '1234') }

  it 'logs in with correct password' do
    visit new_user_session_path
    fill_in User.human_attribute_name(:login), with: user.username
    fill_in User.human_attribute_name(:password), with: '1234'
    click_button I18n.t('devise.sign_in')

    expect(page).to have_text I18n.t('devise.sessions.signed_in')
  end
  it 'logs in with email' do
    visit new_user_session_path
    fill_in User.human_attribute_name(:login), with: user.email
    fill_in User.human_attribute_name(:password), with: '1234'
    click_button I18n.t('devise.sign_in')

    expect(page).to have_text I18n.t('devise.sessions.signed_in')
  end

  it 'doesnt log in with incorrect password' do
    visit new_user_session_path
    fill_in User.human_attribute_name(:login), with: user.username
    fill_in User.human_attribute_name(:password), with: '1235'
    click_button I18n.t('devise.sign_in')

    expect(page).not_to have_text I18n.t('devise.sessions.signed_in')
  end
end

# eof
