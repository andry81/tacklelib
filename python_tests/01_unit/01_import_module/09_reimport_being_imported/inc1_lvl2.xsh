tkl_import_module(SOURCE_DIR, 'inc1_lvl3.xsh', '.')

# defined after the import, can not be visible from the child module!
def inc1_lvl2_test():
  pass
