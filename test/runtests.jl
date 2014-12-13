using cl
using Stage

# write your own tests here
init_read_table()
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
