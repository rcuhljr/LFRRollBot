#require 'C:\Code\GitRepos\LFRRollBot\Dicebox'
require 'Dicebox'

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
    @orig = @rollText
    @label = @rollText.slice!(/#.*$/)
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
      if(inStr =~ /([0-9]+)([dkeu]+)([0-9]+)(\{.*\}|$)/i) #<num><type><num>[<options>]
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
    num1 = num1.to_i
    num2 = num2.to_i
    explodeOn = num2.to_i+1
    explode = true
    override = false
    emphasis = 1    
    if(!options.nil? && options != "")
      options = options[1..options.size-2]
      optionSet = options.split(',')
      optionSet.each { |x| 
        puts x
        couple = x.split(':')
        puts couple
        case couple[0].upcase
          when "EXPLODEON"
            explodeOn = couple[1].to_i
            override = true
          when "EMPHASIS"
            emphasis = 0 unless couple[1].to_s.upcase == "TRUE"
          when "EXPLODE"
            explode = couple[1].to_s.upcase == "TRUE"
        end         
      }      
    end
    if(!explode)
      explodeOn = num2+1
    end
    rollOptions = {:explodeOn => explodeOn, :rerollBelow => emphasis, :sidesPerDie => 10}
    case type.upcase
      when "D"
        rollOptions[:sidesPerDie] = num2
        rollResult = Dicebox.new.RollKeep(num1.to_i, num1.to_i, rollOptions)
      when "K"        
        rollOptions[:explodeOn] = 10 unless override
        rollResult = Dicebox.new.RollKeep(num1.to_i, num2.to_i, rollOptions)
      when "KE"
        rollOptions[:rerollBelow] = 2
        rollOptions[:explodeOn] = 10 unless override
        rollResult = Dicebox.new.RollKeep(num1.to_i, num2.to_i, rollOptions)
      when "KU"
        rollOptions[:explodeOn] = 11 
        rollResult = Dicebox.new.RollKeep(num1.to_i, num2.to_i, rollOptions)
      when "KD"
        rollOptions[:explodeOn] = 9 
        rollResult = Dicebox.new.RollKeep(num1.to_i, num2.to_i, rollOptions)
      else
        @failed = true
        @failText += " I didn't recognize one of your roll types: #{type}."
    end
    return rollResult
  end

  def execute
    rollSplitter
    @atoms.each {|x| evalute x unless @failed}    
    
    if(@failed)
      return @failText
    end
    return "#{@label[1..@label.size]} #{@orig.delete(' ')} #{@resultString.delete(' ')}:#{@result}" unless @label.nil?
    return "#{@orig.delete(' ')} #{@resultString.delete(' ')}:#{@result}"
  end    
end
