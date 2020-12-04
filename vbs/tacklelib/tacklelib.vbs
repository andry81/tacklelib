Sub PrintLine(str)
    Dim fs_obj : Set fs_obj = CreateObject ("Scripting.FileSystemObject")
    Dim stdout_obj : Set stdout_obj = fs_obj.GetStandardStream(1)

    On Error Resume Next
    stdout_obj.WriteLine str
    On Error Goto 0
End Sub

Sub Print(str)
    Dim fs_obj : Set fs_obj = CreateObject ("Scripting.FileSystemObject")
    Dim stdout_obj : Set stdout_obj = fs_obj.GetStandardStream(1)

    On Error Resume Next
    stdout_obj.Write str
    On Error Goto 0
End Sub

Sub PrintLineArr(arr, is_trim_empty)
    Dim fs_obj : Set fs_obj = CreateObject ("Scripting.FileSystemObject")
    Dim stdout_obj : Set stdout_obj = fs_obj.GetStandardStream(1)

    On Error Resume Next
    Dim i
    Dim line_str
    For i = 0 to Ubound(arr)
        If is_trim_empty Then
          line_str = Trim(arr(i))
        Else
          line_str = arr(i)
        End If
        If Not is_trim_empty Or line_str <> "" Then
            stdout_obj.WriteLine arr(i)
        End If
    Next
    On Error Goto 0
End Sub

Sub PrintArr(arr, separator_str, is_trim_empty)
    Dim fs_obj : Set fs_obj = CreateObject ("Scripting.FileSystemObject")
    Dim stdout_obj : Set stdout_obj = fs_obj.GetStandardStream(1)

    On Error Resume Next
    Dim i
    Dim line_str
    For i = 0 to Ubound(arr)
        If is_trim_empty Then
          line_str = Trim(arr(i))
        Else
          line_str = arr(i)
        End If
        If Not is_trim_empty Or line_str <> "" Then
          If separator_str <> "" And i > 0 Then
            stdout_obj.Write separator_str
          End If
          stdout_obj.Write arr(i)
        End If
    Next
    On Error Goto 0
End Sub

Function ReadFileLinesAsArr(file_path_str)
    Set ReadFileLinesAsArr = Nothing

    Dim fs_obj : Set fs_obj = CreateObject("Scripting.FileSystemObject")

    Dim file_obj : Set file_obj = fs_obj.OpenTextFile(file_path_str)

    Dim line_arr
    If Not file_obj.AtEndOfStream Then
        line_arr = Split(file_obj.ReadAll(), vbCrLf)

        Dim upper_bound : upper_bound = UBound(line_arr)
        If upper_bound >= 0 And line_arr(upper_bound) = "" Then
            ReDim Preserve line_arr(upper_bound)
        End If
    Else
        line_arr = Array()
    End If

    ReadFileLinesAsArr = line_arr
End Function

Sub WriteFileLinesFromArr(file_path_str, line_arr, do_truncate)
    Const ForReading = 1, ForWriting = 2, ForAppending = 8

    Dim fs_obj : Set fs_obj = CreateObject("Scripting.FileSystemObject")

    Dim file_obj
    If fs_obj.FileExists(file_path_str) Then
        If do_truncate Then
            Set file_obj = fs_obj.OpenTextFile(file_path_str, ForWriting)
        Else
            Set file_obj = fs_obj.OpenTextFile(file_path_str, ForAppending)
        End If
    Else
        Set file_obj = fs_obj.CreateTextFile(file_path_str)
    End If

    For i = 0 to Ubound(line_arr)
        file_obj.WriteLine line_arr(i)
    Next
End Sub

Function ReadIniFileAsStr(file_path_str)
    Set ReadIniFileAsStr = Nothing

    Dim fs_obj : Set fs_obj = CreateObject("Scripting.FileSystemObject")
    Dim dict_obj : Set dict_obj = CreateObject("Scripting.Dictionary")

    Dim ini_file_obj : Set ini_file_obj = fs_obj.OpenTextFile(file_path_str)
    If Not ini_file_obj.AtEndOfStream Then
        ReadIniFileAsStr = ini_file_obj.ReadAll()
    Else
        ReadIniFileAsStr = ""
    End If
End Function

Function ReadIniFileAsDict(file_path_str)
    Set ReadIniFileAsDict = ReadIniFileLineArrAsDict(ReadFileLinesAsArr(file_path_str))
End Function

Function ReadIniFileLineArrAsDict(ini_line_arr)
    Set ReadIniFileLineArrAsDict = Nothing

    Dim dict_obj : Set dict_obj = CreateObject("Scripting.Dictionary")

    Dim i
    Dim ini_line_str
    Dim section_str : section_str = ""
    Dim key_value_arr

    Set dict_obj("") = CreateObject("Scripting.Dictionary")

    For i = 0 to Ubound(ini_line_arr)
        ini_line_str = Trim(ini_line_arr(i))
        If ini_line_str <> "" Then
            If "[" = Left(ini_line_str, 1) Then
                section_str = Trim(Mid(ini_line_str, 2, Len(ini_line_str) - 2))
                If section_str <> "" Then
                    Set dict_obj(section_str) = CreateObject("Scripting.Dictionary")
                End If
            ElseIf ";" <> Left(ini_line_str, 1) Then
                key_value_arr = Split(ini_line_str, "=", 2)
                If 1 = UBound(key_value_arr) Then
                    dict_obj(section_str)(Trim(key_value_arr(0))) = Trim(key_value_arr(1))
                End If
            End If
        End If
    Next

    Set ReadIniFileLineArrAsDict = dict_obj
End Function

Function PrintIniFileDict(dict_obj)
    Dim section_str

    For Each section_str In dict_obj.Keys()
        If section_str <> "" Then
            PrintLine("[" & section_str & "]")
        End If
        PrintIniFileSectionDict(dict_obj(section_str))
    Next
End Function

Function PrintIniFileSectionDict(section_dict_obj)
    Dim key_

    For Each key_ In section_dict_obj.Keys()
        PrintLine(CStr(key_) & "=" & section_dict_obj(key_))
    Next
End Function

Function GetIniFileKey(file_path_str, section_str, key_)
    Dim dict_obj : Set dict_obj = ReadIniFileAsDict(file_path_str)
    GetIniFileKey = dict_obj(section_str)(key_)
End Function

Function GetIniFileKey_NoExcept(file_path_str, section_str, key_)
    Dim dict_obj : Set dict_obj = ReadIniFileAsDict(file_path_str)
    On Error Resume Next
    GetIniFileKey_NoExcept = dict_obj(section_str)(key_)
    On Error Goto 0
End Function

Function FindArrValue(arr, value)
    FindArrValue = False

    Dim i
    For i = 0 to Ubound(arr)
        If arr(i) = value Then
            FindArrValue = True
            Exit Function
        End If
    Next
End Function

' INFO:
'   Workaround to avoid error `runtime error: Object required: '[undefined]'` around invalid `And` condition parse: `If dict_obj.Exists(key_) And dict_obj(key_).Count = 0 Then`, where
'   the `dict_obj(key_).Count` expression DOES evaluate even if the `dict_obj.Exists(key_)` expression is `False`.
Function GetDictCount(dict_obj, key_)
    On Error Resume Next
    GetDictCount = dict_obj(key_).Count
    On Error Goto 0
End Function

Function PrintFileLines(file_path_str)
    PrintFileLines = 0

    Dim num_lines
    Dim line_str

    Dim fs_obj : Set fs_obj = CreateObject("Scripting.FileSystemObject")
    Dim file_obj : Set file_obj = fs_obj.OpenTextFile(file_path_str)

    Do Until file_obj.AtEndOfStream
        line_str = file_obj.ReadLine()
        PrintLine(CStr(file_obj.Line - 1) & ": " & line_str)
        num_lines = num_lines + 1
    Loop

    file_obj.Close

    PrintFileLines = num_lines
End Function

Function DeleteIniFileArr(ini_file_arr, ini_file_cleanup_arr, do_remove_all_keys_instead_remove_section, do_remove_section_non_key_lines)
    Set DeleteIniFileArr = Nothing

    Dim ini_file_arr_ubound : ini_file_arr_ubound = UBound(ini_file_arr)
    Dim ini_file_out_arr
    ReDim ini_file_out_arr(ini_file_arr_ubound + 1)
    Dim i, j : j = 0
    Dim ini_line_str
    Dim section_str
    Dim key_value_arr
    Dim from_dict_key1
    Dim is_section_to_cleanup : is_section_to_cleanup = False
    Dim do_ignore_blank_lines_after_removed_key : do_ignore_blank_lines_after_removed_key = False

    Dim ini_file_cleanup_dict_obj : Set ini_file_cleanup_dict_obj = ReadIniFileLineArrAsDict(ini_file_cleanup_arr)

    For i = 0 to ini_file_arr_ubound
        ini_line_str = Trim(ini_file_arr(i))

        If ini_line_str <> "" And "[" = Left(ini_line_str, 1) Then
            do_ignore_blank_lines_after_removed_key = False
            section_str = Trim(Mid(ini_line_str, 2, Len(ini_line_str) - 2))
            If section_str <> "" And ini_file_cleanup_dict_obj.Exists(section_str) And GetDictCount(ini_file_cleanup_dict_obj, section_str) = 0 Then
                is_section_to_cleanup = True
            Else
                is_section_to_cleanup = False
            End If
            If (Not is_section_to_cleanup) Or do_remove_all_keys_instead_remove_section Then
                ini_file_out_arr(j) = ini_file_arr(i)
                j = j + 1
            End If
        ElseIf Not is_section_to_cleanup Then
            If ini_line_str <> "" And ini_file_cleanup_dict_obj.Exists(section_str) And GetDictCount(ini_file_cleanup_dict_obj, section_str) <> 0 Then
                If ";" = Left(ini_line_str, 1) Then
                    ini_file_out_arr(j) = ini_file_arr(i)
                    j = j + 1
                Else
                    key_value_arr = Split(ini_line_str, "=", 2)
                    If 1 = UBound(key_value_arr) Then
                        from_dict_key1 = Trim(key_value_arr(0))
                        If Not ini_file_cleanup_dict_obj(section_str).Exists(from_dict_key1) Then
                            do_ignore_blank_lines_after_removed_key = False
                            ini_file_out_arr(j) = ini_file_arr(i)
                            j = j + 1
                        Else
                            ' remove all blank lines below if was at least one blank line above
                            If j > 0 And i < ini_file_arr_ubound Then
                                If Trim(ini_file_out_arr(j - 1)) = "" And Trim(ini_file_in_arr(i + 1)) = "" Then
                                    do_ignore_blank_lines_after_removed_key = True
                                End If
                            End If
                        End If
                    Else
                        do_ignore_blank_lines_after_removed_key = False
                        ini_file_out_arr(j) = ini_file_arr(i)
                        j = j + 1
                    End If
                End If
            Else
                If ini_line_str <> "" Or Not do_ignore_blank_lines_after_removed_key Then
                    ini_file_out_arr(j) = ini_file_arr(i)
                    j = j + 1
                End If
                If ini_line_str <> "" Then
                    do_ignore_blank_lines_after_removed_key = False
                End If
            End If
        ElseIf do_remove_all_keys_instead_remove_section Then
            If Not do_remove_section_non_key_lines Then
                If ini_line_str <> "" Then
                    If ";" = Left(ini_line_str, 1) Then
                        ini_file_out_arr(j) = ini_file_arr(i)
                        j = j + 1
                    Else
                        key_value_arr = Split(ini_line_str, "=", 2)
                        If 0 = UBound(key_value_arr) Then
                            ini_file_out_arr(j) = ini_file_arr(i)
                            j = j + 1
                        End If
                    End If
                Else
                    If Not do_ignore_blank_lines_after_removed_key Then
                        ini_file_out_arr(j) = ini_file_arr(i)
                        j = j + 1
                    Else
                        do_ignore_blank_lines_after_removed_key = False
                    End If
                End If
            End If
        End If
    Next

    ' remove trailing empty line
    If j > 0 Then
        If Trim(ini_file_out_arr(j - 1)) = "" Then
            j = j - 1
        End If
    End If

    ReDim Preserve ini_file_out_arr(j)

    DeleteIniFileArr = ini_file_out_arr
End Function

Function MergeIniFileArr(ini_file_to_arr, ini_file_from_arr, do_append_empty_line_before_append_to_section)
    Set MergeIniFileArr = Nothing

    Dim ini_file_to_arr_ubound : ini_file_to_arr_ubound = UBound(ini_file_to_arr)
    Dim ini_file_out_arr
    ReDim ini_file_out_arr(ini_file_to_arr_ubound + UBound(ini_file_from_arr) * 2 + 2) ' include empty lines
    Dim i, j : j = 0
    Dim ini_line_str
    Dim section_str : section_str = ""
    Dim key_value_arr
    Dim from_dict_key0, from_dict_key1
    Dim tmp_dict_obj

    Dim ini_file_from_dict_obj : Set ini_file_from_dict_obj = ReadIniFileLineArrAsDict(ini_file_from_arr)

    Dim is_section_to_merge

    If GetDictCount(ini_file_from_dict_obj, "") <> 0 Then
        is_section_to_merge = True
    Else
        is_section_to_merge = False
    End If

    For i = 0 to ini_file_to_arr_ubound
        ini_line_str = Trim(ini_file_to_arr(i))

        If ini_line_str <> "" And "[" = Left(ini_line_str, 1) Then
            ' remove trailing empty line
            If j > 0 Then
                If Trim(ini_file_out_arr(j - 1)) = "" Then
                    j = j - 1
                End If
            End If

            If ini_file_from_dict_obj.Exists(section_str) Then
                Set tmp_dict_obj = ini_file_from_dict_obj(section_str)
                If tmp_dict_obj.Count <> 0 Then
                    If do_append_empty_line_before_append_to_section Then
                        ' append trailing empty line
                        If j > 0 Then
                            If Trim(ini_file_out_arr(j - 1)) <> "" Then
                                ini_file_out_arr(j) = ""
                                j = j + 1
                            End If
                        End If
                    End If

                    For Each from_dict_key1 In tmp_dict_obj.Keys()
                        ini_file_out_arr(j) = CStr(from_dict_key1) & "=" & tmp_dict_obj(from_dict_key1)
                        j = j + 1
                        ini_file_from_dict_obj(section_str).Remove(from_dict_key1)
                    Next
                    If GetDictCount(ini_file_from_dict_obj, section_str) = 0 Then
                        ini_file_from_dict_obj.Remove(section_str)
                    End If
                ElseIf GetDictCount(ini_file_from_dict_obj, section_str) = 0 Then
                    ini_file_from_dict_obj.Remove(section_str)
                End If
            End If

            ' merge next section
            section_str = Trim(Mid(ini_line_str, 2, Len(ini_line_str) - 2))
            If section_str <> "" And ini_file_from_dict_obj.Exists(section_str) Then
                is_section_to_merge = True
            Else
                is_section_to_merge = False
            End If

            ' append trailing empty line
            If j > 0 Then
                If Trim(ini_file_out_arr(j - 1)) <> "" Then
                    ini_file_out_arr(j) = ""
                    j = j + 1
                End If
            End If

            ini_file_out_arr(j) = ini_file_to_arr(i)
            j = j + 1
        ElseIf Not is_section_to_merge Then
            ini_file_out_arr(j) = ini_file_to_arr(i)
            j = j + 1
        Else
            If ini_line_str <> "" Then
                If ";" = Left(ini_line_str, 1) Then
                    ini_file_out_arr(j) = ini_file_to_arr(i)
                    j = j + 1
                Else
                    key_value_arr = Split(ini_line_str, "=", 2)
                    If 0 = UBound(key_value_arr) Then
                        ini_file_out_arr(j) = ini_file_to_arr(i)
                        j = j + 1
                    Else
                        from_dict_key1 = Trim(key_value_arr(0))
                        If ini_file_from_dict_obj(section_str).Exists(from_dict_key1) Then
                            ini_file_out_arr(j) = CStr(from_dict_key1) & "=" & ini_file_from_dict_obj(section_str)(from_dict_key1)
                            j = j + 1

                            ini_file_from_dict_obj(section_str).Remove(from_dict_key1)
                            If GetDictCount(ini_file_from_dict_obj, section_str) = 0 Then
                                ini_file_from_dict_obj.Remove(section_str)
                            End If
                        Else
                            ini_file_out_arr(j) = ini_file_to_arr(i)
                            j = j + 1
                        End If
                    End If
                End If
            Else
                ini_file_out_arr(j) = ini_file_to_arr(i)
                j = j + 1
            End If
        End If
    Next

    ' merge remaining sections
    For Each from_dict_key0 In ini_file_from_dict_obj.Keys()
        ' remove trailing empty line
        If j > 0 Then
            If Trim(ini_file_out_arr(j - 1)) = "" Then
                j = j - 1
            End If
        End If

        If from_dict_key0 <> "" Then
            ' append trailing empty line
            If j > 0 Then
                If Trim(ini_file_out_arr(j - 1)) <> "" Then
                    ini_file_out_arr(j) = ""
                    j = j + 1
                End If
            End If

            ini_file_out_arr(j) = "[" + CStr(from_dict_key0) & "]"
            j = j + 1
        End If

        If GetDictCount(ini_file_from_dict_obj, from_dict_key0) <> 0 Then
            If do_append_empty_line_before_append_to_section And from_dict_key0 = "" Then
                ' append trailing empty line
                If j > 0 Then
                    If Trim(ini_file_out_arr(j - 1)) <> "" Then
                        ini_file_out_arr(j) = ""
                        j = j + 1
                    End If
                End If
            End If

            For Each from_dict_key1 In ini_file_from_dict_obj(from_dict_key0).Keys()
                ini_file_out_arr(j) = CStr(from_dict_key1) & "=" & ini_file_from_dict_obj(from_dict_key0)(from_dict_key1)
                j = j + 1
            Next

            ini_file_out_arr(j) = ""
            j = j + 1
        End If
    Next

    ' remove trailing empty line
    If j > 0 Then
        If Trim(ini_file_out_arr(j - 1)) = "" Then
            j = j - 1
        End If
    End If

    ReDim Preserve ini_file_out_arr(j)

    MergeIniFileArr = ini_file_out_arr
End Function
