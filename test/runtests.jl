using Lisp
using Stage

# ----------------------------------------------------------------------------------------------------------------------
# Reader
# ----------------------------------------------------------------------------------------------------------------------
@expect read("1.1f") == 1.1f0
@expect read("1.2f") == 1.2f0
@expect read("2f")   == 2f0

@expect read("3.0d") == 3.0

@expect read("4")    == 4

@expect read("\\u2312") == '\u2312'

@expect read("\\040") == ' '

@expect read("\\c") == 'c'

@expect read("\"test\"") == "test"

@expect read("true") == true
@expect read("false") == false

@expect read("test") == :test

@expect read("()") == sx()
@expect read("(1.1f)") == sx(1.1f0)
@expect read("(1.1f 2.2f)") == sx(1.1f0, 2.2f0)
@expect read("(+ 1.1f 2)") == sx(:+, 1.1f0, 2)
@expect read("(this (+ 1.1f 2))") == sx(:this, sx(:+, 1.1f0, 2))
@expect read("(this (+ 1.1f 2) )") == sx(:this, sx(:+, 1.1f0, 2))

@expect read("#{1 2 3 4}") == Set(1, 2, 3, 4)

@expect read("{a 2 b 3}")  == { :a => 2, :b => 3 }

@expect read("[1 2 3 4]")  == sx(1, 2, 3, 4)
@expect read("[]")         == sx()
@expect read("[1]")        == sx(1)

@expect read("'test")      == sx(:quote, :test)

@expect read("`test")      == sx(:quasi, :test)

@expect read("~test")      == sx(:splice, :test)
@expect read("~@(1 2 3)")  == sx(:splice_seq, sx(1, 2, 3))

@expect read("`~test")     == sx(:quasi, sx(:splice, :test))

@expect desx(sx(:splice_seq, sx(1, 2, 3))) == { :splice_seq, [1, 2, 3] }
@expect desx(sx(:splice_seq, sx(1, 2, sx(3)))) == { :splice_seq, { 1, 2, [3] } }

# ----------------------------------------------------------------------------------------------------------------------
# Code generation
# ----------------------------------------------------------------------------------------------------------------------
@expect codegen(desx(read("(if true a)"))) == :(true && $(esc(:a)))
@expect codegen(desx(read("(if true a b)"))) == :(true ? $(esc(:a)) : $(esc(:b)))

@expect codegen(desx(read("(call)"))) == :($(esc(:call))())
@expect codegen(desx(read("(call a)"))) == :($(esc(:call))($(esc(:a))))
@expect codegen(desx(read("(call a b)"))) == :($(esc(:call))($(esc(:a)), $(esc(:b))))
@expect codegen(desx(read("(call a b c)"))) == :($(esc(:call))($(esc(:a)), $(esc(:b)), $(esc(:c))))

@expect codegen(desx(read("(lambda (x) (call x))"))) == Expr(:function, :((x,)), :($(esc(:call))(x)))

@expect codegen(desx(read("(def x 3)"))) == :($(esc(:x)) = 3)
@expect codegen(desx(read("(def x (+ 3 1))"))) == :($(esc(:x)) = $(esc(:+))(3, 1))

@expect codegen(desx(read("'test"))) == :test
@expect codegen(desx(read("'(1 2)"))) == { 1, 2 }
@expect codegen(desx(read("'(1 2 a b)"))) == { 1, 2, :a, :b }
@expect codegen(desx(read("(call 1 '2)"))) == :($(esc(:call))(1, 2))

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
@expect @lisp("`(test ~x)") == { :test, 10 }
@expect lisp"`(test ~x)" == { :test, 10 }
@expect @lisp("`(~x ~x)") == { 10, 10 }
global y = { 1, 2 }
@expect @lisp("`(~x ~@y)") == { 10, 1, 2 }
@expect @lisp("`(~x ~y)") == { 10, {1, 2} }

@expect @lisp("`(10 ~(+ 10 x))") == {10, 20}

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

# ----------------------------------------------------------------------------------------------------------------------
# Macros
# ----------------------------------------------------------------------------------------------------------------------
lisp"(defn fact [a] (if (< a 1) 1 (* a (fact (- a 1)))))"
lisp"(defmacro fapply [f a] `(~f ~a))"
@expect @fapply(fib2, 2) == 1
@expect @fapply(fact, 3 + 1) == 24
@expect lisp"(@fapply fib2 2)" == 1
@expect lisp"(@fapply fact (+ 3 1))" == 24

# ----------------------------------------------------------------------------------------------------------------------
# Loops
# ----------------------------------------------------------------------------------------------------------------------
number = 0
output = 0
macro incr(x)
  quote
    $(esc(x)) = $(esc(x)) + 1
    $(esc(x))
  end
end

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
# Let
# ----------------------------------------------------------------------------------------------------------------------
@expect lisp"(let [x 10] x)" == 10
@expect lisp"(let [x 10 y 20] (+ x y))" == 30
@expect lisp"(let [x 10 y 20 z 20] (+ x y z))" == 50
@expect lisp"(let [x 10 y 20 z 20] (+ x y z number))" == 52
@expect lisp"(let [x 10 y 20 z 20 number 10] (+ x y z number))" == 60
@expect lisp"(let [x 10 y 20 z 20] (- (+ x y z number) output))" == 50

