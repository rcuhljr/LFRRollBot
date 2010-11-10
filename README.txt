L5R Roller design and grammar for Rolls.


Roll Bot Grammar (Case Insensitive, broken down to regexes) -
<Request>           ::= <Alias> | <Roll Request> | <Command>
<Roll Request>      ::= Roll <Roll Base> <Roll Label>
<Roll Base>         ::= <Roll Base> <Operator> <Roll Base> | <Roll Base>  <Roll Options> |
                        <Number><Inner Roll Type><Number> | <Outer Roll Type><Number> | <Number>
<Roll Options>      ::= {<Option>} | ""
<Option>            ::= <Option>, <Option> | <Setting>:<Value>
<Inner Roll Type>   ::= d | k | ke | ku
<Outer Roll Type>   ::= d
<Alias>             ::= !<Identifier>
<Roll Label>        ::= <String> | ""
<Identifer>         ::= [a-Z0-9()-_]+
<String>            ::= [a-Z0-9 ]+
<Number>            ::= [0-9]+
<Operator>          ::= + | -
<Setting>           ::= Explode | ExplodeOn | ExplodeOnce | Emphasis
<Value>             ::= <String> | <Number> | <Boolean>
<Boolean>           ::= true | false