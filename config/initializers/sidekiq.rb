if Sidekiq.server?
  Sidekiq.default_worker_options = { 'backtrace' => true }

  #
  # jobs running more often than once a day
  #

  Sidekiq::Cron::Job.create(name: 'Archiver background task (every hour)',
                            cron: '0 * * * *',
                            class: 'ArchiverJob',
                            queue: 'cron')

  Sidekiq::Cron::Job.create(name: 'Cites archiver background task (every 2 hours)',
                            cron: '0 */2 * * *',
                            class: 'CitesArchiverJob',
                            queue: 'cron')

  #
  # nightly jobs
  #

  Sidekiq::Cron::Job.create(name: 'Distribute yearling badges (every night at 1:00)',
                            cron: '0 1 * * *',
                            class: 'CheckYearlingBadgesJob',
                            queue: 'cron')

  Sidekiq::Cron::Job.create(name: 'Destroy all unconfirmed users older than 7 days (every night at 3:00)',
                            cron: '0 3 * * *',
                            class: 'CleanUsersJob',
                            queue: 'cron')

  Sidekiq::Cron::Job.create(name: 'Calculate forum statistics (every night at 4:00)',
                            cron: '0 4 * * *',
                            class: 'GenForumStatsJob',
                            queue: 'cron')

  Sidekiq::Cron::Job.create(name: 'Clean up counter tables (every night at 4:00)',
                            cron: '0 4 * * *',
                            class: 'CleanCounterTableJob',
                            queue: 'cron')
end

# eof
