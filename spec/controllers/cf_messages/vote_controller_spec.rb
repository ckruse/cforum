# -*- coding: utf-8 -*-

require "rails_helper"

describe CfMessages::VoteController do
  context "authorized user" do
    let(:user) { create(:cf_user) }
    let(:user1) { create(:cf_user) }
    let(:score) { CfScore.create!(user_id: user.user_id, value: 10)}
    let(:message) { create(:cf_message, owner: user1) }
    let(:badges) do
      [create(:cf_badge, badge_type: RightsHelper::UPVOTE),
       create(:cf_badge, badge_type: RightsHelper::DOWNVOTE)]
    end

    before(:each) do
      score # lazyness sucks
      user.badges_users.create!(badge_id: badges.first.badge_id)
      user.badges_users.create!(badge_id: badges.second.badge_id)
    end

    it "should upvote when user is logged in" do
      sign_in user
      post :vote, message_params_from_slug(message).merge(type: 'up')

      user1.reload

      message.reload

      expect(message.upvotes).to eq 1
      expect(flash[:error]).to be nil
      expect(assigns(:vote)).to be_a(CfVote)
      expect(assigns(:vote).vtype).to eq CfVote::UPVOTE
      expect(user1.score).not_to eq 0
    end

    it "shouldn't upvote when user has no badge" do
      user.badges_users.clear

      sign_in user
      post :vote, message_params_from_slug(message).merge(type: 'up')

      message.reload

      expect(message.upvotes).to eq 0
      expect(flash[:error]).not_to be nil
      expect(assigns(:vote)).to be nil
      expect(user1.score).to eq 0
    end

    it "shouldn't upvote when user is author of bevoted message" do
      sign_in user1
      post :vote, message_params_from_slug(message).merge(type: 'up')

      message.reload

      expect(message.upvotes).to eq 0
      expect(flash[:error]).not_to be nil
      expect(assigns(:vote)).to be nil
      expect(user1.score).to eq 0
    end

    it "should take back vote when user has already voted" do
      CfVote.create!(user_id: user.user_id,
                     message_id: message.message_id,
                     vtype: CfVote::UPVOTE)
      message.update(upvotes: 1)

      sign_in user
      post :vote, message_params_from_slug(message).merge(type: 'up')

      user1.reload
      message.reload

      expect(message.upvotes).to eq 0
      expect(flash[:error]).to be nil
      expect(assigns(:vote)).to be_a(CfVote)
      expect(assigns(:vote).vtype).to eq CfVote::UPVOTE
      expect(user1.score).to eq 0
    end

    it "should change vote when user has already voted" do
      v = CfVote.create!(user_id: user.user_id,
                         message_id: message.message_id,
                         vtype: CfVote::UPVOTE)
      CfScore.create!(user_id: user1.user_id,
                      vote_id: v.vote_id,
                      value: 10)
      message.update(upvotes: 1)

      sign_in user
      post :vote, message_params_from_slug(message).merge(type: 'down')

      user1.reload
      user.reload
      message.reload

      expect(flash[:error]).to be nil
      expect(message.upvotes).to eq 0
      expect(message.downvotes).to eq 1
      expect(assigns(:vote)).to be_a(CfVote)
      expect(assigns(:vote).vtype).to eq CfVote::DOWNVOTE
      expect(user1.score).to eq(-1)
      expect(user.score).to eq(9)
    end

    it "should downvote when user is logged in" do
      sign_in user
      post :vote, message_params_from_slug(message).merge(type: 'down')

      user.reload
      user1.reload
      message.reload

      expect(flash[:error]).to be nil
      expect(message.upvotes).to eq 0
      expect(message.downvotes).to eq 1
      expect(assigns(:vote)).to be_a(CfVote)
      expect(assigns(:vote).vtype).to eq CfVote::DOWNVOTE
      expect(user1.score).to eq(-1)
      expect(user.score).to eq(9)
    end

    it "shouldn't downvote when user has no badge" do
      badges.second.destroy

      sign_in user
      post :vote, message_params_from_slug(message).merge(type: 'down')

      expect(flash[:error]).not_to be_nil
    end

    it "shouldn't downvote when score is zero" do
      score.destroy

      sign_in user
      post :vote, message_params_from_slug(message).merge(type: 'down')

      expect(flash[:error]).not_to be_nil
    end
  end
end

# eof
