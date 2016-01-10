
import Base: LineEdit, REPL

function valid_sexpr(s)
  try
    Lisp.read(bytestring(LineEdit.buffer(s)))
    true
  catch err
    isa(err, BoundsError) || rethrow(err)
    false
  end
end

function initrepl(;
    text  = "lisp> ",
    color = "\e[35;5;166m",
    key   = ')'
  )

  isdefined(Base, :active_repl) || return

  repl       = Base.active_repl
  julia_mode = repl.interface.modes[1]

  prefix = repl.hascolor ? color : ""
  suffix = repl.hascolor ? (repl.envcolors ? Base.input_color : repl.input_color) : ""

  lisp_mode = LineEdit.Prompt(text;
    prompt_prefix    = prefix,
    prompt_suffix    = suffix,
    keymap_func_data = repl,
    on_enter         = valid_sexpr,
    complete         = REPL.REPLCompletionProvider(repl),
  )
  lisp_mode.on_done = REPL.respond(s -> :($(Lisp).@lisp($s)), repl, lisp_mode)

  push!(repl.interface.modes, lisp_mode)

  hp                     = julia_mode.hist
  hp.mode_mapping[:lisp] = lisp_mode
  lisp_mode.hist         = hp

  search_prompt, skeymap = LineEdit.setup_search_keymap(hp)

  mk = REPL.mode_keymap(julia_mode)

  lisp_keymap = Dict(
    key => (s, args...) ->
      if isempty(s) || position(LineEdit.buffer(s)) == 0
        buf = copy(LineEdit.buffer(s))
        LineEdit.transition(s, lisp_mode) do
          LineEdit.state(s, lisp_mode).input_buffer = buf
        end
      else
        LineEdit.edit_insert(s, key)
      end
  )

  lisp_mode.keymap_dict = LineEdit.keymap(Dict[
    skeymap,
    mk,
    LineEdit.history_keymap,
    LineEdit.default_keymap,
    LineEdit.escape_defaults,
  ])
  julia_mode.keymap_dict = LineEdit.keymap_merge(julia_mode.keymap_dict, lisp_keymap)

  nothing
end
