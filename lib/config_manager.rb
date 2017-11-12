# Caches the settings which are often used
# When you use many workers the Rails.cache gets messed upp
# therefor we use some manual timeout.
class ConfigManager
  DEFAULTS = {
    'pagination' => 50,
    'pagination_users' => 50,
    'pagination_search' => 50,
    'locked' => 'no',
    'css_ressource' => nil,
    'js_ressource' => nil,
    'sort_threads' => 'descending',
    'sort_messages' => 'ascending',
    'standard_view' => 'thread-view',
    'fold_read_nested' => 'no',
    'max_tags_per_message' => 3,
    'min_tags_per_message' => 1,
    'close_vote_votes' => 5,
    'close_vote_action_spam' => 'hide',
    'close_vote_action_off-topic' => 'close',
    'close_vote_action_not-constructive' => 'close',
    'close_vote_action_illegal' => 'hide',
    'close_vote_action_duplicate' => 'close',
    'close_vote_action_custom' => 'close',
    'delete_read_notifications_on_new_mail' => 'yes',
    'header_start_index' => 2,
    'editing_enabled' => 'yes',
    'edit_until_has_answer' => 'yes',
    'max_editable_age' => 10,
    'hide_subjects_unchanged' => 'yes',
    'hide_repeating_tags' => 'yes',
    'hide_repeating_date' => 'yes',
    'css_styles' => nil,

    'max_threads' => 150,
    'max_messages_per_thread' => 50,

    'cites_min_age_to_archive' => 2,

    'accept_value' => 15,
    'accept_self_value' => 15,
    'vote_down_value' => -1,
    'vote_up_value' => 10,
    'vote_up_value_user' => 10,

    'date_format_index' => '%d.%m.%Y %H:%M',
    'date_format_index_sameday' => '%H:%M',
    'date_format_post' => '%d.%m.%Y %H:%M',

    'date_format_search' => '%d.%m.%Y',
    'date_format_default' => '%d.%m.%Y %H:%M',
    'date_format_date' => '%d.%m.%Y',

    'mail_index_grouped' => 'yes',
    'mail_thread_sort' => 'ascending',

    'subject_black_list' => '',
    'content_black_list' => '',
    'nick_black_list' => '',

    # search settings
    'search_forum_relevance' => 1,
    'search_cites_relevance' => 0.9,

    # user settings
    'email' => nil,
    'url' => nil,
    'greeting' => nil,
    'farewell' => nil,
    'signature' => nil,
    'flattr' => nil,
    'autorefresh' => 0,
    'quote_signature' => 'yes',
    'show_unread_notifications_in_title' => 'no',
    'show_unread_pms_in_title' => 'no',
    'show_new_messages_since_last_visit_in_title' => 'no',
    'use_javascript_notifications' => 'yes',
    'notify_on_new_mail' => 'no',
    'notify_on_abonement_activity' => 'no',
    'autosubscribe_on_post' => 'yes',
    'notify_on_flagged' => 'no',
    'notify_on_open_close_vote' => 'no',
    'notify_on_move' => 'no',
    'notify_on_new_thread' => 'no',
    'notify_on_mention' => 'yes',
    'highlighted_users' => '',
    'highlight_self' => 'yes',
    'inline_answer' => 'yes',
    'quote_by_default' => 'no',

    'delete_read_notifications_on_abonements' => 'yes',
    'delete_read_notifications_on_mention' => 'yes',

    'open_close_default' => 'open',
    'open_close_close_when_read' => 'no',
    'own_css_file' => nil,
    'own_js_file' => nil,
    'own_css' => nil,
    'own_js' => nil,
    'mark_suspicious' => 'yes',
    'page_messages' => 'yes',
    'fold_quotes' => 'no',
    'live_preview' => 'yes',

    'load_messages_via_js' => 'yes',

    'hide_read_threads' => 'no',

    'links_white_list' => '',

    'notify_on_cite' => 'yes',
    'delete_read_notifications_on_cite' => 'no',

    'max_image_filesize' => 2,

    'diff_context_lines' => nil
  }.freeze

  def initialize(use_cache = true)
    @use_cache = use_cache
    @value_cache = { users: {}, forums: {} }

    @mutex = Mutex.new unless use_cache
  end

  def fill_user_cache(user)
    @value_cache[:users][user] = Setting.find_by(user_id: user) unless @value_cache[:users].key?(user)
  end

  def fill_forum_cache(forum)
    @value_cache[:forums][forum] = Setting.find_by(forum_id: forum) unless @value_cache[:forums].key?(forum)
  end

  def read_settings(user = nil, forum = nil)
    fill_user_cache(user) if user.present?
    fill_forum_cache(forum) if forum.present?

    return if @value_cache.key?(:global)

    @value_cache[:global] = Setting
                              .where('user_id IS NULL and forum_id IS NULL')
                              .first
  end

  def get(name, user = nil, forum = nil)
    @mutex&.lock

    Rails.logger.warn "unknown key: '#{name}'" unless DEFAULTS.key?(name)

    # reset cache before each setting query when cache is disabled
    @value_cache = { users: {}, forums: {} } unless @use_cache

    if user.present?
      user = User.find_by(username: user.to_s) if !user.is_a?(User) && !user.is_a?(Integer)
      user = user.user_id if user.is_a?(User)
    end

    if forum.present?
      forum = Forum.find_by slug: forum.to_s if !forum.is_a?(Forum) && !forum.is_a?(Integer)
      forum = forum.forum_id if forum.is_a?(Forum)
    end

    read_settings(user, forum)

    if @value_cache[:users][user].present? && @value_cache[:users][user].options.key?(name)
      return DEFAULTS[name] if @value_cache[:users][user].options[name].blank?
      return @value_cache[:users][user].options[name]
    end

    if @value_cache[:forums][forum].present? && @value_cache[:forums][forum].options.key?(name)
      return DEFAULTS[name] if @value_cache[:forums][forum].options[name].blank?
      return @value_cache[:forums][forum].options[name]
    end

    if @value_cache[:global]&.options&.key?(name)
      return DEFAULTS[name] if @value_cache[:global].options[name].blank?
      return @value_cache[:global].options[name]
    end

    DEFAULTS[name]
  ensure
    @mutex&.unlock
  end
end

# eof
