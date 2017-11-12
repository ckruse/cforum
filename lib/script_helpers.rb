module ScriptHelpers
  include AuditHelper

  def root_path
    Rails.application.config.action_controller.relative_url_root || '/'
  end

  def root_url
    (ActionMailer::Base.default_url_options[:protocol] || 'http') + '://' +
      ActionMailer::Base.default_url_options[:host] + root_path
  end

  def conf(name, forum = nil)
    $config_manager.get(name, nil, forum) # rubocop:disable Style/GlobalVars
  end

  def uconf(name, forum = nil)
    conf(name, forum)
  end

  def give_badge(user, badge)
    user.badge_users.create!(badge_id: badge.badge_id,
                             created_at: Time.zone.now,
                             updated_at: Time.zone.now)

    audit(user, 'badge-gained', nil)

    notify_user(user, '', I18n.t('badges.badge_won',
                                 name: badge.name,
                                 mtype: I18n.t('badges.badge_medal_types.' + badge.badge_medal_type)),
                badge_path(badge), badge.badge_id, 'badge')
  end

  def notify_user(user, hook, subject, path, oid, otype, icon = nil, description = nil)
    return if hook.present? && (@config_manager.get(hook, user) != 'yes')

    n = Notification.create!(
      recipient_id: user.user_id,
      subject: subject,
      description: description,
      path: path,
      icon: icon,
      oid: oid,
      otype: otype,
      created_at: DateTime.now,
      updated_at: DateTime.now
    )

    unread = Notification.where(recipient_id: user.user_id, is_read: false).count
    BroadcastUserJob.perform_later({ type: 'notification:create', notification: n, unread: unread },
                                   user.user_id)
  end
end

# eof
