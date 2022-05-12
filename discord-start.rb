require 'discordrb'
require './grammarengine.rb'

# Include your token in the specified file token.txt
bot = Discordrb::Commands::CommandBot.new token: IO.readlines("token.txt", chomp: true).first, prefix: '!'


bot.command(:roll, min_args: 1, usage: 'roll Nk(m/e/u)N #Label for roll') do |event, *args|
    parser = GrammarEngine.new(args.join(' '))
    result = parser.execute

    if result[:error]
        result[:message]
    else
        postfix = "_rolls the dice for #{event.user.display_name} #{result[:message]}_"
        if postfix.size > 450
            "_rolls the dice for #{event.user.display_name} #{result[:shortmessage]}_"
        else
            postfix
        end
     end
end

bot.command(:exit, help_available: false) do |event|
    break unless event.user.id == 85173705105211392

    bot.send_message(event.channel.id, 'Bot is shutting down')
    exit
  end

at_exit { bot.stop }
bot.run
