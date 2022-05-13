load 'Dicebox.rb'
load 'GrammarEngine.rb'

[
    '3d20',
    '3d6',
    '3dn6',
    '3dn6 #feet',
    '3dk6',
    '3dk6 #2',
    '3dk6 #feet',
    '3dk6 #feet2',
    '3dk6 #2feet',
    '3dx6',
    "3dx6 #head",
    '3dx6 #3',
    '3dxk6',
    '3dxk6 #vitals',
    '3dxk6 #feet1',
].each do |roll|
    result = GrammarEngine.new(roll).execute
    puts "input->'#{roll}' output->'#{result[:message]}'"
end
