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

## Tutorial

### Basic intro to Lisp for Julians

Okay, maybe you've never used Lisp before, but you've used Julia!

A *hello world* program in `LispSyntax` is actually super simple. Let's try it:

```julia
lisp> (println "Hello World!")
Hello World!
```

See? Easy! As you may have guessed, this is the same as the Julia version of:

```julia
julia> println("Hello World")
Hello World
```

To add up some super simple math, we could do:

```julia
lisp> (+ 1 3)
4
```

Which would return `4` and would be equivalent of:

```julia
lisp> (+ 1 3)
4
```

What you’ll notice is that the first item in the list is the function being called and the rest of the arguments are the arguments being passed in. In fact, in `LispSyntax` (as with most Lisps) we can pass in multiple arguments to the plus operator:

```julia
lisp> (+ 1 3 55)
59
```

Which would return `59`.

Maybe you’ve heard of Lisp before but don’t know much about it. Lisp isn’t as hard as you might think, and `LispSyntax` inherits from Julia, so `LispSyntax` is a great way to start learning Lisp. The main thing that’s obvious about Lisp is that there’s a lot of parentheses. This might seem confusing at first, but it isn’t so hard. Let’s look at some simple math that’s wrapped in a bunch of parentheses that we could enter into the `LispREPL`:

```julia
lisp> (def result (- (/ (+ 1 3 88) 2) 8))
38.0
```

This would return `38.0`. But why? Well, we could look at the equivalent expression in Julia:

```julia
julia> result = ((1 + 3 + 88) / 2) - 8
38.0
```

If you were to try to figure out how the above were to work in Julia, you’d of course figure out the results by solving each inner parenthesis. That’s the same basic idea in `LispSyntax`. Let’s try this exercise first in Julia:

```julia
result = ((1 + 3 + 88) / 2) - 8
# simplified to...
result = (92 / 2) - 8
# simplified to...
result = 46 - 8
# simplified to...
result = 38
```

Now let's try the same thing in `LispSyntax`:

```julia
(def result (- (/ (+ 1 3 88) 2) 8))
; simplified to...
(def result (- (/ 92 2) 8))
; simplified to...
(def result (- 46 8))
; simplified to...
(def result 38)
```

As you probably guessed, this last expression with `def` means to assign the variable `result` to `38`.

See? Not too hard!

These operations were all done with Int64 integers. As LispSyntax preserves Julias types you can also use Float64 and Float32. At present they need to be written as `3.0d` and `3.0f` respectively, though this will likely change towards the same behavior as in the usual Julia.
```julia
lisp> (+ 1.0d 2.0d)
3.0
lisp> (+ 1.0f 2.0d)
3.0
lisp> (typeof 1.0d)
Float64
lisp (typeof 1.0f)
Float32
```

This is the basic premise of Lisp. Lisp stands for “list processing”; this means that the structure of the program is actually lists of lists. (If you’re familiar with Julia vectors, imagine the entire same structure as above but with square brackets instead, any you’ll be able to see the structure above as both a program and a datastructure.) This is easier to understand with more examples, so let’s write a simple Julia program, test it, and then show the equivalent `LispSyntax` program:

```julia
julia> input(prompt) = (print(prompt); chomp(readline()))
input (generic function with 1 method)

julia> function simple_conversation()
           println("Hello!  I'd like to get to know you.  Tell me about yourself!")
           name = input("What is your name? ")
           age = input("What is your age? ")
           println(string( "Hello ", name, "!  I see you are ", age," years old."))
       end
simple_conversation (generic function with 1 method)
```

If we ran this program, it might go like:

```julia
julia> simple_conversation()
Hello!  I'd like to get to know you.  Tell me about yourself!
What is your name? Julia
What is your age? 3
Hello Julia!  I see you are 3 years old.
```

Now let’s look at the equivalent `LispSyntax` program:

```lisp
lisp> (defn input [prompt]
          (print prompt)
          (chomp (readline)))
input (generic function with 1 method)

lisp> (defn simple_conversation []
         (println "Hello!  I'd like to get to know you.  Tell me about yourself!")
         (def name (input "What is your name? "))
         (def age (input "What is your age? "))
         (print (string "Hello " name "!  I see you are " age " years old.")))
simple_conversation (generic function with 1 method)

lisp> (simple_conversation)
Hello!  I'd like to get to know you.  Tell me about yourself!
What is your name? Julia
What is your age? 3
Hello Julia!  I see you are 3 years old.
```

If you look at the above program, as long as you remember that the first element in each list of the program is the function (or macro... we’ll get to those later) being called and that the rest are the arguments, it’s pretty easy to figure out what this all means. (As you probably also guessed, `defn` is the `LispSyntax` method of defining methods.)

Still, lots of people find this confusing at first because there’s so many parentheses, but there are plenty of things that can help make this easier: keep indentation nice and use an editor with parenthesis matching (this will help you figure out what each parenthesis pairs up with) and things will start to feel comfortable.

There are some advantages to having a code structure that’s actually a very simple data structure as the core of Lisp is based on. For one thing, it means that your programs are easy to parse and that the entire actual structure of the program is very clearly exposed to you. 

Another implication of this is macros: if a program’s structure is a simple data structure, that means you can write code that can write code very easily, meaning that implementing entirely new language features can be very fast. You too can make use of macros' incredible power (just be careful to not aim them footward)!
