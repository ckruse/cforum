# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :output, Rails.root + "log/cron_log.log"

every 2.hours do
  script 'archive-runner.rb'
  script 'archive-cites.rb'
end

every 1.day, at: '3:00' do
  script 'clean-users.rb'
  script 'gen_forum_stats.rb'
  script 'check-for-yearling-badges.rb'
end

# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
