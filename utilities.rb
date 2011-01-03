 module Utilities
  class Helper
    def help(command)
      case command.upcase
        when "HELP", "ROLL", "DICE"
          dataFile = File.new("help.txt","r")
          val = dataFile.readlines
          dataFile.close
          return val          
        else
          return nil
        end
    end
  end

  class Logger
    def log(text)   
      stamp = Time.new
      FileUtils.mkdir "logs" unless File.directory? "logs"
      dataFile = File.new("logs\\#{stamp.strftime("%Y%m%d")}.log","a")
      dataFile.write "#{stamp.strftime("%H:%M:%S")}-#{text}"
      dataFile.close
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
end