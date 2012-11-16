# -*- coding: utf-8 -*-

module CForum
  module Tools
    def encode_entities(txt)
      map = {'&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;'}
      x = txt.gsub /([&<>"])/ do |r|
        map[r]
      end
    end

    def root_path
      return '/' # TODO: handle this correctly…
    end
    module_function :root_path

    module_function :encode_entities

    def query_string(args = {})
      qs = []
      args.each do |k, v|
        qs << URI.escape(k.to_s) + "=" + URI.escape(v.to_s)
      end

      return '?' + qs.join("&") unless qs.blank?
      ''
    end
    module_function :query_string

    def cf_forum_path(forum, args = {})
      forum = forum.slug unless forum.is_a?(String)
      root_path + forum + query_string(args)
    end
    module_function :cf_forum_path

    def cf_thread_path(thread, args = {})
      cf_forum_path(thread.forum) + thread.slug + query_string(args)
    end
    module_function :cf_thread_path

    def edit_cf_thread_path(thread, args = {})
      cf_thread_path(thread) + '/edit' + query_string(args)
    end
    module_function :edit_cf_thread_path

    def cf_message_path(thread, message, args = {})
      cf_thread_path(thread) + "/" + message.id.to_s + query_string(args)
    end
    module_function :cf_message_path

    def cf_edit_message_path(thread, message, args = {})
      cf_message_path(thread, message) + "/edit" + query_string(args)
    end
    module_function :cf_edit_message_path

    def new_cf_message_path(thread, message, args = {})
      cf_message_path(thread, message) + "/new" + query_string(args)
    end
    module_function :new_cf_message_path

    def restore_cf_message_path(thread, message, args = {})
      cf_message_path(thread, message) + "/restore" + query_string(args)
    end
    module_function :restore_cf_message_path

    def cf_forum_url(forum, args = {})
      forum = forum.slug unless forum.is_a?(String)
      return root_url + forum + query_string(args)
    end
    module_function :cf_forum_url

    def cf_thread_url(thread, args = {})
      cf_forum_url(thread.forum) + thread.slug + query_string(args)
    end
    module_function :cf_thread_url

    def cf_message_url(thread, message, args = {})
      cf_thread_url(thread) + '/' + message.id.to_s + query_string(args)
    end
    module_function :cf_message_url
  end
end

# end