require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'validations' do
    let(:thread) { create(:cf_thread) }

    it 'is valid with author, subject, content, forum_id and thread_id' do
      msg = Message.new(author: 'Luke',
                        subject: 'Join the rebellion',
                        content: 'Join the rebellion, cookies make fat',
                        forum_id: thread.forum_id,
                        thread_id: thread.thread_id)
      expect(msg).to be_valid
    end

    it 'is invalid w/o author' do
      msg = Message.new(subject: 'Join the rebellion',
                        content: 'Join the rebellion, cookies make fat',
                        forum_id: thread.forum_id,
                        thread_id: thread.thread_id)
      expect(msg).to be_invalid
    end

    it 'is invalid w/o subject' do
      msg = Message.new(author: 'Luke',
                        content: 'Join the rebellion, cookies make fat',
                        forum_id: thread.forum_id,
                        thread_id: thread.thread_id)
      expect(msg).to be_invalid
    end

    it 'is invalid w/o content' do
      msg = Message.new(author: 'Luke',
                        subject: 'Join the rebellion',
                        forum_id: thread.forum_id,
                        thread_id: thread.thread_id)
      expect(msg).to be_invalid
    end

    it 'is invalid w/o forum_id' do
      msg = Message.new(author: 'Luke',
                        subject: 'Join the rebellion',
                        content: 'Join the rebellion, cookies make fat',
                        thread_id: thread.thread_id)
      expect(msg).to be_invalid
    end

    it 'is invalid w/o thread_id' do
      msg = Message.new(author: 'Luke',
                        subject: 'Join the rebellion',
                        content: 'Join the rebellion, cookies make fat',
                        forum_id: thread.forum_id)
      expect(msg).to be_invalid
    end

    it 'is invalid with too short content' do
      msg = Message.new(author: 'Luke',
                        subject: 'Join the rebellion',
                        content: 'a',
                        forum_id: thread.forum_id,
                        thread_id: thread.thread_id)
      expect(msg).to be_invalid
    end

    it 'is invalid with too long content' do
      msg = Message.new(author: 'Luke',
                        subject: 'Join the rebellion',
                        content: 'a' * 12_289,
                        forum_id: thread.forum_id,
                        thread_id: thread.thread_id)
      expect(msg).to be_invalid
    end

    it 'is invalid with too short author' do
      msg = Message.new(author: 'L',
                        subject: 'Join the rebellion',
                        content: 'Join the rebellion, cookies make fat',
                        forum_id: thread.forum_id,
                        thread_id: thread.thread_id)
      expect(msg).to be_invalid
    end

    it 'is invalid with too long author' do
      msg = Message.new(author: 'L' * 61,
                        subject: 'Join the rebellion',
                        content: 'Join the rebellion, cookies make fat',
                        forum_id: thread.forum_id,
                        thread_id: thread.thread_id)
      expect(msg).to be_invalid
    end

    it 'is invalid with too short subject' do
      msg = Message.new(author: 'Luke',
                        subject: 'J',
                        content: 'Join the rebellion, cookies make fat',
                        forum_id: thread.forum_id,
                        thread_id: thread.thread_id)
      expect(msg).to be_invalid
    end

    it 'is invalid with too long subject' do
      msg = Message.new(author: 'Luke',
                        subject: 'J' * 251,
                        content: 'Join the rebellion, cookies make fat',
                        forum_id: thread.forum_id,
                        thread_id: thread.thread_id)
      expect(msg).to be_invalid
    end

    it 'is invalid with too short email' do
      msg = Message.new(author: 'Luke',
                        email: 'a@b.c',
                        subject: 'Join the rebellion',
                        content: 'Join the rebellion, cookies make fat',
                        forum_id: thread.forum_id,
                        thread_id: thread.thread_id)
      expect(msg).to be_invalid
    end

    it 'is invalid with too long email' do
      msg = Message.new(author: 'Luke',
                        email: 'luke@rebel' + ('l' * 60) + 'lion.org',
                        subject: 'Join the rebellion',
                        content: 'Join the rebellion, cookies make fat',
                        forum_id: thread.forum_id,
                        thread_id: thread.thread_id)
      expect(msg).to be_invalid
    end

    it 'is invalid with wrong email syntax' do
      msg = Message.new(author: 'Luke',
                        email: 'luke the rebel',
                        subject: 'Join the rebellion',
                        content: 'Join the rebellion, cookies make fat',
                        forum_id: thread.forum_id,
                        thread_id: thread.thread_id)
      expect(msg).to be_invalid
    end

    it 'is invalid with invalid homepage' do
      msg = Message.new(author: 'Luke',
                        homepage: 'httpwfwef',
                        subject: 'Join the rebellion',
                        content: 'Join the rebellion, cookies make fat',
                        forum_id: thread.forum_id,
                        thread_id: thread.thread_id)
      expect(msg).to be_invalid
    end

    it 'is invalid with too long homepage' do
      msg = Message.new(author: 'Luke',
                        homepage: 'http://' + ('a' * 250) + '.de',
                        subject: 'Join the rebellion',
                        content: 'Join the rebellion, cookies make fat',
                        forum_id: thread.forum_id,
                        thread_id: thread.thread_id)
      expect(msg).to be_invalid
    end
  end

  describe 'scoring' do
    let(:msg) { build(:message) }

    it 'calculates score by upvotes - downvotes' do
      msg.upvotes = 1
      msg.downvotes = 2
      expect(msg.score).to eq(-1)
    end

    it 'uses – when no votes exist' do
      expect(msg.score_str).to eq('–')
    end

    it 'uses +/- when score is zero' do
      msg.upvotes = 1
      msg.downvotes = 1
      expect(msg.score_str).to eq('±0')
    end

    it 'uses − when score is below zero' do
      msg.upvotes = 1
      msg.downvotes = 2
      expect(msg.score_str).to eq('−1')
    end

    it 'uses + when score is above zero' do
      msg.upvotes = 2
      msg.downvotes = 1
      expect(msg.score_str).to eq('+1')
    end

    it 'returns sum of up and down votes' do
      msg.upvotes = 2
      msg.downvotes = 1
      expect(msg.no_votes).to eq 3
    end
  end

  describe 'open' do
    let(:msg) { build(:message) }

    it "is open when no-answer flag isn't set" do
      expect(msg.open?).to be true
    end

    it 'is open when no-answer flag is no' do
      msg.flags['no-answer'] = 'no'
      expect(msg.open?).to be true
    end

    it 'is not open when no-answer flag is yes' do
      msg.flags['no-answer'] = 'yes'
      expect(msg.open?).to be false
    end

    it "is open when no-answer-admin flag isn't set" do
      expect(msg.open?).to be true
    end

    it 'is open when no-answer-admin flag is no' do
      msg.flags['no-answer-admin'] = 'no'
      expect(msg.open?).to be true
    end

    it 'is not open when no-answer-admin flag is yes' do
      msg.flags['no-answer-admin'] = 'yes'
      expect(msg.open?).to be false
    end

    it 'is open when no-answer flag is yes and no-answer-admin flag is no' do
      msg.flags['no-answer'] = 'yes'
      msg.flags['no-answer-admin'] = 'no'
      expect(msg.open?).to be true
    end

    it 'is not open when no-answer flag is no and no-answer-admin flag is yes' do
      msg.flags['no-answer'] = 'no'
      msg.flags['no-answer-admin'] = 'yes'
      expect(msg.open?).to be false
    end

    it 'is open when no-answer flag is no and no-answer-admin flag is no' do
      msg.flags['no-answer'] = 'no'
      msg.flags['no-answer-admin'] = 'no'
      expect(msg.open?).to be true
    end

    it 'is not open when no-answer flag is yes and no-answer-admin flag is yes' do
      msg.flags['no-answer'] = 'yes'
      msg.flags['no-answer-admin'] = 'yes'
      expect(msg.open?).to be false
    end
  end

  describe 'subject changed' do
    let(:thread) do
      m = create(:message)
      m.thread
    end

    before(:each) do
      thread.messages << build(:message,
                               thread: thread,
                               parent_id: thread.messages.first.message_id,
                               subject: thread.messages.first.subject)
      thread.gen_tree
    end

    it "returns false when subject hasn't changed" do
      expect(thread.messages.last.subject_changed?).to be false
    end

    it 'returns false if message is first in tree' do
      expect(thread.message.subject_changed?).to be false
    end

    it 'returns true if subject has changed' do
      thread.messages.last.subject = 'something different'
      expect(thread.messages.last.subject_changed?).to be true
    end
  end

  it 'does not include private attributes when rendering to json' do
    msg = build(:message)
    msg.ip = '1234'
    msg.uuid = '1234'

    json = msg.as_json

    expect(json =~ /"ip":/).to be_nil
    expect(json =~ /"uuid":/).to be_nil
  end
end
