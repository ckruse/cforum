# -*- encoding: utf-8 -*-

class CfThreadsController < ApplicationController
  load_resource
  before_filter :authorize!

  SHOW_THREADLIST  = "show_threadlist"
  SHOW_THREAD      = "show_thread"
  SHOW_NEW_THREAD  = "show_new_thread"
  NEW_THREAD       = "new_thread"
  NEW_THREAD_SAVED = "new_thread_saved"

  def index
    forum  = current_forum
    @page  = params[:p].to_i
    @limit = uconf('pagination', 50)
    @page  = 0 if @page < 0

    conditions = {}
    conditions[:forum_id] = forum.forum_id if forum
    conditions[:archived] = false if conf('use_archive')
    conditions[:messages] = {deleted: false} unless params.has_key?(:view_all)

    @threads = CfThread.
      preload(:forum).
      includes(:messages => :owner).
      where(conditions).
      order('cforum.threads.created_at DESC').
      limit(@limit).
      offset(@limit * @page)

    if forum
      rslt = CfForum.connection.execute("SELECT cforum.counter_table_get_count('threads', " +
        current_forum.forum_id.to_s +
        ") AS cnt")
    else
      rslt = CfForum.connection.execute("SELECT SUM(difference) AS cnt FROM cforum.counter_table WHERE table_name = 'threads'")
    end

    @all_threads_count = rslt[0]['cnt'].to_i

    @threads.each do |t|
      t.gen_tree
      t.sort_tree
    end

    notification_center.notify(SHOW_THREADLIST, @threads)
  end

  def show
    @id = CfThread.make_id(params)
    @thread = CfThread.find_by_slug(@id)

    @thread.gen_tree
    @thread.sort_tree

    notification_center.notify(SHOW_THREAD, @thread)
  end

  def edit
    @id = CfThread.make_id(params)
    @thread = CfThread.find_by_slug!(@id)

    @thread.gen_tree
    @thread.sort_tree
  end

  def new
    @thread = CfThread.new
    @thread.message = CfMessage.new

    notification_center.notify(SHOW_NEW_THREAD, @thread)
  end

  def create
    now = Time.now

    @forum = current_forum

    @thread  = CfThread.new()
    @message = CfMessage.new(params[:cf_thread][:message])
    @thread.messages << @message
    @thread.message  =  @message

    @thread.forum_id  = @forum.forum_id
    @message.forum_id = @forum.forum_id

    notification_center.notify(NEW_THREAD, @thread, @message)

    respond_to do |format|
      if @thread.save
        notification_center.notify(NEW_THREAD_SAVED, @thread, @message)

        format.html { redirect_to cf_message_url(@thread, @message), notice: I18n.t("threads.created") }
        format.json { render json: @thread, status: :created, location: @thread }
      else
        format.html { render action: "new" }
        format.json { render json: @thread.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
  end

  include AuthorizeForum
end

# eof
