# -*- encoding: utf-8 -*-

class MailsController < ApplicationController
  before_filter :authorize!, :index_users

  include AuthorizeUser

  def index_users
    cu    = current_user
    mails = CfPrivMessage
      .preload(:sender, :recipient)
      .where('owner_id = ?', current_user.user_id)
      .all

    @mail_users = {}
    mails.each do |mu|
      if mu.recipient_id != cu.user_id
        @mail_users[mu.recipient.username]         ||= {read: 0, unread: 0}
        @mail_users[mu.recipient.username][:read]   += 1 if mu.is_read?
        @mail_users[mu.recipient.username][:unread] += 1 unless mu.is_read?
      else
        @mail_users[mu.sender.username]          ||= {read: 0, unread: 0}
        @mail_users[mu.sender.username][:read]    += 1 if mu.is_read?
        @mail_users[mu.sender.username][:unread ] += 1 unless mu.is_read?
      end
    end
  end

  def index
    if params[:user]
      @user  = CfUser.find_by_username! params[:user]
      @mails = CfPrivMessage
        .includes(:sender, :recipient)
        .where("owner_id = ? AND (sender_id = ? OR recipient_id = ?)", current_user.user_id, @user.user_id, @user.user_id)
        .order('created_at ASC')
        .all
    else
      @mails = CfPrivMessage
        .includes(:sender, :recipient)
        .where(owner_id: current_user.user_id)
        .order('created_at ASC')
        .limit(conf('pagination', 50).to_i)
        .all
    end
  end

  def show
    @mail = CfPrivMessage.includes(:sender, :recipient).find_by_owner_id_and_priv_message_id!(current_user.user_id, params[:id])

    unless @mail.is_read
      @mail.is_read = true
      @mail.save
    end
  end

  def new
    @mail = CfPrivMessage.new(params[:cf_priv_message])
  end

  def create
    @mail           = CfPrivMessage.new(params[:cf_priv_message])
    @mail.sender_id = current_user.user_id
    @mail.owner_id  = current_user.user_id
    @mail.is_read   = true

    recipient = CfUser.find(@mail.recipient_id)

    @mail_recipient           = CfPrivMessage.new(params[:cf_priv_message])
    @mail_recipient.sender_id = current_user.user_id
    @mail_recipient.owner_id  = recipient.user_id

    saved = false
    CfPrivMessage.transaction do
      if @mail.save
        saved = @mail_recipient.save
      end

      notify_user(
        recipient,
        'notify_on_new_mail',
        t('notifications.new_mail',
          user: current_user.username,
          subject: @mail.subject),
        mail_path(current_user.username, @mail)
      )

      raise ActiveRecord::Rollback.new unless saved
    end

    respond_to do |format|
      if saved
        format.html { redirect_to mail_url(recipient.username, @mail), notice: t('mails.sent') }
        format.json { render json: @mail, status: :created }
      else
        format.html { render :new }
        format.json { render json: @mail.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @mail = CfPrivMessage.find_by_owner_id_and_priv_message_id!(current_user.user_id, params[:id])
    @mail.destroy

    respond_to do |format|
      format.html { redirect_to mails_url, notice: t('mails.destroyed') }
      format.json { head :no_content }
    end
  end

end

# eof
