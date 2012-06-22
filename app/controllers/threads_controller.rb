class ThreadsController < ApplicationController
  def index
    if ConfigManager.get_value('use_archive')
      @threads = CForum::Thread.where(archived: false).order('message.created_at').all
    else
      @threads = CForum::Thread.order('message.created_at' => -1).limit(ConfigManager.get_value('pagination') || 10)
    end
  end

  def view
  end

  def create
  end

  def destroy
  end
end

# eof
