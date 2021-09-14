# imports nothing because of recursion
tkl_import_module(SOURCE_DIR, 'inc3_lvl2.xsh', '.')

def inc3_lvl3_test(pred = lambda: globals()['inc3_lvl2_test']()):
  # already visible through the `globals()` ...
  pred()

def inc3_lvl3_test(pred = lambda: hasattr(tkl_get_stack_frame_module_by_offset(), 'inc3_lvl2_test')):
  # ... but not through the module
  assert(not pred())
