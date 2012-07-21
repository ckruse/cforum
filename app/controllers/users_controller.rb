# -*- encoding: utf-8 -*-

class UsersController < ApplicationController

  def new
    @user = CForum::User.new
  end

  def create
    @user = CForum::User.new(params[:c_forum_user])

    if @user.save
      redirect_to root_url, :notice => I18n.t('users.signed_up')
    else
      render :new
    end
  end
end

# eof