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
require 'GrammarEngine'
#require 'C:\Code\GitRepos\LFRRollBot\GrammarEngine'

module DiceBot
  class Client 
    def initialize(nick, server, port, channels)
      @running = true            
      @nick = nick
      @server = server # one only
      @port = port
      @channels = channels
      @rollAliases = RollAliasMananger.new
      @rollPrefaces = ["roll", "r"]
      @dicesuke = Hash.new
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
        rollString = @rollAliases.load(msg.name, $1).to_s
        puts "init:" +rollString
        reply(msg, "Sorry, I don't have that alias stored for your name.") unless !rollString.nil?
        return unless !rollString.nil?
        if(rollString.include?("#") && msg.text.size > ($1.size+1))
          rollString.sub!("#", msg.text[$1.size+1,msg.text.size]+ " #")
          puts "subbed:" +rollString
        elsif(msg.text.size > ($1.size+1))
          rollString = rollString + msg.text[$1.size,mst.text.size]
          puts "appended:" +rollString
        end
        parser = GrammarEngine.new(rollString)
        begin
          result = parser.execute          
          putRoll(msg, result)
        rescue Exception => e
          puts "ERROR: " + e.to_s
          reply(msg, "I had an unexpected error, sorry.")
        end
      elsif msg.text =~ /^@(\S+)/
        reply(msg, command(msg))
      elsif msg.text =~ /^(\S+) .*[dkeu][0-9].*/i                  
        return unless @rollPrefaces.include?($1)
        parser = GrammarEngine.new(msg.text)
        begin
          result = parser.execute          
          putRoll(msg, result)
        rescue Exception => e
          puts "ERROR: " + e.to_s
          reply(msg, "I had an unexpected error, sorry.")
        end      
      elsif msg.text =~ /^[0-9]*[dkeu][0-9].*/i  
        return if @dicesuke[msg.origin]       
        parser = GrammarEngine.new(msg.text)
        begin
          result = parser.execute          
          putRoll(msg, result)
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
        when /^@Mode:t\{\S+\}/i
          if $1 =~ /list/i
            return "Currently looking for:" + @rollPrefaces.to_s
          end
          setMode msg.text
          return "Set."
        else
          return "I don't recognize that command, sorry."
      end      
    end
    
    def setMode(text)
      results = text.split(':')
      @rollPrefaces = Array.new
      results.each { |x| 
      case x
        when /r/i
          @rollPrefaces << "r" unless @rollPrefaces.include?("r")        
        when /roll/i
          @rollPrefaces << "roll" unless @rollPrefaces.include?("roll")        
      end
      }
    end

    def reply(msg, message) # reply to a pm or channel message
      if msg.privmsg
        @connection.speak "#{msg.mode} #{msg.name} :#{message}"
      else
        @connection.speak "#{msg.mode} #{msg.origin} :#{msg.name}, #{message}"
      end
    end
    
    def putRoll(msg, result)        
      if msg.privmsg
        @connection.speak "#{msg.mode} #{msg.name} :#{result[:message]}" if result[:error]
        @connection.speak "#{msg.mode} #{msg.name} :\x01ACTION#{result[:message]}\x01" unless result[:error]
      else
        @connection.speak "#{msg.mode} #{msg.origin} :\x01ACTION rolls the dice for #{msg.name}, #{result[:message]}\x01" unless result[:error]
        @connection.speak "#{msg.mode} #{msg.origin} :#{msg.name}, #{result[:message]}" if result[:error]
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
        when /^:(\S+)!(\S+) (PRIVMSG|NOTICE|INVITE|[0-9]|PART|JOIN) ((#?)\S+) :(.+)/
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
      
      if(@mode == "353")
        @dicesuke[@origin] = true if @text =~ /dicesuke/i
      end
      if(@mode == "PART")
        @dicesuke[@origin] = false if @name =~ /dicesuke/i
      end
      if(@mode == "JOIN")
        @dicesuke[@origin] = true if @name =~ /dicesuke/i
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
          dataFile = File.new("help.txt","r")
          val = dataFile.gets
          dataFile.close
          return val          
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
      @rollAliases[name.upcase] = Hash.new if @rollAliases[name.upcase].nil?
      @rollAliases[name.upcase][aliasString.upcase] = value
      DataManager.new.store(@rollAliasFileName, @rollAliases)
    end
    
    def load(name, aliasString)    
      return String.new(@rollAliases[name.upcase][aliasString.upcase]) unless @rollAliases[name.upcase].nil?
    end    
    
    def list(name)
      return "No aliases found." if @rollAliases[name.upcase].nil?
      resultString = ""
      @rollAliases[name.upcase].keys.each { |x| resultString += "!" + x.downcase + ", " }
      return resultString.slice(0,resultString.size-2)
    end
  end  
end