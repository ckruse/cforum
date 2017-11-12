class AttendeesController < ApplicationController
  before_action :set_attendee, only: %i[destroy edit update]
  before_action :set_event

  authorize_controller do
    set_event
    if @event.open?
      true
    else
      false
    end
  end

  authorize_action(%i[destroy edit update]) do
    set_attendee
    if (@attendee.user_id == current_user.try(:user_id)) && current_user.present?
      true
    else
      authorize_admin
    end
  end

  # GET /attendees/new
  def new
    @attendee = Attendee.new(event_id: @event.event_id,
                             planned_arrival: @event.start_date,
                             planned_leave: @event.end_date)
  end

  # POST /attendees
  def create
    @attendee = Attendee.new(attendee_params)
    @attendee.event_id = @event.event_id

    if current_user.present?
      @attendee.user_id = current_user.user_id
      @attendee.name = current_user.username
    end

    if @attendee.save
      notify_admins_about_attendee
      redirect_to @event, notice: t('events.attendees.created')
    else
      render :new
    end
  end

  def edit; end

  def update
    @attendee.attributes = attendee_params
    if current_user.present?
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
    unnotify_admins
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
    params.require(:attendee).permit(:name, :comment, :starts_at,
                                     :planned_start, :planned_arrival,
                                     :planned_leave, :seats)
  end

  def notify_admins_about_attendee
    admins = User.where(admin: true).all

    admins.each do |admin|
      notify_user(
        user: admin,
        subject: t('events.attendees.new_attendee_notification', attendee: @attendee.name, event: @event.name),
        path: event_path(@event),
        oid: @attendee.attendee_id,
        otype: 'attendee:create'
      )
    end
  end

  def unnotify_admins
    Notification.where(oid: @attendee.attendee_id, otype: 'attendee:create', is_read: false).delete_all
  end
end

# eof
