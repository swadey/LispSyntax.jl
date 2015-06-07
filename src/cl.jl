module cl
using PEGParser
export init_read_table, read, codegen, @lisp, repl, @lisp_str

# package code goes here
const prompt = "cl>"

@grammar lisp_grammar begin
  float_with_dot_matcher = r"[-+]?[0-9]*\.[0-9]+([eE][-+]?[0-9]+)?[Ff]" { float32(_0[1:end-1]) }
  float_no_dot_matcher   = r"[-+]?[0-9]*[0-9]+([eE][-+]?[0-9]+)?[Ff]" { float32(_0[1:end-1]) }
  white_space            = -r"([\s\n\r]*(?<!\\);[^\n\r$]+[\n\r\s$]*|[\s\n\r]+)"

  doubley  = r"[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?[dD]" { float64(_0[1:end-1]) }
  floaty   = (float_with_dot_matcher | float_no_dot_matcher) { _1 }
  inty     = r"[-+]?\d+" { int(_0) }
  uchary   = r"\\(u[\da-fA-F]{4})" { begin x = unescape_string(_0); x[chr2ind(x, 1)] end }
  achary   = r"\\[0-7]{3}" { unescape_string(_0)[1] }
  chary    = r"\\." { _0[2] }
  stringy  = r"\".*?\"" { _0[2:end-1] } #_0[2:end-1] } #r"(?<!\\)\".*?(?<!\\)"
  booly    = r"(true|false)"i { _0 == "true" ? true : false }
  symboly  = r"[^\d(){}#'`,@~;~\[\]^\s][^\s()#'`,@~;^{}~\[\]]*" { symbol(_0) }
  sexpr0   = ("(" + ?(white_space) + ")") { {{}} }
  sexpr1   = ("(" + list(expr, white_space) + ")") { { vcat(_2.children...) } }
  sexpr    = (sexpr1 | sexpr0) { children }
  hashy    = ("#{" + list(expr, white_space) + "}") { Set(vcat(_2.children...)...) }
  curly    = ("{" + list(expr, white_space) + "}") { [ _2.children[i][1] => _2.children[i+1][1] for i = 1:2:length(_2.children) ] }
  bracket1 = ("[" + list(expr, white_space) + "]") { { vcat(_2.children...) } }
  bracket0 = ("[" + ?(white_space) + "]") { {{}} }
  bracket  = (bracket0 | bracket1) { children }
  quot     = ("'" + expr) { {[ :quote _2[1] ]} }
  quasi    = ("`" + expr) { {[ :quasi _2 ]} }
  tildeseq = ("~@" + expr) { {[ :splice_seq, { _2[1] } ]} }
  tilde    = ("~" + expr) { {{ :splice, _2[1] }} }
  # expr    = (double | float | int | uchar | achar | char | string | bools | symbol | sexpr | 
  #            hash | quot | curly | bracket | quasi | tilde)
  # start   = expr
  expr    = (doubley | floaty | inty | uchary | achary | chary | stringy | booly | symboly | sexpr | hashy | curly | bracket | quot | quasi | tildeseq | tilde) { children }
  start   = expr { _1 }
end

# const lisp_actions = [
#                       :double  => (node, values) -> float64(node.value[1:end-1]),
#                       :float   => (node, values) -> begin println(node.children); float32(node.value[1:end-1]) end,
#                       :int     => (node, values) -> int(node.value),
#                       :uchar   => (node, values) -> begin x = unescape_string(node.value); x[chr2ind(x, 1)] end,
#                       :achar   => (node, values) -> unescape_string(node.value)[1],
#                       :char    => (node, values) -> node.value[2],
#                       :string  => (node, values) -> node.value[2:end-1],
#                       :bools   => (node, values) -> node.value == "true" ? true : false,
#                       :symbol  => (node, values) -> symbol(node.value),
#                       :sexpr0  => (node, values) -> {},
#                       :sexpr1  => (node, values) -> typeof(values[2]) == Array{Any, 1} ? values[2] : { values[2] },
#                       :sexpr   => (node, values) -> values,
#                       :expr    => (node, values) -> values,
#                       :hash    => (node, values) -> Set(values[2]),
#                       :curly   => (node, values) -> [ values[2][i] => values[2][i+1] for i = 1:2:length(values[2]) ],
#                       :bracket => (node, values) -> values[2],
#                       :quot    => (node, values) -> { :quote values[2] },
#                       :quasi   => (node, values) -> { :quasi values[2] },
#                       :tilde   => (node, values) -> ismatch(r"^~@.*$", node.value) ? { :splice_seq, values[2] } : { :splice, values[2] },
#                       :default => (node, values) -> values
#                       ]

function init_read_table()
  # for k in keys(lisp_actions)
  #   kk = string(k)
  #   x = :(grammar_transform(node, values, ::MatchRule{symbol($kk)}) = lisp_actions[symbol($kk)](node, values))
  #   eval(x)
  # end
  #println(methods(grammar_transform))
end

function read(input)
  ast, pos, err = parse(lisp_grammar, input)
  if ast == nothing
    println("pos: " * string(pos))
    println("err: " * string(err))
    return nothing
  else
    #clean = transform(grammar_transform, ast)#, ignore = [:white_space, :float_with_dot_matcher, :float_no_dot_matcher])
    #return clean
    return ast
  end
end

function construct_sexpr(items...) # convert the input tuple to an array
  ret = Array(Any, length(items))
  for i = 1:length(items)
    ret[i] = items[i]
  end
  ret
end

function quasiquote(s)
  if isa(s, Array) && length(s) == 2 && s[1] == :splice
    codegen(s[2])
  elseif isa(s, Array) && length(s) == 2 && s[1] == :splice_seq
    Expr(:..., codegen(s[2]))
  elseif isa(s, Array)
    Expr(:call, :construct_sexpr, map(quasiquote, s)...)
  elseif isa(s, Symbol)
    Expr(:quote, s)
  else
    s
  end
end

function codegen(s; escape_exceptions = Set{Symbol}())
  if isa(s, Symbol)
    if s in escape_exceptions
      s
    else
      esc(s)
    end
  elseif !isa(s, Array) # constant
    s
  elseif length(s) == 0 # empty array
    s
  elseif s[1] == :if
    if length(s) == 3
      :($(codegen(s[2], escape_exceptions = escape_exceptions)) && $(codegen(s[3], escape_exceptions = escape_exceptions)))
    elseif length(s) == 4
      :($(codegen(s[2], escape_exceptions = escape_exceptions)) ? $(codegen(s[3], escape_exceptions = escape_exceptions)) : $(codegen(s[4],  escape_exceptions = escape_exceptions)))
    else
      throw("illegal if statement $s")
    end
  elseif s[1] == :def
    assert(length(s) == 3)
    :($(s[2]) = $(codegen(s[3], escape_exceptions = escape_exceptions)))
  elseif s[1] == :quote
    s[2]
  elseif s[1] == :splice
    throw("missplaced ~ (splice)")
  elseif s[1] == :splice_seq
    throw("missplaced ~@ (splice_seq)")
  elseif s[1] == :quasi
    quasiquote(s[2])
  elseif s[1] == :lambda
    assert(length(s) == 3)
    Expr(:function, Expr(:tuple, s[2]...), codegen(s[3],  escape_exceptions = escape_exceptions))
  elseif s[1] == :defn
    # Note: julia's lambdas are not optimized yet, so we don't define defn as a macro.
    #       this should be revisited later.
    println(s)
    a = Expr(:function, Expr(:call, esc(s[2]), s[3]...), codegen(s[4], escape_exceptions = escape_exceptions ∪ Set(s[3])))
    println(a)
    a
  elseif s[1] == :macro
  elseif s[1] == :defmethod
  else
    coded_s = map(x -> codegen(x, escape_exceptions = escape_exceptions), s)
    Expr(:call, coded_s[1], coded_s[2:end]...)
  end
end

macro lisp(str)
  assert(isa(str, String))
  s = read(str)
  e = codegen(s)
  return e
end

macro lisp_str(str)
  assert(isa(str, String))
  s = read(str)
  e = codegen(s)
  return e
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
