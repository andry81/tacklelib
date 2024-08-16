' Description:
'   Shell based script to copy a file.
'   Can translate a long file path to DOS short path to be able to copy a file.
'
' USAGE:
'   "%WINDIR%\System32\cscript.exe" //NOLOGO copy_file.vbs "<file-path-from-file>" "<file-path-to-file>"
'

Function FixStrToPrint(str)
    Dim new_str : new_str = ""
    Dim i, Char, CharAsc

    For i = 1 To Len(str)
        Char = Mid(str, i, 1)
        CharAsc = Asc(Char)

        ' NOTE:
        '   `&H3F` - is not printable unicode origin character which can not pass through the stdout redirection.
        If CharAsc <> &H3F Then
            new_str = new_str & Char
        Else
            new_str = new_str & "?"
        End If
    Next

    FixStrToPrint = new_str
End Function

Sub PrintOrEchoLine(str)
    On Error Resume Next
    WScript.stdout.WriteLine str
    If err = 5 Then ' Access is denied
        WScript.stdout.WriteLine FixStrToPrint(str)
    ElseIf err = &h80070006& Then
        WScript.Echo str
    End If
    On Error Goto 0
End Sub

Sub PrintOrEchoErrorLine(str)
    On Error Resume Next
    WScript.stderr.WriteLine str
    If err = 5 Then ' Access is denied
        WScript.stderr.WriteLine FixStrToPrint(str)
    ElseIf err = &h80070006& Then
        WScript.Echo str
    End If
    On Error Goto 0
End Sub

'' Features:
''   * Builtin of inclusion guard
''   * Inclusion path can be relative to the script directory
'Class ImportFunction
'    Private imports_dict_obj_
'    Private fs_obj_
'
'    Private Sub CLASS_INITIALIZE
'        set imports_dict_obj_ = WScript.createObject("Scripting.Dictionary")
'        set fs_obj_ = WScript.createObject("Scripting.FileSystemObject")
'    End Sub
'
'    Public Default Property Get func(file_path_str)
'        If "/" = Left(file_path_str, 1) Then
'            ' is relative to the script directory
'            script_file_path_str = WScript.ScriptFullName
'            Dim script_file_obj : Set script_file_obj = fs_obj_.GetFile(script_file_path_str)
'            file_path_str = fs_obj_.GetParentFolderName(script_file_obj) & file_path_str
'        End If
'        file_path_str = fs_obj_.GetAbsolutePathName(file_path_str)
'
'        If Not imports_dict_obj_.Exists(file_path_str) Then
'            ExecuteGlobal fs_obj_.OpenTextFile(file_path_str).ReadAll()
'            imports_dict_obj_.Add file_path_str, Null
'        End If
'    End Property
'End Class

'Dim Import : Set Import = New ImportFunction
Dim ENABLE_ON_ERROR : ENABLE_ON_ERROR = True ' CAUTION: set `False` to debug this script!

'Import("/__init__.vbs")

' ReDim args(WScript.Arguments.Count-1)
' For i = 0 To WScript.Arguments.Count-1
'   args(i) = WScript.Arguments(i)
' Next
' MsgBox Join(args, " ")

Dim from_file_str : from_file_str = WScript.Arguments(0)
Dim to_file_str : to_file_str = WScript.Arguments(1)

Dim fs_obj : Set fs_obj = CreateObject("Scripting.FileSystemObject")

If ENABLE_ON_ERROR Then On Error Resume Next

Dim from_file_path_abs : from_file_path_abs = fs_obj.GetAbsolutePathName(from_file_str)
Dim to_file_path_abs : to_file_path_abs = fs_obj.GetAbsolutePathName(to_file_str)

' NOTE:
'   The `*Exists` methods will return False on a long path without `\\?\`
'   prefix.
'

' remove `\\?\` prefix
If Left(from_file_path_abs, 4) = "\\?\" Then
  from_file_path_abs = Mid(from_file_path_abs, 5)
End If

If Not fs_obj.FileExists("\\?\" & from_file_path_abs) Then
  PrintOrEchoErrorLine _
    WScript.ScriptName & ": error: input file path does not exist:" & vbCrLf & _
    WScript.ScriptName & ": info: InputPath=`" & from_file_path_abs & "`"
  WScript.Quit 1
End IF

' remove `\\?\` prefix
If Left(to_file_path_abs, 4) = "\\?\" Then
  to_file_path_abs = Mid(to_file_path_abs, 5)
End If

Dim to_file_path_abs_last_back_slash_offset : to_file_path_abs_last_back_slash_offset = InStrRev(to_file_path_abs, "\")

Dim to_file_parent_dir_path_abs
Dim to_file_name
If to_file_path_abs_last_back_slash_offset > 0 Then
  to_file_parent_dir_path_abs = Left(to_file_path_abs, to_file_path_abs_last_back_slash_offset - 1)
  to_file_name = Mid(to_file_path_abs, to_file_path_abs_last_back_slash_offset + 1)
Else
  to_file_parent_dir_path_abs = to_file_path_abs
  to_file_name = ""
End If

If Not fs_obj.FolderExists("\\?\" & to_file_parent_dir_path_abs & "\") Then
  PrintOrEchoErrorLine _
    WScript.ScriptName & ": error: output parent directory path does not exist:" & vbCrLf & _
    WScript.ScriptName & ": info: OutputPath=`" & to_file_path_abs & "`"
  WScript.Quit 2
End IF

Dim from_file_obj

' test on long path existence
If Not fs_obj.FileExists(from_file_path_abs) Then
  ' translate into short path

  ' WORKAROUND:
  '   We use `\\?\` to bypass `GetFolder` error: `Path not found`.
  Set from_file_obj = fs_obj.GetFile("\\?\" & from_file_path_abs)
  from_file_path_abs = from_file_obj.ShortPath
  If Left(from_file_path_abs, 4) = "\\?\" Then
    from_file_path_abs = Mid(from_file_path_abs, 5)
  End If
End If

' test on long path existence
If Not fs_obj.FolderExists(to_file_parent_dir_path_abs & "\") Then
  ' translate into short path

  ' WORKAROUND:
  '   We use `\\?\` to bypass `GetFolder` error: `Path not found`.
  Dim to_file_parent_dir_obj : Set to_file_parent_dir_obj = fs_obj.GetFolder("\\?\" & to_file_parent_dir_path_abs & "\")
  to_file_parent_dir_path_abs = to_file_parent_dir_obj.ShortPath
  If Left(to_file_parent_dir_path_abs, 4) = "\\?\" Then
    to_file_parent_dir_path_abs = Mid(to_file_parent_dir_path_abs, 5)
  End If
End If

to_file_path_abs = to_file_parent_dir_path_abs & "\" & to_file_name

fs_obj.CopyFile from_file_path_abs, to_file_path_abs

If ENABLE_ON_ERROR Then If Err Then WScript.Echo WScript.ScriptName & ": fatal error: (" & CStr(Err.Number) & ") " & Err.Source & vbCrLf & "Description: " & Err.Description : WScript.Quit Err.Number
