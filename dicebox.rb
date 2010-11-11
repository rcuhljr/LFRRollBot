module Dicebox # Original by JD. http://d20.jonnydigital.com/ Mostly overhauled now.

  class Dice
    def initialize(line)
      @line = line.to_s
      @dice_regex = /((\+|-|~)?(\d+)(k\d+)?)/
    end
    
    def roll()
      return roll_line(@line)
    end

    def roll_line(line)
      line = line.split(";")
      line.each_index do |i|
        if not line[i] =~ @dice_regex
          line.delete_at i
        end
      end
      if not line[0] =~ @dice_regex
        array.delete
      end
      line = line.map {|attack_roll| roll_attack attack_roll.strip}
      return line.join("; ").delete("\001")
    end
    
    def roll_attack(attack)
      attack = attack.split(" ", 2)
      if attack[1] == "" || attack[1] == nil
        comment = attack[0]
      else
        comment = attack[1]
      end
    
      attack[0] =~ /^(\d+)#(.*)/
      if $1
        times = $1.to_i
      else
        times = 1
      end
      
      if times == 1
        sets = [attack[0]]
      else
        sets = [$2.to_s] * times
      end
      
      sets = sets.map{|roll| roll_roll roll}
      return comment + ": " + sets.join(", ")
    end

    def roll_roll(roll)
      rolls = roll.scan(@dice_regex)  # [["1d6", nil, "1", "d6"], ["+1d6", "+", "1", "d6"]]
      originals = rolls.map {|element| element[0].to_s}  # ["1d6", "+1d6", "+1"]
      results = rolls.map {|element| roll_element element}
      # return elements in a coherent roll
      # turn 1d20+2d6-1d6+4-1
      # into 22 [1d20=4; 2d6=1,6; 1d6=-3]
      
      total = 0
      #results.flatten.each{|r| total += r}
	  results[0].sort! {|x,y| y <=> x }
	  rolls[0][3][1..3].to_i.times {|x| total += results[0][x]}
	  total += results[1][0] unless results[1].nil?
	  
      
      indiv_results = []
      originals.each_index do |i|
        if originals[i] =~ /k/
          f = originals[i] + "=" + results[i].sort {|x,y| y <=> x }.join(",")
          indiv_results << f
        end
      end
      
      return total.to_s + " [" + indiv_results.join("; ").delete("-").delete("+") + "]"
    end
    
    def roll_element(element)
      # sample ["1d6", nil, "1", "d6"]
      # sample ["+1d6", "+", "1", "d6"]
      # sample ["+1", "+", "1", nil]
      original, sign, numerator, denominator = element[0], element[1], element[2], element[3]
	  noex = true	  
	  noex = false unless sign
	  applyemp = true
	  applyemp = false unless sign == "~"
      sign = "+" unless sign
      
      # fix for "d20"
      if (not denominator) and original =~ /^(\+|-|~)?d(\d+)/
        sign = $1
        numerator = 1
        denominator = $2
      end
      
      if denominator
        result = []
        numerator.to_i.times do
		  temp = random(10)
		  while ( ((not noex) or applyemp) && (temp % 10 == 0) ) 
			temp += random(10)
		  end
		  if (applyemp && (temp == 1))
		    temp = random(10)
			while ( temp % 10 == 0 ) 
			temp += random(10)
			end
		  end
          result << temp
        end
      else
        result = [numerator.to_i]
      end

      # flip result unless sign
      if sign == "-"
        result = result.map{ |r| 0 - r}
      end
      
      return result
    end

    def random(value)
      return 0 if value == 0
      return rand(value)+1
    end

  end
  $debug = false
  #TODO remove luck, deal with sidesper instead of mod perdie, force to return an array instead of a result value.
  #Accepts the number of Rolled dice, kept dice, and an optional array of modifiers. Valid modifers are
  #:explodeOn - int - Skilled rolls are 10, great potential would be 9, enter 11 for untrained.  
  #:rerollBelow - int - Reroll any dice below the threshold. 5 would cause a 4 to reroll but not a 5. functions ONCE
  #:dropBelow - int - Drop any dice rolled below the threshold. 5 would cause a 4 to drop bot not a 5.
  #:sidesPerDie - int - add or subtract an integer value on all kept dice.
  #Returns a hash of :value (int) :voidBack (bool)
  def RollKeep(rolled, kept, modifiers = {})
    result = {:value => 0, :voidBack => false}
    explosionCount = 0
    explosionCount2 =0
    
    return result unless (kept > 0 and rolled > 0) # idiot check
    
    kept = rolled unless rolled >= kept #idiot check 2
    
    #load in default values
    explodesOn = modifiers[:explodeOn].nil? ? 10 : modifiers[:explodeOn]
    luck = modifiers[:luck].nil? ? false : modifiers[:luck]
    rerollBelow = modifiers[:rerollBelow].nil? ? 0 : modifiers[:rerollBelow]
    dropBelow = modifiers[:dropBelow].nil? ? 0  : modifiers[:dropBelow]
    modPerDie = modifiers[:modPerDie].nil? ? 0 : modifiers[:modPerDie]
    
    puts "explodesOn:#{explodesOn}"  unless !$debug
    puts "luck:#{luck}"  unless !$debug
    puts "rerollBelow:#{rerollBelow}"  unless !$debug
    puts "dropBelow:#{dropBelow}"  unless !$debug
    puts "modPerDie:#{modPerDie}"  unless !$debug
    
    results = Array.new(rolled) #setup results array
    results2 = Array.new(rolled) if luck
    rolled.times do |i|
        aResult = RollOneDie(explodesOn, rerollBelow)      
        aResult[:value] = 0 unless aResult[:value] >= dropBelow #wipe out the roll if it's below the drop point
        aResult[:value] = aResult[:value] + modPerDie unless aResult[:value] == 0 #add per die modifier if roll is alive
        explosionCount += aResult[:explosions] unless aResult[:value] == 0 #counting for void return
        results[i] = aResult[:value] #all we need from here on out is the result of that roll.
        if luck then
          aResult2 = RollOneDie(explodesOn, rerollBelow)      
          aResult2[:value] = 0 unless aResult2[:value] >= dropBelow #wipe out the roll if it's below the drop point
          aResult2[:value] = aResult2[:value] + modPerDie unless aResult2[:value] == 0 #add per die modifier if roll is alive
          explosionCount2 += aResult2[:explosions] unless aResult2[:value] == 0 #counting for void return
          results2[i] = aResult2[:value] #all we need from here on out is the result of that roll.
        end
      end
      temp1 = 0    
      results.sort! {|x,y| y<=>x}
      results.first(kept).each { |x| temp1 += x}    
      temp2 = 0 if luck
      results2.sort! {|x,y| y<=>x} if luck
      results2.first(kept).each { |x| temp2 += x} if luck
      
      aValue = luck ? (temp1 > temp2 ? temp1 : temp2) : temp1
      explosionCount = luck ? (temp1 > temp2 ? explosionCount : explosionCount2) : explosionCount
      
      result[:voidBack] = true unless explosionCount < 3            
      result[:value] = aValue   
    return result
  end

  def RollOneDie(explodesOn, rerollBelow)
      aRoll = GetDiceRoll(explodesOn)    
      puts "Roll1A: #{aRoll}" unless !$debug
      aRoll = GetDiceRoll(explodesOn) if aRoll[:value] < rerollBelow #Redo!
      puts "Roll1B: #{aRoll}" unless !$debug
       #sort out luck. TODO decide if it's faster to do an if check and don't roll one/two extra times for luck if it's not needed.
      puts "Final: #{aRoll}" unless !$debug    
      return aRoll        
  end

  def GetDiceRoll( explodesOn )
    total = 0
    count = 0 #explosion counter
    while(value = 1+rand(10))
      total += value
      break unless value >= explodesOn
      count += 1 
    end  
  return {:value=>total, :explosions=>count}
  end
end