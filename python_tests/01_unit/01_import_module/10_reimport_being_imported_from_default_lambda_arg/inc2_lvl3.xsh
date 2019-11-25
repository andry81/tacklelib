# will reimport respective module here when it's import is completed (postponed import)
tkl_import_module(SOURCE_DIR, 'inc2_lvl2.xsh', '.', reimport_if_being_imported = True)

def inc2_lvl3_test(pred = lambda: globals()['inc2_lvl2_test']()):
  # still visible through the `globals()` ...
  pred()

def inc2_lvl3_test(pred = lambda: tkl_get_stack_frame_module_by_offset().inc2_lvl2_test()):
  # ... and visible now through the module
  pred()
