using PEGParser

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
  stringy  = r"(?<!\\)\".*?(?<!\\)\"" { _0[2:end-1] } #_0[2:end-1] }
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

