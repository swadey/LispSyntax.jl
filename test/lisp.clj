; File containing top level Clojure-syntax code

(defn func_in_clj_file [x y] (string "x = " x "; y = " y))

(def some_global 1.23f)

; Following should be the return value of include_lisp
(let [not_a_global 10]
  (* not_a_global not_a_global))
