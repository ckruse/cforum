# -*- encoding: utf-8 -*-

class CfThreadsController < ApplicationController
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
      @threads = CfThread.where(archived: false).sort('message.created_at' => -1)
    else
      @threads = CfThread.all().sort('message.created_at' => -1).limit(ConfigManager.setting('pagination') || 10)
    end

    @threads.each do |t|
      t.sort_tree
    end

    notification_center.notify(SHOW_THREADLIST, @threads)
  end

  def show
    @id = CfThread.make_id(params)
    @thread = CfThread.find_by_id(@id)

    notification_center.notify(SHOW_THREAD, @thread)
  end

  def edit
    @id = CfThread.make_id(params)
    @thread = CfThread.find_by_id(@id)
  end

  def new
    @thread = CfThread.new
    @thread.message = CfMessage.new
    @thread.message.author = CfAuthor.new

    notification_center.notify(SHOW_NEW_THREAD, @thread)
  end

  def create
    now = Time.now

    @thread = CfThread.new(params[:cf_thread])
    @thread.message.id = 1

    respond_to do |format|
      if @thread.save
        format.html { redirect_to root_url, notice: 'Thread was successfully created.' } # todo: redirect to new thread
        format.json { render json: @thread, status: :created, location: @thread }
      else
        format.html { render action: "new" }
        format.json { render json: @thread.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
  end
end

# eof
