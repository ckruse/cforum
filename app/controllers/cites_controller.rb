class CitesController < ApplicationController
  authorize_action([:edit, :update, :destroy]) { may?(RightsHelper::MODERATOR_TOOLS) or authorize_admin }

  before_action :set_cite, only: [:show, :edit, :update, :destroy]

  def index
    @limit = conf('pagination').to_i
    @cites = CfCite.
             preload(:message, :user).
             order('cite_id DESC').
             page(params[:page]).
             per(@limit).
             all
  end

  def show
  end

  # GET /cites/new
  def new
    @cite = CfCite.new
  end

  # GET /cites/1/edit
  def edit
  end

  # POST /cites
  def create
    @cite = CfCite.new(cite_params)

    if @cite.save
      redirect_to cite_url(@cite), notice: t('cites.created')
    else
      render :new
    end
  end

  # PATCH/PUT /cites/1
  def update
    if @cite.update(cite_params)
      redirect_to cite_url(@cite), notice: t('cites.updated')
    else
      render :edit
    end
  end

  # DELETE /cites/1
  def destroy
    @cite.destroy
    redirect_to cites_url, notice: t('cites.destroyed')
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cite
      @cite = CfCite.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def cite_params
      params.require(:cf_cite).permit(:cite, :author, :url)
    end
end
