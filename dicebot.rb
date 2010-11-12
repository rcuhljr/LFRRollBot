#!/usr/env ruby
#
# bones v0.03
# by Jonathan Drain http://d20.jonnydigital.com/roleplaying-tools/dicebot
# 
#
# NB: As a security measure, some IRC networks prevent IRC bots from joining
# channels too quickly after connecting. Solve with this:
# /invite botname
# adapted by rcuhljr for the purposes of an L5R specific dice roller.

require 'socket'
require 'strscan'
#require 'GrammarEngine'
require 'C:\Code\GitRepos\LFRRollBot\GrammarEngine'

module DiceBot
  class Client 
    def initialize(nick, server, port, channels)
      @running = true            
      @nick = nick
      @server = server # one only
      @port = port
      @channels = channels
      @rollAliases = RollAliasMananger.new

      connect()
      run()
    end

    def connect
      @connection = Connection.new(@server, @port)
      
      @connection.speak "NICK #{@nick}"
      @connection.speak "USER #{@nick} dice_eta * :Dice_Eta: ?help for more information"
      # TODO: fix join bug
      # TODO: what is the join bug?
      join(@channels)
    end

    def join(channels)
      if channels.kind_of?(Array) 
          channels.each do |channel|
            # join channel
            @connection.speak "JOIN #{channel}"
            puts "Joining #{channel}"
          end 
      else
        @connection.speak "JOIN #{channels}"
            puts "Joining #{channels}"
      end
    end
    
    def join_quietly(channels)
      if channels.kind_of?(Array) 
        channels.each do |channel|
          # join channel
          @connection.speak("JOIN #{channel}", true)
        end
      else
        @connection.speak "JOIN #{channels}"        
      end
    end
    
    def run # go
      # stay connected
      # handle replies

      while @running
        while @connection.disconnected? # never give up reconnect          
          sleep 10
          connect()          
        end
        
        handle_msg (@connection.listen)
      end
    end
    
    def handle_msg(msg)
	  puts msg unless msg.nil?
      case msg
        when nil
          #nothing
        when /^PING (.+)$/
          @connection.speak("PONG #{$1}", true) # PING? PONG!
          # TODO: Check if channels are joined before attempting redundant joins
          join_quietly(@channels)
        when /^:/ # msg
          message = Message.new(msg)
          respond(message)
        else
          puts "RAW>> #{msg}"
          #nothing
      end
    end
    
    def respond(msg)
      # msg :name, :hostname, :mode, :origin, :privmsg, :text
      #if msg.name == "" && msg.text == ""
      #  quit(msg.text)
      #end      
      if msg.mode == "INVITE"
        join msg.text
      elsif msg.text =~ /^\?(\S+)/
        say(msg.origin, Helper.new.help($1)) unless msg.privmsg
        reply(msg,Helper.new.help($1)) unless !msg.privmsg
      elsif msg.text =~ /^!(\S+)/
        rollString = @rollAliases.load(msg.name, $1)
        reply(msg, "Sorry, I don't have that alias stored for your name.") unless !rollString.nil?
        return unless !rollString.nil?
        parser = GrammarEngine.new(rollString)
        begin
          result = parser.execute          
          reply(msg, result)
        rescue Exception => e
          puts "ERROR: " + e.to_s
          reply(msg, "I had an unexpected error, sorry.")
        end
      elsif msg.text =~ /^@(\S+)/
        reply(msg, command(msg))
      elsif msg.text =~ /^roll .*[dkeu][0-9].*/i          
        parser = GrammarEngine.new(msg.text)
        begin
          result = parser.execute          
          reply(msg, result)
        rescue Exception => e
          puts "ERROR: " + e.to_s
          reply(msg, "I had an unexpected error, sorry.")
        end
      end
    end    
    
    def command(msg)
      case msg.text
        when /^@record !(\S+) (roll .*)/i #@record !stuff Roll ...
          @rollAliases.save(msg.name, $1, $2)
          return "Saved."
        when /^@List/i
          return @rollAliases.list(msg.name)
        else
          return "I don't recognize that command, sorry."
      end      
    end

    def reply(msg, message) # reply to a pm or channel message
      if msg.privmsg
        @connection.speak "#{msg.mode} #{msg.name} :#{message}"
      else
        @connection.speak "#{msg.mode} #{msg.origin} :#{msg.name}, #{message}"
      end
    end
    
    def pm(person, message)
      @connection.speak "PRIVMSG #{person} :#{message}"
    end
    
    def say(channel, message)
      pm(channel, message) # they're functionally the same
    end
    
    def notice(person, message)
      @conection.speak "NOTICE #{person} :#{message}"
    end

    def quit(message)
      @connection.speak "QUIT :#{message}"
      @connection.disconnect
      @running = false;
    end
  end

  class Message
    attr_accessor :name, :hostname, :mode, :origin, :privmsg, :text
    
    def initialize(msg)
      parse(msg)
    end
    
    def parse(msg)
      # sample messages:
      # :JDigital!~JD@86.156.2.220 PRIVMSG #bones :hi
      # :JDigital!~JD@86.156.2.220 PRIVMSG bones :hi
      
      # filter out bold and colour
      # feature suggested by KT
      msg = msg.gsub(/\x02/, '') # bold
      msg = msg.gsub(/\x03(\d)?(\d)?/, '') # colour

      case msg
        when nil
          puts "heard nil? wtf"
        when /^:(\S+)!(\S+) (PRIVMSG|NOTICE|INVITE) ((#?)\S+) :(.+)/
          @name = $1
          @hostname = $2
          @mode = $3
          @origin = $4
          if ($5 == "#")
            @privmsg = false
          else
            @privmsg = true
          end
          @text = $6.chomp
          print()
      end
    end

    def print
      puts "[#{@origin}|#{@mode}] <#{@name}> #{@text}"
    end
  end
  
  class Connection # a connection to an IRC server; only one so far
    attr_reader :disconnected

    def initialize(server, port)
      @server = server
      @port = port
      @disconnected = false
      connect()
    end
    
    def connect
      # do some weird stuff with ports
      @socket = TCPSocket.open(@server, @port)
      puts "hammer connected!"
      @disconnected = false
    end

    def disconnected? # inadvertently disconnected
      return @socket.closed? || @disconnected
    end

    def disconnect
      @socket.close
    end

    def speak(msg,quietly = nil)
      begin
        if quietly != true
          puts("spoke>> " + msg)
        end
        @socket.write(msg + "\n")
      rescue Errno::ECONNRESET
        @disconnected = true;
      end 
    end
  
    def listen  # poll socket for lines. luckily, listen is sleepy
      sockets = select([@socket], nil, nil, 1)
      if sockets == nil
        return nil
      else
        begin
          s = sockets[0][0] # read from socket 1
          
          if s.eof?
            @disconnected = true
            return nil
          end
          
          msg = s.gets
          
        rescue Errno::ECONNRESET
          @disconnected = true
          return nil
        end
      end
    end
  end
  #Todo move help texts out to txt files.
  class Helper
    def help(command)
      case command.upcase
        when "HELP", "ROLL", "DICE"
          return "L5R Dice Roller. Examples: 'roll 5k3' rolls 5 d10 and keeps the best 3, exploding on 10's. 'roll 5ke3' rerolls 1's one time(emphasis). 'roll 3ku3' this roll has no explosions(unskilled). The BNF that this bot will follow is at found at https://github.com/rcuhljr/LFRRollBot/blob/master/README.txt not all non terminals are implemented."
        else
          return nil
        end
    end
  end
  
  class DataManager
    def load(name)
      dataFile = File.new(name,"r")      
      return Marshal.load(dataFile)
    end

    def store(name, data)
      dataFile = File.new(name,"w")        
      Marshal.dump(data,dataFile)
      dataFile.close
    end
  end
  
  class RollAliasMananger    
    def initialize    
      @rollAliasFileName = "rollalias.dat"      
      begin
        @rollAliases = DataManager.new.load(@rollAliasFileName)
      rescue
        @rollAliases = Hash.new
        @rollAliases["TOKI"] = Hash.new
        @rollAliases["TOKI"]["TEST"] = "8k3{ExplodeOn:9} #sample"
        DataManager.new.store(@rollAliasFileName, @rollAliases)
      end    
    end
    
    def save(name, aliasString, value)
      @rollAliases[name.upcase][aliasString.upcase] = value
      DataManager.new.store(@rollAliasFileName, @rollAliases)
    end
    
    def load(name, aliasString)    
      return @rollAliases[name.upcase][aliasString.upcase] unless @rollAliases[name.upcase].nil?
    end    
    
    def list(name)
      return "No aliases found." if @rollAliases[name.upcase].nil?
      resultString = ""
      @rollAliases[name.upcase].keys.each { |x| resultString += "!" + x.downcase + ", " }
      return resultString.slice(0,resultString.size-2)
    end
  end  
end