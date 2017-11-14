class ArchiverJob < ApplicationJob
  queue_as :cron

  def archive_max_messages_per_thread(forum)
    max_messages = conf('max_messages_per_thread', forum).to_i # max messages per thread

    # first: max messages per thread (to avoid monster threads like „Test, bitte ignorieren“)
    CfThread.transaction do
      threads = CfThread.select('threads.thread_id, COUNT(*) AS cnt, threads.flags')
                  .joins(:messages)
                  .where(archived: false, forum_id: forum.forum_id)
                  .group('threads.thread_id')

      threads.each do |t|
        next unless t.cnt.to_i > max_messages
        if t.flags['no-archive'] == 'yes'
          Rails.logger.info('ArchiveRunnerTask: archiving (deleting!) thread ' +
                            t.thread_id.to_s + ' because of to many messages')

          audit(t, 'destroy', nil)
          SearchDocument.where('reference_id IN (?)', t.messages.map(&:message_id)).delete_all
          t.destroy

        else
          Rails.logger.info('ArchiveRunnerTask: archiving thread ' +
                            t.thread_id.to_s + ' because of to many messages')

          CfThread.connection.execute 'UPDATE threads SET archived = true WHERE thread_id = ' + t.thread_id.to_s
          Message.connection.execute 'UPDATE messages SET ip = NULL where thread_id = ' + t.thread_id.to_s
          CfThread.connection.execute 'DELETE FROM invisible_threads WHERE thread_id = ' + t.thread_id.to_s
          audit(t, 'archive', nil)
        end
      end
    end
  end

  def archive_max_threads_per_forum(forum)
    max_threads = conf('max_threads', forum).to_i # max threads per forum

    # second: max threads per forum
    CfThread.transaction do
      while CfThread.where(forum_id: forum.forum_id, archived: false).count > max_threads
        rslt = CfThread.connection.execute 'SELECT threads.thread_id, MAX(messages.created_at) AS created_at' \
                                           '  FROM threads INNER JOIN messages USING(thread_id)' \
                                           '  WHERE threads.forum_id = ' + forum.forum_id.to_s +
                                           '        AND archived = false' \
                                           '  GROUP BY threads.thread_id' \
                                           '  ORDER BY MAX(messages.created_at) ASC LIMIT 1'
        tid = rslt[0]['thread_id']
        t = CfThread.find tid
        message_ids = t.messages.map(&:message_id)

        if t.flags['no-archive'] == 'yes'
          Rails.logger.info 'ArchiveRunnerTask: archiving (deleting!) thread ' + tid.to_s +
                            ' because oldest while to many threads'
          audit(t, 'destroy', nil)
          SearchDocument.where('reference_id IN (?)', message_ids).delete_all
          t.destroy
        else
          Rails.logger.info 'ArchiveRunnerTask: archiving thread ' + tid.to_s + ' because oldest while to many threads'
          audit(t, 'archive', nil)

          CfThread.connection.execute 'UPDATE threads SET archived = true WHERE thread_id = ' + tid.to_s
          Message.connection.execute 'UPDATE messages SET ip = NULL where thread_id = ' + tid.to_s
          CfThread.connection.execute 'DELETE FROM invisible_threads WHERE thread_id = ' + t.thread_id.to_s
          Subscription.where(message_id: message_ids).delete_all
        end
      end
    end
  end

  def archive_forum(forum)
    Rails.logger.info "ArchiveRunnerTask: running archiver for forum #{forum.name}"

    archive_max_messages_per_thread(forum)
    archive_max_threads_per_forum(forum)
  end

  def perform(*_args)
    # run for each forum separately
    forums = Forum.all

    forums.each do |f|
      archive_forum(f)
    end
  end
end

# eof
