module cl
using PEGParser
export init_read_table, read, repl

# package code goes here
const prompt = "cl>"

@grammar lisp_grammar begin
  float_with_dot_matcher = r"[-+]?[0-9]*\.[0-9]+([eE][-+]?[0-9]+)?[Ff]"
  float_no_dot_matcher   = r"[-+]?[0-9]*[0-9]+([eE][-+]?[0-9]+)?[Ff]"
  white_space            = r"([\s\n\r]*(?<!\\);[^\n\r$]+[\n\r\s$]*|[\s\n\r]+)"

  double  = r"[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?[dD]"
  float   = float_with_dot_matcher | float_no_dot_matcher
  int     = r"[-+]?\d+"
  uchar   = r"\\(u[\da-fA-F]{4})"
  achar   = r"\\[0-7]{3}"
  char    = r"\\."
  string  = r"\"(?:[^\"]|\.)*\"" #r"(?<!\\)\".*?(?<!\\)"
  bools   = r"(true|false)"i
  hash    = "#{" + list(expr, white_space) + "}"
  curly   = "{" + list(expr, white_space) + "}"
  bracket = "[" + list(expr, white_space) + "]"
  quot    = "'" + expr
  quasi   = "`" + expr
  tilde   = ("~@" + expr) | ("~" + expr)
  symbol  = r"[^\d(){}#'`,@~;~\[\]^\s][^\s()#'`,@~;^{}~\[\]]*"
  sexpr0  = "(" + ?(white_space) + ")"
  sexpr1  = "(" + list(expr, white_space) + ")"
  sexpr   = sexpr1 | sexpr0
  expr    = (double | float | int | uchar | achar | char | string | bools | symbol | sexpr | 
             hash | quot | curly | bracket | quasi | tilde)
  start   = expr
end

const lisp_actions = [
                      :double  => (node, values) -> float64(node.value[1:end-1]),
                      :float   => (node, values) -> float32(node.value[1:end-1]),
                      :int     => (node, values) -> int(node.value),
                      :uchar   => (node, values) -> begin x = unescape_string(node.value); x[chr2ind(x, 1)] end,
                      :achar   => (node, values) -> unescape_string(node.value)[1],
                      :char    => (node, values) -> node.value[2],
                      :string  => (node, values) -> node.value[2:end-1],
                      :bools   => (node, values) -> node.value == "true" ? true : false,
                      :symbol  => (node, values) -> symbol(node.value),
                      :sexpr0  => (node, values) -> {},
                      :sexpr1  => (node, values) -> typeof(values[2]) == Array{Any, 1} ? values[2] : { values[2] },
                      :sexpr   => (node, values) -> values,
                      :expr    => (node, values) -> values,
                      :hash    => (node, values) -> Set(values[2]),
                      :curly   => (node, values) -> [ values[2][i] => values[2][i+1] for i = 1:2:length(values[2]) ],
                      :bracket => (node, values) -> values[2],
                      :quot    => (node, values) -> { :quote values[2] },
                      :quasi   => (node, values) -> { :quasi values[2] },
                      :tilde   => (node, values) -> ismatch(r"^~@.*$", node.value) ? { :splice_seq, values[2] } : { :splice, values[2] },
                      :default => (node, values) -> values
                      ]

function init_read_table()
  for k in keys(lisp_actions)
    kk = string(k)
    x = :(grammar_transform(node, values, ::MatchRule{symbol($kk)}) = lisp_actions[symbol($kk)](node, values))
    eval(x)
  end
  #println(methods(grammar_transform))
end

function read(input)
  ast, pos, err = parse(lisp_grammar, input)
  if ast == nothing
    println("pos: " * string(pos))
    println("err: " * string(err))
    return nothing
  else
    clean = transform(grammar_transform, ast, ignore = [:white_space, :float_with_dot_matcher, :float_no_dot_matcher])
    #println("ast: " * string(clean))
    return clean
  end
end

function repl(is, os)
  # init
  init_read_table()
  
  # repl loop
  while true
    print(os, prompt * " ")
    input = read(is)
    res   = eval(input)
    println(res)
  end
end

end # module
