class CfMessagesController < ApplicationController
  load_and_authorize_resource

  def show
    @id = CfThread.make_id(params)
    @thread = CfThread.find_by_slug(@id)

    @thread.gen_tree
    @thread.sort_tree

    @message = @thread.find_message(params[:mid].to_i) if @thread
    raise CForum::NotFoundException.new if @thread.nil? or @message.nil?
  end

  def new
    @id = CfThread.make_id(params)
    @thread = CfThread.find_by_slug(@id)
    @thread.gen_tree
    @thread.sort_tree

    @parent = @thread.find_message(params[:mid].to_i) if @thread

    raise CForum::NotFoundException.new if @thread.nil? or @parent.nil?

    @message = CfMessage.new

    # inherit message and subject from previous post
    @message.subject = @parent.subject
  end

  def create
    @id = CfThread.make_id(params)
    @thread = CfThread.find_by_slug(@id)
    @thread.gen_tree
    @thread.sort_tree

    @parent = @thread.find_message(params[:mid].to_i) if @thread

    raise CForum::NotFoundException.new if @thread.nil? or @parent.nil?

    @message = CfMessage.new(params[:cf_message])
    @message.parent_id = @parent.message_id

    @thread.messages.push @message

    if @thread.save
      redirect_to cf_message_path(@thread, @message), :notice => I18n.t('messages.new.created')
    else
      @categories = ConfigManager.setting('categories', [])
      render :new
    end
  end
end