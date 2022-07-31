* README_EN.txt
* 2022.07.31
* tacklelib--python--tacklelib

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. PREREQUISITES
5. USAGE
5.1. Basic initialization
5.2. Importing other modules
6. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
The `tacklelib` python subproject to support:

  * Alternative importing technique based on `importlib` module.
  * Has alternative global variables declaration in a current module from the
    stack.
  * Has guard logic to avoid double import in case of nameless (local) import.
  * Has a builtin print to trace modules import sequence.

Pros:

  * Can import both module as a submodule and can import content of a module to
    a parent module (or into a globals if has no parent module).
  * Can import modules with periods in a file name.
  * Can import any extension module from any extension module.
  * Can use a standalone name for a submodule instead of a file name without
    extension which is by default (for example, testlib.std.py as testlib,
    testlib.blabla.py as testlib_blabla and so on).
  * Does not depend on a sys.path or on a what ever search path storage.
  * Does not require to save/restore global variables like SOURCE_FILE and
    SOURCE_DIR between calls to tkl_import_module.
  * [for 3.4.x and higher] Can mix the module namespaces in nested
    tkl_import_module calls (ex: named->local->named or local->named->local
    and so on).
  * [for 3.4.x and higher] Can auto export global variables/functions/classes
    from where being declared to all children modules imported through the
    tkl_import_module (through the tkl_declare_global function).

Cons:

  * Does not support complete import:
    * Ignores enumerations and subclasses.
    * Ignores builtins because each what type has to be copied exclusively.
    * Ignores not trivially copiable classes.
    * Avoids copying builtin modules including all packaged modules.
  * [for 3.3.x and lower] Require to declare tkl_import_module in all modules
    which calls to tkl_import_module (code duplication)

WARNING:
  Use the SVN access to find out latest functionality and bug fixes.
  See the REPOSITORIES section.

-------------------------------------------------------------------------------
2. LICENSE
-------------------------------------------------------------------------------
The MIT license (see included text file "license.txt" or
https://en.wikipedia.org/wiki/MIT_License)

-------------------------------------------------------------------------------
3. REPOSITORIES
-------------------------------------------------------------------------------
Primary:
  * https://sf.net/p/tacklelib/tacklelib/HEAD/tree/trunk/python/tacklelib
  * https://svn.code.sf.net/p/tacklelib/tacklelib/trunk/python/tacklelib
First mirror:
  * https://github.com/andry81/tacklelib/tree/trunk/python/tacklelib
  * https://github.com/andry81/tacklelib.git
Second mirror:
  * https://bitbucket.org/andry81/tacklelib/src/trunk/python/tacklelib
  * https://bitbucket.org/andry81/tacklelib.git

-------------------------------------------------------------------------------
4. PREREQUISITES
-------------------------------------------------------------------------------
See details in the `PREREQUISITES` section in the root `README_EN.txt` file.

-------------------------------------------------------------------------------
5. USAGE
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
5.1. Basic initialization
-------------------------------------------------------------------------------

To initialize from python interactive command line using
`tacklelib/__init__/__init__.py` script:

1. Switch to `tacklelib` directory before run python as interactive command
   line.

2. >>>
   import __init__ as tkl
   tkl.tkl_init(tkl)
   del tkl

3. >>>
   dir()

   <
   ['TackleGlobalCache', 'TackleGlobalState', '__annotations__',
   '__builtins__', '__doc__', '__init__', '__loader__', '__name__',
   '__package__', '__spec__', 'builtins', 'copy', 'distutils', 'enum', 'glob',
   'importlib', 'inspect', 'os', 'pkgutil', 'sys', 'tkl_classcopy',
   'tkl_declare_global', 'tkl_get_global_config',
   'tkl_get_imported_module_by_file_path', 'tkl_get_method_class',
   'tkl_get_packaged_modules', 'tkl_get_stack_frame_module_by_name',
   'tkl_get_stack_frame_module_by_offset', 'tkl_import_module', 'tkl_init',
   'tkl_is_inited', 'tkl_membercopy', 'tkl_merge_module', 'tkl_remove_global',
   'tkl_source_module', 'tkl_uninit', 'tkl_update_global_config']

To initialize from python interactive command line using
`tacklelib/tacklelib.py` script:

1. Switch to `tacklelib` directory before run python as interactive command
   line.

2. >>>
   import tacklelib as tkl
   tkl.tkl_init(tkl)
   del tkl

3. >>>
   dir()

   <
   ['TackleGlobalCache', 'TackleGlobalState', '__annotations__',
   '__builtins__', '__doc__', '__loader__', '__name__',
   '__package__', '__spec__', 'builtins', 'copy', 'distutils', 'enum', 'glob',
   'importlib', 'inspect', 'os', 'pkgutil', 'sys', 'tkl_classcopy',
   'tkl_declare_global', 'tkl_get_global_config',
   'tkl_get_imported_module_by_file_path', 'tkl_get_method_class',
   'tkl_get_packaged_modules', 'tkl_get_stack_frame_module_by_name',
   'tkl_get_stack_frame_module_by_offset', 'tkl_import_module', 'tkl_init',
   'tkl_is_inited', 'tkl_membercopy', 'tkl_merge_module', 'tkl_remove_global',
   'tkl_source_module', 'tkl_uninit', 'tkl_update_global_config']

-------------------------------------------------------------------------------
5.2. Importing other modules
-------------------------------------------------------------------------------

Usage:

  tkl_import_module(<dir-path>, <file-name>[, <module-name>])

  tkl_source_module(<dir-path>, <file-name>)

-------------------------------------------------------------------------------
6. AUTHOR
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
