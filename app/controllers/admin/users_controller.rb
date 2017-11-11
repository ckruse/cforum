class Admin::UsersController < ApplicationController
  authorize_controller { authorize_admin }

  before_action :load_resource

  def load_resource
    @user = User.find(params[:id]) if params[:id]
  end

  def index
    @limit = conf('pagination_users').to_i

    if params[:s].blank?
      @users = User
    else
      term = '%' + params[:s].strip + '%'
      @users = User.where('LOWER(username) LIKE LOWER(?) OR LOWER(email) LIKE LOWER(?)', term, term)
      @search_term = params[:s]
    end

    @users = sort_query(%w[username email admin active created_at updated_at],
                        @users, admin: 'COALESCE(admin, false)')
               .page(params[:page]).per(@limit)

    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end

  def edit; end

  def user_params
    params.require(:user).permit(:username, :email, :password, :active, :admin)
  end

  def update
    if @user.update_attributes(user_params)
      audit(@user, 'update')
      redirect_to edit_admin_user_url(@user), notice: I18n.t('admin.users.updated')
    else
      render :edit
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      audit(@user, 'create')
      redirect_to edit_admin_user_url(@user), notice: I18n.t('admin.users.created')
    else
      render :new
    end
  end

  def destroy
    @user.destroy
    audit(@user, 'destroy')

    redirect_to admin_users_url, notice: I18n.t('admin.users.deleted')
  end
end

# eof
