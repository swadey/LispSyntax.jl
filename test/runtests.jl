using Lisp
using Stage

# ----------------------------------------------------------------------------------------------------------------------
# Setup
# ----------------------------------------------------------------------------------------------------------------------
macro incr(x)
  quote
    $(esc(x)) = $(esc(x)) + 1
    $(esc(x))
  end
end

# ----------------------------------------------------------------------------------------------------------------------
# Reader
# ----------------------------------------------------------------------------------------------------------------------
@expect Lisp.read("1.1f") == 1.1f0
@expect Lisp.read("1.2f") == 1.2f0
@expect Lisp.read("2f")   == 2f0

@expect Lisp.read("3.0d") == 3.0

@expect Lisp.read("4")    == 4

@expect Lisp.read("\\u2312") == '\u2312'

@expect Lisp.read("\\040") == ' '

@expect Lisp.read("\\c") == 'c'

@expect Lisp.read("\"test\"") == "test"

@expect Lisp.read("true") == true
@expect Lisp.read("false") == false

@expect Lisp.read("test") == :test

@expect Lisp.read("()") == sx()
@expect Lisp.read("(1.1f)") == sx(1.1f0)
@expect Lisp.read("(1.1f 2.2f)") == sx(1.1f0, 2.2f0)
@expect Lisp.read("(+ 1.1f 2)") == sx(:+, 1.1f0, 2)
@expect Lisp.read("(this (+ 1.1f 2))") == sx(:this, sx(:+, 1.1f0, 2))
@expect Lisp.read("(this (+ 1.1f 2) )") == sx(:this, sx(:+, 1.1f0, 2))

@expect Lisp.read("#{1 2 3 4}") == Set([1, 2, 3, 4])

@expect Lisp.read("{a 2 b 3}")  == Dict(:a => 2, :b => 3)

@expect Lisp.read("[1 2 3 4]")  == sx(1, 2, 3, 4)
@expect Lisp.read("[]")         == sx()
@expect Lisp.read("[1]")        == sx(1)

@expect Lisp.read("'test")      == sx(:quote, :test)

@expect Lisp.read("`test")      == sx(:quasi, :test)

@expect Lisp.read("~test")      == sx(:splice, :test)
@expect Lisp.read("~@(1 2 3)")  == sx(:splice_seq, sx(1, 2, 3))

@expect Lisp.read("`~test")     == sx(:quasi, sx(:splice, :test))

@expect desx(sx(:splice_seq, sx(1, 2, 3))) == Any[ :splice_seq, [1, 2, 3] ]
@expect desx(sx(:splice_seq, sx(1, 2, sx(3)))) == Any[ :splice_seq, Any[ 1, 2, [3] ] ]

@expect Lisp.read("""(defn multiline
                           [x]
                           (+ x 1))""") == sx(:defn, :multiline, sx(:x), sx(:+, :x, 1))

@expect Lisp.read("""
(defn f1 [n]
   (if (< n 2)
       1
       (+ (f1 (- n 1))
          (f1 (- n 2)))))
""") == sx(:defn, :f1, sx(:n), sx(:if, sx(:<, :n, 2), 1, sx(:+, sx(:f1, sx(:-, :n, 1)), sx(:f1, sx(:-, :n, 2)))))
# ----------------------------------------------------------------------------------------------------------------------
# Code generation
# ----------------------------------------------------------------------------------------------------------------------
@expect codegen(desx(Lisp.read("(if true a)"))) == :(true && $(esc(:a)))
@expect codegen(desx(Lisp.read("(if true a b)"))) == :(true ? $(esc(:a)) : $(esc(:b)))

@expect codegen(desx(Lisp.read("(call)"))) == :($(esc(:call))())
@expect codegen(desx(Lisp.read("(call a)"))) == :($(esc(:call))($(esc(:a))))
@expect codegen(desx(Lisp.read("(call a b)"))) == :($(esc(:call))($(esc(:a)), $(esc(:b))))
@expect codegen(desx(Lisp.read("(call a b c)"))) == :($(esc(:call))($(esc(:a)), $(esc(:b)), $(esc(:c))))

@expect codegen(desx(Lisp.read("(lambda (x) (call x))"))) == Expr(:function, :((x,)), Expr(:block, :($(esc(:call))(x))))
@expect codegen(desx(Lisp.read("(def x 3)"))) == :($(esc(:x)) = 3)
@expect codegen(desx(Lisp.read("(def x (+ 3 1))"))) == :($(esc(:x)) = $(esc(:+))(3, 1))

@expect codegen(desx(Lisp.read("'test"))) == :test
@expect codegen(desx(Lisp.read("'(1 2)"))) == Any[ 1, 2 ]
@expect codegen(desx(Lisp.read("'(1 2 a b)"))) == Any[ 1, 2, :a, :b ]
@expect codegen(desx(Lisp.read("(call 1 '2)"))) == :($(esc(:call))(1, 2))

# ----------------------------------------------------------------------------------------------------------------------
# Scope and variables
# ----------------------------------------------------------------------------------------------------------------------
global x = 10
@expect @lisp("x") == 10
@expect lisp"x" == 10

lisp"(def w (+ 3 1))"
@expect w == 4

# ----------------------------------------------------------------------------------------------------------------------
# Quoting and splicing
# ----------------------------------------------------------------------------------------------------------------------
@expect @lisp("`~x") == 10
@expect lisp"`~x" == 10
@expect @lisp("`(test ~x)") == Any[ :test, 10 ]
@expect lisp"`(test ~x)" == Any[ :test, 10 ]
@expect @lisp("`(~x ~x)") == Any[ 10, 10 ]
global y = Any[ 1, 2 ]
@expect @lisp("`(~x ~@y)") == Any[ 10, 1, 2 ]
@expect @lisp("`(~x ~y)") == Any[ 10, Any[1, 2] ]

@expect @lisp("`(10 ~(+ 10 x))") == Any[10, 20]

@expect lisp"(quote (+ 1 2))" == Any[:+, 1, 2]

# ----------------------------------------------------------------------------------------------------------------------
# Functions
# ----------------------------------------------------------------------------------------------------------------------
@lisp("(defn xxx [a b] (+ a b))")
@expect @lisp("(xxx 1 2)") == 3

global z = 10
@lisp("(defn yyy [a] (+ a z))")
@expect @lisp("(yyy 1)") == 11
@expect @lisp("(yyy z)") == 20

# recursion
lisp"(defn fib [a] (if (< a 2) a (+ (fib (- a 1)) (fib (- a 2)))))"
@expect lisp"(fib 2)" == 1
@expect lisp"(fib 4)" == 3
@expect lisp"(fib 30)" == 832040
@expect lisp"(fib 40)" == 102334155

# Note this version is very slow due to the anonymous function
lisp"(def fib2 (lambda [a] (if (< a 2) a (+ (fib2 (- a 1)) (fib2 (- a 2))))))"
@expect lisp"(fib2 2)" == 1
@expect lisp"(fib2 4)" == 3
@expect lisp"(fib2 30)" == 832040

lisp"(defn dostuff [a] (@incr a) (@incr a) (@incr a))"
@expect lisp"(dostuff 3)" == 6
@expect lisp"(dostuff 6)" == 9

lisp"(def dostuff2 (lambda [a] (@incr a) (@incr a) (@incr a)))"
@expect lisp"(dostuff2 3)" == 6
@expect lisp"(dostuff2 6)" == 9

lisp"(def dostuff3 (fn [a] (@incr a) (@incr a) (@incr a)))"
@expect lisp"(dostuff3 3)" == 6
@expect lisp"(dostuff3 6)" == 9

# ----------------------------------------------------------------------------------------------------------------------
# Macros
# ----------------------------------------------------------------------------------------------------------------------
lisp"(defn fact [a] (if (< a 1) 1 (* a (fact (- a 1)))))"
lisp"(defmacro fapply [f a] `(~f ~a))"
@expect @fapply(fib2, 2) == 1
@expect @fapply(fact, 3 + 1) == 24
@expect lisp"(@fapply fib2 2)" == 1
@expect lisp"(@fapply fact (+ 3 1))" == 24

fcount = 0
lisp"(defmacro fapply_trace [f a] (global fcount) (@incr fcount) `(~f ~a))"
@expect @fapply_trace(fib2, 2) == 1
@expect fcount == 1
@expect @fapply_trace(fact, 3 + 1) == 24
@expect fcount == 2

# ----------------------------------------------------------------------------------------------------------------------
# Loops
# ----------------------------------------------------------------------------------------------------------------------
number = 0
output = 0

lisp"(while (< number 2) (@incr number) (@incr output))"
@expect number == 2
@expect output == 2
r = output
lisp"(for [i (range 1 10)] (@incr r))"
@expect r == 12

r = 0
lisp"(for [i (range 1 10) j (range 1 10)] (@incr r))"
@expect r == 100

# ----------------------------------------------------------------------------------------------------------------------
# Let and do
# ----------------------------------------------------------------------------------------------------------------------
@expect lisp"(let [x 10] x)" == 10
@expect lisp"(let [x 10 y 20] (+ x y))" == 30
@expect lisp"(let [x 10 y 20 z 20] (+ x y z))" == 50
@expect lisp"(let [x 10 y 20 z 20] (+ x y z number))" == 52
@expect lisp"(let [x 10 y 20 z 20 number 10] (+ x y z number))" == 60
@expect lisp"(let [x 10 y 20 z 20] (- (+ x y z number) output))" == 50

lisp"(do (@incr r) (@incr number))"
@expect number == 3
@expect r == 101

# ----------------------------------------------------------------------------------------------------------------------
# Import
# ----------------------------------------------------------------------------------------------------------------------
lisp"(import ParserCombinator)"
@expect lisp"(@E_str \"S\")" == E"S"
