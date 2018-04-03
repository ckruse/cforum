module MessageHelper
  include MessageHeaderHelper

  def message_header(thread, message, opts = {})
    opts = { first: false, prev_deleted: false,
             show_icons: false, do_parent: false,
             tree: true, id: true, hide_repeating_subjects: false,
             show_editor: false, id_prefix: nil, active_message: @message,
             subject: true, tags: true, author_link_to_message: true,
             parent_subscribed: false }.merge(opts)

    html = message_header_header_element(thread, message, opts)

    html << message_header_message_icons(thread, message, opts)
    html << '  ' << message_header_forum_plate(thread.forum) if opts[:first] && current_forum.blank?
    html << message_header_votes(message, opts)
    html << message_header_subject(thread, message, opts)
    html << message_header_details(thread, message, opts)
    html << message_header_thread_icons(thread, opts)

    html << '</header>'

    html.html_safe
  end

  def message_tree(thread, messages, opts = {})
    opts = { prev_deleted: false, show_icons: false, id: true,
             hide_repeating_subjects: false, hide_repeating_tags: false,
             active_message: @message, subject: true,
             tags: true, id_prefix: nil,
             parent_subscribed: false }.merge(opts)

    html = "<ol>\n"
    messages.each do |message|
      classes = []

      html << '<li'
      html << ' class="' << classes.join(' ') << '"' if classes.present?
      html << '>'
      html << message_header(thread, message,
                             first: false,
                             prev_deleted: opts[:prev_deleted],
                             show_icons: opts[:show_icons],
                             id: opts[:id],
                             hide_repeating_subjects: opts[:hide_repeating_subjects],
                             hide_repeating_tags: opts[:hide_repeating_tags],
                             active_message: opts[:active_message],
                             id_prefix: opts[:id_prefix],
                             parent_subscribed: opts[:parent_subscribed])

      if message.messages.present?
        html << message_tree(thread, message.messages,
                             first: false,
                             prev_deleted: message.deleted?,
                             show_icons: opts[:show_icons],
                             id: opts[:id],
                             hide_repeating_subjects: opts[:hide_repeating_subjects],
                             hide_repeating_tags: opts[:hide_repeating_tags],
                             active_message: opts[:active_message],
                             id_prefix: opts[:id_prefix],
                             parent_subscribed: opts[:parent_subscribed] || message.attribs[:is_subscribed])
      end

      html << '</li>'
    end

    html << "\n</ol>"

    html.html_safe
  end

  def set_message_attibutes(message, thread, user = current_user, parent = nil)
    message.forum_id   = thread.forum_id
    message.user_id    = user.try(:user_id)
    message.thread_id  = thread.thread_id

    message.content    = Message.to_internal(message.content)

    message.created_at = Time.zone.now
    message.updated_at = message.created_at

    message.parent_id  = parent.try(:message_id)
  end

  def message_author(message)
    message.author = current_user.username if current_user.present?
    # we ignore the case when user has forgotten to enter a name
    return true if message.author.blank?

    found_user = User.where('LOWER(username) = LOWER(?)', @message.author.strip).first
    return true if found_user.blank?

    if found_user.user_id != current_user.try(:user_id)
      flash.now[:error] = I18n.t('errors.name_taken')
      return false
    end

    true
  end

  def save_user_cookies(message)
    return if current_user

    cookies[:cforum_user] = { value: request.uuid, expires: 1.year.from_now } if cookies[:cforum_user].blank?
    message.uuid = cookies[:cforum_user]

    cookies[:cforum_author]   = { value: @message.author, expires: 1.year.from_now }
    cookies[:cforum_email]    = { value: @message.email, expires: 1.year.from_now }
    cookies[:cforum_homepage] = { value: @message.homepage, expires: 1.year.from_now }
  end

  def std_conditions(conditions, tid = false)
    if conditions.is_a?(String) || conditions.is_a?(Integer)
      conditions = if tid
                     { thread_id: conditions }
                   else
                     { slug: conditions }
                   end
    end

    conditions[:messages] = { deleted: false } unless @view_all

    conditions
  end

  def get_thread(thread_id = nil)
    tid = false
    id  = nil

    if !thread_id.nil?
      id = thread_id
      tid = true
    elsif params[:year] && params[:mon] && params[:day] && params[:tid]
      id = CfThread.make_id(params)
    else
      id = params[:id]
      tid = true
    end

    thread = CfThread
               .preload(:forum,
                        messages: [:editor, :tags, :thread, :versions, :cite, :open_moderation_queue_entry,
                                   { votes: :voters,
                                     owner: %i[settings badges],
                                     message_references: { src_message: [{ thread: :forum },
                                                                         :owner, :tags, :votes] } }])
               .includes(messages: :owner)
               .where(std_conditions(id, tid))
               .references(messages: :owner)
               .first

    raise ActiveRecord::RecordNotFound if thread.blank?

    # sort messages
    sort_thread(thread)

    [thread, id]
  end

  def get_thread_w_post(tid = nil, mid = nil)
    thread, id = get_thread(tid)

    mid = params[:mid] if mid.nil?
    message = nil

    if mid.present?
      mid = mid.to_i if mid.is_a?(String)
      message = thread.find_message(mid)
      raise ActiveRecord::RecordNotFound if message.nil?
    end

    [thread, message, id]
  end

  def positive_score_class(score)
    case score
    when 0..3
      'positive-score'
    when 4
      'positiver-score'
    else
      'best-score'
    end
  end

  def negative_score_class(score)
    case score
    when 0..3
      'negative-score'
    when 4
      'negativer-score'
    else
      'negative-bad-score'
    end
  end

  def score_class(score)
    return '' if score.zero?

    if score >= 0
      positive_score_class(score)
    else
      negative_score_class(score.abs)
    end
  end

  def message_classes(msg, thread, active, rm = :thread)
    classes = []
    classes << 'active' if active
    classes << 'interesting' if msg.attribs[:is_interesting]
    classes << 'accepted' if thread.accepted.include?(msg)

    if uconf('fold_read_nested') == 'yes' && rm == :nested && !active &&
       !thread.archived && msg.attribs['classes'].include?('visited')
      classes << 'folded'
    end

    classes << score_class(msg.score)

    classes.join(' ')
  end

  def flag_reason(msg)
    flag_reason_entry(msg.open_moderation_queue_entry)
  end

  def flag_reason_entry(entry)
    case entry.reason
    when 'custom'
      entry.custom_reason
    when 'duplicate'
      cf_link_to I18n.t('plugins.flag_plugin.duplicate_message'), entry.duplicate_url
    else
      I18n.t('messages.close_vote.' + entry.reason)
    end
  end
end

# eof
