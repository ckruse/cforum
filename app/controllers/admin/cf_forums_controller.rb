# -*- encoding: utf-8 -*-

class Admin::CfForumsController < ApplicationController
  authorize_controller { authorize_admin }

  before_filter :load_forum

  SHOW_FORUMLIST = "show_forumlist"

  def index
    @forums = CfForum.order('position ASC, UPPER(name) ASC')

    results = CfForum.connection.execute("SELECT table_name, group_crit, SUM(difference) AS diff FROM counter_table WHERE table_name = 'threads' OR table_name = 'messages' GROUP BY table_name, group_crit")

    @counts = {}
    results.each do |r|
      @counts[r['group_crit'].to_i] ||= {threads: 0, messages: 0}
      @counts[r['group_crit'].to_i][r['table_name'].to_sym] = r['diff']
    end

    msgs = CfMessage.includes(:owner, :thread => :forum).where("
      messages.message_id IN (
        SELECT (
          SELECT
            message_id
          FROM
            messages
          WHERE
              messages.forum_id = forums.forum_id
            AND
              deleted = false
          ORDER BY
            created_at DESC
          LIMIT 1
        )
        FROM forums
      )")

    @activities = {}
    msgs.each do |msg|
      @activities[msg.forum_id] = msg
    end

    notification_center.notify(SHOW_FORUMLIST, @threads, @activities, true)
  end

  def edit
    @settings = CfSetting.find_by_forum_id(@cf_forum.forum_id) || CfSetting.new
  end

  def forum_params
    params.require(:cf_forum).permit(:slug, :name, :short_name, :description, :standard_permission, :keywords, :position)
  end

  def update
    saved = false
    @settings = CfSetting.find_by_forum_id(@cf_forum.forum_id) || CfSetting.new
    @settings.options ||= {}
    @settings.forum_id = @cf_forum.forum_id

    unless params[:settings].blank?
      params[:settings].each do |k,v|
        if v == '_DEFAULT_'
          @settings.options.delete(k)
        else
          @settings.options[k] = v
        end
      end
    end

    @settings.options_will_change!

    CfForum.transaction do
      if @cf_forum.update_attributes(forum_params)
        raise ActiveRecord::Rollback.new unless saved = @settings.save
      end
    end

    if saved
      redirect_to edit_admin_forum_url(@cf_forum.forum_id), notice: I18n.t("admin.forums.updated")
    else
      render :edit
    end
  end

  def new
    @cf_forum = CfForum.new
    @settings = CfSetting.new
  end

  def create
    @cf_forum = CfForum.new(forum_params)
    @settings = CfSetting.new
    @settings.options ||= {}
    @settings.forum_id = @cf_forum.forum_id

    unless params[:settings].blank?
      params[:settings].each do |k,v|
        if v == '_DEFAULT_'
          @settings.options.delete(k)
        else
          @settings.options[k] = v
        end
      end
    end

    saved = false
    CfForum.transaction do
      if @cf_forum.save
        raise ActiveRecord::Rollback.new unless saved = @settings.save
      end
    end

    if saved
      redirect_to edit_admin_forum_url(@cf_forum.forum_id), notice: I18n.t("admin.forums.created")
    else
      render :new
    end
  end

  def destroy
    CfForum.transaction do
      CfForum.connection.execute "DELETE FROM messages WHERE forum_id = " + @cf_forum.forum_id.to_s
      CfForum.connection.execute "DELETE FROM threads WHERE forum_id = " + @cf_forum.forum_id.to_s
      @cf_forum.destroy
    end

    redirect_to admin_forums_url, notice: I18n.t("admin.forums.destroyed")
  end

  def merge
    @forums = CfForum.order(:name)
    @merge_with = params[:merge_with]
  end

  def do_merge
    @merge_forum = CfForum.find_by_forum_id params[:merge_with]

    if @merge_forum
      CfForum.transaction do
        CfForum.connection.execute 'UPDATE threads SET forum_id = ' + @merge_forum.forum_id.to_s + ' WHERE forum_id = ' + @cf_forum.forum_id.to_s
        CfMessage.connection.execute 'UPDATE messages SET forum_id = ' + @merge_forum.forum_id.to_s + ' WHERE forum_id = ' + @cf_forum.forum_id.to_s
        CfForumGroupPermission.connection.execute 'DELETE FROM forums_groups_permissions WHERE forum_id = ' + @merge_forum.forum_id.to_s

        @cf_forum.destroy
      end

      redirect_to admin_forums_url, notice: I18n.t('admin.forums.merged')
    else
      flash[:error] = 'Forum to merge with not found!' # TODO: i18n/l10n
      @forums = CfForum.order(:name)
      @merge_with = params[:merge_with]

      render :merge
    end
  end

  private
  def load_forum
    @cf_forum = CfForum.unscoped.find params[:id] if params[:id]
  end
end
