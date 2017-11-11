require 'rails_helper'

RSpec.describe TagsController, type: :controller do
  let(:forum) { create(:write_forum) }
  let(:tag) { create(:tag, forum: forum) }

  let(:valid_attributes) do
    { tag_name: 'Foo 1' }
  end

  let(:invalid_attributes) do
    { tag_name: '' }
  end

  describe 'GET #index' do
    it 'assigns all tags as @tags' do
      get :index, params: { curr_forum: tag.forum.slug }
      expect(assigns(:tags)).to eq([tag])
    end

    it 'searches tags with s param' do
      tags = [create(:tag, forum: forum), create(:tag, forum: forum), create(:tag, forum: forum)]
      get :index, params: { curr_forum: forum.slug, s: tags.first.tag_name }
      expect(assigns(:tags)).to eq([tags.first])
    end
  end

  describe 'POST #suggestions' do
    it 'generates a suggestion list by tags param' do
      tag1 = create(:tag, forum: forum)
      post :suggestions, params: { curr_forum: forum.slug,
                                   tags: tag.tag_name.gsub(/ .*/, '') + ',' + tag1.tag_name.gsub(/ .*/, ''),
                                   format: :json }

      expect(assigns(:tags).to_a).to eq([tag1, tag])
    end
  end

  describe 'GET #autocomplete' do
    it 'renders a list of tags' do
      get :autocomplete, params: { curr_forum: tag.forum.slug }
      expect(assigns[:tags_list]).not_to be_empty
      expect(assigns[:tags_list]).to eq([tag.tag_name])
    end

    it 'renders a list of tags filtered by s param' do
      get :autocomplete, params: { curr_forum: tag.forum.slug, s: tag.tag_name.gsub(/ .*/, '') }
      expect(assigns[:tags_list]).not_to be_empty
      expect(assigns[:tags_list]).to eq([tag.tag_name])
    end

    it 'renders an empty list of tags when none found' do
      get :autocomplete, params: { curr_forum: tag.forum.slug, s: 'Quetzalcoatl' }
      expect(assigns[:tags_list]).to be_empty
    end

    it 'includes synonyms in tags list' do
      tag.synonyms.create!(forum_id: forum.forum_id, synonym: 'foobar')
      get :autocomplete, params: { curr_forum: tag.forum.slug, s: 'foobar' }
      expect(assigns[:tags_list]).not_to be_empty
      expect(assigns[:tags_list]).to eq(['foobar'])
    end
  end

  describe 'GET #show' do
    it 'assigns the tag as @tag' do
      get :show, params: { curr_forum: tag.forum.slug, id: tag.to_param }
      expect(assigns(:tag)).to eq tag
    end

    it 'loads a list of messages in @messages' do
      message = create(:message, forum: tag.forum)
      message.tags << tag

      get :show, params: { curr_forum: tag.forum.slug, id: tag.to_param }
      expect(assigns(:messages)).to eq [message]
    end
  end

  describe 'GET #new' do
    let(:user) { create(:user_admin) }

    it 'assigns a new tag as @tag' do
      sign_in user
      get :new, params: { curr_forum: forum.slug }
      expect(assigns(:tag)).to be_a_new(Tag)
    end
  end

  describe 'POST #create' do
    let(:user) { create(:user_admin) }
    before(:each) { sign_in user }

    context 'with valid params' do
      it 'creates a new Tag' do
        expect do
          post :create, params: { curr_forum: forum.slug, tag: valid_attributes }
        end.to change(Tag, :count).by(1)
      end

      it 'assigns a newly created tag as @tag' do
        post :create, params: { curr_forum: forum.slug, tag: valid_attributes }
        expect(assigns(:tag)).to be_a(Tag)
        expect(assigns(:tag)).to be_persisted
      end

      it 'redirects to the tags index' do
        post :create, params: { curr_forum: forum.slug, tag: valid_attributes }
        expect(response).to redirect_to(tags_url(forum))
      end
    end

    context 'with invalid params' do
      it 'assigns a newly created but unsaved tag as @tag' do
        post :create, params: { curr_forum: forum.slug, tag: invalid_attributes }
        expect(assigns(:tag)).to be_a_new(Tag)
      end

      it "re-renders the 'new' template" do
        post :create, params: { curr_forum: forum.slug, tag: invalid_attributes }
        expect(response).to render_template('new')
      end
    end
  end

  describe 'GET #edit' do
    let(:user) { create(:user_admin) }

    it 'assigns the requested tag as @tag' do
      sign_in user
      get :edit, params: { curr_forum: forum.slug, id: tag.to_param }
      expect(assigns(:tag)).to eq(tag)
    end
  end

  describe 'PUT #update' do
    let(:user) { create(:user_admin) }
    before(:each) { sign_in user }

    context 'with valid params' do
      it 'updates the requested tag' do
        put :update, params: { curr_forum: forum.slug, id: tag.to_param, tag: valid_attributes }
        tag.reload
        expect(tag.tag_name).to eq 'Foo 1'
      end

      it 'assigns the requested tag as @tag' do
        put :update, params: { curr_forum: forum.slug, id: tag.to_param, tag: { tag_name: tag.tag_name } }
        expect(assigns(:tag)).to eq(tag)
      end

      it 'redirects to the tag' do
        put :update, params: { curr_forum: forum.slug, id: tag.to_param, tag: valid_attributes }
        expect(response).to redirect_to(tags_url(forum))
      end
    end

    context 'with invalid params' do
      it 'assigns the tag as @tag' do
        put :update, params: { curr_forum: forum.slug, id: tag.to_param, tag: invalid_attributes }
        expect(assigns(:tag)).to eq(tag)
      end

      it "re-renders the 'edit' template" do
        put :update, params: { curr_forum: forum.slug, id: tag.to_param, tag: invalid_attributes }
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:user) { create(:user_admin) }
    before(:each) { sign_in user }

    it 'destroys the requested tag' do
      tag # 💩 ensure creation, fuck you laziness

      expect do
        delete :destroy, params: { curr_forum: forum.slug, id: tag.to_param }
      end.to change(Tag, :count).by(-1)
    end

    it 'redirects to the tags url' do
      delete :destroy, params: { curr_forum: forum.slug, id: tag.to_param }
      expect(response).to redirect_to(tags_url(forum))
    end

    it "doesn't destroy a tag with messages assigned" do
      message = create(:message, forum: tag.forum)
      message.tags << tag

      expect do
        delete :destroy, params: { curr_forum: forum.slug, id: tag.to_param }
      end.to change(Tag, :count).by(0)

      expect(response).to redirect_to(tag_url(forum, tag))
    end
  end

  describe 'GET #merge' do
    let(:user) { create(:user_admin) }
    before(:each) { sign_in user }

    it 'assigns the tag as @tag' do
      get :merge, params: { curr_forum: forum.slug, id: tag.to_param }
      expect(assigns(:tag)).to eq(tag)
    end

    it 'assigns a list of tags as @tags' do
      tags = [create(:tag, forum: forum), create(:tag, forum: forum), create(:tag, forum: forum)]
      get :merge, params: { curr_forum: forum.slug, id: tag.to_param }
      expect(assigns(:tags)).to eq(tags)
    end
  end

  describe 'POST #do_merge' do
    let(:user) { create(:user_admin) }
    before(:each) { sign_in user }
    let(:tags) { [create(:tag, forum: forum), create(:tag, forum: forum), create(:tag, forum: forum)] }

    it 'merges this tag' do
      message = create(:message, forum: tag.forum)
      message.tags << tag

      post :do_merge, params: { curr_forum: forum.slug,
                                id: tag.to_param,
                                merge_tag: tags.first.tag_id }

      message.tags.reload
      expect(message.tags).to include(tags.first)
    end

    it 'adds this tag as a synonym' do
      tags # 💩 ensure creation, fuck you laziness
      tag # 💩 ensure creation, fuck you laziness

      expect do
        post :do_merge, params: { curr_forum: forum.slug,
                                  id: tag.to_param,
                                  merge_tag: tags.first.tag_id }
      end.to change(TagSynonym, :count).by(1)
    end

    it 'destroys this tag' do
      tags # 💩 ensure creation, fuck you laziness
      tag # 💩 ensure creation, fuck you laziness

      expect do
        post :do_merge, params: { curr_forum: forum.slug,
                                  id: tag.to_param,
                                  merge_tag: tags.first.tag_id }
      end.to change(Tag, :count).by(-1)
    end

    it 'moves the existing tag synonyms to the other tag' do
      synonym = tag.synonyms.create!(forum_id: forum.forum_id, synonym: 'foobar')

      post :do_merge, params: { curr_forum: forum.slug,
                                id: tag.to_param,
                                merge_tag: tags.first.tag_id }

      synonym.reload
      expect(synonym.tag_id).to eq(tags.first.tag_id)
    end
  end
end

# eof
