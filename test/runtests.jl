using Lisp
using Stage

# Reader tests
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

# Code generation tests
if false
@expect codegen(read("(if true a)")) == :(true && a)
@expect codegen(read("(if true a b)")) == :(true ? a : b)

@expect codegen(read("(call)")) == :(call())
@expect codegen(read("(call a)")) == :(call(a))
@expect codegen(read("(call a b)")) == :(call(a, b))
@expect codegen(read("(call a b c)")) == :(call(a, b, c))

@expect codegen(read("(lambda (x) (call x))")) == Expr(:function, :((x,)), :(call(x)))

@expect codegen(read("(def x 3)")) == :(x = 3)
@expect codegen(read("(def x (+ 3 1))")) == :(x = +(3, 1))

@expect codegen(read("'test")) == :test
@expect codegen(read("'(1 2)")) == { 1, 2 }
@expect codegen(read("'(1 2 a b)")) == { 1, 2, :a, :b }
@expect codegen(read("(call 1 '2)")) == :(call(1, 2))
end

global x = 10
@expect @lisp("x") == 10
@expect lisp"x" == 10
@expect @lisp("`~x") == 10
@expect lisp"`~x" == 10
@expect @lisp("`(test ~x)") == { :test, 10 }
@expect lisp"`(test ~x)" == { :test, 10 }
@expect @lisp("`(~x ~x)") == { 10, 10 }
global y = { 1, 2 }
@expect @lisp("`(~x ~@y)") == { 10, 1, 2 }
@expect @lisp("`(~x ~y)") == { 10, {1, 2} }

@expect @lisp("`(10 ~(+ 10 x))") == {10, 20}

@lisp("(defn xxx [a b] (+ a b))")
@expect @lisp("(xxx 1 2)") == 3

global z = 10
@lisp("(defn yyy [a] (+ a z))")
@expect @lisp("(yyy 1)") == 11
@expect @lisp("(yyy z)") == 20

lisp"(defn fib [a] (if (< a 2) a (+ (fib (- a 1)) (fib (- a 2)))))"
@expect lisp"(fib 2)" == 1
@expect lisp"(fib 4)" == 3
@expect lisp"(fib 30)" == 832040
@expect lisp"(fib 40)" == 102334155

