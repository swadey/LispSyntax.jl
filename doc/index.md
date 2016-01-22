# LispSyntax.jl

## Quickstart

### How to install

* Clone this repo using Julia's `Pkg.clone` function:

```julia
$ julia
   _       _ _(_)_     |  A fresh approach to technical computing
  (_)     | (_) (_)    |  Documentation: http://docs.julialang.org
   _ _   _| |_  __ _   |  Type "?help" for help.
  | | | | | | |/ _' |  |
  | | |_| | | | (_| |  |  Version 0.5.0-dev+2212 (2016-01-19 15:43 UTC)
 _/ |\__'_|_|_|\__'_|  |  Commit 0b96cc3 (2 days old master)
|__/                   |  x86_64-unknown-linux-gnu

julia> Pkg.clone("https://github.com/swadey/LispSyntax.jl.git")
INFO: Initializing package repository /home/ismaelvc/.julia/v0.5
INFO: Cloning METADATA from https://github.com/JuliaLang/METADATA.jl
INFO: Cloning LispSyntax from https://github.com/swadey/LispSyntax.jl.git
INFO: Computing changes...
INFO: Installing AutoHashEquals v0.0.9
INFO: Installing Compat v0.7.8
INFO: Installing ParserCombinator v1.7.4
INFO: Package database updated
```

* Install the `LispREPL`:

```julia
julia> Pkg.clone("https://github.com/swadey/LispREPL.jl.git")
INFO: Cloning LispREPL from https://github.com/swadey/LispREPL.jl.git
INFO: Computing changes...
INFO: No packages to install, update or remove
```

* Start using the package, the first time `julia` will precompile the module so next load times are faster:

```julia
julia> using LispSyntax
INFO: Precompiling module LispSyntax...

julia> lisp"(println \"Hello World!\")"
Hello World!
```

* Start the `LispREPL`, again, the first time `julia` will precompile the package:

```julia
julia> using LispREPL
INFO: Precompiling module LispREPL...
```

After loading the `LispREPL`, type `)` and the `julia>` prompt will change in place to `lisp>`, now you can type some lispy stuff in the REPL:

```julia
lisp> (println "Hello World!")
Hello World!

lisp> (defn hello [name]
          (println (string "Hello " name "!")))
hello (generic function with 1 method)

lisp> (hello "Julia")
Hello Julia!
```

* Type `CTRL + C` to get back to the `julia>` prompt:

```julia
lisp> ^C

julia>
```

