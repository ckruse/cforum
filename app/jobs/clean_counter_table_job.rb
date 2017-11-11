class CleanCounterTableJob < ApplicationJob
  queue_as :cron

  def perform(*_args)
    forums = Forum.all
    forums.each do |f|
      Rails.logger.info 'Cleaning counter table: ' + f.name
      Forum.connection.execute("SELECT counter_table_get_count('threads', " + f.forum_id.to_s + ')')
      Forum.connection.execute("SELECT counter_table_get_count('messages', " + f.forum_id.to_s + ')')
    end
  end
end

# eof
