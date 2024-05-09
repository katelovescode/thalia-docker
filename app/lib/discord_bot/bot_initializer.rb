require_relative "discord_bot"

class DiscordBot::BotInitializer < Rails::Railtie
  Rails.logger.info("Initializing the bot")
  server do
    Rails.logger.info("Server started")
    fork do
      Rails.logger.info("Server forked")
      bot = DiscordBot.new
      Rails.logger.info("New Bot: #{bot}")
      at_exit { bot.stop }
      bot.run
      Rails.logger.info("Invite URL: #{bot.invite_url}")
    end
  end
end
