class ThreadsController < ApplicationController
  def index
    @threads = CForum::Thread.where(archived: false).order('messages.0.date').all
  end

  def view
  end

  def create
  end

  def destroy
  end
end

# eof
