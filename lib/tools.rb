# -*- coding: utf-8 -*-

module CForum
  module Tools
    @@url_attribs = {}

    def init
      @@url_attribs = {}
    end
    module_function :init

    def set_url_attrib(nam, val)
      @@url_attribs ||= {}
      @@url_attribs[nam] = val
    end

    def encode_entities(txt)
      map = {'&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;'}
      txt.gsub(/([&<>"])/) do |r|
        map[r]
      end
    end

    def query_string(args = {})
      qs = []
      had_key = {}
      @@url_attribs ||= {}

      args.each do |k, v|
        had_key[k.to_s] = true
        qs << URI.escape(k.to_s) + "=" + URI.escape(v.to_s)
      end

      @@url_attribs.each do |k,v|
        next if had_key[k.to_s] == true
        qs << URI.escape(k.to_s) + "=" + URI.escape(v.to_s)
      end

      return '?' + qs.join("&") unless qs.blank?
      ''
    end

    def _cf_forum_path(forum)
      forum = 'all' if forum.blank?
      forum = forum.slug unless forum.is_a?(String)
      root_path + forum
    end

    def cf_forum_path(forum, args = {})
      _cf_forum_path(forum) + query_string(args)
    end

    def _cf_thread_path(thread)
      _cf_forum_path(thread.forum) + thread.slug
    end

    def cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + query_string(args)
    end

    def edit_cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + '/edit' + query_string(args)
    end

    def move_cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + "/move" + query_string(args)
    end

    def sticky_cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + "/sticky" + query_string(args)
    end

    def no_archive_cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + "/no_archive" + query_string(args)
    end

    def interesting_cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + "/interesting" + query_string(args)
    end

    def boring_cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + "/boring" + query_string(args)
    end

    #
    # message path helpers
    #

    def _cf_message_path_wo_anchor(thread, message)
      _cf_thread_path(thread) + "/" + message.message_id.to_s
    end

    def cf_message_path_wo_anchor(thread, message, args = {})
      _cf_message_path_wo_anchor(thread, message) + query_string(args)
    end

    def cf_message_path(thread, message, args = {})
      _cf_message_path_wo_anchor(thread, message) + query_string(args) + "#m" + message.message_id.to_s
    end

    def edit_cf_message_path(thread, message, args = {})
      _cf_message_path_wo_anchor(thread, message) + "/edit" + query_string(args)
    end

    def new_cf_message_path(thread, message, args = {})
      _cf_message_path_wo_anchor(thread, message) + "/new" + query_string(args)
    end

    def restore_cf_message_path(thread, message, args = {})
      _cf_message_path_wo_anchor(thread, message) + "/restore" + query_string(args)
    end

    def vote_cf_message_path(thread, message, args = {})
      _cf_message_path_wo_anchor(thread, message) + "/vote" + query_string(args)
    end

    def accept_cf_message_path(thread, message, args = {})
      _cf_message_path_wo_anchor(thread, message) + "/accept" + query_string(args)
    end

    def no_answer_cf_message_path(thread, message, args = {})
      _cf_message_path_wo_anchor(thread, message) + "/no_answer" + query_string(args)
    end

    def close_cf_message_path(thread, message, args = {})
      _cf_message_path_wo_anchor(thread, message) + "/close" +
        query_string(args)
    end

    def open_cf_message_path(thread, message, args = {})
      _cf_message_path_wo_anchor(thread, message) + "/open" +
        query_string(args)
    end

    def unread_cf_message_path(thread, message, args = {})
      _cf_message_path_wo_anchor(thread, message) + "/unread" +
        query_string(args)
    end

    def cf_badges_path
      root_path + 'badges'
    end

    def cf_badge_path(badge)
      badge = badge.slug unless badge.is_a?(String)
      cf_badges_path + '/' + badge
    end

    #
    # URL helpers
    #

    def _cf_forum_url(forum)
      forum = 'all' if forum.blank?
      forum = forum.slug unless forum.is_a?(String)
      root_url + forum
    end

    def cf_forum_url(forum, args = {})
      _cf_forum_url(forum) + query_string(args)
    end

    def _cf_thread_url(thread)
      _cf_forum_url(thread.forum) + thread.slug
    end

    def cf_thread_url(thread, args = {})
      _cf_thread_url(thread) + query_string(args)
    end

    def interesting_cf_thread_url(thread, args = {})
      _cf_thread_url(thread) + '/interesting' + query_string(args)
    end

    def boring_cf_thread_url(thread, args = {})
      _cf_thread_url(thread) + '/boring' + query_string(args)
    end

    def _cf_message_url_wo_anchor(thread, message)
      _cf_thread_url(thread) + '/' + message.message_id.to_s
    end

    def cf_message_url_wo_anchor(thread, message, args = {})
      _cf_message_url_wo_anchor(thread, message) + query_string(args)
    end

    def cf_message_url(thread, message, args = {})
      _cf_message_url_wo_anchor(thread, message) + query_string(args) + "#m" + message.message_id.to_s
    end

    def open_cf_message_url(thread, message, args = {})
      _cf_message_url_wo_anchor(thread, message) + "/open" +
        query_string(args)
    end

    def unread_cf_message_url(thread, message, args = {})
      _cf_message_url_wo_anchor(thread, message) + "/unread" +
        query_string(args)
    end

    def cf_badges_url
      root_url + 'badges'
    end

    def cf_badge_url(badge)
      badge = badge.slug unless badge.is_a?(String)
      cf_badges_url + '/' + badge
    end
  end
end

# end
