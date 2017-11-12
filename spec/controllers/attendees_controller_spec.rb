require 'rails_helper'

RSpec.describe AttendeesController, type: :controller do
  let(:event) { create(:event) }
  let(:user) { create(:user) }

  describe 'GET #new' do
    it 'assigns a new attendee as @attendee' do
      get :new, params: { event_id: event.event_id }
      expect(assigns(:attendee)).to be_a_new(Attendee)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Attendee' do
        expect do
          post :create, params: { event_id: event.event_id, attendee: attributes_for(:attendee) }
        end.to change(Attendee, :count).by(1)
      end

      it 'assigns a newly created attendee as @attendee' do
        post :create, params: { event_id: event.event_id, attendee: attributes_for(:attendee) }
        expect(assigns(:attendee)).to be_a(Attendee)
        expect(assigns(:attendee)).to be_persisted
      end

      it 'redirects to the event attendee' do
        post :create, params: { event_id: event.event_id, attendee: attributes_for(:attendee) }
        expect(response).to redirect_to(event)
      end

      it 'fills in the name when created as a user' do
        sign_in user

        expect do
          post :create, params: { event_id: event.event_id, attendee: attributes_for(:attendee, name: nil) }
        end.to change(Attendee, :count).by(1)
      end

      it 'notifies all admins' do
        create(:user_admin)
        expect do
          post :create, params: { event_id: event.event_id, attendee: attributes_for(:attendee) }
        end.to change(Notification, :count).by(1)
      end
    end

    context 'with invalid params' do
      it 'assigns a newly created but unsaved attendee as @attendee' do
        post :create, params: { event_id: event.event_id, attendee: attributes_for(:attendee, name: nil) }
        expect(assigns(:attendee)).to be_a_new(Attendee)
      end

      it "re-renders the 'new' template" do
        post :create, params: { event_id: event.event_id, attendee: attributes_for(:attendee, name: nil) }
        expect(response).to render_template('new')
      end
    end
  end

  describe 'GET #edit' do
    let(:attendee) { create(:attendee, event: event, user: user) }
    before(:each) { sign_in user }

    it 'assigns the requested event as @event' do
      get :edit, params: { event_id: event.to_param, id: attendee.to_param }
      expect(assigns(:event)).to eq(event)
    end

    it 'assigns the requested attendee as @attendee' do
      get :edit, params: { event_id: event.to_param, id: attendee.to_param }
      expect(assigns(:attendee)).to eq(attendee)
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:attendee) { create(:attendee, event: event, user: user) }
      let(:new_attributes) do
        { comment: 'Foo bar' }
      end

      before(:each) do
        attendee
        sign_in user
      end

      it 'updates the requested attendee' do
        put :update, params: { event_id: event.to_param, id: attendee.to_param, attendee: new_attributes }
        attendee.reload
        expect(attendee.comment).to eql('Foo bar')
      end

      it 'assigns the requested event as @event' do
        put :update, params: { event_id: event.to_param, id: attendee.to_param, attendee: new_attributes }
        expect(assigns(:event)).to eq(event)
      end

      it 'assigns the requested attendee as @attendee' do
        put :update, params: { event_id: event.to_param, id: attendee.to_param, attendee: new_attributes }
        attendee.reload
        expect(assigns(:attendee)).to eq(attendee)
      end

      it 'redirects to the event' do
        put :update, params: { event_id: event.to_param, id: attendee.to_param, attendee: new_attributes }
        expect(response).to redirect_to(event)
      end
    end

    context 'with invalid params' do
      let(:attendee) { create(:attendee, event: event, user: user) }
      let(:invalid_attributes) { { planned_arrival: '' } }

      before(:each) do
        attendee
        sign_in user
      end

      it 'assigns the event as @event' do
        put :update, params: { event_id: event.to_param, id: attendee.to_param, attendee: invalid_attributes }
        expect(assigns(:event)).to eq(event)
      end

      it 'assigns the attendee as @attendee' do
        put :update, params: { event_id: event.to_param, id: attendee.to_param, attendee: invalid_attributes }
        expect(assigns(:attendee)).to eq(attendee)
      end

      it "re-renders the 'edit' template" do
        put :update, params: { event_id: event.to_param, id: attendee.to_param, attendee: invalid_attributes }
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:attendee) { create(:attendee, event: event, user: user) }
    before(:each) do
      attendee # ugly but necessary, due to lazyness
      sign_in user
    end

    it 'destroys the requested attendee' do
      expect do
        delete :destroy, params: { event_id: event.event_id, id: attendee.to_param }
      end.to change(Attendee, :count).by(-1)
    end

    it 'redirects to the event' do
      delete :destroy, params: { event_id: event.event_id, id: attendee.to_param }
      expect(response).to redirect_to(event)
    end

    it 'unnotifies admins' do
      admin = create(:user_admin)
      Notification.create!(oid: attendee.attendee_id,
                           otype: 'attendee:create',
                           is_read: false,
                           path: '/foo/bar/baz',
                           subject: 'Bar',
                           recipient_id: admin.user_id)

      expect do
        delete :destroy, params: { event_id: event.event_id, id: attendee.to_param }
      end.to change(Notification, :count).by(-1)
    end
  end

  describe 'forbids access for closed events' do
    let(:cevent) { create(:event, start_date: Date.today - 3, end_date: Date.today - 3) }
    let(:attendee) { create(:attendee, event: cevent, user: user) }
    before(:each) { sign_in user }

    it 'forbids #new for closed events' do
      expect do
        get :new, params: { event_id: cevent.event_id }
      end.to raise_error(CForum::ForbiddenException)
    end

    it 'forbids #create for closed events' do
      expect do
        post :create, params: { event_id: cevent.event_id, attendee: attributes_for(:attendee) }
      end.to raise_error(CForum::ForbiddenException)
    end

    it 'forbids #edit for closed events' do
      expect do
        get :edit, params: { event_id: cevent.event_id, id: attendee.attendee_id }
      end.to raise_error(CForum::ForbiddenException)
    end

    it 'forbids #update for closed events' do
      expect do
        put :update, params: { event_id: cevent.event_id,
                               id: attendee.attendee_id,
                               attendee: attributes_for(:attendee) }
      end.to raise_error(CForum::ForbiddenException)
    end

    it 'forbids #destroy for closed events' do
      expect do
        delete :destroy, params: { event_id: cevent.event_id, id: attendee.attendee_id }
      end.to raise_error(CForum::ForbiddenException)
    end
  end
end
