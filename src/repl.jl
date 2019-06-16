using ParserCombinator
using REPL: REPL, LineEdit
using ReplMaker

function lisp_reader(s)
    try
        read(String(take!(copy(LineEdit.buffer(s)))))
        true
    catch err
        isa(err, ParserCombinator.ParserException) || rethrow(err)
        false
    end
end

function init_repl(; prompt_text="jλ> ", prompt_color = :red, start_key = ")", sticky=true)
	    ReplMaker.initrepl(lisp_eval_helper,
	                  repl = Base.active_repl,
	                  valid_input_checker = lisp_reader,
	                  prompt_text = prompt_text,
	                  prompt_color = prompt_color,
	                  start_key = start_key,
                          sticky_mode=sticky,
	                  mode_name = "Lisp Mode")
end