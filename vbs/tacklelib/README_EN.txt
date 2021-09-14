* README_EN.txt
* 2021.09.06
* tacklelib--vbs

1. DESCRIPTION
2. LICENSE
3. REPOSITORIES
4. PREREQUISITES
5. CATALOG CONTENT DESCRIPTION
6. KNOWN ISSUES
6.1. A Visual Basic script error message: `Microsoft VBScript runtime error: This script contains malicious content and has been blocked by your antivirus software.: 'ExecuteGlobal'`
6.2. A Visual Basic script hangs on execution.
7. AUTHOR

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
The `tacklelib` library vbs support modules to run vbs scripts on Windows.

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
  * https://sf.net/p/tacklelib/tacklelib/HEAD/tree/trunk/vbs
  * https://svn.code.sf.net/p/tacklelib/tacklelib/trunk/vbs
First mirror:
  * https://github.com/andry81/tacklelib/tree/trunk/vbs
  * https://github.com/andry81/tacklelib.git
Second mirror:
  * https://bitbucket.org/andry81/tacklelib/src/trunk/vbs
  * https://bitbucket.org/andry81/tacklelib.git

-------------------------------------------------------------------------------
4. PREREQUISITES
-------------------------------------------------------------------------------
See details in the `PREREQUISITES` section in the root `README_EN.txt` file.

-------------------------------------------------------------------------------
5. CATALOG CONTENT DESCRIPTION
-------------------------------------------------------------------------------

<root>
 |
 +- /`tools`
 |    #
 |    # The tool scripts.
 |
 +- `*.vbs`
     #
     # The core library.

-------------------------------------------------------------------------------
6. KNOWN ISSUES
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
6.1. A Visual Basic script error message: `Microsoft VBScript runtime error: This script contains malicious content and has been blocked by your antivirus software.: 'ExecuteGlobal'`
-------------------------------------------------------------------------------

Reason:

  The Windows Defender generates a false positive for a vbs script.

Solution:

  Turn off the Windows Defender on a moment of a script execution.

-------------------------------------------------------------------------------
6.2. A Visual Basic script hangs on execution.
-------------------------------------------------------------------------------

Reason:

  The Windows Defender generates a false positive for a vbs script.

Solution:

  Turn off the Windows Defender on a moment of a script execution.

-------------------------------------------------------------------------------
7. AUTHOR
-------------------------------------------------------------------------------
Andrey Dibrov (andry at inbox dot ru)
