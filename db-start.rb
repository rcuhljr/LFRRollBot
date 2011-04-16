#!/usr/env ruby
# by Jonathan Drain
# Adopted as a framework for a new roller by Robert Uhl

load 'DiceBot.rb'

# I recommend that you change the name of your bot and the channels it joins to avoid
# conflict with other dicebots. Check with your network operator to ensure they allow bots.

# NB: As a security measure, some IRC networks prevent IRC bots from joining
# channels too quickly after connecting. Manually encourage it to join with this:
# /msg <bot_name> @join #channel

bot_name = "Dice_Eta"
server_to_join = "irc.sandwich.net"
port = 6667
list_of_channels = ["#Rokugan", "#Rokugan2", "#hor", "#hor1", "#hor3"]
bots = ["Dicesuke", "@Dicesuke"]  #fix hack later

#If you don't want any bot detection features just don't send in a bots paramater. E.g. DiceBot::Client.new(bot_name, server_to_join, port, list_of_channels)
begin
  client = DiceBot::Client.new(bot_name, server_to_join, port, list_of_channels, bots)
end