Import("/__init__.vbs")

Function CleanupTotalcmdButtonbar(ini_file_arr, ini_file_cleanup_arr)
    Set CleanupTotalcmdButtonbar = Nothing

    Dim ini_file_dict_obj : Set ini_file_dict_obj = ReadIniFileLineArrAsDict(ini_file_arr, -1)
    Dim ini_file_cleanup_dict_obj : Set ini_file_cleanup_dict_obj = ReadIniFileLineArrAsDict(ini_file_cleanup_arr, 0)

    If Not ini_file_dict_obj.Exists("Buttonbar") Then Return
    If Not ini_file_cleanup_dict_obj.Exists("Buttonbar") Then Return

    Dim button_index_arr : button_index_arr = Array()
    Dim button_index_arr_size : button_index_arr_size = 0

    Dim ini_file_dict_obj1 : Set ini_file_dict_obj1 = ini_file_dict_obj("Buttonbar")
    Dim ini_file_cleanup_dict_obj1 : Set ini_file_cleanup_dict_obj1 = ini_file_cleanup_dict_obj("Buttonbar")

    Dim key0_prefix_regexp : Set key0_prefix_regexp = CreateObject("VBScript.RegExp")
    Dim key0_suffix_regexp : Set key0_suffix_regexp = CreateObject("VBScript.RegExp")
    Dim key1_prefix_regexp : Set key1_prefix_regexp = CreateObject("VBScript.RegExp")
    Dim key0_prefix_match, key0_suffix_match, key1_prefix_match
    Dim key_value0, key_value1

    key0_prefix_regexp.Pattern = "^\D+"
    key0_suffix_regexp.Pattern = "\d+$"
    key1_prefix_regexp.Pattern = "^(\D+)"

    Dim do_remove_trailing_separators_after_index : do_remove_trailing_separators_after_index = -1

    ' empty `Do-Loop` to emulate `Continue`
    For Each key0 In ini_file_dict_obj1.Keys() : Do
        Set key0_prefix_match = key0_prefix_regexp.Execute(key0)
        Set key0_suffix_match = key0_suffix_regexp.Execute(key0)
        If key0_prefix_match.Count + key0_suffix_match.Count < 2 Then Exit Do

        key_value0 = ini_file_dict_obj1(key0)

        For Each key1 In ini_file_cleanup_dict_obj1.Keys() : Do
            Set key1_prefix_match = key1_prefix_regexp.Execute(key1)
            If key1_prefix_match.Count = 0 Then Exit Do
            If key0_prefix_match.Item(0) <> key1_prefix_match.Item(0) Then Exit Do

            key_value1 = ini_file_cleanup_dict_obj1(key1)
            If InStr(key_value0, key_value1) > 0 Then
                GrowArr button_index_arr, button_index_arr_size
                button_index_arr(button_index_arr_size) = key0_suffix_match.Item(0)
                button_index_arr_size = button_index_arr_size + 1
                do_remove_trailing_separators_after_index = key0_suffix_match.Item(0)
                Exit For
            ElseIf do_remove_trailing_separators_after_index >= 0 And do_remove_trailing_separators_after_index <> key0_suffix_match.Item(0) Then
                do_remove_trailing_separators_after_index = -1
            End If
        Loop While False : Next

        ' include trailing separators
        If do_remove_trailing_separators_after_index >= 0 And key0_prefix_match.Item(0) = "button" And key_value0 = "" Then
            do_remove_trailing_separators_after_index = do_remove_trailing_separators_after_index + 1
            If key0_suffix_match.Item(0) = CStr(do_remove_trailing_separators_after_index) Then
                GrowArr button_index_arr, button_index_arr_size
                button_index_arr(button_index_arr_size) = key0_suffix_match.Item(0)
                button_index_arr_size = button_index_arr_size + 1
            Else
                do_remove_trailing_separators_after_index = -1
            End If
        End If
    Loop While False : Next

    If button_index_arr_size > 0 Then ReDim Preserve button_index_arr(button_index_arr_size - 1) ' upper bound instead of reserve size

    ' renumber buttons
    Dim ini_file_buttonbar_cleanuped_dict_obj : Set ini_file_buttonbar_cleanuped_dict_obj = CreateObject("Scripting.Dictionary")
    Dim prev_button_index : prev_button_index = -1
    Dim next_button_index : next_button_index = 0
    Dim button_index

    For Each key0 In ini_file_dict_obj1.Keys() : Do
        Set key0_suffix_match = key0_suffix_regexp.Execute(key0)
        If key0_suffix_match.Count < 1 Then
            ini_file_buttonbar_cleanuped_dict_obj(key0) = ini_file_dict_obj1(key0)
        Else
            button_index = key0_suffix_match.Item(0)
            If Not FindArrValue(button_index_arr, button_index) Then
                If prev_button_index <> button_index Then
                    next_button_index = next_button_index + 1
                    prev_button_index = button_index
                End If

                Set key0_prefix_match = key0_prefix_regexp.Execute(key0)
                ini_file_buttonbar_cleanuped_dict_obj(key0_prefix_match.Item(0) & CStr(next_button_index)) = ini_file_dict_obj1(key0)
            End If
        End If
    Loop While False : Next

    ini_file_buttonbar_cleanuped_dict_obj("Buttoncount") = next_button_index

    ' rebuild dictionary
    Dim ini_file_cleanuped_dict_obj : Set ini_file_cleanuped_dict_obj = CreateObject("Scripting.Dictionary")

    For Each key0 In ini_file_dict_obj.Keys()
        If key0 = "Buttonbar" Then
            Set ini_file_cleanuped_dict_obj(key0) = ini_file_buttonbar_cleanuped_dict_obj
        Else
            Set ini_file_cleanuped_dict_obj(key0) = ini_file_dict_obj(key0)
        End If
    Next

    ' generate array
    Dim ini_file_cleanuped_arr : ini_file_cleanuped_arr = Array()

    Dim i : i = 0
    For Each key0 In ini_file_cleanuped_dict_obj.Keys()
        If key0 <> "" Then
            GrowArr ini_file_cleanuped_arr, i + 1
            ini_file_cleanuped_arr(i) = "[" & key0 & "]"
            i = i + 1
        End If
        If ini_file_cleanuped_dict_obj(key0).Count > 0 Then
            For Each key1 In ini_file_cleanuped_dict_obj(key0)
                GrowArr ini_file_cleanuped_arr, i + 1
                ini_file_cleanuped_arr(i) = key1 & "=" & ini_file_cleanuped_dict_obj(key0)(key1)
                i = i + 1
            Next
            GrowArr ini_file_cleanuped_arr, i + 1
            ini_file_cleanuped_arr(i) = ""
            i = i + 1
        End If
    Next

    If i > 0 Then ReDim Preserve ini_file_cleanuped_arr(i - 1) ' upper bound instead of reserve size

    CleanupTotalcmdButtonbar = ini_file_cleanuped_arr
End Function
