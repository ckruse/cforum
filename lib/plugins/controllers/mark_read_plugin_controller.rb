# -*- coding: utf-8 -*-

class MarkReadPluginController < ApplicationController
  authorize_controller { authorize_user && authorize_forum(permission: :read?) }

  include ThreadsHelper

  def mark_unread
    if current_user.blank?
      flash[:error] = t('global.only_as_user')
      redirect_to cf_forum_url(current_forum)
      return :redirected
    end

    @thread, @message, @id = get_thread_w_post

    CfMessage.connection.
      execute("DELETE FROM read_messages WHERE user_id = " +
              current_user.user_id.to_s + " AND message_id = " +
              @message.message_id.to_s)
    redirect_to cf_forum_url(@thread.forum.slug), notice: t('plugins.mark_read.marked_unread')
  end

  def mark_all_read
    index_threads

    sql = "INSERT INTO read_messages (message_id, user_id) VALUES"
    parts = []

    @threads.each do |t|
      t.messages.each do |m|
        parts << " (" + m.message_id.to_s + ", " + current_user.user_id.to_s + ")"
      end
    end

    sql << ' ' + parts.join(", ")

    CfMessage.connection.execute(sql)

    redirect_to cf_threads_url(current_forum),
                notice: t('plugins.mark_read.marked_all_read')
  end
end


# eof
