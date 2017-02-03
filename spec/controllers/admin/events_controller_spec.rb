require 'rails_helper'

RSpec.describe Admin::EventsController, type: :controller do
  let(:valid_attributes) { attributes_for(:event) }
  let(:invalid_attributes) { attributes_for(:event, name: nil) }
  let(:admin) { create(:user_admin) }

  before(:each) { sign_in admin }

  describe 'GET #index' do
    it 'assigns all events as @events' do
      event = create(:event)
      get :index
      expect(assigns(:events)).to eq([event])
    end
  end

  describe 'GET #new' do
    it 'assigns a new event as @event' do
      get :new
      expect(assigns(:event)).to be_a_new(Event)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested event as @event' do
      event = create(:event)
      get :edit, params: { id: event.to_param }
      expect(assigns(:event)).to eq(event)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Event' do
        expect do
          post :create, params: { event: valid_attributes }
        end.to change(Event, :count).by(1)
      end

      it 'assigns a newly created event as @event' do
        post :create, params: { event: valid_attributes }
        expect(assigns(:event)).to be_a(Event)
        expect(assigns(:event)).to be_persisted
      end

      it 'redirects to the events index' do
        post :create, params: { event: valid_attributes }
        expect(response).to redirect_to(admin_events_url)
      end
    end

    context 'with invalid params' do
      it 'assigns a newly created but unsaved event as @event' do
        post :create, params: { event: invalid_attributes }
        expect(assigns(:event)).to be_a_new(Event)
      end

      it "re-renders the 'new' template" do
        post :create, params: { event: invalid_attributes }
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        { description: 'Foo bar' }
      end

      it 'updates the requested event' do
        event = create(:event)
        put :update, params: { id: event.to_param, event: new_attributes }
        event.reload
        expect(event.description).to eql('Foo bar')
      end

      it 'assigns the requested event as @event' do
        event = create(:event)
        put :update, params: { id: event.to_param, event: valid_attributes }
        event.reload
        expect(assigns(:event)).to eq(event)
      end

      it 'redirects to the events index' do
        event = create(:event)
        put :update, params: { id: event.to_param, event: valid_attributes }
        expect(response).to redirect_to(admin_events_url)
      end
    end

    context 'with invalid params' do
      it 'assigns the event as @event' do
        event = create(:event)
        put :update, params: { id: event.to_param, event: invalid_attributes }
        expect(assigns(:event)).to eq(event)
      end

      it "re-renders the 'edit' template" do
        event = create(:event)
        put :update, params: { id: event.to_param, event: invalid_attributes }
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested event' do
      event = create(:event)
      expect do
        delete :destroy, params: { id: event.to_param }
      end.to change(Event, :count).by(-1)
    end

    it 'redirects to the events list' do
      event = create(:event)
      delete :destroy, params: { id: event.to_param }
      expect(response).to redirect_to(admin_events_url)
    end
  end
end
