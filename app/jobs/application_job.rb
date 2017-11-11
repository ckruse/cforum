require Rails.root + 'lib/script_helpers.rb'

class ApplicationJob < ActiveJob::Base
  include Rails.application.routes.url_helpers

  include CForum::Tools
  include SortingHelper
  include ScriptHelpers

  def initialize(*args)
    super(*args)
    @config_manager = ConfigManager.new(false)
  end

  def conf(name, forum = nil)
    @config_manager.get(name, nil, forum)
  end

  def uconf(name, user = nil, forum = nil)
    @config_manager.get(name, user, forum)
  end

  def admins_and_moderators(forum_id)
    User.where('admin = true OR user_id IN ( ' \
               '  SELECT user_id FROM forums_groups_permissions ' \
               '    INNER JOIN groups_users USING(group_id) ' \
               '    WHERE forum_id = ? AND permission = ?' \
               ') OR user_id IN (' \
               '  SELECT user_id FROM badges_users ' \
               '    INNER JOIN badges USING(badge_id) ' \
               '    WHERE badge_type = ?)',
               forum_id, ForumGroupPermission::MODERATE,
               Badge::MODERATOR_TOOLS)
  end

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end
end

# eof
