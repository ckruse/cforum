# -*- coding: utf-8 -*-

require 'rails_helper'

RSpec.describe CfThreads::InvisibleController, type: :controller do
  include InvisibleHelper

  before(:each) do
    @forum = create(:write_forum)
    @user = create(:user)
    @messages = [create(:message, forum: @forum),
                 create(:message, forum: @forum),
                 create(:message, forum: @forum)]
    @threads = @messages.map(&:thread).reverse # default sort order is descending
    sign_in @user
  end

  describe 'GET #list_invisible_threads' do
    it 'assigns a list of invisible threads to @threads' do
      @threads.each do |thread|
        mark_invisible(@user, thread)
      end

      get :list_invisible_threads
      expect(assigns(:threads)).to eq(@threads)
    end
  end

  describe 'POST #hide_thread' do
    it 'hides a thread' do
      expect do
        post :hide_thread, params: thread_params_from_slug(@threads.first)
      end.to change {
        CfThread
          .joins('INNER JOIN invisible_threads iv ON iv.thread_id = threads.thread_id')
          .where('iv.user_id = ?', @user.user_id)
          .count
      }.by(1)
    end
  end

  describe 'POST #unhide_thread' do
    it 'unhides a thread' do
      mark_invisible(@user, @threads.first)
      expect do
        post :unhide_thread, params: thread_params_from_slug(@threads.first)
      end.to change {
        CfThread
          .joins('INNER JOIN invisible_threads iv ON iv.thread_id = threads.thread_id')
          .where('iv.user_id = ?', @user.user_id).count
      }.by(-1)
    end
  end
end

# eof
