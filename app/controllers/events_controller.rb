# -*- coding: utf-8 -*-

class EventsController < ApplicationController
  before_action :set_event, only: [:show]

  # GET /events
  def index
    @events = sort_query(%w(name start_date end_date visible created_at updated_at),
                         Event.where(visible: true).all).
              page(params[:page])
  end

  # GET /events/1
  def show
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_event
    @event = Event.where(visible: true, event_id: params[:id]).first!
  end
end

# eof
