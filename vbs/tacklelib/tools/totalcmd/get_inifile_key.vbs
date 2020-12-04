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

PrintLine(GetIniFileKey_NoExcept(WScript.Arguments(0), WScript.Arguments(1), WScript.Arguments(2)))
