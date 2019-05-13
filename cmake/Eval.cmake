include(Std)
include(MakeTemp)

macro(Eval)
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

  foreach(_67AB359F_arg IN LISTS argn)
    ## WORKAROUND: we have to replace because `foreach(...)` discardes ;-escaping
    #string(REPLACE ";" "\;" _67AB359F_arg "${_67AB359F_arg}") # regex is required to properly replace to `\;`
    ## WORKAROUND: we have to replace because the backslash character is special escape character
    #string(REPLACE "\\" "\\\\" _67AB359F_arg "${_67AB359F_arg}")
    decode_control_chars("${_67AB359F_arg}" _67AB359F_arg)
    file(APPEND "${_67AB359F_temp_dir_path}/eval.cmake" "${_67AB359F_arg}\n")
  endforeach()

  include("${_67AB359F_temp_dir_path}/eval.cmake")

  file(REMOVE_RECURSE "${_67AB359F_temp_dir_path}")

  unset(argn)
  unset(_67AB359F_arg) # just in case
  unset(_67AB359F_temp_dir_path)
endmacro()
