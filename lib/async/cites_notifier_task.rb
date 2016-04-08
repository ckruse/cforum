# -*- coding: utf-8 -*-

class Peon::Tasks::CitesNotifier < Peon::Tasks::PeonTask
  def send_create_notifications(args)
    cite = Cite.find(args['cite_id'])

    users = Setting.
            preload(:user).
            where("user_id IS NOT NULL AND ((options->'notify_on_cite') != 'no' OR (options->'notify_on_cite') IS NULL)")

    users = users.where('user_id != ?', cite.creator_user_id) unless cite.creator_user_id.blank?

    users.all.each do |user|
      notify_user(user.user, nil, I18n.t('cites.new_cite_arrived'),
                  cite_path(cite), cite.cite_id, 'cite:create',
                  'icon-new-activity')

      send_mail(cite, user.user) if user.conf('notify_on_cite') == 'email'
    end
  end

  def send_mail(cite, user)
    Rails.logger.debug('notify new cite: send mention mail to ' + user.email)
    begin
      NotifyNewMailer.new_cite(user, cite, cite_url(cite)).deliver_now
    rescue => e
      Rails.logger.error('Error sending mail to ' + user.email.to_s + ': ' + e.message + "\n" + e.backtrace.join("\n"))
    end
  end

  def send_destroy_notifications(args)
    val = Notification.where(oid: args['cite_id'], otype: 'cite:create', is_read: false).delete_all
    Rails.logger.debug('DELETE: ' + val.inspect)

    Notification.
      preload(:recipient).
      where(oid: args['cite_id'], otype: 'cite:create').
      all.each do |notification|
      Rails.logger.debug("another nocification: " + notification.notification_id.to_s)
      notify_user(notification.recipient, nil, I18n.t('cites.cite_got_deleted'),
                  cites_url, args['cite_id'], 'cite:destroy',
                  'icon-new-activity')
    end
  end

  def work_work(args)
    Rails.logger.debug('notify new cite: ' + args.inspect)

    if args['type'] == 'create'
      send_create_notifications(args)
    elsif args['type'] == 'destroy'
      send_destroy_notifications(args)
    end
  end
end

# eof
