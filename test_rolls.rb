load 'Dicebox.rb'
load 'GrammarEngine.rb'

[
    '3d20',
    '3d6',
    '3d6n',
    '3d6n-1',
    '3d6n+1',
    '3d6n #feet',
    '3d6k',
    '3d6k-1',
    '3d6k #2',
    '3d6k #feet',
    '3d6k #feet2',
    '3d6k #2feet',
    '3d6 NND',
    "3d6 NND #head",
    '3d6 NND #3',
    '3d6k NND',
    '3d6k NND #vitals',
    '3d6k NND #feet1',
].each do |roll|
    roll += " #show"
    result = GrammarEngine.new(roll).execute
    puts "input->'#{roll}' output->'#{result[:message]}'"
end
