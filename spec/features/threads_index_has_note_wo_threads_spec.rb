# -*- coding: utf-8 -*-

require 'rails_helper'

include Warden::Test::Helpers
Warden.test_mode!

describe 'threads index' do
  let(:forum) { create(:write_forum) }

  include CForum::Tools

  it 'has a note when no threads exist' do
    visit forum_path(forum)
    expect(page.body).to have_css('.no-data')
  end
end

# eof
