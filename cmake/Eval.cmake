include(Std)
include(ForwardVariables)
include(MakeTemp)

macro(Eval)
  # save specific variables to stack
  pushset_variable_to_stack("argn" "${argn}")

  #message("=${ARGV}=")
  #message("=${ARGN}=")
  make_argn_var_from_ARGV_ARGN_begin("${ARGV}" "${ARGN}")
  # in case of in a macro call we must pass all ARGV arguments explicitly
  set_ARGV(
    "${ARGV0}" "${ARGV1}" "${ARGV2}" "${ARGV3}" "${ARGV4}" "${ARGV5}" "${ARGV6}" "${ARGV7}" "${ARGV8}" "${ARGV9}"
    "${ARGV10}" "${ARGV11}" "${ARGV12}" "${ARGV13}" "${ARGV14}" "${ARGV15}" "${ARGV16}" "${ARGV17}" "${ARGV18}" "${ARGV19}"
    "${ARGV20}" "${ARGV21}" "${ARGV22}" "${ARGV23}" "${ARGV24}" "${ARGV25}" "${ARGV26}" "${ARGV27}" "${ARGV28}" "${ARGV29}"
    "${ARGV30}" "${ARGV31}")
  #print_ARGV()
  make_argn_var_from_ARGV_ARGN_end()
  unset_ARGV()
  #message("Eval: argn=${argn}")

  if (NOT TESTLIB_TESTPROC_INDEX STREQUAL "")
    # running under TestLib, the macro can call under different cmake processes when the inner timestamp is not yet changed (timestamp has seconds resolution)
    MakeTempDir("Cmake.Eval." "%Y'%m'%d''%H'%M'%SZ" "${TESTLIB_TESTPROC_INDEX}" 8 _67AB359F_temp_dir_path)
  else()
    MakeTempDir("Cmake.Eval." "%Y'%m'%d''%H'%M'%SZ" "" 8 _67AB359F_temp_dir_path)
  endif()

  file(WRITE "${_67AB359F_temp_dir_path}/eval.cmake" "")

  decode_control_chars("${argn}" _67AB359F_argn)

  file(APPEND "${_67AB359F_temp_dir_path}/eval.cmake" "${_67AB359F_argn}\n")

  unset(_67AB359F_argn)

  # restore specific variables from stack
  popset_variable_from_stack("argn")

  include("${_67AB359F_temp_dir_path}/eval.cmake")

  file(REMOVE_RECURSE "${_67AB359F_temp_dir_path}")

  unset(_67AB359F_temp_dir_path)
endmacro()
