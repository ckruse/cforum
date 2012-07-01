class CfMessagesController < ApplicationController
  def show
    @id = '/' + params[:year] + '/' + params[:mon] + '/' + params[:day] + '/' + params[:tid]
    @thread = CfThread.find_by_id(@id)
    @thread.sort_tree

    @message = @thread.find_message(params[:mid]) if @thread
    raise CForum::NotFoundException.new if @thread.nil? or @message.nil?
  end

  def new
    @id = '/' + params[:year] + '/' + params[:mon] + '/' + params[:day] + '/' + params[:tid]
    @thread = CfThread.find_by_id(@id)
    @thread.sort_tree

    @parent = @thread.find_message(params[:mid]) if @thread

    raise CForum::NotFoundException.new if @thread.nil? or @parent.nil?

    @message = CfMessage.new
    @message.author = CfAuthor.new
    @categories = ConfigManager.setting('categories', [])
  end

  def create
    @id = '/' + params[:year] + '/' + params[:mon] + '/' + params[:day] + '/' + params[:tid]
    @thread = CfThread.find_by_id(@id)
    @thread.sort_tree

    @parent = @thread.find_message(params[:mid]) if @thread

    raise CForum::NotFoundException.new if @thread.nil? or @parent.nil?

    @message = CfMessage.new(params[:cf_message])
    @message.id = find_next_id() + 1

    @parent.messages.push @message

    if @thread.save
      redirect_to cf_message_path(@thread, @message), :notice => I18n.t('messages.new.created')
    else
      @categories = ConfigManager.setting('categories', [])
      render :new
    end
  end

  private

  def find_next_id(msg = nil, latest = -1)
    msg = @thread.message if msg.nil?

    latest = msg.id.to_i if msg.id.to_i > latest

    unless msg.messages.empty?
      msg.messages.each do |m|
        latest = find_next_id(m, latest)
      end
    end

    latest
  end
end