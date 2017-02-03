require 'rails_helper'

RSpec.describe CfThreadsController, type: :controller do
  let(:forum) { create(:write_forum) }
  let(:tag) { create(:tag, forum: forum) }

  before(:each) do
    # ensure that forum and tag exist
    forum
    tag

    s = Setting.new
    s.options['min_tags_per_message'] = 1
    s.options['max_tags_per_message'] = 3
    s.save!
  end

  describe 'POST #create' do
    it 'creates a new thread' do
      expect do
        post :create, params: { curr_forum: forum.slug,
                                tags: [tag.tag_name],
                                cf_thread: { message: attributes_for(:message, forum: nil) } }
      end.to change(CfThread, :count).by(1)
    end

    it 'fails to create a new thread due to missing parameters' do
      attrs = attributes_for(:message, forum: nil)
      attrs.delete(:subject)

      post :create, params: { curr_forum: forum.slug,
                              tags: [tag.tag_name],
                              cf_thread: { message: attrs } }

      expect(response).to render_template('new')
    end

    it 'fails to create a new thread due to missing tags' do
      post :create, params: { curr_forum: forum.slug,
                              cf_thread: { message: attributes_for(:message, forum: nil) } }
      expect(response).to render_template('new')
    end

    it 'creates a new thread when using /all/new' do
      expect do
        post :create, params: { curr_forum: 'all',
                                tags: [tag.tag_name],
                                cf_thread: { message: attributes_for(:message, forum: nil),
                                             forum_id: forum.forum_id } }
      end.to change(CfThread, :count).by(1)
    end

    it 'fails to create a post with a spammy subject' do
      s = Setting.first!
      s.options['subject_black_list'] = 'some spammy text'
      s.save!

      attrs = attributes_for(:message, forum: nil)
      attrs[:subject] = 'some spammy text'
      post :create, params: { curr_forum: 'all',
                              tags: [tag.tag_name],
                              cf_thread: { message: attrs,
                                           forum_id: forum.forum_id } }

      expect(response).to render_template 'new'
    end

    it 'fails to create a post with spammy content' do
      s = Setting.first!
      s.options['content_black_list'] = 'some spammy text'
      s.save!

      attrs = attributes_for(:message, forum: nil)
      attrs[:content] = 'some spammy text'

      post :create, params: { curr_forum: 'all',
                              tags: [tag.tag_name],
                              cf_thread: { message: attrs,
                                           forum_id: forum.forum_id } }

      expect(response).to render_template 'new'
    end
  end
end
