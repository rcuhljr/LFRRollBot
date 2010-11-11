L5R Roller design and grammar for Rolls.


Roll Bot Grammar (Case Insensitive, broken down to regexes) -
<Request>           ::= <Alias> | <Roll Request> | @<Command> | ?<Help>
<Roll Request>      ::= Roll <Roll Base> <Roll Label>
<Roll Base>         ::= <Roll Base><Operator><Roll Base> | <Roll Base><Roll Options> |
                        <Number><Inner Roll Type><Number> | <Outer Roll Type><Number> | <Number>
<Roll Options>      ::= {<Option>} | "" | {<Alias>}
<Option>            ::= <Option>, <Option> | <Setting>:<Value>
<Inner Roll Type>   ::= d | k | ke | ku
<Outer Roll Type>   ::= d
<Alias>             ::= !<Identifier>
<Roll Label>        ::= #<String> | ""
<Identifer>         ::= [a-Z0-9()-_]+
<Value>             ::= <String> | <Number> | <Boolean>
<String>            ::= [a-Z0-9 ]+
<Number>            ::= [0-9]+
<Operator>          ::= + | -
<Setting>           ::= Explode | ExplodeOn | ExplodeOnce | Emphasis
<Boolean>           ::= true | false
<Command>           ::= Record <Identifier> <Roll Request> | Mode:<Mode> | List | Remove <Identifier> | 
                        Record <Identifier> <Roll Options>
<Help>              ::= Help | Roll | Dice
<Mode>              ::= L5R | D&D

Notes. ke = keep emphasis, ku keep unskilled (no explosions) 
Slight grammar mistake in the fact that you can attach a roll options to a number, but I don't feel bad about that.