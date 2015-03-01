require 'openssl'

class Connection # a connection to an IRC server; only one so far
  attr_reader :disconnected

  def initialize(server, port, ssl)
    @server = server
    @port = port
    @disconnected = false
	@ssl = ssl
    connect()
  end
  
  def connect    
    begin
      @socket = TCPSocket.open(@server, @port)	  
	  if @ssl
		  ssl = OpenSSL::SSL::SSLContext.new
		  ssl.verify_mode = OpenSSL::SSL::VERIFY_NONE
		  @socket = OpenSSL::SSL::SSLSocket.new(@socket, ssl)
		  @socket.sync = true
		  @socket.connect
	   end
      puts "hammer connected!"
      @disconnected = false
    rescue
      puts "failed to connect at #{Time.now}"
      @disconnected = true
    end
  end

  def disconnected? # inadvertently disconnected
    return @disconnected || @socket.closed?
  end

  def disconnect
    @disconnected = true
    @socket.close
  end

  def speak(msg,quietly = nil)
    if @disconnected
      puts "tried to send '#{msg}' while disconnected."
      return
    end
    begin
      if quietly != true
        puts("spoke>> " + msg)
      end
      @socket.write(msg + "\n")
    rescue 
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
      rescue 
        @disconnected = true
        return nil
      end
    end
  end
end