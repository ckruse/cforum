# -*- coding: utf-8 -*-

require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  let(:admin) { create(:user_admin) }
  let(:message) { create(:message) }
  let(:tag) { create(:tag, forum: message.forum) }

  before(:each) do
    # ensure that message and tag exist
    message
    tag

    s = Setting.new
    s.options['min_tags_per_message'] = 1
    s.options['max_tags_per_message'] = 3
    s.save!
  end

  describe 'GET #show' do
    render_views

    it 'shows a message' do
      get :show, message_params_from_slug(message)
    end

    it 'shows no versions link if there are no versions but an edit_author is set' do
      message.edit_author = admin.username
      message.save!

      get :show, message_params_from_slug(message)

      expect(response.body).not_to have_css('.versions')
    end

    it 'shows versions link if there are versions' do
      message.edit_author = admin.username
      message.versions.create!(subject: message.subject, content: message.content, author: message.author)
      message.save!

      get :show, message_params_from_slug(message)

      expect(response.body).to have_css('.versions')
    end

    it 'redirects to correct form when accessing via wrong forum' do
      forum1 = create(:write_forum)
      message.forum = forum1

      get :show, message_params_from_slug(message).merge(curr_forum: forum1.slug)

      expect(response).to redirect_to message_url(message.thread, message)
    end

    it 'sets readmode cookie when overwriting via query string' do
      get :show, message_params_from_slug(message).merge(rm: 'thread-view')
      expect(response.cookies['cf_readmode']).to eq 'thread-view'
    end

    it "doesn't set readmode cookie when overwriting via query string and signed in" do
      sign_in admin
      get :show, message_params_from_slug(message).merge(rm: 'thread-view')
      expect(response.cookies['cf_readmode']).to be_nil
    end
  end

  describe 'GET #new' do
    it 'shows a new message form' do
      get :new, message_params_from_slug(message)

      expect(assigns(:message)).to be_a_new(Message)
    end
  end

  describe 'POST #create' do
    it 'creates a new message' do
      expect do
        post :create, message_params_from_slug(message).merge(tags: [tag.tag_name],
                                                              message: attributes_for(:message, forum: message.thread.forum))
      end.to change(Message, :count).by(1)
      expect(response).to redirect_to message_url(message.thread, assigns(:message))
    end

    it 'fails to create a new message because of invalid tags' do
      post :create, message_params_from_slug(message).merge(message: attributes_for(:message, forum: message.thread.forum))

      expect(response).to render_template 'new'
    end

    it 'fails to create a new message because of missing attributes' do
      attrs = attributes_for(:message, forum: message.thread.forum)
      attrs.delete(:author)

      post :create, message_params_from_slug(message).merge(tags: [tag.tag_name], message: attrs)

      expect(response).to render_template 'new'
    end

    it 'fails to create a post with a spammy subject' do
      s = Setting.first!
      s.options['subject_black_list'] = 'some spammy text'
      s.save!

      attrs = attributes_for(:message, forum: message.thread.forum)
      attrs[:subject] = 'some spammy text'
      post :create, message_params_from_slug(message).merge(tags: [tag.tag_name], message: attrs)

      expect(response).to render_template 'new'
    end

    it 'fails to create a post with spammy content' do
      s = Setting.first!
      s.options['content_black_list'] = 'some spammy text'
      s.save!

      attrs = attributes_for(:message, forum: message.thread.forum)
      attrs[:content] = 'some spammy text'
      post :create, message_params_from_slug(message).merge(tags: [tag.tag_name], message: attrs)

      expect(response).to render_template 'new'
    end
  end

  describe 'POST #retag' do
    it 'changes tags' do
      sign_in admin

      expect do
        post :retag, message_params_from_slug(message).merge(tags: [tag.tag_name])
      end.to change(message.tags, :count).by(1)
    end

    it 'creates new tag' do
      sign_in admin

      expect do
        post :retag, message_params_from_slug(message).merge(tags: ['old republic'])
      end.to change(message.tags, :count).by(1)
    end
  end

  describe 'GET #edit' do
    it 'shows the edit form as admin' do
      sign_in admin
      get :edit, message_params_from_slug(message)
      expect(response).to render_template 'edit'
    end

    it 'shows the edit form as owner' do
      sign_in message.owner
      get :edit, message_params_from_slug(message)
      expect(response).to render_template 'edit'
    end

    it 'redirects when trying to edit as anonymous' do
      get :edit, message_params_from_slug(message)
      expect(response).to redirect_to message_url(message.thread, message)
    end

    it 'redirects when trying to edit as wrong user' do
      user1 = create(:user)
      sign_in user1
      get :edit, message_params_from_slug(message)
      expect(response).to redirect_to message_url(message.thread, message)
    end
  end

  describe 'POST #update' do
    it 'updates a message to markdown' do
      message.format = 'cforum'
      message.save

      sign_in admin

      post :update, message_params_from_slug(message).merge(message: message.attributes,
                                                            tags: ['rebellion'])

      expect(response).to redirect_to message_url(message.thread, assigns(:message))
      message.reload
      expect(message.format).to eq 'markdown'
    end

    it "doesn't create a version when format is not markdown" do
      message.format = 'cforum'
      message.save

      sign_in admin

      expect do
        post :update, message_params_from_slug(message).merge(message: message.attributes,
                                                              tags: ['rebellion'])
      end.to change(message.versions, :count).by(0)
    end

    it 'renders new when anon' do
      post :update, message_params_from_slug(message).merge(message: message.attributes,
                                                            tags: ['rebellion'])
      expect(response).to render_template 'new'
    end

    it 'renders new when wrong user' do
      user1 = create(:user)
      sign_in user1
      post :update, message_params_from_slug(message).merge(message: message.attributes,
                                                            tags: ['rebellion'])
      expect(response).to render_template 'new'
    end

    it 'updates search index when content changed' do
      sign_in admin

      message.author = 'Jar Jar Binks'

      expect do
        post :update, message_params_from_slug(message).merge(message: message.attributes,
                                                              tags: ['rebellion'])
      end.to change(SearchDocument, :count).by(1)
    end
  end
end

# eof
