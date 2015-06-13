Lisp.jl: A clojure-like lisp syntax for julia
=============================================

<img align=right src="https://travis-ci.org/swadey/Lisp.jl.svg?branch=master" alt="Build Status"/>

This package provides a julia-to-lisp syntax translator with
convenience macros that let you do this: 

```julia 
lisp"(defn fib [a] (if (< a 2) a (+ (fib (- a 1)) (fib (- a 2)))))" @test lisp"(fib 30)" == 832040 
```

Lisp.jl is implemented as an expression translator between
lisp/clojure-like syntax and julia's AST.  Julia's compiler, JIT and
multiple-dispatch infrastructure is used for code generation and
execution. Because of this, Lisp.jl is not really clojure or lisp in
most meaningful ways.  The semantics are entirely julia-based (which
are very similar to scheme/lisp in many ways).  The net result is that
Lisp.jl is really an alternative S-expression-like syntax for julia,
not an implemention of clojure or lisp.

Notable Differences
-------------------


