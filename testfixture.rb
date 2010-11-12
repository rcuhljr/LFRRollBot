#require 'C:\Code\GitRepos\LFRRollBot\Dicebox'
#require 'C:\Code\GitRepos\LFRRollBot\GrammarEngine'
require 'test/unit'
require 'Dicebox'
require 'GrammarEngine'

class TestFixture < Test::Unit::TestCase

  def test_grammarbasic
    result = GrammarEngine.new("Roll 5k3 #Katana").execute
    assert(false, result)  
  end
  
  def test_grammarbasic2
    result = GrammarEngine.new("Roll 5k3+6k2+5 #Katana").execute
    assert(false, result)  
  end
  
  def test_grammarbasic3
    result = GrammarEngine.new("Roll 5k3 + 6k2 + 5 #Katana").execute
    assert(false, result)  
  end
  
  def test_grammarbasic4
    result = GrammarEngine.new("Roll 5k3+ 6k2+ 5 #Katana").execute
    assert(false, result)  
  end
  
  def test_grammarbasic5
    result = GrammarEngine.new("Roll 5k3 +6k2 +5 #Katana").execute
    assert(false, result)  
  end
  
  def test_grammarbasic6
    result = GrammarEngine.new("Roll 5k3 +6k2+ 5 #Katana").execute
    assert(false, result)  
  end

  def test_roll1d20
    100.times do     
      testValue = Dicebox.new.RollKeep(1, 1, {:explodeOn => 21, :sidesPerDie => 20})
      assert((testValue[:total] > 0), "value of #{testValue[:total]}")
      assert((testValue[:total] < 21), "value of #{testValue[:total]}")
    end
  end
  def test_roll1d2
    100.times do
      testValue = Dicebox.new.RollKeep(1, 1, {:explodeOn => 3, :sidesPerDie => 2})
      assert((testValue[:total] > 0), "value of #{testValue[:total]}")
      assert((testValue[:total] < 3), "value of #{testValue[:total]}")
    end
  end
  
  def test_roll5k3
    1.times do
      testValue = Dicebox.new.RollKeep(5, 3, {:explodeOn => 10, :sidesPerDie => 10})
      assert(false, "value of #{testValue[:total]}\nValues of:#{testValue[:values].to_s}")      
    end
  end
end