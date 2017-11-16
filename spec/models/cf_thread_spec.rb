require 'rails_helper'

RSpec.describe CfThread, type: :model do
  it 'is valid with a slug and a forum id' do
    forum = create(:forum)
    thread = CfThread.new(forum_id: forum.forum_id,
                          slug: '/rebellion',
                          latest_message: DateTime.now)
    expect(thread).to be_valid
  end

  it 'is invalid with a missing slug' do
    forum = create(:forum)
    thread = CfThread.new(forum_id: forum.forum_id,
                          latest_message: DateTime.now)
    expect(thread).to be_invalid
  end

  it 'is invalid with a missing forum id' do
    thread = CfThread.new(slug: '/rebellion',
                          latest_message: DateTime.now)
    expect(thread).to be_invalid
  end

  it 'is invalid with a duplicate slug' do
    t1 = create(:cf_thread)
    thread = CfThread.new(forum_id: t1.forum_id,
                          slug: t1.slug,
                          latest_message: DateTime.now)
    expect(thread).to be_invalid
  end

  describe 'find messages' do
    let(:message) { create(:message, mid: 1) }

    it 'finds a message message_id' do
      expect(message.thread.find_message(message.message_id)).to eq message
    end
    it "returns nil when message doesn't exist" do
      expect(message.thread.find_message(-1)).to be nil
    end

    it 'finds a message by message_id' do
      expect(message.thread.find_message!(message.message_id)).to eq message
    end
    it "throws an exception when message doesn't exist" do
      expect { message.thread.find_message!(-1) }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'finds a message by mid' do
      expect(message.thread.find_by_mid(1)).to eq message # rubocop:disable Rails/DynamicFindBy
    end
    it "returns nil when message doesn't exist" do
      expect(message.thread.find_by_mid(-1)).to be nil # rubocop:disable Rails/DynamicFindBy
    end

    it 'finds a message by mid' do
      expect(message.thread.find_by_mid!(1)).to eq message # rubocop:disable Rails/DynamicFindBy
    end
    it "throws an exception when message doesn't exist" do
      expect { message.thread.find_by_mid!(-1) } # rubocop:disable Rails/DynamicFindBy
        .to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe 'id generation' do
    it 'generates an id from a thread' do
      thread = create(:message).thread
      thread.message = thread.messages.first
      thread.message.subject = 'The Rebellion'

      expect(CfThread.gen_id(thread)).to eq(thread.created_at.strftime('/%Y/%b/%d/')
                                             .gsub(%r{0(\d)/$}, '\1/').downcase +
                                            'the-rebellion')
    end

    it 'generates an id from a thread without a leading zero in one-digit days' do
      thread = create(:message).thread
      thread.message = thread.messages.first
      thread.message.subject = 'The Rebellion'
      thread.message.created_at = DateTime.civil(1999, 1, 1, 0, 0)

      expect(CfThread.gen_id(thread)).to eq('/1999/jan/1/the-rebellion')
    end

    it 'generates an id from hash' do
      hash = { year: 1999, mon: 'jan', day: 1, tid: 'the-rebellion' }
      expect(CfThread.make_id(hash)).to eq '/1999/jan/1/the-rebellion'
    end
  end
end

# eof
