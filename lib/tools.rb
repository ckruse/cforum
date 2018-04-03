module CForum
  module Tools
    def init
      @url_attribs = {}
    end
    module_function :init

    def set_url_attrib(nam, val)
      @url_attribs ||= {}
      @url_attribs[nam] = val
    end

    def encode_entities(txt)
      map = { '&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;' }
      txt.gsub(/([&<>"])/) do |r|
        map[r]
      end
    end

    def query_string(args = {})
      format = args.delete(:format) || ''

      qs = []
      had_key = {}
      @url_attribs ||= {}

      args.each do |k, v|
        had_key[k.to_s] = true
        next if v.nil?
        qs << CGI.escape(k.to_s) + '=' + CGI.escape(v.to_s)
      end

      @url_attribs.each do |k, v|
        next if had_key[k.to_s] == true
        qs << CGI.escape(k.to_s) + '=' + CGI.escape(v.to_s)
      end

      retval = ''
      retval = '.' + format.to_s if format.present?
      retval << '?' + qs.join('&') if qs.present?

      retval
    end

    def cf_return_url(thread = nil, message = nil, args = {})
      args = { p: params[:p], page: params[:page] }.merge(args)

      return forum_url(current_forum, args) if thread.blank? && message.blank?

      f = params[:f].gsub(/[^a-z0-9_-]/, '') if params[:f].present?
      f = current_forum.try(:slug) if f.blank?
      raise ActiveRecord::RecordNotFound if f.blank?

      case params[:r]
      when nil
        forum_url(f, args)
      when 'cf_threads'
        r = forum_url(f, args)
        r << '#t' + thread.thread_id.to_s if thread.present? && thread.thread_id.present?
        r
      when 'messages'
        args.delete(:p)
        message_url(thread, message || thread.messages.first, args)
      when 'messages/interesting'
        (@app_controller || self).interesting_messages_url(args)
      when 'cf_threads/invisible'
        (@app_controller || self).hidden_threads_url(args)
      end
    end

    def _forum_path(forum)
      forum = 'all' if forum.blank?
      forum = forum.slug unless forum.is_a?(String)
      root_path + forum
    end

    def forum_path(forum = nil, args = {})
      _forum_path(forum) + query_string(args)
    end

    def open_all_threads_path(forum, args = {})
      _forum_path(forum) + '/open_all' + query_string(args)
    end

    def close_all_threads_path(forum, args = {})
      _forum_path(forum) + '/close_all' + query_string(args)
    end

    def mark_all_read_path(forum, args = {})
      _forum_path(forum) + '/mark_all_visited' + query_string(args)
    end

    def stats_path(forum, args = {})
      _forum_path(forum) + '/stats' + query_string(args)
    end

    def cites_path(args = {})
      root_path + 'cites' + query_string(args)
    end

    def cite_path(cite, args = {})
      root_path + 'cites/' + cite.cite_id.to_s + query_string(args)
    end

    def _cf_thread_path(thread)
      _forum_path(thread.forum) + thread.slug
    end

    def cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + query_string(args)
    end

    def cf_threads_path(forum, args = {})
      _forum_path(forum) + query_string(args)
    end

    def new_cf_thread_path(forum, args = {})
      _forum_path(forum) + '/new' + query_string(args)
    end

    def edit_cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + '/edit' + query_string(args)
    end

    def move_cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + '/move' + query_string(args)
    end

    def sticky_cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + '/sticky' + query_string(args)
    end

    def archive_cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + '/archive' + query_string(args)
    end

    def no_archive_cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + '/no_archive' + query_string(args)
    end

    def mark_cf_thread_read_path(thread, args = {})
      _cf_thread_path(thread) + '/mark_read' + query_string(args)
    end

    def open_cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + '/open' + query_string(args)
    end

    def close_cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + '/close' + query_string(args)
    end

    def hide_cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + '/hide' + query_string(args)
    end

    def unhide_cf_thread_path(thread, args = {})
      _cf_thread_path(thread) + '/unhide' + query_string(args)
    end

    def redirect_to_page_path(forum, thread, args = {})
      args[:tid] = thread.thread_id
      _forum_path(forum) + '/redirect-to-page' + query_string(args)
    end

    #
    # message path helpers
    #

    def _message_path_wo_anchor(thread, message)
      _cf_thread_path(thread) + '/' + message.message_id.to_s
    end

    def message_path_wo_anchor(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + query_string(args)
    end

    def message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + query_string(args) + '#m' + message.message_id.to_s
    end

    def edit_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/edit' + query_string(args)
    end

    def new_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/new' + query_string(args)
    end

    def retag_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/retag' + query_string(args)
    end

    def restore_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/restore' + query_string(args)
    end

    def vote_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/vote' + query_string(args)
    end

    def accept_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/accept' + query_string(args)
    end

    def forbid_answer_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/forbid_answer' + query_string(args)
    end

    def allow_answer_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/allow_answer' + query_string(args)
    end

    def close_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/close' +
        query_string(args)
    end

    def open_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/open' +
        query_string(args)
    end

    def unread_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/unread' +
        query_string(args)
    end

    def flag_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/flag' +
        query_string(args)
    end

    def unflag_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/unflag' +
        query_string(args)
    end

    def interesting_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/interesting' +
        query_string(args)
    end

    def boring_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/boring' +
        query_string(args)
    end

    def versions_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/versions' +
        query_string(args)
    end

    def tweet_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/tweet' + query_string(args)
    end

    def subscribe_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/subscribe' + query_string(args)
    end

    def unsubscribe_message_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/unsubscribe' + query_string(args)
    end

    def split_thread_path(thread, message, args = {})
      _message_path_wo_anchor(thread, message) + '/split' + query_string(args)
    end

    def badges_path(args = {})
      root_path + 'badges' + query_string(args)
    end

    def badge_path(badge, args = {})
      badge = badge.slug unless badge.is_a?(String)
      badges_path + '/' + badge + query_string(args)
    end

    def cf_archive_path(forum, args = {})
      _forum_path(forum) + '/archive' + query_string(args)
    end

    def cf_archive_year_path(forum, year, args = {})
      _forum_path(forum) + '/' + year.to_s + query_string(args)
    end

    def cf_archive_month_path(forum, month, args = {})
      _forum_path(forum) + '/' + month.strftime('%Y/%b').downcase + query_string(args)
    end

    #
    # URL helpers
    #

    def _forum_url(forum)
      forum = 'all' if forum.blank?
      forum = forum.slug unless forum.is_a?(String)
      root_url + forum
    end

    def forum_url(forum, args = {})
      _forum_url(forum) + query_string(args)
    end

    def _cf_thread_url(thread)
      _forum_url(thread.forum) + thread.slug
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

    def mark_cf_thread_read_url(thread, args = {})
      _cf_thread_url(thread) + '/mark_read' + query_string(args)
    end

    def open_cf_thread_url(thread, args = {})
      _cf_thread_url(thread) + '/open' + query_string(args)
    end

    def close_cf_thread_url(thread, args = {})
      _cf_thread_url(thread) + '/close' + query_string(args)
    end

    def hide_cf_thread_url(thread, args = {})
      _cf_thread_url(thread) + '/hide' + query_string(args)
    end

    def unhide_cf_thread_url(thread, args = {})
      _cf_thread_url(thread) + '/unhide' + query_string(args)
    end

    def stats_url(forum, args = {})
      _forum_url(forum) + '/stats' + query_string(args)
    end

    def cites_url(args = {})
      root_url + 'cites' + query_string(args)
    end

    def cite_url(cite, args = {})
      root_url + 'cites/' + cite.cite_id.to_s + query_string(args)
    end

    def _message_url_wo_anchor(thread, message)
      _cf_thread_url(thread) + '/' + message.message_id.to_s
    end

    def message_url_wo_anchor(thread, message, args = {})
      _message_url_wo_anchor(thread, message) + query_string(args)
    end

    def message_url(thread, message, args = {})
      _message_url_wo_anchor(thread, message) + query_string(args) + '#m' + message.message_id.to_s
    end

    def retag_message_url(thread, message, args = {})
      _message_url_wo_anchor(thread, message) + '/retag' + query_string(args)
    end

    def open_message_url(thread, message, args = {})
      _message_url_wo_anchor(thread, message) + '/open' +
        query_string(args)
    end

    def unread_message_url(thread, message, args = {})
      _message_url_wo_anchor(thread, message) + '/unread' +
        query_string(args)
    end

    def flag_message_url(thread, message, args = {})
      _message_url_wo_anchor(thread, message) + '/flag' +
        query_string(args)
    end

    def tweet_message_url(thread, message, args = {})
      _message_url_wo_anchor(thread, message) + '/tweet' + query_string(args)
    end

    def subscribe_message_url(thread, message, args = {})
      _message_url_wo_anchor(thread, message) + '/subscribe' + query_string(args)
    end

    def unsubscribe_message_url(thread, message, args = {})
      _message_url_wo_anchor(thread, message) + '/unsubscribe' + query_string(args)
    end

    def split_thread_url(thread, message, args = {})
      _message_url_wo_anchor(thread, message) + '/split' + query_string(args)
    end

    def badges_url
      root_url + 'badges'
    end

    def badge_url(badge)
      badge = badge.slug unless badge.is_a?(String)
      badges_url + '/' + badge
    end

    def cf_archive_url(forum)
      forum_url(forum) + '/archive'
    end

    def cf_archive_year_url(forum, year)
      forum_url(forum) + '/' + year.to_s
    end

    def cf_archive_month_url(forum, month)
      forum_url(forum) + '/' + month.strftime('%Y/%b').downcase
    end
  end
end

# end
