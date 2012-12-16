# -*- coding: utf-8 -*-

class Admin::CfForumPermissionsController < ApplicationController
  before_filter :authorize!, :load_forum

  include Admin::AuthorizeHelper

  # GET /collections
  # GET /collections.json
  def index
    @permissions = CfForumPermission.includes(:forum, :user).find_all_by_forum_id(params[:forum_id])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @permission }
    end
  end

  # GET /collections/1
  # GET /collections/1.json
  def show
    @permission = CfForumPermission.find_by_forum_id_and_forum_permission_id!(params[:forum_id], params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @permission }
    end
  end

  # GET /collections/new
  # GET /collections/new.json
  def new
    @permission = CfForumPermission.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @permission }
    end
  end

  # GET /collections/1/edit
  def edit
    @permission = CfForumPermission.find_by_forum_id_and_forum_permission_id!(params[:forum_id], params[:id])
  end

  # POST /collections
  # POST /collections.json
  def create
    @permission = CfForumPermission.new(params[:cf_forum_permission])
    @user = CfUser.find_by_username! params[:username]

    @permission.user_id  = @user.user_id
    @permission.forum_id = @cf_forum.forum_id

    respond_to do |format|
      if @permission.save
        format.html {
          redirect_to edit_admin_forum_permission_url(@cf_forum.forum_id, @permission),
            notice: I18n.t('admin.forums.permissions.created')
        }
        format.json { render json: @permission, status: :created }
      else
        format.html { render action: "new" }
        format.json { render json: @permission.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /collections/1
  # PUT /collections/1.json
  def update
    @permission = CfForumPermission.find_by_forum_id_and_forum_permission_id!(params[:forum_id], params[:id])

    respond_to do |format|
      if @permission.update_attributes(params[:cf_forum_permission])
        format.html {
          redirect_to edit_admin_forum_permission_url(@cf_forum.forum_id, @permission),
            notice: I18n.t('admin.forums.permissions.updated')
        }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @permission.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /collections/1
  # DELETE /collections/1.json
  def destroy
    @permission = CfForumPermission.find_by_forum_id_and_forum_permission_id!(params[:forum_id], params[:id])
    @permission.destroy

    respond_to do |format|
      format.html {
        redirect_to admin_cf_forum_permissions_url(@cf_forum.forum_id),
          notice: I18n.t('admin.forums.permissions.destroyed')
      }
      format.json { head :no_content }
    end
  end

  private
  def load_forum
    @cf_forum = CfForum.unscoped.find params[:forum_id] if params[:forum_id]
  end
end

# eof