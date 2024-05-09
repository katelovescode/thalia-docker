class DiscordBot::DiscordBot < Discordrb::Commands::CommandBot
  include DiscordBot::Commands::Ping

  def initialize
    Rails.logger.info "Initializing new bot object"
    token = Rails.application.credentials.dig(:discord, :token)
    client_id = Rails.application.credentials.dig(:discord, :client_id)
    super(token:, client_id:, prefix: "/")
  end
end
