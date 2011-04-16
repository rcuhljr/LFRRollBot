  load 'Utilities.rb'
  
  class RollAliasMananger    
    def initialize    
      @rollAliasFileName = "rollalias.dat"      
      begin
        @rollAliases = Utilities::DataManager.new.load(@rollAliasFileName)
      rescue
        @rollAliases = Hash.new
        @rollAliases["TOKI"] = Hash.new
        @rollAliases["TOKI"]["TEST"] = "8km3 #sample"
        Utilities::DataManager.new.store(@rollAliasFileName, @rollAliases)
      end    
    end
    
    def save(name, aliasString, value)
      @rollAliases[name.upcase] = Hash.new if @rollAliases[name.upcase].nil?
      @rollAliases[name.upcase][aliasString.upcase] = value
      Utilities::DataManager.new.store(@rollAliasFileName, @rollAliases)
    end
    
    def remove(name, aliasString)
      return if @rollAliases[name.upcase].nil?      
      @rollAliases[name.upcase].delete aliasString.upcase
      Utilities::DataManager.new.store(@rollAliasFileName, @rollAliases)
    end
    
    def load(name, aliasString) 
       puts name
       puts aliasString
      return String.new(@rollAliases[name.upcase][aliasString.upcase]) unless @rollAliases[name.upcase].nil? or @rollAliases[name.upcase][aliasString.upcase].nil?
    end    
    
    def list(name)
      return "No aliases found." if @rollAliases[name.upcase].nil?
      resultString = ""
      @rollAliases[name.upcase].keys.each { |x| resultString += "!" + x.downcase + ", " }
      return resultString.slice(0,resultString.size-2)
    end
  end  