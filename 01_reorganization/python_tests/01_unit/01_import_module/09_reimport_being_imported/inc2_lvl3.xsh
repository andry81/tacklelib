# will reimport respective module here when it's import is completed (postponed import)
tkl_import_module(SOURCE_DIR, 'inc2_lvl2.xsh', '.', reimport_if_being_imported = True)

def inc2_lvl3_test():
  current_module = tkl_get_stack_frame_module_by_offset()
  current_globals = globals()

  # still visible through the `globals()` ...
  assert('inc2_lvl2_test' in current_globals)
  current_globals['inc2_lvl2_test']()

  # ... and visible now through the module
  assert(hasattr(current_module, 'inc2_lvl2_test'))
  current_module.inc2_lvl2_test()
