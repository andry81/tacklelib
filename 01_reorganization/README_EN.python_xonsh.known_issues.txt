* README_EN.known_issues.txt
* 2019.12.30
* python/xonsh

1. KNOWN ISSUES
1.1. issues with the pipe `|` operator
1.2. isseus with the `@(...)` operator
1.3. issues with another modules
2. AUTHOR

-------------------------------------------------------------------------------
1. KNOWN ISSUES
-------------------------------------------------------------------------------
There is issues with the xonsh module which might be important to known before
change the .xsh script code.

Tested in version: 0.9.12

-------------------------------------------------------------------------------
1.1. issues with the pipe `|` operator
-------------------------------------------------------------------------------
* https://github.com/xonsh/xonsh/issues/3202 : "`print` order broken while piping"
* https://github.com/xonsh/xonsh/issues/3198 : "can not use log from xonsh on any arbitrary xonsh code"

CAUTION:
  Because the inner xonsh piping is broken, there is no other option except to
  log the output through the external to a python pipe through a shell script
  and an external utility.

-------------------------------------------------------------------------------
1.2. issues with the `@(...)` operator
-------------------------------------------------------------------------------
* https://github.com/xonsh/xonsh/issues/3189 : "module `cmdix`/`yes` can not be interrupted (ctrl+c) from the python evaluation command `@(...)`"
* https://github.com/xonsh/xonsh/issues/3191 : "multiline python evaluation `@(...)` under try block fails with IndexError"
* https://github.com/xonsh/xonsh/issues/3192 : "multiline python evaluation `@(...)` breaks the parser"

NOTE:
  This is the reason to always write the inner python evaluation blocks `@(..)`
  on a single line.

-------------------------------------------------------------------------------
1.3. issues with another modules
-------------------------------------------------------------------------------
https://github.com/xonsh/xonsh/issues/3190 : "module `cmdix` executables is not visible from the python `Scripts` directory"
https://github.com/xonsh/xonsh/issues/3189 : "module `cmdix`/`yes` can not be interrupted (ctrl+c) from the python evaluation command `@(...)`"

-------------------------------------------------------------------------------
2. AUTHOR
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
