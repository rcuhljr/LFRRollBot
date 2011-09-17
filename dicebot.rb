#!/usr/env ruby
# bones v0.03
# by Jonathan Drain http://d20.jonnydigital.com/roleplaying-tools/dicebot #
# adapted by Robert Uhl for the purposes of an L5R specific dice roller.

require 'socket'
require 'strscan'
require 'FileUtils'
require 'Thread'
require 'pp'
load 'GrammarEngine.rb'
load 'InputReader.rb'
load 'RollAliasManager.rb'
load 'Utilities.rb'
load 'Connection.rb'

module DiceBot
  class Client 
    def initialize(nick, server, port, channels, bots = [], debug = false)
      @sema = Mutex.new
      @running = {:state => true}      
      @outputBuffer = [""]
      @nick = nick
      @server = server # one only
      @port = port
      @channels = channels
      @rollAliases = RollAliasMananger.new
      @rollPrefaces = ["roll", "r"]
      @botLocations = []
      @bots = bots.map{|x| x.upcase}
      @lastPong = Time.new
      @debug = debug
      connect()
      Thread.new{InputReader.new(@outputBuffer, @running, @sema)}
      run()
    end
    
    def debug(msg)
      puts msg
      puts "running:"
      pp @running
      puts "channels:" + @channels.inspect
      puts "bot locations:" + @botLocations.inspect
    end

    def connect
      @connection = Connection.new(@server, @port)
      
      @connection.speak "NICK #{@nick}"
      @connection.speak "USER #{@nick} #{@nick} * :#{@nick}: ?help for more information"
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
            Utilities::Logger.new.log("Joining #{channel}")
          end 
      else
        @connection.speak "JOIN #{channels}"            
            puts "Joining #{channels}"
            Utilities::Logger.new.log("Joining #{channels}")
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

      while @running[:state]
        while @connection.disconnected? #|| (Time.new-@lastPong) > 600 # never give up reconnect          
          sleep 30
          connect()   
          #puts "reconnecting: #{@lastPong}"
          #@lastPong == Time.new
        end
        sleep(0.1)
        speak_input
        handle_msg (@connection.listen)
      end
    end
    
    def handle_msg(msg)	         
      case msg
        when nil
          #nothing
        when /^PING (.+)$/
          @lastPong = Time.new
          puts "PONGED #{@lastPong}"
          @connection.speak("PONG #{$1}", true) # PING? PONG!
          # TODO: Check if channels are joined before attempting redundant joins
          join_quietly(@channels)
        when /^:/ # msg
          Utilities::Logger.new.log(msg)
          message = Message.new(msg, @botLocations, @bots)
          respond(message)
        else
          Utilities::Logger.new.log("RAW>>"+msg)
          puts "RAW>> #{msg}"
          #nothing
      end
      if(@debug && !msg.nil?) then
        debug(msg);
      end
    end
    
    def respond(msg)
      if msg.mode == "INVITE"
        join msg.text
      elsif msg.text =~ /^@join (#.*)$/  #someone messaged him with @join #channel
        join $1.to_s
      elsif msg.text =~ /^\?(\S+)/ #help command
        reply_array(msg, Utilities::Helper.new.help($1))        
      elsif msg.text =~ /^!([a-z0-9_]*)([+\-# ].*)?$/ #a roll alias name, possibly followed by additional dice and or a label
        rollString = @rollAliases.load(msg.name, $1)        
        reply(msg, "Sorry, I don't have that alias stored for your name.") unless !rollString.nil?
        return unless !rollString.nil?                
        if(rollString.include?("#") && !$2.nil? && $2.include?("#")) #if there's already a label in the alias and they added a new label, combine them.
          rollString.sub!(/#.*/, msg.text[$1.size+1,msg.text.size])                  
        elsif(rollString.include?("#")) #if there's just a label in the stored alias, insert any dice rolls into the roll string ahead of the label
          rollString.sub!("#", msg.text[$1.size+1,msg.text.size]+ " #")    
        elsif(msg.text.size+1 > ($1.size)) #if the rollstring has no label just tack on whatever they added to the alias.
          rollString = rollString + msg.text[$1.size+1,msg.text.size]                    
        end
        respond_roll(rollString, msg)        
      elsif msg.text =~ /^@(\S+)/ #commands from the users, also incidently operator users in the 353 channel user listing mode
        reply(msg, command(msg)) unless msg.mode == "353"
      elsif msg.text =~ /^(\S+) [0-9]*[dkeum]+[0-9].*/i #roll message following some initial text like roll, r, etc.                  
        return unless @rollPrefaces.include?($1)
        respond_roll(msg.text, msg)
      elsif msg.text =~ /^[0-9]*[dkeum]+[0-9].*/i  #roll message without preface, roll if no competing dicebots detected.        
        return if @botLocations.count{|x| x.slice(0,msg.origin.size+1) == "#{msg.origin.upcase}." } > 0 #index is faster, but have to deal with nils.
        respond_roll(msg.text, msg)
      end
    end   
    
    def respond_roll(rollstring, msg)
      parser = GrammarEngine.new(rollstring)
      begin
        result = parser.execute          
        putRoll(msg, result)
      rescue Exception => e
        puts "ERROR: " + e.to_s
        Utilities::Logger.new.log("ERROR: " + e.to_s)
        reply(msg, "I had an unexpected error, sorry.")
      end
    end    
    
    def command(msg)
      case msg.text
        when /^@record (!)?(\S+) (.*)/i #@record !stuff Roll ...
          @rollAliases.save(msg.name, $2, $3)
          return "Saved."
        when /^@remove (!)?(\S+)/i #@remove !alias
          @rollAliases.remove(msg.name, $2)
          return "Removed."
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
    
    def reply_array(msg, message) # reply to a pm or channel message
      return if message.nil?
      if msg.privmsg
        message.each { |x|
        @connection.speak "#{msg.mode} #{msg.name} :#{x.chomp}"
        sleep(0.25)
        }
      else
        message.each { |x|
        @connection.speak "#{msg.mode} #{msg.origin} :#{x.chomp}"
        sleep(0.25)
        }
      end
    end
    
    def putRoll(msg, result)  
      answer = "Errored Message?"
      if msg.privmsg
        answer = "#{msg.mode} #{msg.name} :#{result[:message]}" if result[:error]
        answer = "#{msg.mode} #{msg.name} :\x01ACTION rolls the dice for you. #{result[:message]}\x01" unless result[:error]
      else
        answer = "#{msg.mode} #{msg.origin} :\x01ACTION rolls the dice for #{msg.name} #{result[:message]}\x01" unless result[:error]
        answer = "#{msg.mode} #{msg.origin} :#{msg.name}, #{result[:message]}" if result[:error]
      end
      Utilities::Logger.new.log(answer)
      @connection.speak answer
    end
    
    def pm(person, message)
      person = @channels[0] if person =~ /:/
      @connection.speak "PRIVMSG #{person} :#{message}"
    end
    
    def say(channel, message)
      pm(channel, message) # they're functionally the same
      sleep(0.25)
    end
    
    def say_array(channel, message)
      message.each { |x|
        pm(channel, x.chomp) 
        sleep(0.25)
      }
    end
    
    def speak_input() 
      outLine = ""      
      @sema.synchronize{outLine = String.new(@outputBuffer[0])}      
      if(outLine.nil? or outLine.empty?)
        return
      end      
      target = outLine.slice(/^\S+/i)      
      message = outLine.slice(/ .*/)      
      if (target =~ /join/i)
        join message
        @sema.synchronize{@outputBuffer[0] = ""}
        return
      end
      pm(target, message) 
      @sema.synchronize{@outputBuffer[0] = ""}
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
    attr_accessor :name, :hostname, :mode, :origin, :privmsg, :text, :kicked
    
    def initialize(msg, botLocations, bots)
      @botLocations = botLocations
      @bots = bots
      parse(msg)      
    end
    
    def parse(msg)
      # sample messages:
      # :JDigital!~JD@86.156.2.220 PRIVMSG #bones :hi
      # :JDigital!~JD@86.156.2.220 PRIVMSG bones :hi

      msg = msg.gsub(/\x02/, '') # bold
      msg = msg.gsub(/\x03(\d)?(\d)?/, '') # colour

      case msg
        when nil
          puts "heard nil? wtf"
        when /^:(\S+)!(\S+) (PRIVMSG|NOTICE|INVITE|PART|JOIN|KICK) ((#?).+) :(.+)/
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
        when /^:(\S+) ([0-9]+) (.*) ((#?)\S+) :(.+)/          
          @origin = $4
          @mode = $2                    
          if ($5 == "#")
            @privmsg = false
          else
            @privmsg = true
          end
          @text = $6.chomp
        when /^:(\S+)!(\S+) (JOIN|QUIT) :(.+)/          
          @name = $1
          @mode = $3  
          @origin = $4
      end
      puts "message:"+msg
      puts @mode
      return if @bots.empty?   
      if(@mode == "353")
        puts msg
        puts @text
        foundBots = @text.upcase.split.select {|x| @bots.include? x} #array of bots found
        foundBots.each {|x| puts x}
        foundBots.each {|x| @botLocations << "#{@origin.upcase}.#{x}"}
      end
      if(@mode == "PART")
        @botLocations.delete_if {|x| x == "#{@origin.upcase}.#{@name.upcase}"} unless @bots.index{|x| @name.upcase == x }.nil?
      end
      if(@mode == "KICK")
        puts "kick detected"
        @kicked = @origin.split[1].chomp
        @origin = @origin.split[0].chomp
        puts "kicked:#{kicked}"
        @botLocations.delete_if {|x| x == "#{@origin.upcase}.#{kicked.upcase}"}
      end
      if(@mode == "QUIT")
        @botLocations.delete_if {|x| x.match ".#{@name.upcase}" } unless @bots.index{|x| @name.upcase == x }.nil?
      end
      if(@mode == "JOIN")
        @botLocations  << "#{@origin.chomp.upcase}.#{@name.chomp.upcase}" unless @bots.index{|x| @name.chomp.upcase == x }.nil?
      end      
    end

    def print
      puts "[#{@origin}|#{@mode}] <#{@name}> #{@text}"
    end
  end
end