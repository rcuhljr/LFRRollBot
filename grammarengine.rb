require 'C:\Code\GitRepos\LFRRollBot\Dicebox'
#require 'Dicebox'

class GrammarEngine
  def initialize(msg)
    @rollText = msg.squeeze(' ').strip.chomp    
    @failed = false
    @failText = "I was unable to interpret part of your request, sorry."
    @result = 0
    @resultString = " "
    @opVal = "+"
    @opCount = 1
    @orig
  end    
  
  def rollSplitter
    @rollText.slice!(/^roll /i)
    @rollText.slice!(/^r /i)    
    @orig = @rollText
    @label = @rollText.slice!(/#.*$/)
    @label = @label[1..@label.size] unless @label.nil?
    @label = "" if @label.nil?
    #puts "start state:"+ @rollText
    while(!@rollText.sub!(/([^\s])([+-])([^\s])/){|s| $1 + ' ' + $2 + ' ' +$3}.nil?) do #add a space around + or - signs without one.
      #puts @rollText
    end
    while(!@rollText.sub!(/([+-])([^\s])/){|s|  $1 + ' ' +$2}.nil?) do #add a space around + or - signs without one.
      #puts @rollText
    end
    while(!@rollText.sub!(/([^\s])([+-])/){|s| $1 + ' ' + $2}.nil?) do #add a space around + or - signs without one.
      #puts @rollText
    end
	while(!@rollText.sub!(/([\s]+)({)/){|s| $2}.nil?) do #remove spaces before and inside {}
      #puts @rollText
    end
	while(!@rollText.sub!(/({[^}]*)[\s]+([^}]*})/){|s| $1 + $2}.nil?) do #remove spaces before and inside {}
      #puts @rollText
    end
    @atoms = @rollText.split(' ')
  end
  
  def evalute (inStr)
    #puts "instr:"+inStr.to_s
    return if (inStr.nil? or inStr == "")    
    if(@opCount == 0)
      if(inStr =~ /(\+|\-)/)
        @opCount += 1
        @opVal = $1      
        return
      else
        @failed = true
        @failText += " Are you missing an Operator between rolls?"      
        return
      end
    else
      @opCount -= 1
      if(inStr =~ /([0-9]+)([dkeum]+)([0-9]+)(\{.*\}|$)/i) #<num><type><num>[<options>]
        rollResult = Roll($1,$2,$3,$4);
      elsif(inStr =~ /d([0-9]+)(\{.*\}|$)/i)#<type><num>[<options>]
        rollResult = Roll("1",$1,$2,$3);
      elsif(inStr =~ /[0-9]+/)
        rollResult = {:total => inStr.to_i, :values => ""}
      end
    end
    if(rollResult.nil?)
      return
    end
    case @opVal
      when /\+/
        puts "adding:" + rollResult[:total].to_s        
        @result += rollResult[:total]        
      when /\-/
        puts "subtracting:" + rollResult[:total].to_s
        @result -= rollResult[:total]
    end 
    if(!rollResult[:values].nil? && rollResult[:values] != "")    
      @resultString += rollResult[:values].to_s    
    end
  end
  
	def Roll(num1, type, num2, options)
    puts "num1:" + num1
    puts "num2:" + num2
    num1 = num1.to_i
    num2 = num2.to_i
    roll = 0
    keep = 0
    explodeOn = num2+1
    explode = true    
    emphasis = 1            
    rollOptions = {:explodeOn => explodeOn, :rerollBelow => emphasis, :sidesPerDie => 10}
    type.upcase.split('').each {|typeLetter| 
      case typeLetter
        when "D"
          rollOptions[:sidesPerDie] = num2
          roll = num1
          keep = num1
        when "K"        
          rollOptions[:explodeOn] = 10 
          roll = num1
          keep = num2
        when "E"
          rollOptions[:rerollBelow] = 2                    
        when "U"
          rollOptions[:explodeOn] = 11           
        when "M"
          rollOptions[:explodeOn] = 9          
        else
          @failed = true
          @failText += " I didn't recognize one of your roll types: #{type}."
          return
      end
    }
    if(!options.nil? && options != "")
      options = options[1..options.size-2]
      optionSet = options.split(',')
      optionSet.each { |x|         
        couple = x.split(':')        
        case couple[0].upcase
          when "EXPLODEON"
            explodeOn = couple[1].to_i
            rollOptions[:explodeOn] = explodeOn          
        end         
      }      
    end
    return Dicebox.new.RollKeep(roll, keep, rollOptions)
  end

  def execute
    puts "execute:" + @rollText
    rollSplitter
    @atoms.each {|x| evalute x unless @failed}    
    
    return {:error => true, :message => @failText} if @failed
    return {:error => false, :message => "#{@label} #{@orig} #{@resultString.delete(' ')}:#{@result}"}    
  end    
end
