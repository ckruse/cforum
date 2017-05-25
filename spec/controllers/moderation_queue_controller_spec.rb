# -*- coding: utf-8 -*-

require 'rails_helper'

RSpec.describe ModerationQueueController, type: :controller do
  let(:admin) { create(:user_admin) }

  before(:each) do
    sign_in admin
  end

  describe 'GET #index' do
    it 'assigns queue entries as @moderation_queue_entries' do
      mqe1 = create(:mod_queue_entry_cleared)
      mqes = [create(:mod_queue_entry), create(:mod_queue_entry_cleared), mqe1]
      get :index
      expect(assigns(:moderation_queue_entries)).to eq(mqes)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested entry as @moderation_queue_entry' do
      mqe = create(:mod_queue_entry_cleared)
      get :edit, params: { id: mqe.to_param }
      expect(assigns(:moderation_queue_entry)).to eq(mqe)
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      it 'updates the requested mod queue entry' do
        mqe = create(:mod_queue_entry)

        put :update, params: { id: mqe.to_param,
                               moderation_queue_entry: { resolution_action: 'close',
                                                         resolution: 'foo bar baz' } }
        mqe.reload

        expect(mqe.cleared).to be true
        expect(mqe.resolution_action).to eq 'close'
      end

      context 'resolution actions' do
        let(:mqe) { create(:mod_queue_entry) }

        it 'closes the message' do
          put :update, params: { id: mqe.to_param,
                                 moderation_queue_entry: { resolution_action: 'close',
                                                           resolution: 'foo bar baz' } }
          mqe.message.reload
          expect(mqe.message.flags['no-answer-admin']).to eq 'yes'
        end

        it 'deletes the message' do
          put :update, params: { id: mqe.to_param,
                                 moderation_queue_entry: { resolution_action: 'delete',
                                                           resolution: 'foo bar baz' } }
          mqe.message.reload
          expect(mqe.message.deleted).to be true
        end

        it 'sets thread to don\'t archive' do
          put :update, params: { id: mqe.to_param,
                                 moderation_queue_entry: { resolution_action: 'no-archive',
                                                           resolution: 'foo bar baz' } }
          mqe.message.thread.reload
          expect(mqe.message.thread.flags['no-archive']).to eq 'yes'
        end
      end

      it 'redirects to the index' do
        mqe = create(:mod_queue_entry)
        put :update, params: { id: mqe.to_param,
                               moderation_queue_entry: { resolution_action: 'close',
                                                         resolution: 'foo bar baz' } }
        expect(response).to redirect_to(moderation_queue_index_url)
      end
    end

    context 'with invalid params' do
      it 'assigns the cite as @cite' do
        mqe = create(:mod_queue_entry)
        put :update, params: { id: mqe.to_param, moderation_queue_entry: { resolution: '' } }
        expect(assigns(:moderation_queue_entry)).to eq(mqe)
      end

      it "re-renders the 'edit' template" do
        mqe = create(:mod_queue_entry)
        put :update, params: { id: mqe.to_param, moderation_queue_entry: { resolution: '' } }
        expect(response).to render_template('edit')
      end
    end
  end
end

# eof
