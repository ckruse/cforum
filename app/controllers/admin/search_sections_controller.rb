class Admin::SearchSectionsController < ApplicationController
  authorize_controller { authorize_admin }

  before_action :load_search_section

  def index
    @search_sections = SearchSection.order(:position, :name)

    respond_to do |format|
      format.html
      format.json { render json: @sections }
    end
  end

  def edit; end

  def search_section_params
    params
      .require(:search_section)
      .permit(:name, :position, :active_by_default, :forum_id)
  end

  def update
    if @search_section.update_attributes(search_section_params)
      redirect_to edit_admin_search_section_url(@search_section),
                  notice: I18n.t('admin.search_sections.updated')
    else
      render :edit
    end
  end

  def new
    @search_section = SearchSection.new
  end

  def create
    @search_section = SearchSection.new(search_section_params)

    if @search_section.save
      redirect_to edit_admin_search_section_url(@search_section),
                  notice: I18n.t('admin.search_sections.created')
    else
      render :new
    end
  end

  def destroy
    @search_section.destroy
    redirect_to admin_search_sections_url, notice: I18n.t('admin.search_sections.destroyed')
  end

  private

  def load_search_section
    @search_section = SearchSection.where(search_section_id: params[:id]).first! if params[:id]
  end
end
