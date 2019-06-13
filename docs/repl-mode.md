# Custom REPL Mode

LispSyntax.jl provides a default REPL mode, but if you'd like to
customize your own, you may do so by using 
[ReplMaker.jl](https://github.com/MasonProtter/ReplMaker.jl)
directly:
```julia
julia> using LispSyntax, ReplMaker

julia> ReplMaker.initrepl(LispSyntax.lisp_eval_helper,
                prompt_text="λ> ",
                prompt_color=:red,
                start_key=")",
                mode_name="Lisp Mode")
REPL mode Lisp Mode initialized. Press ) to enter and backspace to exit.
```
At this point, type `)`, and you're ready to Lisp:

```clj
λ> (* 2 (reduce + (: 1 6)))
42
λ> (defn fib [a] (if (< a 2) a (+ (fib (- a 1)) (fib (- a 2)))))
fib (generic function with 1 method)
λ> (fib 10)
55
```

If you want to support multi-line S-expressions then you must define 
a `valid_input_checker` for the REPL mode as follows:
```julia
julia> using REPL: REPL, LineEdit; using LispSyntax: ParserCombinator

julia> function lisp_reader(s)
         try
           LispSyntax.read(String(take!(copy(LineEdit.buffer(s)))))
           true
         catch err
           isa(err, ParserCombinator.ParserException) || rethrow(err)
           false
         end
       end
valid_sexpr (generic function with 1 method)

julia> initrepl(LispSyntax.lisp_eval_helper,
                valid_input_checker=lisp_reader,
                prompt_text="λ> ",
                prompt_color=:red,
                start_key=")",
                mode_name="Lisp Mode")
REPL mode Lisp Mode initialized. Press ) to enter and backspace to exit.
```
```clj
λ> (defn fib [a] 
    (if (< a 2) 
      a 
      (+ (fib (- a 1)) (fib (- a 2)))))
fib (generic function with 1 method)
```

Note that this is provided by default with `LispSyntax.init_repl`.