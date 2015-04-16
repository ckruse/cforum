# -*- coding: utf-8 -*-

# Caches the settings which are often used
# When you use many workers the Rails.cache gets messed upp
# therefor we use some manual timeout.

class ConfigManager
  DEFAULTS = {
    'pagination' => 50,
    'pagination_users' => 50,
    'locked' => 'no',
    'sort_threads' => 'descending',
    'sort_messages' => 'ascending',
    'standard_view' => 'thread-view',
    'max_tags_per_message' => 3,
    'min_tags_per_message' => 1,
    'close_vote_votes' => 5,
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
    'use_archive' => 'no',
    'hide_subjects_unchanged' => 'yes',
    'css_styles' => nil,

    'max_threads' => 150,
    'max_messages_per_thread' => 50,

    'accept_value' => 15,
    'vote_down_value' => -1,
    'vote_up_value' => 10,
    'vote_up_value_user' => 10,

    'date_format_index' => '%d.%m.%Y %H:%M',
    'date_format_post' => '%d.%m.%Y %H:%M',
    'date_format_default' => '%d.%m.%Y %H:%M',

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
    'notify_on_new_mail' => 'no',
    'notify_on_activity' => 'no',
    'notify_on_answer' => 'no',
    'notify_on_flagged' => 'no',
    'notify_on_open_close_vote' => 'no',
    'notify_on_move' => 'no',
    'highlighted_users' => '',
    'highlight_self' => 'yes',
    'mark_read_moment' => 'before_render',

    'delete_read_notifications_on_answer' => 'yes',
    'delete_read_notifications_on_activity' => 'yes',

    'open_close_default' => 'open',
    'open_close_close_when_read' => 'no',
    'own_css_file' => nil,
    'own_js_file' => nil,
    'own_css' => nil,
    'own_js' => nil,
    'mark_suspicious' => 'no',
    'page_messages' => 'yes',
    'fold_quotes' => 'no'
  }

  def initialize(use_cache = true)
    @use_cache = use_cache
    @value_cache = {:users => {}, :forums => {}}

    @mutex = Mutex.new unless use_cache
  end

  def read_settings(user = nil, forum = nil)
    if not user.blank? and not @value_cache[:users].has_key?(user)
      @value_cache[:users][user] = CfSetting.find_by_user_id(user)
    end

    if not forum.blank? and not @value_cache[:forums].has_key?(forum)
      @value_cache[:forums][forum] = CfSetting.find_by_forum_id(forum)
    end

    unless @value_cache.has_key?(:global)
      @value_cache[:global] = CfSetting.where('user_id IS NULL and forum_id IS NULL').first
    end
  end

  def get(name, user = nil, forum = nil)
    @mutex.lock if @mutex

    Rails.logger.warn "unknown key: '#{name}'" unless DEFAULTS.has_key?(name)

    # reset cache before each setting query when cache is disabled
    @value_cache = {:users => {}, :forums => {}} unless @use_cache

    unless user.blank?
      user = CfUser.find_by_username(user.to_s) if not user.is_a?(CfUser) and not user.is_a?(Integer)
      user = user.user_id if user.is_a?(CfUser)
    end

    unless forum.blank?
      forum = CfForum.find_by_slug forum.to_s if not forum.is_a?(CfForum) and not forum.is_a?(Integer)
      forum = forum.forum_id if forum.is_a?(CfForum)
    end

    read_settings(user, forum)

    if not @value_cache[:users][user].blank? and @value_cache[:users][user].options.has_key?(name)
      return @value_cache[:users][user].options[name].blank? ? DEFAULTS[name] : @value_cache[:users][user].options[name]
    end

    if not @value_cache[:forums][forum].blank? and @value_cache[:forums][forum].options.has_key?(name)
      return @value_cache[:forums][forum].options[name].blank? ? DEFAULTS[name] : @value_cache[:forums][forum].options[name]
    end

    if @value_cache[:global] and @value_cache[:global].options.has_key?(name)
      return @value_cache[:global].options[name].blank? ? DEFAULTS[name] : @value_cache[:global].options[name]
    end

    DEFAULTS[name]
  ensure
    @mutex.unlock if @mutex
  end

end

# eof
