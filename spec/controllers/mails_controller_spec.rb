require 'rails_helper'

RSpec.describe MailsController, type: :controller do
  let(:user) { create(:user) }
  let(:mail) { create(:priv_message, recipient: user, owner: user) }
  before(:each) do
    mail # fu laziness
    sign_in user
  end

  describe 'GET #index' do
    it 'assigns all messages to @mails' do
      get :index
      expect(assigns(:mails)).to eq([mail])
    end
    it 'assigns only user messages to @mails' do
      create(:priv_message, recipient: user, owner: user)
      get :index, params: { user: mail.sender_name }
      expect(assigns(:mails)).to eq([mail])
    end
  end

  describe 'GET #show' do
    it 'assigns the message as @mail' do
      get :show, params: { id: mail.to_param, user: mail.sender_name }
      expect(assigns(:mail)).to eq(mail)
    end

    it 'deletes the notification' do
      Notification.create!(subject: 'foo', path: '/foo/bar/baz',
                           recipient_id: user.user_id,
                           oid: mail.to_param,
                           otype: 'mails:create')

      expect do
        get :show, params: { id: mail.to_param, user: mail.sender_name }
      end.to change(Notification, :count).by(-1)
    end

    it 'marks the notification as read when configured' do
      n = Notification.create!(subject: 'foo', path: '/foo/bar/baz',
                               recipient_id: user.user_id,
                               oid: mail.to_param,
                               otype: 'mails:create')
      Setting.create!(user_id: user.user_id, options: { 'delete_read_notifications_on_new_mail' => 'no' })

      get :show, params: { id: mail.to_param, user: mail.sender_name }

      n.reload
      expect(n.is_read).to be true
    end
  end

  describe 'GET #new' do
    it 'assigns the new mail as @mail' do
      get :new
      expect(assigns(:mail)).to be_a_new(PrivMessage)
    end

    it 'creates an answer when giving a message id' do
      get :new, params: { priv_message_id: mail.priv_message_id }
      expect(assigns(:mail).recipient_id).to eq mail.sender_id
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      { subject: 'foo', body: 'foo bar foo bar' }
    end
    let(:invalid_attributes) do
      { subject: '', body: 'foo bar foo bar' }
    end

    context 'with valid params' do
      it 'creates a new mail' do
        expect do
          post :create, params: { priv_message: valid_attributes.merge(recipient_id: user.user_id) }
        end.to change(PrivMessage, :count).by(2)
      end

      it 'assigns a newly created mail as @mail' do
        post :create, params: { priv_message: valid_attributes.merge(recipient_id: user.user_id) }
        expect(assigns(:mail)).to be_a(PrivMessage)
        expect(assigns(:mail)).to be_persisted
      end

      it 'redirects to the new mail' do
        post :create, params: { priv_message: valid_attributes.merge(recipient_id: user.user_id) }
        expect(response).to redirect_to(mail_url(user.username, assigns(:mail).to_param))
      end
    end

    context 'with invalid params' do
      it 'assigns a newly created but unsaved mail as @mail' do
        post :create, params: { priv_message: invalid_attributes }
        expect(assigns(:mail)).to be_a_new(PrivMessage)
      end

      it "re-renders the 'new' template" do
        post :create, params: { priv_message: invalid_attributes }
        expect(response).to render_template('new')
      end

      it 'renders the new template when only recipient is missing' do
        post :create, params: { priv_message: valid_attributes }
        expect(response).to render_template('new')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes a mail' do
      expect do
        delete :destroy, params: { user: mail.sender_name, id: mail.to_param }
      end.to change(PrivMessage, :count).by(-1)
    end

    it 'redirects to index' do
      delete :destroy, params: { user: mail.sender_name, id: mail.to_param }
      expect(response).to redirect_to(mails_url)
    end
  end

  describe 'DELETE #batch_destroy' do
    it 'deletes one mail' do
      expect do
        delete :batch_destroy, params: { ids: [mail.to_param] }
      end.to change(PrivMessage, :count).by(-1)
    end

    it 'deletes more than one mail' do
      m1 = create(:priv_message, recipient: user, owner: user)

      expect do
        delete :batch_destroy, params: { ids: [mail.to_param, m1.to_param] }
      end.to change(PrivMessage, :count).by(-2)
    end

    it 'redirects to index' do
      delete :batch_destroy, params: { ids: [mail.to_param] }
      expect(response).to redirect_to(mails_url)
    end

    it "doesn't fail with empty IDs" do
      delete :batch_destroy, params: { ids: [] }
      expect(response).to redirect_to(mails_url)
    end
  end

  describe 'POST #mark_read_unread' do
    it 'marks a read message as unread' do
      post :mark_read_unread, params: { user: mail.sender_name, id: mail.to_param }
      mail.reload
      expect(mail.is_read).to be true
    end

    it 'marks a unread message as read' do
      mail.is_read = true
      mail.save!

      post :mark_read_unread, params: { user: mail.sender_name, id: mail.to_param }

      mail.reload
      expect(mail.is_read).to be false
    end

    it 'redirects to index' do
      post :mark_read_unread, params: { user: mail.sender_name, id: mail.to_param }
      expect(response).to redirect_to(mails_url)
    end
  end
end

# eof
