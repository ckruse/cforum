class Messages::MarkReadController < ApplicationController
  authorize_controller { authorize_user && authorize_forum(permission: :read?) }

  include ThreadsHelper

  def mark_thread_read
    if current_user.blank?
      flash[:error] = t('global.only_as_user')
      redirect_to cf_return_url
      return :redirected
    end

    @thread, @id = get_thread

    sql = 'INSERT INTO read_messages (user_id, message_id) VALUES (' + current_user.user_id.to_s + ', '

    @thread.messages.each do |m|
      begin
        Message.connection.execute(sql + m.message_id.to_s + ')')
      rescue ActiveRecord::RecordNotUnique # rubocop:disable Lint/HandleExceptions
      end
    end

    BroadcastUserJob.perform_later({ type: 'thread:read', thread: @thread },
                                   current_user.user_id)

    respond_to do |format|
      format.html do
        redirect_to cf_return_url(@thread),
                    notice: t('plugins.mark_read.thread_marked_read')
      end

      format.json { render json: { status: :success, slug: @thread.slug } }
    end
  end

  def mark_all_read
    index_threads

    sql = 'INSERT INTO read_messages (user_id, message_id) VALUES (' + current_user.user_id.to_s + ', '

    @threads.each do |t|
      t.messages.each do |m|
        begin
          Message.connection.execute(sql + m.message_id.to_s + ')')
        rescue ActiveRecord::RecordNotUnique # rubocop:disable Lint/HandleExceptions
        end
      end
    end

    redirect_to cf_return_url,
                notice: t('plugins.mark_read.marked_all_read')
  end
end

# eof
