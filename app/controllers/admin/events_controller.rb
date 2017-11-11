class Admin::EventsController < ApplicationController
  authorize_controller { authorize_admin }
  before_action :set_event, only: %i[show edit update destroy]

  # GET /events
  def index
    @events = sort_query(%w[name location start_date end_date visible created_at updated_at],
                         Event.all)
                .page(params[:page])
  end

  # GET /events/1
  def show; end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit; end

  # POST /events
  def create
    @event = Event.new(event_params)

    if @event.save
      redirect_to admin_events_url, notice: t('admin.events.created')
    else
      render :new
    end
  end

  # PATCH/PUT /events/1
  def update
    if @event.update(event_params)
      redirect_to admin_events_url, notice: t('admin.events.updated')
    else
      render :edit
    end
  end

  # DELETE /events/1
  def destroy
    @event.destroy
    redirect_to admin_events_url, notice: t('admin.events.destroyed')
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_event
    @event = Event.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def event_params
    params
      .require(:event)
      .permit(:name, :description, :location, :maps_link,
              :start_date, :end_date, :visible)
  end
end

# eof
