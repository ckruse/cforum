Cforum::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # eager loading
  config.eager_load = false

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = {
    :host => 'localhost:3000'
  }
  config.action_mailer.smtp_settings = {
    address: "painkiller.defunced.de",
    openssl_verify_mode: 'none',
    port: 25,
    domain: "localhost:3000"
#    #authentication: "plain",
#    enable_starttls_auto: true,
#    #user_name: ENV["GMAIL_USERNAME"],
#    #password: ENV["GMAIL_PASSWORD"]
  }

  config.mail_sender = 'cforum@wwwtech.de'
  config.faye_url = "//localhost:9090/faye"
  config.internal_faye_url = 'http://localhost:9090/faye'

  config.allow_concurrency = true
end
