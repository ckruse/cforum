class MailsController < ApplicationController
  include UserDataHelper

  before_action :index_users

  authorize_controller { authorize_user }

  def index_users
    cu    = current_user
    mails = PrivMessage
              .select('(CASE recipient_id' \
                      " WHEN #{cu.user_id} THEN sender_name " \
                      ' ELSE recipient_name END) AS username, ' \
                      'is_read, COUNT(*) AS cnt')
              .where('owner_id = ?', current_user.user_id)
              .group("username, CASE recipient_id WHEN #{cu.user_id} THEN sender_id ELSE recipient_id end, is_read")

    @mail_users = {}
    mails.each do |mu|
      @mail_users[mu.username] ||= { read: 0, unread: 0 }
      @mail_users[mu.username][mu.is_read? ? :read : :unread] += mu.cnt
    end
  end

  def index
    if params[:user]
      @user = params[:user]
      @user_object = User.where(username: params[:user]).first
      @mails = PrivMessage
                 .preload(:sender, :recipient)
                 .where('owner_id = ? AND (sender_name = ? OR recipient_name = ?)',
                        current_user.user_id, @user, @user)

    else
      @mails = PrivMessage
                 .preload(:sender, :recipient)
                 .where(owner_id: current_user.user_id)
    end

    @mails = sort_query(%w[created_at sender recipient subject],
                        @mails, { sender: 'sender_name',
                                  recipient: 'recipient_name' },
                        dir: :desc)

    @mail_groups = {}
    @mail_groups_keys = []
    @mails.each do |mail|
      key = mail.subject.gsub(/^Re: /, '') + '-' + mail.partner(current_user)
      @mail_groups_keys << key if @mail_groups[key].blank?

      @mail_groups[key] ||= []
      @mail_groups[key] << mail
    end

    @mail_groups_keys.each do |k|
      @mail_groups[k] = @mail_groups[k].sort do |a, b|
        if uconf('mail_thread_sort') == 'ascending'
          a.created_at <=> b.created_at
        else
          b.created_at <=> a.created_at
        end
      end
    end
  end

  def show
    @mail = PrivMessage.includes(:sender, :recipient)
              .where(owner_id: current_user.user_id, priv_message_id: params[:id])
              .first!

    return if @mail.is_read

    PrivMessage.transaction do
      @mail.update(is_read: true)

      n = Notification.where(recipient_id: current_user.user_id,
                             oid: @mail.priv_message_id,
                             otype: 'mails:create', is_read: false).first

      if n.present?
        @new_notifications -= [n]

        if uconf('delete_read_notifications_on_new_mail') == 'yes'
          n.destroy
        else
          n.is_read = true
          n.save!
        end
      end
    end
  end

  def new
    @mail = PrivMessage.new(params[:priv_message].blank? ? {} : priv_message_params)

    if params[:priv_message_id].present?
      @parent = PrivMessage
                  .where(owner_id: current_user.user_id,
                         priv_message_id: params[:priv_message_id])
                  .first!
    end

    if @parent.present?
      @mail.recipient_id = @parent.recipient_id == current_user.user_id ? @parent.sender_id : @parent.recipient_id
      @mail.subject      = @parent.subject.match?(/^Re:/i) ? @parent.subject : 'Re: ' + @parent.subject
      @mail.body         = @parent.to_quote(self) if params.key?(:quote_old_message)
      @mail.thread_id    = @parent.thread_id
    end

    @mail.body = gen_content(@mail.body, @mail.recipient.try(:username))
  end

  def create
    @mail           = PrivMessage.new(priv_message_params)
    @mail.sender_id = current_user.user_id
    @mail.sender_name = current_user.username
    @mail.owner_id  = current_user.user_id
    @mail.is_read   = true

    @mail.body      = PrivMessage.to_internal(@mail.body)

    @preview = params[:preview].present?

    saved = false
    if @mail.recipient_id.present?
      recipient = User.find(@mail.recipient_id)

      @mail.recipient_name = recipient.username

      @mail_recipient           = PrivMessage.new(priv_message_params)
      @mail_recipient.sender_id = current_user.user_id
      @mail_recipient.sender_name = current_user.username
      @mail_recipient.recipient_name = recipient.username
      @mail_recipient.owner_id  = recipient.user_id
      @mail_recipient.body      = PrivMessage.to_internal(@mail_recipient.body)

      unless @preview
        PrivMessage.transaction do
          if @mail.save
            @mail_recipient.thread_id = @mail.thread_id
            saved = @mail_recipient.save
          end

          raise ActiveRecord::Rollback unless saved
        end
      end

    else
      flash[:error] = t('mails.define_recipient_please')
    end

    respond_to do |format|
      if saved
        format.html do
          redirect_to mail_url(recipient.username, @mail),
                      notice: t('mails.sent')
        end
        format.json { render json: @mail, status: :created }

        unread = PrivMessage.where(owner_id: @mail.recipient_id, is_read: false).count
        BroadcastUserJob.perform_later({ type: 'mail:create', mail: @mail, unread: unread },
                                       @mail.recipient_id)
      else
        format.html { render :new }
        format.json { render json: @mail.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @mail = PrivMessage.where(owner_id: current_user.user_id,
                              priv_message_id: params[:id]).first!
    @mail.destroy

    respond_to do |format|
      format.html { redirect_to mails_url, notice: t('mails.destroyed') }
      format.json { head :no_content }
    end
  end

  def batch_destroy
    if params[:ids].present?
      PrivMessage.transaction do
        @mails = PrivMessage.where(owner_id: current_user.user_id,
                                   priv_message_id: params[:ids])
        @mails.each(&:destroy)
      end
    end

    redirect_to mails_url, notice: t('mails.destroyed')
  end

  def mark_read_unread
    @mail = PrivMessage.where(owner_id: current_user.user_id,
                              priv_message_id: params[:id]).first!

    @mail.is_read = !@mail.is_read

    respond_to do |format|
      if @mail.save
        format.html { redirect_to mails_url, notice: t('mails.marked_' + (@mail.is_read? ? 'read' : 'unread')) }
        format.json { render json: @mail }
      else
        format.html { redirect_to mails_url, notice: t('global.something_went_wrong') }
        format.json { render json: @mail.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def priv_message_params
    params.require(:priv_message).permit(:recipient_id, :subject, :body, :thread_id)
  end
end

# eof
