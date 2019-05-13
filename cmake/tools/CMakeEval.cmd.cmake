include(Std)
include(Eval)

make_var_from_CMAKE_ARGV_ARGC(-P argv)
#message("argv=${argv}")

ListSublist(argv_tail 1 -1 argv)
#message("argv_tail=${argv_tail}")

escape_list_expansion(cmdline "${argv_tail}")
#message("cmdline=${cmdline}")

Eval(${cmdline})