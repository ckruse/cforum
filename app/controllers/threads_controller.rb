class ThreadsController < ApplicationController
  def index
    if params[:t]
      thread = CForum::Thread.find_by_tid("t" + params[:t])
      if thread
        if params[:m] && message = thread.find_message(params[:m])
          return redirect_to message_path(thread, message)
        else
          return redirect_to thread_path(thread)
        end
      end
    end

    if ConfigManager.get_value('use_archive')
      @threads = CForum::Thread.where(archived: false).order('message.created_at').all
    else
      @threads = CForum::Thread.order('message.created_at' => -1).limit(ConfigManager.get_value('pagination') || 10)
    end
  end

  def show
    @id = '/' + params[:year] + '/' + params[:mon] + '/' + params[:day] + '/' + params[:tid]
    @thread = CForum::Thread.find_by_id(@id)
  end

  def new
    @thread = CForum::Thread.new
    @thread.message = CForum::Message.new

    render :template => 'messages/new'
  end

  def create
  end

  def destroy
  end
end

# eof
