# inclusion guard for protection and speedup
if (NOT DEFINED TACKLELIB_EVAL_INCLUDE_DEFINED)
set(TACKLELIB_EVAL_INCLUDE_DEFINED 1)

include(tacklelib/Std)
include(tacklelib/MakeTemp)
include(tacklelib/Handlers)

tkl_enable_handlers_for(return PRE)

macro(tkl_eval)
  #message("=${ARGV}=")
  #message("=${ARGN}=")
  tkl_make_vars_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}" "" _67AB359F_eval_argn)
  # in case of in a macro call we must pass all ARGV arguments explicitly
  tkl_set_ARGV(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #tkl_print_ARGV()
  tkl_make_vars_from_ARGV_ARGN_end("" _67AB359F_eval_argn)
  tkl_unset_ARGV()
  #message("tkl_eval: argn=${_67AB359F_eval_argn}")

  if (NOT TACKLELIB_TESTLIB_TESTPROC_INDEX STREQUAL "")
    # running under TestLib, the macro can call under different cmake processes when the inner timestamp is not yet changed (timestamp has seconds resolution)
    tkl_make_temp_dir("CMake.Eval." "%Y'%m'%d''%H'%M'%SZ" "${TACKLELIB_TESTLIB_TESTPROC_INDEX}" 8 _67AB359F_temp_dir_path)
  else()
    tkl_make_temp_dir("CMake.Eval." "%Y'%m'%d''%H'%M'%SZ" "" 8 _67AB359F_temp_dir_path)
  endif()

  # builtin variables for the `eval` self testing from the `TestLib`
  if (DEFINED TACKLELIB_TESTLIB_INITED)
    set(TACKLELIB_TESTLIB_EVAL_LAST_TEMP_DIR_PATH "${_67AB359F_temp_dir_path}")
  endif()

  tkl_decode_control_chars("${_67AB359F_eval_argn}" _67AB359F_eval_argn)

  # 1. drop local variables at begin
  # 2. the expression at the middle
  # 3. self cleanup at the end
  file(WRITE "${_67AB359F_temp_dir_path}/eval.cmake" "\
unset(_67AB359F_temp_dir_path)
unset(_67AB359F_eval_argn)

# handler for the `return`
macro tkl_return_pre_only_handler()
  # remove return handler before handling
  tkl_remove_handler_for_return(PRE)
  # cleanup before return
  file(REMOVE_RECURSE \"${_67AB359F_temp_dir_path}\")
endmacro()

tkl_add_handler_for_return(PRE tkl_return_pre_only_handler)

# evaluating...
${_67AB359F_eval_argn}

# cleanup after evaluate
file(REMOVE_RECURSE \"${_67AB359F_temp_dir_path}\")
")

  # evaluating...
  include("${_67AB359F_temp_dir_path}/eval.cmake")
endmacro()

endif()
