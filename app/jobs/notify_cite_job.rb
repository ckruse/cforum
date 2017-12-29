class NotifyCiteJob < ApplicationJob
  queue_as :default

  def send_create_notifications(cite_id)
    cite = Cite.find(cite_id)

    users = User
              .joins('LEFT JOIN settings USING(user_id)')
              .where('setting_id IS NULL OR' \
                     "  (setting_id IS NOT NULL AND ((options->>'notify_on_cite') != 'no' OR " \
                     "  (options->>'notify_on_cite') IS NULL))")

    users = users.where('user_id != ?', cite.creator_user_id) if cite.creator_user_id.present?

    users.all.each do |user|
      notify_user(user, nil, I18n.t('cites.new_cite_arrived'),
                  cite_path(cite), cite.cite_id, 'cite:create',
                  'icon-new-activity')

      send_mail(cite, user) if user.conf('notify_on_cite') == 'email'
    end
  end

  def send_mail(cite, user)
    Rails.logger.debug('notify new cite: send mention mail to ' + user.email)
    NotifyNewMailer.new_cite(user, cite, cite_url(cite)).deliver_later
  end

  def send_destroy_notifications(cite_id)
    val = Notification.where(oid: cite_id, otype: 'cite:create', is_read: false).delete_all
    Rails.logger.debug('DELETE: ' + val.inspect)

    notifications = Notification
                      .preload(:recipient)
                      .where(oid: cite_id, otype: 'cite:create')
                      .all

    notifications.each do |notification|
      Rails.logger.debug('another nocification: ' + notification.notification_id.to_s)
      notify_user(notification.recipient, nil, I18n.t('cites.cite_got_deleted'),
                  cites_url, cite_id, 'cite:destroy',
                  'icon-new-activity')
    end
  end

  def perform(cite_id, type)
    Rails.logger.debug('notify new cite: ' + cite_id.inspect)

    if type == 'create'
      send_create_notifications(cite_id)
    elsif type == 'destroy'
      send_destroy_notifications(cite_id)
    end
  end
end

# eof
