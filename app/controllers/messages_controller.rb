class MessagesController < ApplicationController
  def show
    found = false
    @id = '/' + params[:year] + '/' + params[:mon] + '/' + params[:day] + '/' + params[:tid]
    @thread = CForum::Thread.find_by_id(@id)

    if @thread
      @message = @thread.find_message(params[:mid])
      found = true if @message
    end

    if @thread.nil? or @message.nil?
      raise CForum::NotFoundException.new
    end
  end
end