# -*- coding: utf-8 -*-

class NoAnswerNoArchivePlugin < Plugin
  def show_new_message(thread, parent, message)
    redirect_to(cf_message_path(thread, parent), alert: I18n.t('plugins.no_answer_no_archive.answer_not_allowed')) if parent.flags['no-answer'] == 'yes'
  end

  def creating_new_message(thread, parent, message, tags)
    if parent.flags['no-answer'] == 'yes'
      flash[:error] = I18n.t('plugins.no_answer_no_archive.answer_not_allowed')
      return false
    end

    return true
  end
end

ApplicationController.init_hooks << Proc.new do |app_controller|
  na_na_plugin = NoAnswerNoArchivePlugin.new(app_controller)

  app_controller.notification_center.register_hook(CfMessagesController::SHOW_NEW_MESSAGE, na_na_plugin)
  app_controller.notification_center.register_hook(CfMessagesController::CREATING_NEW_MESSAGE, na_na_plugin)
end

# eof
