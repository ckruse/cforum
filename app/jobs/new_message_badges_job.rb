class NewMessageBadgesJob < ApplicationJob
  queue_as :default

  def perform_no_messages_badge(user)
    no_messages = user.messages.where(deleted: false).count

    badges = [
      { messages: 100, name: 'chisel' },
      { messages: 1000, name: 'brush' },
      { messages: 2500, name: 'quill' },
      { messages: 5000, name: 'pen' },
      { messages: 7500, name: 'printing_press' },
      { messages: 10_000, name: 'typewriter' },
      { messages: 20_000, name: 'matrix_printer' },
      { messages: 30_000, name: 'inkjet_printer' },
      { messages: 40_000, name: 'laser_printer' },
      { messages: 50_000, name: '1000_monkeys' }
    ]

    badges.each do |badge|
      if no_messages >= badge[:messages]
        b = user.badges.find { |user_badge| user_badge.slug == badge[:name] }
        give_badge(user, Badge.where(slug: badge[:name]).first!) if b.blank?
      end
    end
  end

  def check_for_teacher_badge(message)
    return if message.parent_id.blank? || message.parent.upvotes < 1

    votes = Vote.where(message_id: message.parent_id, user_id: message.user_id).first
    b = message.owner.badges.find { |user_badge| user_badge.slug == 'teacher' }

    return if b.present? || votes.present? || (message.parent.user_id == message.user_id)
    give_badge(message.owner, Badge.where(slug: 'teacher').first!)
  end

  def perform(thread_id, message_id)
    thread = CfThread
               .includes(:forum, messages: :owner)
               .where(thread_id: thread_id)
               .first

    return if thread.blank?

    sort_thread(thread)

    message = thread.find_message message_id

    return if message.blank? || message.user_id.blank?

    perform_no_messages_badge(message.owner)
    check_for_teacher_badge(message)
  end
end
