#!/usr/env ruby
#
# bones
# by Jonathan Drain
# Adopted as a framework for a new roller by rcuhljr

require 'DiceBot'

# I recommend that you change the name of your bot and the channels it joins to avoid
# conflict with other dicebots. Check with your network operator to ensure they allow bots.

# NB: As a security measure, some IRC networks prevent IRC bots from joining
# channels too quickly after connecting. Manually encourage it to join with this:
# /msg bones @@@join #channel

your_bot_name = "Dice_Eta"
server_to_join = "irc.sandwich.net"
port = 6667
list_of_channels = ["#rokugan"]

# NOTE: To join multiple networks, you can copy this file to create two Boneses.
# Alternatively, if you're familiar with Ruby, it should be straightforward. ('_')b

begin
  client = Bones::Client.new(your_bot_name, server_to_join, port, list_of_channels)
end