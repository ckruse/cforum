require 'rails_helper'

RSpec.describe Messages::VoteController, type: :controller do
  context 'authorized user' do
    let(:user) { create(:user) }
    let(:user1) { create(:user) }
    let(:score) { Score.create!(user_id: user.user_id, value: 10) }
    let(:message) { create(:message, owner: user1) }
    let(:badges) do
      [create(:badge, badge_type: Badge::UPVOTE),
       create(:badge, badge_type: Badge::DOWNVOTE)]
    end

    before(:each) do
      score # lazyness sucks
      user.badge_users.create!(badge_id: badges.first.badge_id)
      user.badge_users.create!(badge_id: badges.second.badge_id)
    end

    it 'should upvote when user is logged in' do
      sign_in user
      post :vote, params: message_params_from_slug(message).merge(type: 'up')

      user1.reload

      message.reload

      expect(message.upvotes).to eq 1
      expect(flash[:error]).to be nil
      expect(assigns(:vote)).to be_a(Vote)
      expect(assigns(:vote).vtype).to eq Vote::UPVOTE
      expect(user1.score).not_to eq 0
    end

    it "shouldn't upvote when user has no badge" do
      user.badge_users.clear

      sign_in user
      post :vote, params: message_params_from_slug(message).merge(type: 'up')

      message.reload

      expect(message.upvotes).to eq 0
      expect(flash[:error]).not_to be nil
      expect(assigns(:vote)).to be nil
      expect(user1.score).to eq 0
    end

    it "shouldn't upvote when user is author of bevoted message" do
      sign_in user1
      post :vote, params: message_params_from_slug(message).merge(type: 'up')

      message.reload

      expect(message.upvotes).to eq 0
      expect(flash[:error]).not_to be nil
      expect(assigns(:vote)).to be nil
      expect(user1.score).to eq 0
    end

    it 'should take back vote when user has already voted' do
      Vote.create!(user_id: user.user_id,
                   message_id: message.message_id,
                   vtype: Vote::UPVOTE)
      message.update(upvotes: 1)

      sign_in user
      post :vote, params: message_params_from_slug(message).merge(type: 'up')

      user1.reload
      message.reload

      expect(message.upvotes).to eq 0
      expect(flash[:error]).to be nil
      expect(assigns(:vote)).to be_a(Vote)
      expect(assigns(:vote).vtype).to eq Vote::UPVOTE
      expect(user1.score).to eq 0
    end

    it 'should change vote when user has already voted' do
      v = Vote.create!(user_id: user.user_id,
                       message_id: message.message_id,
                       vtype: Vote::UPVOTE)
      Score.create!(user_id: user1.user_id,
                    vote_id: v.vote_id,
                    value: 10)
      message.update(upvotes: 1)

      sign_in user
      post :vote, params: message_params_from_slug(message).merge(type: 'down')

      user1.reload
      user.reload
      message.reload

      expect(flash[:error]).to be nil
      expect(message.upvotes).to eq 0
      expect(message.downvotes).to eq 1
      expect(assigns(:vote)).to be_a(Vote)
      expect(assigns(:vote).vtype).to eq Vote::DOWNVOTE
      expect(user1.score).to eq(-1)
      expect(user.score).to eq(9)
    end

    it 'should downvote when user is logged in' do
      sign_in user
      post :vote, params: message_params_from_slug(message).merge(type: 'down')

      user.reload
      user1.reload
      message.reload

      expect(flash[:error]).to be nil
      expect(message.upvotes).to eq 0
      expect(message.downvotes).to eq 1
      expect(assigns(:vote)).to be_a(Vote)
      expect(assigns(:vote).vtype).to eq Vote::DOWNVOTE
      expect(user1.score).to eq(-1)
      expect(user.score).to eq(9)
    end

    it "shouldn't downvote when user has no badge" do
      badges.second.destroy

      sign_in user
      post :vote, params: message_params_from_slug(message).merge(type: 'down')

      expect(flash[:error]).not_to be_nil
    end

    it "shouldn't downvote when score is zero" do
      score.destroy

      sign_in user
      post :vote, params: message_params_from_slug(message).merge(type: 'down')

      expect(flash[:error]).not_to be_nil
    end

    it "shouldn't score when target user's score is below zero" do
      Score.create!(user_id: user1.user_id, value: -1)

      sign_in user
      post :vote, params: message_params_from_slug(message).merge(type: 'down')

      user1.reload
      expect(user1.score).to eq(-1)
    end

    it "should score when target user's score isn't below zero" do
      sign_in user
      post :vote, params: message_params_from_slug(message).merge(type: 'down')

      user1.reload
      expect(user1.score).to eq(-1)
    end

    it "shouldn't score when updating a vote and target score falls below -1" do
      v = Vote.create!(user_id: user.user_id,
                       message_id: message.message_id,
                       vtype: Vote::UPVOTE)
      Score.create!(user_id: user1.user_id,
                    vote_id: v.vote_id,
                    value: 10)
      Score.create!(user_id: user1.user_id,
                    value: -1)

      message.update(upvotes: 1)

      sign_in user
      post :vote, params: message_params_from_slug(message).merge(type: 'down')

      user1.reload
      user.reload
      message.reload

      expect(flash[:error]).to be nil
      expect(message.upvotes).to eq 0
      expect(message.downvotes).to eq 1
      expect(assigns(:vote)).to be_a(Vote)
      expect(assigns(:vote).vtype).to eq Vote::DOWNVOTE
      expect(user1.score).to eq(-1)
    end

    it "should score when updating a vote and target score doesn't fall below -1" do
      v = Vote.create!(user_id: user.user_id,
                       message_id: message.message_id,
                       vtype: Vote::UPVOTE)
      Score.create!(user_id: user1.user_id,
                    vote_id: v.vote_id,
                    value: 10)

      message.update(upvotes: 1)

      sign_in user
      post :vote, params: message_params_from_slug(message).merge(type: 'down')

      user1.reload
      user.reload
      message.reload

      expect(flash[:error]).to be nil
      expect(message.upvotes).to eq 0
      expect(message.downvotes).to eq 1
      expect(assigns(:vote)).to be_a(Vote)
      expect(assigns(:vote).vtype).to eq Vote::DOWNVOTE
      expect(user1.score).to eq(-1)
    end
  end
end

# eof
