module DiscordBot::Commands::Ping
  extend Discordrb::Commands::CommandContainer

  command :ping do |event|
    event.respond("Pong!")
  end

  # bot.message(content: "Ping!") do |event|
  #   event.respond("Pongpong")
  # end
end
