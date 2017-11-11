require 'rails_helper'

RSpec.describe 'mails/show', type: :view do
  before(:each) do
    @mail = assign(:mail, create(:priv_message))
    sign_in @mail.owner
  end

  it 'renders attributes in <p>' do
    @app_controller = self
    render
    expect(rendered).to have_css('a', text: I18n.t('mails.mark_unread'))
  end
end

# eof
