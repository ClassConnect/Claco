require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"
require "addressable/uri"

require 'digest/md5'
require 'zip/zip'


require 'log4r'
require 'log4r/yamlconfigurator'
require 'log4r/outputter/datefileoutputter'
include Log4r

# API_OPTIONS = {
#     # Your API token
#     :token => "3QsGvCVcSyYuN9HM2edPh4ZD",

#     # When uploading in async mode, a response is returned before conversion begins.
#     :async => false,

#     # Documents uploaded as private can only be accessed by owners or via sessions.
#     :private => false,

#     # When downloading, should the document include annotations?
#     :annotated => false,

#     # Can users mark up the document? (Affects both #share and #get_session)
#     :editable => true,

#     # Whether or not a session user can download the document.
#     :downloadable => true
# }

Bundler.require(:default, Rails.env) if defined?(Bundler)

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Claco
  class Application < Rails::Application

    config.middleware.use Rack::Pjax

    config.middleware.insert_before Rack::ETag, Rack::Deflater

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    # config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    config.assets.enabled = ENV['RAILS_ENV'] == "staging" ? false : true

    # Component of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # assign log4r's logger as rails' logger.
    if Rails.env == "development"
        log4r_config= YAML.load_file(File.join(File.dirname(__FILE__),"log4r.yml"))
        YamlConfigurator.decode_yaml( log4r_config['log4r_config'] )
        config.logger = Log4r::Logger[Rails.env]

        config.mongoid.logger = Log4r::Logger[Rails.env]

        # mongoid logger init calls
        #config.mongoid.logger = Logger.new($stdout, :debug)

        Mongoid.logger.level = Logger::DEBUG
    end
  end
end

