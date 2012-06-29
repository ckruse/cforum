class UserData < Plugin
  def new_thread(thread)
    if usr = current_user
      thread.message.author.name = usr.settings['name']
      thread.message.author.email = usr.settings['email']
      thread.message.author.homepage = usr.settings['homepage']
    end
  end
end

notification_center.register_hook(ThreadsController::SHOW_NEW_THREAD, UserData.new(self))