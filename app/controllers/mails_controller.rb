# -*- encoding: utf-8 -*-

class MailsController < ApplicationController
  before_filter :authorize!, :index_users

  include AuthorizeUser

  def index_users
    cu    = current_user
    mails = CfPrivMessage.
            select("username, is_read, COUNT(*) AS cnt").
            joins("INNER JOIN users ON user_id = case recipient_id when #{cu.user_id} then sender_id else recipient_id end").
            where('owner_id = ?', current_user.user_id).
            group("username, case recipient_id when #{cu.user_id} then sender_id else recipient_id end, is_read")

    @mail_users = {}
    mails.each do |mu|
      @mail_users[mu.username] ||= {read: 0, unread: 0}
      @mail_users[mu.username][mu.is_read? ? :read : :unread] += mu.cnt
    end
  end

  def index
    if params[:user]
      @user  = CfUser.where(username: params[:user]).first!
      @mails = CfPrivMessage.
               preload(:sender, :recipient).
               joins("INNER JOIN users AS senders ON senders.user_id = sender_id, INNER JOIN users AS recipients ON recipients.user_id = recipient_id").
               where("owner_id = ? AND (sender_id = ? OR recipient_id = ?)",
                     current_user.user_id, @user.user_id, @user.user_id)

    else
      @mails = CfPrivMessage.
               includes(:sender, :recipient).
               where(owner_id: current_user.user_id)
    end

    @mails = sort_query(%w(created_at sender recipient subject),
                        @mails, {sender: "senders.username",
                                 recipient: 'recipients.username'}).
             page(params[:page]).per(conf('pagination', 50).to_i)
  end

  def show
    @mail = CfPrivMessage.includes(:sender, :recipient).
      where(owner_id: current_user.user_id, priv_message_id: params[:id]).first!

    unless @mail.is_read
      CfPrivMessage.transaction do
        @mail.is_read = true
        @mail.save!

        if n = CfNotification.where(recipient_id: current_user.user_id,
                                    oid: @mail.priv_message_id,
                                    otype: 'mails:create', is_read: false).first
          @new_notifications -= [n]

          if uconf('delete_read_notifications_on_new_mail', 'yes') == 'yes'
            n.destroy
          else
            n.is_read = true
            n.save!
          end
        end
      end
    end
  end

  def priv_message_params
    params.require(:cf_priv_message).permit(:recipient_id, :subject, :body)
  end

  def new
    @mail = CfPrivMessage.new(params[:cf_priv_message].blank? ? {} :
                              priv_message_params)

    if not params[:priv_message_id].blank? and
        @parent = CfPrivMessage.where(owner_id: current_user.user_id,
                                      priv_message_id: params[:priv_message_id]).first!
      @mail.recipient_id = @parent.recipient_id == current_user.user_id ? @parent.sender_id : @parent.recipient_id
      @mail.subject      = @parent.subject =~ /^Re:/i ? @parent.subject : 'Re: ' + @parent.subject
      @mail.body         = @parent.to_quote(self) if params.has_key?(:quote_old_message)
    end
  end

  def create
    @mail           = CfPrivMessage.new(priv_message_params)
    @mail.sender_id = current_user.user_id
    @mail.owner_id  = current_user.user_id
    @mail.is_read   = true

    @mail.body      = CfPrivMessage.to_internal(@mail.body)

    saved = false
    if not @mail.recipient_id.blank?
      recipient = CfUser.find(@mail.recipient_id)

      @mail_recipient           = CfPrivMessage.new(priv_message_params)
      @mail_recipient.sender_id = current_user.user_id
      @mail_recipient.owner_id  = recipient.user_id
      @mail_recipient.body      = CfPrivMessage.to_internal(@mail_recipient.body)

      CfPrivMessage.transaction do
        if @mail.save
          saved = @mail_recipient.save
        end

        if saved
          notify_user(
            user: recipient,
            hook: 'notify_on_new_mail',
            subject: t('notifications.new_mail',
              user: current_user.username,
              subject: @mail.subject),
            path: mail_path(current_user.username, @mail_recipient),
            oid: @mail_recipient.priv_message_id,
            otype: 'mails:create',
            icon: 'icon-envelope',
            body: @mail.to_txt
          )
        end

        raise ActiveRecord::Rollback.new unless saved
      end

    else
      flash[:error] = t('mails.define_recipient_please')
    end

    respond_to do |format|
      if saved
        format.html { redirect_to mail_url(recipient.username, @mail),
          notice: t('mails.sent') }
        format.json { render json: @mail, status: :created }
      else
        format.html { render :new }
        format.json { render json: @mail.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @mail = CfPrivMessage.where(owner_id: current_user.user_id,
                                priv_message_id: params[:id]).first!
    @mail.destroy

    respond_to do |format|
      format.html { redirect_to mails_url, notice: t('mails.destroyed') }
      format.json { head :no_content }
    end
  end

  def batch_destroy
    unless params[:ids].blank?
      CfPrivMessage.transaction do
        @mails = CfPrivMessage.where(owner_id: current_user.user_id,
                                     priv_message_id: params[:ids])
        @mails.each do |m|
          m.destroy
        end
      end
    end

    redirect_to mails_url, notice: t('mails.destroyed')
  end

end

# eof
