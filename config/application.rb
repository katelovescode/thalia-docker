require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Thalia
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))

    logger.info("Initializing the bot")
    server do
      config.after_initialize do
        logger.info("Server started")
        bot = Discordrb::Commands::CommandBot.new(
          token: Rails.application.credentials.dig(:discord, :token),
          client_id: Rails.application.credentials.dig(:discord, :client_id),
          prefix: "/"
        )
        logger.info("New Bot: #{bot}")
        bot.command :ping do |event|
          event.respond("Pong!")
        end
        logger.info("Commands: #{bot.commands}")
        at_exit { bot.stop }
        bot.run(true)
        logger.info("Invite URL: #{bot.invite_url}")
      end
    end
  end
end
