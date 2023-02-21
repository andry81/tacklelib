* README_EN.txt
* 2023.02.21
* tacklelib--vbs

1. DESCRIPTION
2. PREREQUISITES
3. CATALOG CONTENT DESCRIPTION
4. KNOWN ISSUES
4.1. A Visual Basic script error message: `Microsoft VBScript runtime error: This script contains malicious content and has been blocked by your antivirus software.: 'ExecuteGlobal'`
4.2. A Visual Basic script hangs on execution.

-------------------------------------------------------------------------------
1. DESCRIPTION
-------------------------------------------------------------------------------
The `tacklelib` library vbs support modules to run vbs scripts on Windows.

-------------------------------------------------------------------------------
2. PREREQUISITES
-------------------------------------------------------------------------------
See details in the `PREREQUISITES` section in the root `README_EN.txt` file.

-------------------------------------------------------------------------------
3. CATALOG CONTENT DESCRIPTION
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
4. KNOWN ISSUES
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
4.1. A Visual Basic script error message: `Microsoft VBScript runtime error: This script contains malicious content and has been blocked by your antivirus software.: 'ExecuteGlobal'`
-------------------------------------------------------------------------------

Reason:

  The Windows Defender generates a false positive for a vbs script.

Solution:

  Turn off the Windows Defender on a moment of a script execution.

-------------------------------------------------------------------------------
4.2. A Visual Basic script hangs on execution.
-------------------------------------------------------------------------------

Reason:

  The Windows Defender generates a false positive for a vbs script.

Solution:

  Turn off the Windows Defender on a moment of a script execution.
