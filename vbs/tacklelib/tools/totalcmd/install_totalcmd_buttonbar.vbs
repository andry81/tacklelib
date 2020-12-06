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

Import("/__init__.vbs")

Import("/libs/totalcmdlib.vbs")

' PrintIniFileDict(ReadIniFileAsDict(WScript.Arguments(0)), -1)
