' CAUTION
'   You must execute this script under `cscript.exe` ONLY!
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

Import("/__init__.vbs")

Dim ExpectFlags : ExpectFlags = True
Dim UnescapeArgs : UnescapeArgs = False
Dim ParamPerLine : ParamPerLine = False

ReDim hkey_str_arr(WScript.Arguments.Count - 1)

Dim in_param_arr : in_param_arr = Array()
Dim in_param_arr_size : in_param_arr_size = 0

' positional parameters, when each parameter is associated with set of hkey positional indexes
Dim in_param_hkey_pos_arr_arr : in_param_hkey_pos_arr_arr = Array()
Dim in_param_hkey_pos_arr_arr_size : in_param_hkey_pos_arr_arr_size = 0

Dim column_separator : column_separator = "|"
Dim default_value : default_value = "."

Dim from_str_replace_arr : from_str_replace_arr = Array()
Dim to_str_replace_arr : to_str_replace_arr = Array()

Dim str_replace_arr_size : str_replace_arr_size = 0

Dim i, j : j = 0

For i = 0 To WScript.Arguments.Count-1
  If ExpectFlags Then
    If Mid(WScript.Arguments(i), 1, 1) = "-" Then
      If WScript.Arguments(i) = "-unesc" Then ' Unescape %xx or %uxxxx
        UnescapeArgs = True
      ElseIf WScript.Arguments(i) = "-param_per_line" Then
        ParamPerLine = True
      ElseIf WScript.Arguments(i) = "-param" Then
        in_param_arr_size = in_param_arr_size + 1
        in_param_hkey_pos_arr_arr_size = in_param_hkey_pos_arr_arr_size + 1
        GrowArr in_param_arr, in_param_arr_size
        GrowArr in_param_hkey_pos_arr_arr, in_param_hkey_pos_arr_arr_size
        i = i + 1
        in_param_arr(in_param_arr_size - 1) = WScript.Arguments(i)
        in_param_hkey_pos_arr_arr(in_param_hkey_pos_arr_arr_size - 1) = Array() ' empty array if position list is not defined, which means `for all`
      ElseIf WScript.Arguments(i) = "-posparam" Then
        ParamPerLine = True
        in_param_arr_size = in_param_arr_size + 1
        in_param_hkey_pos_arr_arr_size = in_param_hkey_pos_arr_arr_size + 1
        GrowArr in_param_arr, in_param_arr_size
        GrowArr in_param_hkey_pos_arr_arr, in_param_hkey_pos_arr_arr_size
        ' position list at first
        i = i + 1
        in_param_hkey_pos_arr_arr(in_param_hkey_pos_arr_arr_size - 1) = Split(WScript.Arguments(i), ",", -1, vbBinaryCompare)
        i = i + 1
        in_param_arr(in_param_arr_size - 1) = WScript.Arguments(i)
      ElseIf WScript.Arguments(i) = "-sep" Then
        i = i + 1
        column_separator = WScript.Arguments(i)
      ElseIf WScript.Arguments(i) = "-defval" Then
        i = i + 1
        default_value = WScript.Arguments(i)
      ElseIf WScript.Arguments(i) = "-rep" Then
        str_replace_arr_size = str_replace_arr_size + 1

        GrowArr from_str_replace_arr, str_replace_arr_size
        i = i + 1
        from_str_replace_arr(str_replace_arr_size - 1) = WScript.Arguments(i)

        GrowArr to_str_replace_arr, str_replace_arr_size
        i = i + 1
        to_str_replace_arr(str_replace_arr_size - 1) = WScript.Arguments(i)
      End If
    Else
      ExpectFlags = False
    End If
  End If

  If Not ExpectFlags Then
    hkey_str_arr(j) = WScript.Arguments(i)
    j = j + 1
  End If
Next

' upper bound instead of reserve size
ReDim Preserve hkey_str_arr(j - 1)
ReDim Preserve in_param_arr(in_param_arr_size - 1)
ReDim Preserve in_param_hkey_pos_arr_arr(in_param_hkey_pos_arr_arr_size - 1)
ReDim Preserve from_str_replace_arr(str_replace_arr_size - 1)
ReDim Preserve to_str_replace_arr(str_replace_arr_size - 1)

Dim hkey_str_arr_ubound : hkey_str_arr_ubound = UBound(hkey_str_arr)

Dim fso_obj : Set fso_obj = CreateObject("Scripting.FileSystemObject")

Dim stdout_obj : Set stdout_obj = fso_obj.GetStandardStream(1)
Dim stderr_obj : Set stderr_obj = fso_obj.GetStandardStream(2)

If hkey_str_arr_ubound < 0 Then
  stderr_obj.WriteLine WScript.ScriptName & ": error: must be defined at least one hkey."
  WScript.Quit 255
End If

Const HKEY_CLASSES_ROOT   = &H80000000
Const HKEY_CURRENT_USER   = &H80000001
Const HKEY_LOCAL_MACHINE  = &H80000002
Const HKEY_USERS          = &H80000003
Const HKEY_CURRENT_CONFIG = &H80000005

Dim hkey_prefix_str_arr : hkey_prefix_str_arr = Array()
ReDim hkey_prefix_str_arr(9) ' upper bound instead of reserve size

hkey_prefix_str_arr(0) = "HKEY_CLASSES_ROOT"
hkey_prefix_str_arr(1) = "HKEY_CURRENT_USER"
hkey_prefix_str_arr(2) = "HKEY_LOCAL_MACHINE"
hkey_prefix_str_arr(3) = "HKEY_USERS"
hkey_prefix_str_arr(4) = "HKEY_CURRENT_CONFIG"
hkey_prefix_str_arr(5) = "HKCR"
hkey_prefix_str_arr(6) = "HKCU"
hkey_prefix_str_arr(7) = "HKLM"
hkey_prefix_str_arr(8) = "HKU"
hkey_prefix_str_arr(9) = "HKCC"

Dim hkey_prefix_str_arr_ubound : hkey_prefix_str_arr_ubound = UBound(hkey_prefix_str_arr)

Dim hkey_prefix_len_arr : hkey_prefix_len_arr = Array()
ReDim hkey_prefix_len_arr(hkey_prefix_str_arr_ubound) ' upper bound instead of reserve size

For i = 0 To hkey_prefix_str_arr_ubound
  hkey_prefix_len_arr(i) = Len(hkey_prefix_str_arr(i))
Next

Dim hkey_hive_arr : hkey_hive_arr = Array()
ReDim hkey_hive_arr(hkey_prefix_str_arr_ubound) ' upper bound instead of reserve size

For i = 0 To hkey_prefix_str_arr_ubound
  hkey_prefix_str = hkey_prefix_str_arr(i)
  If hkey_prefix_str = "HKEY_CLASSES_ROOT" Or hkey_prefix_str = "HKCR" Then
    hkey_hive_arr(i) = HKEY_CLASSES_ROOT
  ElseIf hkey_prefix_str = "HKEY_CURRENT_USER" Or hkey_prefix_str = "HKCU" Then
    hkey_hive_arr(i) = HKEY_CURRENT_USER
  ElseIf hkey_prefix_str = "HKEY_LOCAL_MACHINE" Or hkey_prefix_str = "HKLM" Then
    hkey_hive_arr(i) = HKEY_LOCAL_MACHINE
  ElseIf hkey_prefix_str = "HKEY_USERS" Or hkey_prefix_str = "HKU" Then
    hkey_hive_arr(i) = HKEY_USERS
  ElseIf hkey_prefix_str = "HKEY_CURRENT_CONFIG" Or hkey_prefix_str = "HKCC" Then
    hkey_hive_arr(i) = HKEY_CURRENT_CONFIG
  End If
Next

' default replacements
If str_replace_arr_size = 0 Then
  ' upper bound instead of reserve size
  Redim from_str_replace_arr(1)
  Redim to_str_replace_arr(1)

  from_str_replace_arr(0) = "?"
  to_str_replace_arr(0) = "?00"
  from_str_replace_arr(1) = column_separator
  to_str_replace_arr(1) = "?01"

  str_replace_arr_size = 2
End If

Dim shell_obj : Set shell_obj = WScript.CreateObject("WScript.Shell")
Dim StdRegProv_obj : Set StdRegProv_obj = GetObject("winmgmts://./root/default:StdRegProv")

Dim hkey_prefix_str, hkey_prefix_len
Dim hkey_suffix_str
Dim hkey_str, hkey_str_len
Dim hkey_hive
Dim subkey, subkey_arr

Dim param_hkey_pos_arr, param_hkey_pos_arr_ubound
Dim paramkey, paramval

Dim hkey_path_str, paramkey_path_str
Dim print_line
Dim k, is_param_requested_on_hkey

For i = 0 To hkey_str_arr_ubound : Do ' empty `Do-Loop` to emulate `Continue`
  hkey_str = hkey_str_arr(i)
  hkey_str_len = Len(hkey_str)
  hkey_suffix_str = ""

  For j = 0 To hkey_prefix_str_arr_ubound
    hkey_prefix_str = hkey_prefix_str_arr(j)
    hkey_prefix_len = hkey_prefix_len_arr(j)

    If Left(hkey_str, hkey_prefix_len) = hkey_prefix_str And (hkey_prefix_len = hkey_str_len Or Mid(hkey_str, hkey_prefix_len + 1, 1) = "\") Then
      hkey_suffix_str = Mid(hkey_str, hkey_prefix_len + 2)
      hkey_hive = hkey_hive_arr(j)
      Exit For
    End If
  Next

  If hkey_suffix_str = "" Then Exit Do

  StdRegProv_obj.EnumKey hkey_hive, hkey_suffix_str, subkey_arr

  If Not IsNull(subkey_arr) Then
    For Each subkey In subkey_arr
      If Right(hkey_str, 1) <> "\" Then
        hkey_path_str = hkey_str & "\" & subkey
      Else
        hkey_path_str = hkey_str & subkey
      End If

      If in_param_arr_size > 0 Then
        If ParamPerLine Then
          For j = 0 To in_param_arr_size - 1 : Do ' empty `Do-Loop` to emulate `Continue`
            param_hkey_pos_arr = in_param_hkey_pos_arr_arr(j)
            param_hkey_pos_arr_ubound = UBound(param_hkey_pos_arr)

            If param_hkey_pos_arr_ubound >= 0 Then
              is_param_requested_on_hkey = False

              For k = 0 To param_hkey_pos_arr_ubound
                If CInt(param_hkey_pos_arr(k)) = i Then
                  is_param_requested_on_hkey = True
                  Exit For
                End If
              Next

              If Not is_param_requested_on_hkey Then Exit Do
            End If

            print_line = ReplaceStringArr(hkey_path_str, Len(hkey_path_str), str_replace_arr_size, from_str_replace_arr, to_str_replace_arr)

            paramkey = in_param_arr(j)

            print_line = print_line & column_separator & ReplaceStringArr(paramkey, Len(paramkey), str_replace_arr_size, from_str_replace_arr, to_str_replace_arr)

            If Right(hkey_path_str, 1) <> "\" Then
              paramkey_path_str = hkey_path_str & "\" & paramkey
            Else
              paramkey_path_str = hkey_path_str & paramkey
            End If

            paramval = default_value
            On Error Resume Next
            paramval = shell_obj.RegRead(paramkey_path_str)
            On Error Goto 0
            If paramval = "" Then paramval = default_value

            print_line = print_line & column_separator & ReplaceStringArr(paramval, Len(paramval), str_replace_arr_size, from_str_replace_arr, to_str_replace_arr)

            If UnescapeArgs Then
              print_line = Unescape(print_line)
            End If

            stdout_obj.WriteLine print_line
          Loop While False : Next
        Else
          For Each paramkey In in_param_arr
            print_line = ReplaceStringArr(hkey_path_str, Len(hkey_path_str), str_replace_arr_size, from_str_replace_arr, to_str_replace_arr)

            If Right(hkey_path_str, 1) <> "\" Then
              paramkey_path_str = hkey_path_str & "\" & paramkey
            Else
              paramkey_path_str = hkey_path_str & paramkey
            End If

            paramval = default_value
            On Error Resume Next
            paramval = shell_obj.RegRead(paramkey_path_str)
            On Error Goto 0
            If paramval = "" Then paramval = default_value

            print_line = print_line & column_separator & ReplaceStringArr(paramval, Len(paramval), str_replace_arr_size, from_str_replace_arr, to_str_replace_arr)

            If UnescapeArgs Then
              print_line = Unescape(print_line)
            End If

            stdout_obj.WriteLine print_line
          Next
        End If
      Else
        print_line = ReplaceStringArr(hkey_path_str, Len(hkey_path_str), str_replace_arr_size, from_str_replace_arr, to_str_replace_arr)

        If Right(hkey_path_str, 1) <> "\" Then
          paramkey_path_str = hkey_path_str & "\"
        Else
          paramkey_path_str = hkey_path_str
        End If

        paramval = default_value
        On Error Resume Next
        paramval = shell_obj.RegRead(paramkey_path_str)
        On Error Goto 0
        If paramval = "" Then paramval = default_value

        print_line = print_line & column_separator & ReplaceStringArr(paramval, Len(paramval), str_replace_arr_size, from_str_replace_arr, to_str_replace_arr)

        If UnescapeArgs Then
          print_line = Unescape(print_line)
        End If

        stdout_obj.WriteLine print_line
      End If
    Next
  Else
    print_line = ReplaceStringArr(hkey_str, hkey_str_len, str_replace_arr_size, from_str_replace_arr, to_str_replace_arr)

    If UnescapeArgs Then
      print_line = Unescape(print_line)
    End If

    stdout_obj.WriteLine print_line
  End If
Loop While False : Next
