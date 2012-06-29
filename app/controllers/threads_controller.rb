# -*- encoding: utf-8 -*-

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

    @threads.each do |t|
      t.sort_tree
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
    now = Time.now

    @thread = CfThread.new(params[:cf_thread])
    @thread.id = to_id(@thread)
    @thread.archived = false
    @thread.message.id = 1

    respond_to do |format|
      if @thread.save
        format.html { redirect_to root_url, notice: 'Campaign was successfully created.' } # todo: redirect to new thread
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

  TO_URI_MAP = [
    {:rx => /[äÄ]/, :replacement => 'ae'},
    {:rx => /[öÖ]/, :replacement => 'oe'},
    {:rx => /[üÜ]/, :replacement => 'ue'},
    {:rx => /ß/,    :replacement => 'ss'},
    {:rx => /[ÀÁÂÃÅÆàáâãåæĀāĂăĄą]/, :replacement => 'a'},
    {:rx => /[ÇçĆćĈĉĊċČč]/, :replacement => 'c'},
    {:rx => /[ÐĎďĐđ]/, :replacement => 'd'},
    {:rx => /[ÈÉÊËèéêëĒēĔĕĖėĘęĚě]/, :replacement => 'e'},
    {:rx => /[ÌÍÎÏìíîï]/, :replacement => 'i'},
    {:rx => /[Ññ]/, :replacement => 'n'},
    {:rx => /[ÒÓÔÕ×Øòóôõø]/, :replacement => 'o'},
    {:rx => /[ÙÚÛùúû]/, :replacement => 'u'},
    {:rx => /[Ýýÿ]/, :replacement => 'y'}
  ]
  def to_id(thread)
    now = Time.now
    id = now.strftime("/%Y/") + now.strftime("%b").downcase + now.strftime("/%d/")

    subject = thread.message.subject.tr(' ','-')
    subject.downcase!

    TO_URI_MAP.each do |map|
      subject.gsub!(map[:rx], map[:replacement])
    end


    subject.gsub!(/[^a-zA-Z0-9.$%;,_*-]/,'-')

    subject.gsub!(/-{2,}/,'-')
    subject.gsub!(/-+$/,'')
    subject.gsub!(/^-+/,'')

    subject = subject[0..120]+"..." if subject.length > 120

    id + subject
  end
end

# eof
