# -*- encoding: utf-8 -*-

class MailsController < ApplicationController
  before_filter :authorize!, :index_users

  include AuthorizeUser

  def index_users
    mail_users = CfPrivMessage
      .preload(:sender)
      .select('sender_id, is_read, COUNT(*) AS cnt')
      .where('owner_id = ?', current_user.user_id)
      .group('sender_id, is_read')
      .all

    @mail_users = {}
    mail_users.each do |mu|
      @mail_users[mu.sender.username]        ||= {read: 0, unread: 0}
      @mail_users[mu.sender.username][:read]   = mu.cnt.to_i if mu.is_read?
      @mail_users[mu.sender.username][:unread] = mu.cnt.to_i unless mu.is_read?
    end
  end

  def index
    if params[:user]
      @user  = CfUser.find_by_username! params[:user]
      @mails = CfPrivMessage
        .includes(:sender, :recipient)
        .where(owner_id: current_user.user_id, sender_id: @user.user_id)
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
    @mail = CfPrivMessage.new
  end

  def create
    # @user = CfUser.new(params[:cf_user])

    # if @user.save
    #   redirect_to edit_admin_user_url(@user), notice: I18n.t('admin.users.created')
    # else
    #   render :new
    # end
  end

  def destroy
    # @user.destroy

    # redirect_to admin_users_url, notice: I18n.t('admin.users.deleted')
  end

end

# eof
