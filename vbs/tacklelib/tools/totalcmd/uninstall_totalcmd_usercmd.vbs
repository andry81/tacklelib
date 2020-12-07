' Features:
'   * Builtin of inclusion guard
'   * Inclusion path can be relative to the script directory
Class ImportFunction
    Private imports_dict_obj_
    Private fs_obj_

    Private Sub CLASS_INITIALIZE
        set imports_dict_obj_ = WScript.createObject("Scripting.Dictionary")
        set fs_obj_ = WScript.createObject("Scripting.FileSystemObject")
    End Sub

    Public Default Property Get func(file_path_str)
        If "/" = Left(file_path_str, 1) Then
            ' is relative to the script directory
            script_file_path_str = WScript.ScriptFullName
            Dim script_file_obj : Set script_file_obj = fs_obj_.GetFile(script_file_path_str)
            file_path_str = fs_obj_.GetParentFolderName(script_file_obj) & file_path_str
        End If
        file_path_str = fs_obj_.GetAbsolutePathName(file_path_str)

        If Not imports_dict_obj_.Exists(file_path_str) Then
            ExecuteGlobal fs_obj_.OpenTextFile(file_path_str).ReadAll()
            imports_dict_obj_.Add file_path_str, Null
        End If
    End Property
End Class

Dim Import : Set Import = New ImportFunction
Dim ENABLE_ON_ERROR : ENABLE_ON_ERROR = True ' CAUTION: set `False` to debug this script!

Import("/__init__.vbs")

' PrintIniFileDict(ReadIniFileAsDict(WScript.Arguments(0)), -1)

Dim ini_file_path_in_str : ini_file_path_in_str = WScript.Arguments(0)
Dim ini_file_path_out_str : ini_file_path_out_str = WScript.Arguments(1)
Dim ini_file_path_cleanup_str : ini_file_path_cleanup_str = WScript.Arguments(2)

Dim ini_file_in_arr : ini_file_in_arr = ReadFileLinesAsArr(ini_file_path_in_str)
Dim ini_file_cleanup_arr : ini_file_cleanup_arr = ReadFileLinesAsArr(ini_file_path_cleanup_str)

If ENABLE_ON_ERROR Then On Error Resume Next
Dim ini_file_cleanuped_arr : ini_file_cleanuped_arr = DeleteIniFileArr(ini_file_in_arr, ini_file_cleanup_arr, False, False)
If ENABLE_ON_ERROR Then If Err Then WScript.Echo WScript.ScriptName & ": fatal error: (" & CStr(Err.Number) & ") " & Err.Source & " | " & "Description: " & Err.Description : WScript.Quit Err.Number

' PrintLineArr ini_file_in_arr, False
' PrintLine("---")
' PrintLineArr ini_file_cleanup_arr, False
' PrintLine("---")
' PrintLineArr ini_file_cleanuped_arr, False

If ENABLE_ON_ERROR Then On Error Resume Next
WriteFileLinesFromArr ini_file_path_out_str, ini_file_cleanuped_arr, True
If ENABLE_ON_ERROR Then If Err Then WScript.Echo WScript.ScriptName & ": fatal error: (" & CStr(Err.Number) & ") " & Err.Source & " | " & "Description: " & Err.Description : WScript.Quit Err.Number
