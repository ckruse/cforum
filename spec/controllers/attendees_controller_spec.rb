require 'rails_helper'

RSpec.describe AttendeesController, type: :controller do

  let(:event) { create(:event) }
  let(:user) { create(:user) }

  describe "GET #new" do
    it "assigns a new attendee as @attendee" do
      get :new, event_id: event.event_id
      expect(assigns(:attendee)).to be_a_new(Attendee)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Attendee" do
        expect {
          post :create, event_id: event.event_id, attendee: attributes_for(:attendee)
        }.to change(Attendee, :count).by(1)
      end

      it "assigns a newly created attendee as @attendee" do
        post :create, event_id: event.event_id, attendee: attributes_for(:attendee)
        expect(assigns(:attendee)).to be_a(Attendee)
        expect(assigns(:attendee)).to be_persisted
      end

      it "redirects to the event attendee" do
        post :create, event_id: event.event_id, attendee: attributes_for(:attendee)
        expect(response).to redirect_to(event)
      end

      it "fills in the name when created as a user" do
        sign_in user

        expect {
          post :create, event_id: event.event_id, attendee: attributes_for(:attendee, name: nil)
        }.to change(Attendee, :count).by(1)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved attendee as @attendee" do
        post :create, event_id: event.event_id, attendee: attributes_for(:attendee, name: nil)
        expect(assigns(:attendee)).to be_a_new(Attendee)
      end

      it "re-renders the 'new' template" do
        post :create, event_id: event.event_id, attendee: attributes_for(:attendee, name: nil)
        expect(response).to render_template("new")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested attendee" do
      attendee = create(:attendee, event: event)
      expect {
        delete :destroy, event_id: event.event_id, id: attendee.to_param
      }.to change(Attendee, :count).by(-1)
    end

    it "redirects to the event" do
      attendee = create(:attendee, event: event)
      delete :destroy, event_id: event.event_id, id: attendee.to_param
      expect(response).to redirect_to(event)
    end
  end

end
