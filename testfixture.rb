require 'C:\Code\GitRepos\LFRRollBot\Dicebox'
require 'test/unit'

class TestFixture < Test::Unit::TestCase

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

end