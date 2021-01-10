' Description:
'   Shell based script to be able to move directory.
'
' USAGE:
'   "%WINDIR%\System32\cscript.exe" //NOLOGO move_dir.vbs "<file-path-from-dir>" "<file-path-to-dir>"
'

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

' ReDim args(WScript.Arguments.Count-1)
' For i = 0 To WScript.Arguments.Count-1
'   args(i) = WScript.Arguments(i)
' Next
' MsgBox Join(args, " ")

Dim from_file_dir_str : from_file_dir_str = WScript.Arguments(0)
Dim to_file_dir_str : to_file_dir_str = WScript.Arguments(1)

Dim fs_obj : Set fs_obj = CreateObject("Scripting.FileSystemObject")

If ENABLE_ON_ERROR Then On Error Resume Next
Dim from_dir_obj : Set from_dir_obj = fs_obj.GetFolder(from_file_dir_str)
from_dir_obj.Move to_file_dir_str
If ENABLE_ON_ERROR Then If Err Then WScript.Echo WScript.ScriptName & ": fatal error: (" & CStr(Err.Number) & ") " & Err.Source & " | " & "Description: " & Err.Description : WScript.Quit Err.Number
