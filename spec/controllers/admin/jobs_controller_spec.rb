# -*- coding: utf-8 -*-

require 'rails_helper'

RSpec.describe Admin::JobsController, type: :controller do
  let(:admin) { FactoryGirl.create(:user_admin) }
  let(:valid_params) do
    { queue_name: 'Foo', class_name: 'Bar', arguments: '{}' }
  end

  before(:each) do
    sign_in admin
  end

  describe 'GET #index' do
    it 'assigns the jobs as @jobs' do
      job = PeonJob.create! valid_params
      get :index
      expect(assigns(:jobs)).to eq([job])
    end

    it 'assigns a jobs stats as @stat_jobs' do
      get :index
      expect(assigns(:jobs)).not_to be_nil
    end
  end
end

# eof
