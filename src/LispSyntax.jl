module LispSyntax

include("parser.jl")
export sx, desx, codegen, @lisp_str, assign_reader_dispatch

# Internal types
mutable struct s_expr
  vector
end

sx(x...) = s_expr([x...])
==(a :: s_expr, b :: s_expr) = a.vector == b.vector


function desx(s)
  if typeof(s) == s_expr
    return map(desx, s.vector)
  elseif isa(s, Dict)
    return Dict(desx(x[1])=>desx(x[2]) for x in s)
  elseif isa(s, Set)
    return Set(desx(v) for v in s)
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

# convert the input tuple to an array
construct_sexpr(items...) = Any[items...]

function assign_reader_dispatch(sym, fn)
  reader_table[sym] = fn
end

function quasiquote(s)
  if isa(s, Array) && length(s) == 2 && s[1] == :splice
    codegen(s[2])
  elseif isa(s, Array) && length(s) == 2 && s[1] == :splice_seq
    Expr(:..., codegen(s[2]))
  elseif isa(s, Array)
    Expr(:call, construct_sexpr, map(quasiquote, s)...)
  elseif isa(s, Symbol)
    Expr(:quote, s)
  else
    s
  end
end

function quote_it(s)
  if isa(s, Array)
    Expr(:call, construct_sexpr, map(s -> quote_it(s), s)...)
  elseif isa(s, Symbol)
   QuoteNode(s)
  else
    s
  end
end

function codegen(s)
  if isa(s, Symbol)
      s
  elseif isa(s, Dict)
    coded_s = [:($(codegen(x[1])) => $(codegen(x[2]))) for x in s]
    Expr(:call, Dict, coded_s...)
  elseif isa(s, Set)
    coded_s = [codegen(x) for x in s]
    Expr(:call, Set, Expr(:vect, coded_s...))
  elseif s isa Expr && s.head == :escape
    # Special case to allow use of `esc` in lisp syntax macros
    esc(codegen(s.args[1]))
  elseif !isa(s, Array) # constant
    s
  elseif length(s) == 0 # empty array
    s
  elseif s[1] == :if
    if length(s) == 3
      :($(codegen(s[2])) && $(codegen(s[3])))
    elseif length(s) == 4
      :($(codegen(s[2])) ? $(codegen(s[3])) : $(codegen(s[4])))
    else
      throw("illegal if statement $s")
    end
  elseif s[1] == :def
    length(s) == 3 || error("Malformed def: Length of list must be == 3")
    :(global $(s[2]) = $(codegen(s[3])))
  elseif s[1] == :let
    bindings = [ :($(s[2][i]) = $(codegen(s[2][i+1]))) for i = 1:2:length(s[2]) ]
    coded_s  = map(codegen, s[3:end])
    Expr(:let, Expr(:block, bindings...), Expr(:block, coded_s...))
  elseif s[1] == :while
    coded_s = map(codegen, s[2:end])
    Expr(:while, coded_s[1], Expr(:block, coded_s[2:end]...))
  elseif s[1] == :for
    bindings = [ :($(s[2][i]) = $(codegen(s[2][i+1]))) for i = 1:2:length(s[2]) ]
    coded_s  = map(codegen, s[3:end])
    Expr(:for, Expr(:block, bindings...), Expr(:block, coded_s...))
  elseif s[1] == :do
    Expr(:block, map(codegen, s[2:end])...)
  elseif s[1] == :global
    Expr(:global, s[2:end]...)
  elseif s[1] == :quote
    quote_it(s[2])
  elseif s[1] == :import
    Expr(:using, [Expr(:., x) for x in s[2:end]]...)
  elseif s[1] == :splice
    throw("missplaced ~ (splice)")
  elseif s[1] == :splice_seq
    throw("missplaced ~@ (splice_seq)")
  elseif s[1] == :quasi
    quasiquote(s[2])
  elseif s[1] == :lambda || s[1] == :fn
    length(s) >= 3 || error("Malformed lambda/fn: list length must be >= 3")
    coded_s = map(codegen, s[3:end])
    Expr(:function, Expr(:tuple, s[2]...), Expr(:block, coded_s...))
  elseif s[1] == :defn
    # NB: This lowering of `defn` makes a julia function which may be a closure
    # if used in local scope. This is a semantic mismatch with clojure where
    # `defn` binds a lambda to a mutable global name. We could do it the
    # closure way, but it would generate much worse code.
    coded_s = map(codegen, s[4:end])
    Expr(:function, Expr(:call, s[2], s[3]...), Expr(:block, coded_s...))
  elseif s[1] == :defmacro
    # NB: Clojure macros are unhygenic by default, the opposite of Julia.
    # Choose Julia semantics and allow the use of `esc` intermixed with lists
    # (see `Expr(:escape)` handling above).
    Expr(:macro, Expr(:call, s[2], s[3]...),
         begin
             sexpr = Expr(:block, map(codegen, s[4:end])...)
             Expr(:block, Expr(:call, codegen, sexpr))
         end)
  elseif s[1] == :defmethod
    # TODO
  else
    coded_s = map(codegen, s)
    if (typeof(coded_s[1]) == Symbol && occursin(r"^@.*$", string(coded_s[1]))) ||
       (typeof(coded_s[1]) == Expr && occursin(r"^@.*$", string(coded_s[1].args[1])))
      Expr(:macrocall, coded_s[1], nothing, coded_s[2:end]...)
    else
      Expr(:call, coded_s[1], coded_s[2:end]...)
    end
  end
end

"This is an internal helper function, do not call outside of package"
function lisp_eval_helper(str :: AbstractString)
  s = desx(LispSyntax.read(str))
  return codegen(s)
end

macro lisp_str(str)
  return esc(lisp_eval_helper(str))
end

end # module
