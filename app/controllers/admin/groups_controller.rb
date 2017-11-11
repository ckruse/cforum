class Admin::GroupsController < ApplicationController
  authorize_controller { authorize_admin }

  def index
    @limit = conf('pagination').to_i
    @limit = 50 if @limit <= 0

    @groups = Group.select('*, (SELECT COUNT(*) FROM groups_users WHERE group_id = groups.group_id) AS members_cnt')
    @groups = sort_query(%w[name members_cnt created_at updated_at],
                         @groups, members_cnt: '(SELECT COUNT(*) FROM groups_users WHERE group_id = groups.group_id)')
                .page(params[:page]).per(@limit)
  end

  def edit
    @group = Group.find params[:id]
    @forums_groups_permissions = @group.forums_groups_permissions
    @users = @group.users
    @forums = Forum.all
  end

  def group_params
    params.require(:group).permit(:name)
  end

  def update
    @group = Group.find params[:id]
    @forums = Forum.all

    @users = []
    @users = User.find(params[:users]) if params[:users].present?

    saved = false
    Group.transaction do
      raise ActiveRecord::Rollback unless @group.update_attributes(group_params)

      @group.group_users.clear
      @users.each do |u|
        @group.group_users.create!(user_id: u.user_id)
      end

      @group.forums_groups_permissions.clear
      if params[:forums].present? && params[:permissions].present?
        params[:forums].each_with_index do |forum, i|
          next if forum.blank? || params[:permissions][i].blank?

          @group.forums_groups_permissions.create!(forum_id: forum,
                                                   permission: params[:permissions][i])
        end
      end

      saved = true
    end

    if saved
      redirect_to edit_admin_group_url(@group), notice: I18n.t('admin.groups.updated')
    else
      render :edit
    end
  end

  def new
    @group = Group.new
    @forums = Forum.all
    @forums_groups_permissions = []
    @users = []
  end

  def create
    @group = Group.new(group_params)
    @forums = Forum.all

    @users = []
    @users = User.find(params[:users]) if params[:users].present?

    saved = false
    Group.transaction do
      raise ActiveRecord::Rollback unless @group.save

      @users.each do |u|
        @group.group_users.create!(user_id: u.user_id)
      end

      if params[:forums].present? && params[:permissions].present?
        params[:forums].each_with_index do |forum, i|
          next if forum.blank? || params[:permissions][i].blank?
          @group.forums_groups_permissions.create!(forum_id: forum,
                                                   permission: params[:permissions][i])
        end
      end

      saved = true
    end

    if saved
      redirect_to edit_admin_group_url(@group), notice: I18n.t('admin.groups.created')
    else
      render :new
    end
  end

  def destroy
    @group = Group.find params[:id]
    @group.destroy

    redirect_to admin_groups_url, notice: I18n.t('admin.groups.deleted')
  end
end

# eof
