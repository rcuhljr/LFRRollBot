L5R Roller design and grammar for Rolls.


Roll Bot Grammar (Case Insensitive, broken down to regexes) -
<Request>           ::= <Alias> | <Alias><OperatorPair> | <Roll Request> | @<Command> | ?<Help>
<Roll Request>      ::= <Trigger> <Roll Base> <Roll Label>
<Roll Base>         ::= <Roll Base><Operator><Roll Base> | < | <Roll Base><Roll Options> |
                        <Number><Inner Roll Type><Number> | <Outer Roll Type><Number> | <Number>  
<OperatorPair>      ::= <Operator><number> | <OperatorPair><OperatorPair>
<Roll Options>      ::= {<Option>} | "" | {<Alias>}
<Option>            ::= <Option>, <Option> | <Setting>:<Value>
<Inner Roll Type>   ::= d | k<KeepModifier>
<KeepModifier>      ::= e | u | m | "" | <KeepModifier><KeepModifier>
<Outer Roll Type>   ::= d
<Alias>             ::= !<Identifier>
<Roll Label>        ::= #<String> | ""
<Identifer>         ::= [a-Z0-9()-_]+
<Value>             ::= <String> | <Number> | <Boolean>
<String>            ::= [a-Z0-9 ]+
<Number>            ::= [0-9]+
<Operator>          ::= + | -
<Setting>           ::= ExplodeOn
<Boolean>           ::= true | false
<Command>           ::= Record <Identifier> <Roll Request> | Mode:<Mode> | List | Remove <Identifier> | 
                        Record <Identifier> <Roll Options>
<Help>              ::= Help | Roll | Dice
<Mode>              ::= T{<TriggerString>} | T{List}
<Trigger>           ::= r | roll | ""
<TriggerString>     ::= <Trigger> | <TriggerString>:<TriggerString>

Notes. ke = keep emphasis, ku keep unskilled (no explosions) km = explode on 9's no emphasis. "" is only valid as a trigger if Dicesuke isn't in the same channel to prevent spam/confusion.
Slight grammar mistake in the fact that you can attach a roll options to a number, but I don't feel bad about that.

Operator notes
You can speak through the bot, in the shell running the bot just type your target, message, then hit enter. "#test hello all" will send 'hello all' to channel #test. 
typing "join #test" will have the bot join channel #test. typing ": hello all" will send 'hello all' to the first channel in the bots channel list.
'toki hey there' will send 'hey there' to there user toki as a private message. "quit" kills the bot.