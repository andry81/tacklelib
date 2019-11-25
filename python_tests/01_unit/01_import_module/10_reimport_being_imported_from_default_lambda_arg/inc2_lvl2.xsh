tkl_import_module(SOURCE_DIR, 'inc2_lvl3.xsh', '.')

# defined after the import, but becomes visible in the child module after the reimport!
def inc2_lvl2_test():
  pass
