Sub IncludeFile(file_path_str)
    executeGlobal CreateObject("Scripting.FileSystemObject").OpenTextFile(file_path_str).ReadAll()
End Sub

Function GetScriptDir()
    script_file_path_str = WScript.ScriptFullName
    Dim fs_obj : Set fs_obj = CreateObject("Scripting.FileSystemObject")
    Dim script_file_obj : Set script_file_obj = fs_obj.GetFile(script_file_path_str)
    GetScriptDir = fs_obj.GetParentFolderName(script_file_obj)
End Function

IncludeFile(GetScriptDir() & "/__init__.vbs")

' PrintIniFileDict(ReadIniFileAsDict(WScript.Arguments(0)))

Dim ini_file_path_in_str : ini_file_path_in_str = WScript.Arguments(0)
Dim ini_file_path_out_str : ini_file_path_out_str = WScript.Arguments(1)
Dim ini_file_path_cleanup_str : ini_file_path_cleanup_str = WScript.Arguments(2)
Dim ini_file_path_add_str : ini_file_path_add_str = WScript.Arguments(3)

Dim ini_file_in_arr : ini_file_in_arr = ReadFileLinesAsArr(ini_file_path_in_str)
Dim ini_file_cleanup_arr
If ini_file_path_cleanup_str <> "" Then
    ini_file_cleanup_arr = ReadFileLinesAsArr(ini_file_path_cleanup_str)
Else
    ini_file_cleanup_arr = Array()
End If
Dim ini_file_add_arr : ini_file_add_arr = ReadFileLinesAsArr(ini_file_path_add_str)

'On Error Resume Next
Dim ini_file_cleanuped_arr : ini_file_cleanuped_arr = DeleteIniFileArr(ini_file_in_arr, ini_file_cleanup_arr, False, False)
'If Err Then WScript.Echo WScript.ScriptName & ": fatal error: (" & CStr(Err.Number) & ") " & Err.Source & " | " & "Description: " & Err.Description : WScript.Quit Err.Number

'On Error Resume Next
Dim ini_file_updated_arr : ini_file_updated_arr = MergeIniFileArr(ini_file_cleanuped_arr, ini_file_add_arr, True)
'If Err Then WScript.Echo WScript.ScriptName & ": fatal error: (" & CStr(Err.Number) & ") " & Err.Source & " | " & "Description: " & Err.Description : WScript.Quit Err.Number

' PrintLineArr ini_file_in_arr, False
' PrintLine("---")
' PrintLineArr ini_file_cleanup_arr, False
' PrintLine("---")
' PrintLineArr ini_file_cleanuped_arr, False
' PrintLine("---")
' PrintLineArr ini_file_add_arr, False
' PrintLine("---")
' PrintLineArr ini_file_updated_arr, False

'On Error Resume Next
WriteFileLinesFromArr ini_file_path_out_str, ini_file_updated_arr, True
'If Err Then WScript.Echo WScript.ScriptName & ": fatal error: (" & CStr(Err.Number) & ") " & Err.Source & " | " & "Description: " & Err.Description : WScript.Quit Err.Number
