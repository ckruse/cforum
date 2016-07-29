class AttendeesController < ApplicationController
  before_action :set_attendee, only: [:destroy, :edit, :update]
  before_action :set_event

  authorize_action([:destroy, :edit, :update]) do
    set_attendee
    if @attendee.user_id == current_user.try(:user_id) and not current_user.blank?
      true
    else
      authorize_admin
    end
  end

  # GET /attendees/new
  def new
    @attendee = Attendee.new(event_id: @event.event_id, planned_arrival: @event.start_date)
  end

  # POST /attendees
  def create
    @attendee = Attendee.new(attendee_params)
    @attendee.event_id = @event.event_id

    unless current_user.blank?
      @attendee.user_id = current_user.user_id
      @attendee.name = current_user.username
    end

    if @attendee.save
      redirect_to @event, notice: t('events.attendees.created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    @attendee.attributes = attendee_params
    unless current_user.blank?
      @attendee.user_id = current_user.user_id
      @attendee.name = current_user.username
    end

    if @attendee.save
      redirect_to @event, notice: t('events.attendees.updated')
    else
      render :edit
    end

  end

  # DELETE /attendees/1
  def destroy
    @attendee.destroy
    redirect_to @event, notice: t('events.attendees.destroyed')
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_attendee
    @attendee ||= Attendee.find(params[:id])
  end

  def set_event
    @event = Event.where(visible: true).find(params[:event_id])
  end

  # Only allow a trusted parameter "white list" through.
  def attendee_params
    params.require(:attendee).permit(:name, :comment, :starts_at, :planned_start, :planned_arrival, :seats)
  end
end
