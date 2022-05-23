load 'Dicebox.rb'

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
    @orig = @rollText.dup
    @label = @rollText.slice!(/#.*$/)
    @label = @label[1..@label.size] unless @label.nil?
    @label ||= ""
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
    if @rollText =~ /(\+\s+1\/2)/
      @half_die = 1+rand(3)
      @rollText.gsub!($1,"")
    end
    if @rollText =~ /[kn]/i && @rollText =~ /(\+\s+\d|-\s+\d)/
      @modifier = $1
      @rollText.gsub!($1,"")
      @modifier.gsub!(/\s/,"")
    end
    @atoms = @rollText.split(' ')
    if @atoms.delete("NND")
      @hero_damage = true
      @nnd = true
    end
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
      if(inStr =~ /([0-9]+)([dknxeum]+)([0-9]+)(\{.*\}|$)/i) #<num><type><num>[<options>]
        rollResult = Roll($1,$2,$3,$4)
      elsif(inStr =~ /(d)([0-9]+)(\{.*\}|$)/i)#<type><num>[<options>]
        rollResult = Roll("1",$1,$2,$3)
      elsif(inStr =~ /([0-9]+)([dknxeum]+)([0-9]+)([dknxeum]+)$/i)
        rollResult = Roll($1,$2+$4,$3, "")
      elsif(inStr =~ /[0-9]+/)
        rollResult = {:total => inStr.to_i, :values => ""}
      end
    end
    if(rollResult.nil?)
      return
    end
    if @hero_damage
      return if rollResult[:values].empty?
      if @nnd && !@killing
        @result = " Stun-#{count_stun(rollResult[:values]).ceil}"
      else
        @result = " Stun-#{count_stun(rollResult[:values]).ceil} Body-#{count_body(rollResult[:values]).ceil}"
      end
    else
      case @opVal
        when /\+/
          #puts "adding:" + rollResult[:total].to_s
          @result += rollResult[:total]
        when /\-/
          #puts "subtracting:" + rollResult[:total].to_s
          @result -= rollResult[:total]
      end
    end
    if(!rollResult[:values].nil? && rollResult[:values] != "")
      @resultString += rollResult[:values].to_s
    end
  end

  def count_stun(values)
    result = values.sum
    if @modifier
      result = eval("#{result}#{@modifier}")
    end
    if @half_die
      result += @half_die
    end
    multipliers = find_location_multipliers
    bonus = @label.scan(/\d+/).first.to_i
    if multipliers.empty?
      if @killing
        @rand_stun_mod = [rand(6),1].max
        return result*(@rand_stun_mod + bonus)
      else
        return result*(1+bonus)
      end
    else
      if @killing
        return result*(multipliers[:kstun] + bonus)
      else
        return result*(multipliers[:stun] + bonus)
      end
    end
  end

  def count_body(values)
    multipliers = find_location_multipliers
    bonus = @label.scan(/\d+/).first.to_i
    result = 0
    if !@killing
      result = values.map{ |x|
        case x
        when 1
          0
        when 6
          2
        else
          1
        end
      }.sum
    else
      result = values.sum
    end
    if @modifier
      result = eval("#{result}#{@modifier}")
    end
    if @half_die
      result += @half_die
    end
    if multipliers.empty?
      return result
    else
      return result * multipliers[:body]
    end
  end

  def find_location_multipliers
    case @label
    when /head/i
      {:kstun => 5, :stun => 2, :body => 2}
    when /hands|feet/i
      {:kstun => 1, :stun => 0.5, :body => 0.5}
    when /arms|legs/i
      {:kstun => 2, :stun => 0.5, :body => 0.5}
    when /shoulders|chests/i
      {:kstun => 3, :stun => 1, :body => 1}
    when /stomach/i
      {:kstun => 4, :stun => 1.5, :body => 1}
    when /vitals/i
      {:kstun => 4, :stun => 1.5, :body => 2}
    when /thighs/i
      {:kstun => 2, :stun => 1, :body => 1}
    else
      {}
    end
  end

	def Roll(num1, type, num2, options)
    #puts "num1:" + num1
    #puts "num2:" + num2
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
        @hero_damage = true if num2 == 6
        @killing = true
      when "N"
        @hero_damage = true
      when "X"
        @hero_damage = true
        @nnd = true
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
    rollSplitter
    @atoms.each {|x| evalute x unless @failed}
    return {:error => true, :message => @failText} if @failed
    @label = "##{@label}" unless (@label.nil? || @label.size == 0)
    aMessage = if @label =~ /show/
                 "(#{@orig}) #{@resultString}(half:#{@half_die}, 1d6-1:#{@rand_stun_mod}):#{@result}"
               else
                 "(#{@orig}):#{@result}"
               end
    shortMessage = "(#{@orig}#{@label}) for a total of #{@result}"
    return {:error => false, :message => aMessage, :shortmessage => shortMessage}
  end
end
