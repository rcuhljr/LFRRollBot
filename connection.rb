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
    begin
      @socket = TCPSocket.open(@server, @port)
      puts "hammer connected!"
      @disconnected = false
    rescue
      puts "failed to connect at #{Time.now}"
      @disconnected = true
    end
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