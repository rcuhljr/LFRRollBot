class InputReader
  def initialize(outputBuffer, running, sema)    
    @outputBuffer = outputBuffer
    @running = running
    @sema = sema    
    run()
  end    

  def run  
    while(@running[:state])
      sleep(0.1)            
      newLine = gets.chomp 
      return if newLine.nil?        
      if(newLine =~ /^quit/i)
        @running[:state] = false
        return
      end        
      @sema.synchronize{          
        @outputBuffer[0] = String.new(newLine)
      }            
    end
  end  
end