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

    if ConfigManager.get_setting('use_archive')
      @threads = CForum::Thread.where(archived: false).order('message.created_at' => -1).all
    else
      @threads = CForum::Thread.order('message.created_at' => -1).limit(ConfigManager.get_setting('pagination') || 10)
    end
  end

  def show
    @id = make_id
    @thread = CForum::Thread.find_by_id(@id)
  end

  def edit
    @thread = CForum::Thread.find_by_id(make_id)
  end

  def new
    @thread = CForum::Thread.new
    @thread.message = CForum::Message.new
    @thread.message.author = CForum::Author.new
    @categories = ConfigManager.get_setting('categories', [])
  end

  def create
    @thread = CForum::Thread.new(params[:c_forum_thread])

    respond_to do |format|
      if @thread.save
        format.html { redirect_to @thread, notice: 'Campaign was successfully created.' }
        format.json { render json: @thread, status: :created, location: @thread }
      else
        format.html { render action: "new" }
        format.json { render json: @thread.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
  end

  private

  def make_id
    '/' + params[:year] + '/' + params[:mon] + '/' + params[:day] + '/' + params[:tid]
  end
end

# eof
