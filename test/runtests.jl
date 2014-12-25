using cl
using Stage

# Setup
init_read_table()

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

@expect read("()") == []
@expect read("(1.1f)") == { 1.1f0 }
@expect read("(1.1f 2.2f)") == { 1.1f0, 2.2f0 }
@expect read("(+ 1.1f 2)") == { :+, 1.1f0, 2 }
@expect read("(this (+ 1.1f 2))") == { :this, { :+, 1.1f0, 2 } }
@expect read("(this (+ 1.1f 2) )") == { :this, { :+, 1.1f0, 2 } }

@expect read("#{1 2 3 4}") == Set(1, 2, 3, 4)

@expect read("{a 2 b 3}")  == { :a => 2, :b => 3 }

@expect read("[1 2 3 4]")  == { 1, 2, 3, 4 }

@expect read("'test")      == [:quote :test]

@expect read("`test")      == [:quasi :test]

@expect read("~test")      == { :splice, :test }
@expect read("~@(1 2 3)")  == { :splice_seq, { 1, 2, 3 } }

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
@expect @lisp("`~x") == { :test, 10 }
#@expect @lisp("`(test ~x)") == { :test, 10 }
