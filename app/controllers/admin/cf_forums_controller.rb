# -*- encoding: utf-8 -*-

class Admin::CfForumsController < ApplicationController #< CfForumsController
  before_filter :load_forum
  authorize_resource

  SHOW_FORUMLIST = "show_forumlist"

  def index
    @forums = CfForum.unscoped.order('name ASC').find(:all)
    results = CfForum.connection.execute("SELECT table_name, group_crit, SUM(difference) AS diff FROM cforum.counter_table WHERE table_name = 'threads' OR table_name = 'messages' GROUP BY table_name, group_crit")

    @counts = {}
    results.each do |r|
      @counts[r['group_crit'].to_i] ||= {threads: 0, messages: 0}
      @counts[r['group_crit'].to_i][r['table_name'].to_sym] = r['diff']
    end

    results = CfForum.unscoped.select("forum_id, (SELECT updated_at FROM cforum.messages WHERE cforum.messages.forum_id = cforum.forums.forum_id AND deleted = false ORDER BY updated_at DESC LIMIT 1) AS updated_at")
    @activities = {}
    results.each do |row|
      @activities[row.forum_id] = row.updated_at
    end

    notification_center.notify(SHOW_FORUMLIST, @threads, true)
  end

  def show
  end

  def edit
  end

  def update
    if @cf_forum.update_attributes(params[:cf_forum])
      redirect_to edit_admin_forum_url(@cf_forum.forum_id), notice: I18n.t("admin.forums.updated")
    else
      render :edit
    end
  end

  def new
    @cf_forum = CfForum.new
  end

  def create
    @cf_forum = CfForum.new(params[:cf_forum])

    if @cf_forum.save
      redirect_to admin_forum_url(@cf_forum.forum_id), notice: I18n.t("admin.forums.created")
    else
      render :new
    end
  end

  def destroy
    CfForum.transaction do
      CfForum.connection.execute "DELETE FROM cforum.messages WHERE forum_id = " + @cf_forum.forum_id.to_s
      CfForum.connection.execute "DELETE FROM cforum.threads WHERE forum_id = " + @cf_forum.forum_id.to_s
      @cf_forum.destroy
    end

    redirect_to admin_forums_url, notice: I18n.t("admin.forums.destroyed")
  end

  def merge
    @forums = CfForum.order(:name).find :all
    @merge_with = params[:merge_with]
  end

  def do_merge
    CfForum.transaction do
      CfForum.connection.execute 'UPDATE cforum.threads SET forum_id = ' + params[:merge_with].to_i.to_s + ' WHERE forum_id = ' + @cf_forum.forum_id.to_s
      CfMessage.connection.execute 'UPDATE cforum.messages SET forum_id = ' + params[:merge_with].to_i.to_s + ' WHERE forum_id = ' + @cf_forum.forum_id.to_s
      CfModerator.connection.execute 'UPDATE cforum.moderators SET forum_id = ' + params[:merge_with].to_i.to_s + ' WHERE forum_id = ' + @cf_forum.forum_id.to_s

      @cf_forum.destroy
    end

    redirect_to admin_forums_url, notice: I18n.t('admin.forums.merged')
  end

  private
  def load_forum
    @cf_forum = CfForum.unscoped.find params[:id] if params[:id]
  end
end
