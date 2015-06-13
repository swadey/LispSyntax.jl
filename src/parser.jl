using ParserCombinator, Compat
import Base.==

expr         = Delayed()
floaty_dot   = p"[-+]?[0-9]*\.[0-9]+([eE][-+]?[0-9]+)?[Ff]" > (x -> float32(x[1:end-1]))
floaty_nodot = p"[-+]?[0-9]*[0-9]+([eE][-+]?[0-9]+)?[Ff]" > (x -> float32(x[1:end-1]))
floaty       = floaty_dot | floaty_nodot
white_space  = p"([\s\n\r]*(?<!\\);[^\n\r$]+[\n\r\s$]*|[\s\n\r]+)"
opt_ws       = white_space | s""

doubley      = p"[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?[dD]" > (x -> float64(x[1:end-1]))

inty         = p"[-+]?\d+" > (x -> int(x))

uchary       = p"\\(u[\da-fA-F]{4})" > (x -> begin y = unescape_string(x); y[chr2ind(y, 1)] end)
achary       = p"\\[0-7]{3}" > (x -> unescape_string(x)[1])
chary        = p"\\." > (x -> x[2])

stringy      = p"(?<!\\)\".*?(?<!\\)\"" > (x -> x[2:end-1]) #_0[2:end-1] } #r"(?<!\\)\".*?(?<!\\)"
booly        = p"(true|false)" > (x -> x == "true" ? true : false)
symboly      = p"[^\d(){}#'`,@~;~\[\]^\s][^\s()#'`,@~;^{}~\[\]]*" > symbol
macrosymy    = p"@[^\d(){}#'`,@~;~\[\]^\s][^\s()#'`,@~;^{}~\[\]]*" > symbol

sexpr        = S"(" + ~opt_ws + Repeat(expr + ~opt_ws) + S")" |> (x -> s_expr(x))
hashy        = S"#{" + Repeat(expr + ~opt_ws) + S"}" |> (x -> Set(x...))
curly        = S"{" + Repeat(expr + ~opt_ws) + S"}" |> (x -> [ x[i] => x[i+1] for i = 1:2:length(x) ])
bracket      = S"[" + Repeat(expr + ~opt_ws) + S"]" |> (x -> s_expr(x)) # TODO: not quite right
quot         = S"'" + expr > (x -> sx(:quote, x))
quasi        = S"`" + expr > (x -> sx(:quasi, x))
tildeseq     = S"~@" + expr > (x -> sx(:splice_seq, x))
tilde        = S"~" + expr > (x -> sx(:splice, x))

expr.matcher = Nullable{ParserCombinator.Matcher}(doubley | floaty | inty | uchary | achary | chary | stringy | booly | symboly | macrosymy | sexpr |
                                                  hashy | curly | bracket | quot | quasi | tildeseq | tilde)
#expr.matcher = doubley | floaty | inty | uchary | achary | chary | stringy | booly | symboly | sexpr

function read(str)
  x = parse_one(str, expr)
  #@debug " ***             parser returned = $x"
  x[1]
end

