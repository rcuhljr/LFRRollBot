class InputReader
  def initialize(canSend, outputBuffer, running)
    @canSend = canSend
    @outputBuffer = outputBuffer
    @running = running
    run()
  end    

  def run
    while(@running[:state])
      sleep(0.1)
      next if @canSend[:state]
      @outputBuffer[0] = gets.chomp      
      if(@outputBuffer[0] =~ /^quit/i)
        @canSend[:state] = false
        @running[:state] = false
      elsif @outputBuffer[0].size > 0               
        @canSend[:state] = true      
      end
    end
  end  
end