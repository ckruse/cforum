# -*- encoding: utf-8 -*-

class Admin::CfForumsController < CfForumsController
  load_and_authorize_resource

  def index
    @forums = CfForum.order('name ASC').find(:all)
    results = CfThread.select('forum_id, COUNT(thread_id) AS cnt').group('forum_id')

    @counts = {}
    results.each do |r|
      @counts[r.forum_id] = r.cnt.to_i
    end

    results = CfForum.select("forum_id, (SELECT updated_at FROM cforum.messages WHERE cforum.messages.forum_id = cforum.forums.forum_id AND deleted = false ORDER BY updated_at DESC LIMIT 1) AS updated_at")
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
    if @cf_forum.update_attributes(params[:cf_user])
      redirect_to edit_admin_cf_forum_url(@cf_forum.forum_id), notice: I18n.t("admin.forums.updated")
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
      redirect_to admin_cf_forum_url(@cf_forum.forum_id), notice: I18n.t("admin.forums.created")
    else
      render :new
    end
  end

  def destroy
    @cf_forum.destroy

    redirect_to admin_cf_forums_url, notice: I18n.t("admin.forums.destroyed")
  end
end
