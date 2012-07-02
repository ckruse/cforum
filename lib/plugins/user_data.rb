class UserData < Plugin
  def show_new_thread(thread)
    if user = current_user
      thread.message.author.name = user.settings['name']
      thread.message.author.email = user.settings['email']
      thread.message.author.homepage = user.settings['homepage']
    end
  end
end

notification_center.register_hook(CfThreadsController::SHOW_NEW_THREAD, UserData.new(self))