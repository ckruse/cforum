require 'rails_helper'

RSpec.describe Admin::SearchSectionsController, type: :controller do
  let(:admin) { FactoryBot.create(:user_admin) }

  before(:each) do
    sign_in admin
  end

  describe 'GET #index' do
    it 'assigns all search_sections as @search_sections' do
      search_section = create(:search_section)
      get :index
      expect(assigns(:search_sections)).to eq([search_section])
    end
  end

  describe 'GET #new' do
    it 'assigns a new search_section as @search_section' do
      get :new
      expect(assigns(:search_section)).to be_a_new(SearchSection)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested search section as @search_section' do
      section = create(:search_section)
      get :edit, params: { id: section.search_section_id }
      expect(assigns(:search_section)).to eq(section)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new search section' do
        expect do
          post :create, params: { search_section: attributes_for(:search_section) }
        end.to change(SearchSection, :count).by(1)
      end

      it 'assigns a newly created search section as @search_section' do
        post :create, params: { search_section: attributes_for(:search_section) }
        expect(assigns(:search_section)).to be_a(SearchSection)
        expect(assigns(:search_section)).to be_persisted
      end

      it 'redirects to the search section' do
        post :create, params: { search_section: attributes_for(:search_section) }
        expect(response).to redirect_to(edit_admin_search_section_url(assigns(:search_section).search_section_id))
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) do
        { name: '' }
      end

      it 'assigns a newly created but unsaved search section as @search_section' do
        post :create, params: { search_section: invalid_attributes }
        expect(assigns(:search_section)).to be_a_new(SearchSection)
      end

      it "re-renders the 'new' template" do
        post :create, params: { search_section: invalid_attributes }
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        { name: 'Foo 1' }
      end

      it 'updates the requested search section' do
        search_section = create(:search_section)
        put :update, params: { id: search_section.search_section_id, search_section: new_attributes }
        search_section.reload
        expect(search_section.name).to eq 'Foo 1'
      end

      it 'assigns the requested search_section as @search_section' do
        search_section = create(:search_section)
        put :update, params: { id: search_section.search_section_id, search_section: new_attributes }
        expect(assigns(:search_section)).to eq(search_section)
      end

      it 'redirects to the search_section' do
        search_section = create(:search_section)
        put :update, params: { id: search_section.search_section_id, search_section: new_attributes }
        expect(response).to redirect_to(edit_admin_search_section_url(search_section.search_section_id))
      end
    end

    context 'with invalid params' do
      let(:invalid_attributes) do
        { name: '' }
      end

      it 'assigns the search_section as @search_section' do
        search_section = create(:search_section)
        put :update, params: { id: search_section.search_section_id, search_section: invalid_attributes }
        expect(assigns(:search_section)).to eq(search_section)
      end

      it "re-renders the 'edit' template" do
        search_section = create(:search_section)
        put :update, params: { id: search_section.search_section_id, search_section: invalid_attributes }
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested search_section' do
      search_section = create(:search_section)
      expect do
        delete :destroy, params: { id: search_section.search_section_id }
      end.to change(SearchSection, :count).by(-1)
    end

    it 'redirects to the search sections list' do
      search_section = create(:search_section)
      delete :destroy, params: { id: search_section.search_section_id }
      expect(response).to redirect_to(admin_search_sections_url)
    end
  end
end

# eof
