module Lisp
include("parser.jl")
export sx, desx, codegen, @lisp, repl, @lisp_str
# TODO: lexpr needs to be fixed prior to exposure

# Konstants
const prompt = "cl>"

# Internal types
type s_expr
  vector
end

sx(x...) = s_expr([x...])
==(a :: s_expr, b :: s_expr) = a.vector == b.vector


function desx(s)
  if typeof(s) == s_expr
    return map(desx, s.vector)
  else
    return s
  end
end

function lispify(s)
  if isa(s, s_expr)
    return "(" * join(map(lispify, s.vector), " ") * ")"
  else
    return "$s"
  end
end

function construct_sexpr(items...) # convert the input tuple to an array
  ret = Array(Any, length(items))
  for i = 1:length(items)
    ret[i] = items[i]
  end
  ret
end

function quasiquote(s, escape_exceptions)
  if isa(s, Array) && length(s) == 2 && s[1] == :splice
    codegen(s[2], escape_exceptions = escape_exceptions)
  elseif isa(s, Array) && length(s) == 2 && s[1] == :splice_seq
    Expr(:..., codegen(s[2], escape_exceptions = escape_exceptions))
  elseif isa(s, Array)
    Expr(:call, :construct_sexpr, map(s -> quasiquote(s, escape_exceptions), s)...)
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
    :($(esc(s[2])) = $(codegen(s[3], escape_exceptions = escape_exceptions)))
  elseif s[1] == :let
    syms     = Set([ s[2][i] for i = 1:2:length(s[2]) ])
    bindings = [ :($(s[2][i]) = $(codegen(s[2][i+1], escape_exceptions = escape_exceptions ∪ syms))) for i = 1:2:length(s[2]) ]
    coded_s  = map(x -> codegen(x, escape_exceptions = escape_exceptions ∪ syms), s[3:end])
    Expr(:let, Expr(:block, coded_s...), bindings...)
  elseif s[1] == :while
    coded_s = map(x -> codegen(x, escape_exceptions = escape_exceptions), s[2:end])
    Expr(:while, coded_s[1], Expr(:block, coded_s[2:end]...))
  elseif s[1] == :for
    syms     = Set([ s[2][i] for i = 1:2:length(s[2]) ])
    bindings = [ :($(s[2][i]) = $(codegen(s[2][i+1], escape_exceptions = escape_exceptions ∪ syms))) for i = 1:2:length(s[2]) ]
    coded_s  = map(x -> codegen(x, escape_exceptions = escape_exceptions ∪ syms), s[3:end])
    Expr(:for, Expr(:block, bindings...), Expr(:block, coded_s...))
  elseif s[1] == :do
    Expr(:block, map(x -> codegen(x, escape_exceptions = escape_exceptions), s[2:end])...)
  elseif s[1] == :global
    Expr(:global, map(x -> esc(x), s[2:end])...)
  elseif s[1] == :quote
    s[2]
  elseif s[1] == :import
     Expr(:using, map(x -> esc(x), s[2:end])...)
  elseif s[1] == :splice
    throw("missplaced ~ (splice)")
  elseif s[1] == :splice_seq
    throw("missplaced ~@ (splice_seq)")
  elseif s[1] == :quasi
    quasiquote(s[2], escape_exceptions)
  elseif s[1] == :lambda || s[1] == :fn
    assert(length(s) >= 3)
    coded_s = map(x -> codegen(x, escape_exceptions = escape_exceptions ∪ Set(s[2])), s[3:end])
    Expr(:function, Expr(:tuple, s[2]...), Expr(:block, coded_s...))
  elseif s[1] == :defn
    # Note: julia's lambdas are not optimized yet, so we don't define defn as a macro.
    #       this should be revisited later.
    coded_s = map(x -> codegen(x, escape_exceptions = escape_exceptions ∪ Set(s[3])), s[4:end])
    Expr(:function, Expr(:call, esc(s[2]), s[3]...), Expr(:block, coded_s...))
  elseif s[1] == :defmacro
     Expr(:macro, Expr(:call, esc(s[2]), s[3]...),
          begin
            coded_s = map(x -> codegen(x, escape_exceptions = escape_exceptions ∪ Set(s[3])), s[4:end])
            sexpr = Expr(:block, coded_s...) #codegen(s[4], escape_exceptions = escape_exceptions ∪ Set(s[3]))
            :(codegen($sexpr, escape_exceptions = $escape_exceptions ∪ Set($(s[3]))))
          end)
  elseif s[1] == :defmethod
    # TODO
  else
    coded_s = map(x -> codegen(x, escape_exceptions = escape_exceptions), s)
    if (typeof(coded_s[1]) == Symbol && ismatch(r"^@.*$", string(coded_s[1]))) ||
       (typeof(coded_s[1]) == Expr && ismatch(r"^@.*$", string(coded_s[1].args[1])))
      Expr(:macrocall, coded_s[1], coded_s[2:end]...)
    else
      Expr(:call, coded_s[1], coded_s[2:end]...)
    end
  end
end

macro lisp(str)
  assert(isa(str, AbstractString))
  s = desx(Lisp.read(str))
  e = codegen(s)
  return e
end

macro lisp_str(str)
  assert(isa(str, AbstractString))
  s = desx(Lisp.read(str))
  e = codegen(s)
  return e
end

function lexpr(str)
  assert(isa(str, AbstractString))
  s = desx(Lisp.read(str))
  e = codegen(s)
  return e
end

function repl(is, os)
  
  # repl loop
  while true
    print(os, prompt * " ")
    input = lispify(Lisp.read(is))
    println(input)
    res = eval(:(@lisp $input))
    println(res)
  end
end

end # module
