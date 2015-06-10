Lisp.jl: A clojure-like lisp dialect implemented in julia
=========================================================

<img align=right src="https://travis-ci.org/swadey/Lisp.jl.svg?branch=master" alt="Build Status"/>

This package provides a julia-to-lisp syntax translator with convenience macros that let you do this:
```julia
lisp"(defn fib [a] (if (< a 2) a (+ (fib (- a 1)) (fib (- a 2)))))"
@test lisp"(fib 30)" == 832040
```

