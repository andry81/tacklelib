include(tacklelib/Std)
include(tacklelib/Eval)
include(tacklelib/ForwardArgs)

tkl_make_var_from_CMAKE_ARGV_ARGC(-P argv)
#message("argv=`${argv}`")

tkl_list_sublist(argv_tail 1 -1 argv)
#message("argv_tail=`${argv_tail}`")

tkl_escape_list_expansion(cmdline "${argv_tail}")
#message("cmdline=`${cmdline}`")

tkl_eval(${cmdline})
