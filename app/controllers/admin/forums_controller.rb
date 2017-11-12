class Admin::ForumsController < ApplicationController
  authorize_controller { authorize_admin }

  before_action :load_forum

  SHOW_FORUMLIST = 'show_forumlist'.freeze

  def index
    @forums = Forum.order('position ASC, UPPER(name) ASC')

    results = Forum.connection.execute('SELECT table_name, group_crit, SUM(difference) AS diff ' \
                                       "  FROM counter_table WHERE table_name = 'threads' OR table_name = 'messages'" \
                                       '  GROUP BY table_name, group_crit')

    @counts = {}
    results.each do |r|
      @counts[r['group_crit'].to_i] ||= { threads: 0, messages: 0 }
      @counts[r['group_crit'].to_i][r['table_name'].to_sym] = r['diff']
    end

    msgs = Message.includes(:owner, thread: :forum).where("
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
  end

  def edit
    @settings = Setting.find_by(forum_id: @forum.forum_id) || Setting.new
  end

  def forum_params
    params.require(:forum).permit(:slug, :name, :short_name, :description, :standard_permission, :keywords, :position)
  end

  def update
    saved = false
    @settings = Setting.find_by(forum_id: @forum.forum_id) || Setting.new
    @settings.options ||= {}
    @settings.forum_id = @forum.forum_id

    if params[:settings].present?
      params[:settings].each do |k, v|
        if v == '_DEFAULT_'
          @settings.options.delete(k)
        else
          @settings.options[k] = v
        end
      end
    end

    @settings.options_will_change!

    Forum.transaction do
      if @forum.update_attributes(forum_params)
        saved = @settings.save
        raise ActiveRecord::Rollback unless saved
      end
    end

    if saved
      redirect_to edit_admin_forum_url(@forum.forum_id), notice: I18n.t('admin.forums.updated')
    else
      render :edit
    end
  end

  def new
    @forum = Forum.new
    @settings = Setting.new
  end

  def create
    @forum = Forum.new(forum_params)
    @settings = Setting.new
    @settings.options ||= {}
    @settings.forum_id = @forum.forum_id

    if params[:settings].present?
      params[:settings].each do |k, v|
        if v == '_DEFAULT_'
          @settings.options.delete(k)
        else
          @settings.options[k] = v
        end
      end
    end

    saved = false
    Forum.transaction do
      if @forum.save
        saved = @settings.save
        raise ActiveRecord::Rollback unless saved
      end
    end

    if saved
      redirect_to edit_admin_forum_url(@forum.forum_id), notice: I18n.t('admin.forums.created')
    else
      render :new
    end
  end

  def destroy
    Forum.transaction do
      Forum.connection.execute 'DELETE FROM messages WHERE forum_id = ' + @forum.forum_id.to_s
      Forum.connection.execute 'DELETE FROM threads WHERE forum_id = ' + @forum.forum_id.to_s
      @forum.destroy
    end

    redirect_to admin_forums_url, notice: I18n.t('admin.forums.destroyed')
  end

  def merge
    @forums = Forum.order(:name)
    @merge_with = params[:merge_with]
  end

  def do_merge
    @merge_forum = Forum.find_by forum_id: params[:merge_with]

    if @merge_forum
      Forum.transaction do
        Forum.connection.execute 'UPDATE threads SET forum_id = ' + @merge_forum.forum_id.to_s +
                                 ' WHERE forum_id = ' + @forum.forum_id.to_s
        Message.connection.execute 'UPDATE messages SET forum_id = ' + @merge_forum.forum_id.to_s +
                                   ' WHERE forum_id = ' + @forum.forum_id.to_s
        ForumGroupPermission.connection.execute 'DELETE FROM forums_groups_permissions WHERE forum_id = ' +
                                                @merge_forum.forum_id.to_s

        @forum.destroy
      end

      redirect_to admin_forums_url, notice: I18n.t('admin.forums.merged')
    else
      flash[:error] = 'Forum to merge with not found!' # TODO: i18n/l10n
      @forums = Forum.order(:name)
      @merge_with = params[:merge_with]

      render :merge
    end
  end

  private

  def load_forum
    @forum = Forum.unscoped.find params[:id] if params[:id]
  end
end
