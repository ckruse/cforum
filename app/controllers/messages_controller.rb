class MessagesController < ApplicationController
  def show
    @id = '/' + params[:year] + '/' + params[:mon] + '/' + params[:day] + '/' + params[:tid]
    @thread = CForum::Thread.find_by_id(@id)

    @message = @thread.find_message(params[:mid]) if @thread
    raise CForum::NotFoundException.new if @thread.nil? or @message.nil?
  end
end