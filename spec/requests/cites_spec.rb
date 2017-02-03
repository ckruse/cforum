require 'rails_helper'

RSpec.describe 'Cites', type: :request do
  describe 'GET /cites' do
    it 'works! (now write some real specs)' do
      get cites_path
      expect(response).to have_http_status(200)
    end
  end
end
