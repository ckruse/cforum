# frozen_string_literal: true

source 'https://rubygems.org'

ruby File.read('.ruby-version').strip

gem 'bootsnap', require: false

gem 'rails', '~> 5.1.0'
gem 'rails-i18n'
gem 'warden', '!= 1.2.5'

gem 'pg', '~> 1.0.0'

gem 'bcrypt'
gem 'kramdown'
gem 'pygments.rb'

gem 'devise'
gem 'devise-i18n'

gem 'autoprefixer-rails'
gem 'coffee-rails'
gem 'sass-rails', '> 4.0.0'
gem 'sprockets'
gem 'therubyracer'
gem 'uglifier', '>= 1.0.3'

gem 'redis', '~> 3.0'
gem 'sidekiq', '~> 5.0.0'
gem 'sidekiq-cron'
gem 'rufus-scheduler', '~> 3.4.0'
gem 'terrapin'

gem 'content_for_in_controllers'

gem 'kaminari'

group :development, :test do
  gem 'active_record_query_trace'
  gem 'capybara'
  gem 'capybara-screenshot'
  gem 'email_spec'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'guard-rspec'
  gem 'listen'
  gem 'pry-byebug'
  gem 'puma'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'selenium-webdriver'
  gem 'spring-commands-rspec'
  gem 'terminal-notifier-guard'
end

gem 'rails-controller-testing', require: false, group: :test
gem 'simplecov', require: false, group: :test

gem 'spring', group: :development
gem 'web-console', '~> 3.5', group: :development

gem 'libnotify',
    group: :development,
    require: RUBY_PLATFORM.include?('linux') && 'libnotify'

gem 'font-awesome-sass', '<5.0'
gem 'jquery-rails'
gem 'jquery-ui-rails'

gem 'email_validator'
gem 'validate_url'

gem 'paperclip'

gem 'stringex'

gem 'diffy'

gem 'exception_notification'

gem 'htmlentities'

gem 'unicorn', group: :production

gem 'oauth'
gem 'twitter'

# eof
