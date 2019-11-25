# imports nothing because of recursion
tkl_import_module(SOURCE_DIR, 'inc3_lvl2.xsh', '.')

def inc3_lvl3_test():
  current_module = tkl_get_stack_frame_module_by_offset()
  current_globals = globals()

  # already visible through the `globals()` ...
  assert('inc3_lvl2_test' in current_globals)
  current_globals['inc3_lvl2_test']()

  # ... but not through the module
  assert(not hasattr(current_module, 'inc3_lvl2_test'))
