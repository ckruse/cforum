# -*- coding: utf-8 -*-

require 'rails_helper'

RSpec.describe "mails/show", type: :view do
  def conf(name)
    ConfigManager::DEFAULTS[name]
  end
  def uconf(name)
    ConfigManager::DEFAULTS[name]
  end
  def current_user
    @mail.owner
  end
  helper_method :current_user, :conf, :uconf

  before(:each) do
    @mail = assign(:mail, create(:priv_message))
  end

  it "renders attributes in <p>" do
    @app_controller = self
    render
    expect(rendered).to have_css('a', text: I18n.t('mails.mark_unread'))
  end
end

# eof
