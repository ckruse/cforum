# -*- coding: utf-8 -*-

class SearchPlugin < Plugin
  def new_thread_saved(thread, message)
    created_new_message(thread, nil, message, nil)
  end

  def created_new_message(thread, parent, message, tags)
    section = SearchSection.where(forum_id: message.forum_id).first
    if section.blank?
      section = SearchSection.create!(name: message.forum.name,
                                      position: -1,
                                      forum_id: message.forum_id)
    end

    base_relevance = conf('search_forum_relevance')


    opts = {
      reference_id: message.message_id,
      forum_id: message.forum_id,
      search_section_id: section.search_section_id,
      author: message.author,
      user_id: message.user_id,
      title: message.subject,
      content: message.to_search(self),
      url: cf_message_url(message.thread, message),
      relevance: base_relevance.to_f + (message.score.to_f / 10.0) + (message.flags['accepted'] == 'yes' ? 0.5 : 0.0) + ('0.0' + message.created_at.year.to_s).to_f,
      lang: Cforum::Application.config.search_dict,
      document_created: message.created_at,
      tags: message.tags.map { |t| t.tag_name.downcase }
    }

    doc = SearchDocument.where(reference_id: message.message_id).first
    doc = SearchDocument.new if doc.blank?

    doc.attributes = opts
    doc.save!
  end

  alias updated_message created_new_message

  def restored_message(thread, message)
    created_new_message(thread, nil, message, message.tags)
  end

  def deleted_message(thread, message)
    mids = [message.message_id]
    message.all_answers do |m|
      mids << m.message_id
    end

    SearchDocument.delete_all(['reference_id IN (?)', mids]) unless mids.blank?
  end

end

ApplicationController.init_hooks << Proc.new do |app_controller|
  search_plugin = SearchPlugin.new(app_controller)

  app_controller.notification_center.
    register_hook(CfMessagesController::CREATED_NEW_MESSAGE, search_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::UPDATED_MESSAGE, search_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::DELETED_MESSAGE, search_plugin)
  app_controller.notification_center.
    register_hook(CfMessagesController::RESTORED_MESSAGE, search_plugin)
  app_controller.notification_center.
    register_hook(CfThreadsController::NEW_THREAD_SAVED, search_plugin)
end

# eof
