require 'C:\Code\GitRepos\LFRRollBot\Dicebox'

class GrammarEngine
  def initialize(msg)
    @rollText = msg.squeeze(' ').strip.chomp    
    @failed = false
    @failText = "I was unable to interpret part of your request, sorry."
    @result = 0
    @resultsString = ""
    @opVal = "+"
    @opCount = 1
  end    
  
  def rollSplitter
    @rollText.slice!(/^roll /i)
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
    @atoms = @rollText.split(' ')
  end
  
  def evalute (inStr)
    return if instr.nil?
    rollResult = false;
    if(@opCount == 0)
      if(inStr ~= "+|-")
        @opCount += 1
        @opVal = $1      
      else
        @failed = true
        @failText += " Are you missing an Operator between rolls?"      
      end
    else
      @opCount -= 1
      if(inStr ~= /([0-9]+)([dkeu])([0-9]+)({.*}$)/i) #<num><type><num>[<options>]
        rollResult = Roll($1,$2,$3,$4);
      elsif(inStr ~= /d([0-9]+)({.*}$)/i)#<type><num>[<options>]
        rollResult = Roll("1",$1,$2,$3);
      elsif()#unusued
      
      end
    end
    if(!rollResult)
      return
    end
    
  end
  
   def Roll(num1, type, num2, options)
    if(!options.nil?)
      options = options[1..options.size-1]
      optionSet = options.split(',')
      optionSet.each { |x| x }
    
    end
    case type.upcase
      when "D"
      
      when "K"
      
      when "KE"
      
      when "KU"
      
      else
        @failed = true
        @failText += " I didn't recognize one of your roll types: #{type}."
      end
   end
  

  def execute
    rollSplitter
    @atoms.each {|x| evalute x}    
    
    if(@failed)
      return failText
    end
    return "#{@label[1..@label.size]} #{@resultsString}:#{@result}"
  end    
end