# -*- coding: utf-8 -*-

module CForum
  module Tools
    def encode_entities(txt)
      map = {'&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;'}
      x = txt.gsub /([&<>"])/ do |r|
        map[r]
      end
    end

    def query_string(args = {})
      qs = []
      args.each do |k, v|
        qs << URI.escape(k.to_s) + "=" + URI.escape(v.to_s)
      end

      return '?' + qs.join("&") unless qs.blank?
      ''
    end

    def cf_forum_path(forum, args = {})
      forum = forum.slug unless forum.is_a?(String)
      root_path + forum + query_string(args)
    end

    def cf_thread_path(thread, args = {})
      cf_forum_path(thread.forum) + thread.slug + query_string(args)
    end

    def edit_cf_thread_path(thread, args = {})
      cf_thread_path(thread) + '/edit' + query_string(args)
    end

    def move_cf_thread_path(thread, args = {})
      cf_thread_path(thread) + "/move" + query_string(args)
    end

    def sticky_cf_thread_path(thread, args = {})
      cf_thread_path(thread) + "/sticky" + query_string(args)
    end

    #
    # message path helpers
    #

    def cf_message_path_wo_anchor(thread, message, args = {})
      cf_thread_path(thread) + "/" + message.id.to_s + query_string(args)
    end

    def cf_message_path(thread, message, args = {})
      cf_message_path_wo_anchor(thread, message) + query_string(args) + "#" + message.id.to_s
    end

    def cf_edit_message_path(thread, message, args = {})
      cf_message_path_wo_anchor(thread, message) + "/edit" + query_string(args)
    end

    def new_cf_message_path(thread, message, args = {})
      cf_message_path_wo_anchor(thread, message) + "/new" + query_string(args)
    end

    def restore_cf_message_path(thread, message, args = {})
      cf_message_path_wo_anchor(thread, message) + "/restore" + query_string(args)
    end

    def vote_cf_message_path(thread, message, args = {})
      cf_message_path_wo_anchor(thread, message) + "/vote" + query_string(args)
    end

    #
    # URL helpers
    #

    def cf_forum_url(forum, args = {})
      forum = forum.slug unless forum.is_a?(String)
      return root_url + forum + query_string(args)
    end

    def cf_thread_url(thread, args = {})
      cf_forum_url(thread.forum) + thread.slug + query_string(args)
    end

    def cf_message_url_wo_anchor(thread, message, args = {})
      cf_thread_url(thread) + '/' + message.message_id.to_s + query_string(args)
    end

    def cf_message_url(thread, message, args = {})
      cf_message_url_wo_anchor(thread, message) + query_string(args) + "#" + message.message_id.to_s
    end
  end
end

# end
