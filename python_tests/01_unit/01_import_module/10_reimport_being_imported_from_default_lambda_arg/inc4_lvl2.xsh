tkl_import_module(SOURCE_DIR, 'inc4_lvl3.xsh', '.')

# defined after the import, but becomes visible in the child module after the reimport!
def inc4_lvl2_test():
  pass
