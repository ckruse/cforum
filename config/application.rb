require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require File.expand_path('../../lib/config_manager.rb', __FILE__)
require File.expand_path('../../lib/exceptions.rb', __FILE__)

module Cforum
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.autoload_paths += ["#{config.root}/app/validators"]
    config.time_zone = 'Europe/Berlin'
    config.i18n.default_locale = :de
    config.active_record.schema_format = :sql
    config.action_dispatch.ip_spoofing_check = false

    config.search_dict = 'german'
    config.exception_mail_receiver = 'cforum@wwwtech.de'
  end
end
