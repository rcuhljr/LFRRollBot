class Dicebox 
  $debug = false  
  #Accepts the number of Rolled dice, kept dice, and an optional array of modifiers. Valid modifers are
  #:explodeOn - int - Skilled rolls are 10, great potential would be 9, enter 11 for untrained.  
  #:rerollBelow - int - Reroll any dice below the threshold. 5 would cause a 4 to reroll but not a 5. functions ONCE
  #:dropBelow - int - Drop any dice rolled below the threshold. 5 would cause a 4 to drop bot not a 5.
  #:sidesPerDie - int - add or subtract an integer value on all kept dice.
  #Returns a hash of :value (int) :voidBack (bool)
  def RollKeep(rolled, kept, modifiers = {})    
    result = {:total => 0, :values => []}    
    explosionCount = 0    
    if(rolled > 100 or modifiers[:sidesPerDie] > 10000)
      result[:values] = "A_LOT_OF_DICE"
      return result
    end
    return result unless (kept > 0 and rolled > 0) # idiot check
    
    kept = rolled unless rolled >= kept #idiot check 2
    
    #load in default values
    explodesOn = modifiers[:explodeOn].nil? ? 10 : modifiers[:explodeOn]    
    rerollBelow = modifiers[:rerollBelow].nil? ? 0 : modifiers[:rerollBelow]
    dropBelow = modifiers[:dropBelow].nil? ? 0  : modifiers[:dropBelow]
    sidesPerDie = modifiers[:sidesPerDie].nil? ? 10 : modifiers[:sidesPerDie]
    
    explodesOn = 2 unless (explodesOn >= 2)
    
    puts "explodesOn:#{explodesOn}"  unless !$debug    
    puts "rerollBelow:#{rerollBelow}"  unless !$debug
    puts "dropBelow:#{dropBelow}"  unless !$debug
    puts "sidesPerDie:#{sidesPerDie}"  unless !$debug
    
    results = Array.new(rolled) #setup results array    
    rolled.times do |i|
        aResult = RollOneDie(sidesPerDie, explodesOn, rerollBelow )              
        results[i] = aResult #all we need from here on out is the result of that roll.        
      end
      aValue = 0    
      results.sort! {|x,y| y<=>x}
      results.first(kept).each { |x| aValue += x}          
      
      result[:values] = results
      result[:total] = aValue   
    return result
  end

  def RollOneDie(sidesPerDie, explodesOn, rerollBelow)
      aRoll = GetDiceRoll(sidesPerDie,explodesOn )    
      puts "Roll1A: #{aRoll}" unless !$debug
      aRoll = GetDiceRoll(sidesPerDie, explodesOn) if aRoll < rerollBelow #Redo!
      puts "Roll1B: #{aRoll}" unless !$debug       
      puts "Final: #{aRoll}" unless !$debug    
      return aRoll        
  end

  def GetDiceRoll(sidesPerDie, explodesOn )
    total = 0    
    while(value = 1+rand(sidesPerDie))
      total += value
      break unless value >= explodesOn      
    end  
  return total
  end
end