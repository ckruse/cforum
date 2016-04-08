require "rails_helper"

RSpec.describe ForumsController do
  let(:forum) { create(:forum) }

  describe "Stats" do
    it "shows stats for a specific forum" do
      get :stats, { curr_forum: forum.slug }
      expect(response.status).to eq(200)
      expect(response).to render_template("stats")
    end

    it "shows stats for all forums" do
      get :stats, { curr_forum: 'all' }
      expect(response.status).to eq(200)
      expect(response).to render_template("stats")
    end
  end
end
