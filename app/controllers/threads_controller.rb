class ThreadsController < ApplicationController
  before_filter :require_login, :only => [:edit, :destroy]

  SHOW_THREADLIST = "show_threadlist"
  SHOW_THREAD = "show_thread"
  SHOW_NEW_THREAD = "new_thread"

  def index
    if params[:t]
      thread = CfThread.find_by_tid("t" + params[:t])

      if thread
        if params[:m] && message = thread.find_message(params[:m])
          return redirect_to message_path(thread, message)
        else
          return redirect_to thread_path(thread)
        end
      end
    end

    if ConfigManager.setting('use_archive')
      @threads = CfThread.where(archived: false).order('message.created_at' => -1).all
    else
      @threads = CfThread.order('message.created_at' => -1).limit(ConfigManager.setting('pagination') || 10)
    end

    notification_center.notify(SHOW_THREADLIST, @threads)
  end

  def show
    @id = make_id
    @thread = CfThread.find_by_id(@id)

    notification_center.notify(SHOW_THREAD, @thread)
  end

  def edit
    @id = make_id
    @thread = CfThread.find_by_id(@id)
  end

  def new
    @thread = CfThread.new
    @thread.message = CfMessage.new
    @thread.message.author = CfAuthor.new
    @categories = ConfigManager.setting('categories', [])

    notification_center.notify(SHOW_NEW_THREAD, @thread)
  end

  def create
    @thread = CfThread.new(params[:cf_thread])

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
