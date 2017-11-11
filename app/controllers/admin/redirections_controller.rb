class Admin::RedirectionsController < ApplicationController
  authorize_controller { authorize_admin }

  before_action :load_ressource

  def index
    @redirections = sort_query(%w[redirection_id path destination],
                               Redirection)
                      .page(params[:page])
  end

  def new
    @redirection = Redirection.new
  end

  def create
    @redirection = Redirection.new(redirection_params)

    if @redirection.save
      redirect_to admin_redirections_path, notice: t('admin.redirections.created')
    else
      render :new
    end
  end

  def edit; end

  def update
    if @redirection.update(redirection_params)
      redirect_to admin_redirections_path, notice: t('admin.redirections.updated')
    else
      render :edit
    end
  end

  def destroy
    @redirection.destroy
    redirect_to admin_redirections_path, notice: t('admin.redirections.destroyed')
  end

  def load_ressource
    @redirection = Redirection.find(params[:id]) if params[:id].present?
  end

  def redirection_params
    params.require(:redirection).permit(:path, :destination, :comment, :http_status)
  end
end

# eof
