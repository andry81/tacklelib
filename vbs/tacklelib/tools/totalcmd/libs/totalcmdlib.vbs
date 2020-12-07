Import("/__init__.vbs")

Function CleanupTotalcmdButtonbar(ini_file_arr, ini_file_cleanup_arr)
    CleanupTotalcmdButtonbar = Array()

    Dim ini_file_dict_obj : Set ini_file_dict_obj = ReadIniFileLineArrAsDict(ini_file_arr, -1)
    Dim ini_file_cleanup_dict_obj : Set ini_file_cleanup_dict_obj = ReadIniFileLineArrAsDict(ini_file_cleanup_arr, 0)

    If Not ini_file_dict_obj.Exists("Buttonbar") Then Exit Function
    If Not ini_file_cleanup_dict_obj.Exists("Buttonbar") Then Exit Function

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
    key1_prefix_regexp.Pattern = "^\D+"

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
                button_index_arr_size = button_index_arr_size + 1
                GrowArr button_index_arr, button_index_arr_size
                button_index_arr(button_index_arr_size - 1) = key0_suffix_match.Item(0)
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
                button_index_arr_size = button_index_arr_size + 1
                GrowArr button_index_arr, button_index_arr_size
                button_index_arr(button_index_arr_size - 1) = key0_suffix_match.Item(0)
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
            i = i + 1
            GrowArr ini_file_cleanuped_arr, i
            ini_file_cleanuped_arr(i - 1) = "[" & key0 & "]"
        End If
        If ini_file_cleanuped_dict_obj(key0).Count > 0 Then
            For Each key1 In ini_file_cleanuped_dict_obj(key0)
                i = i + 1
                GrowArr ini_file_cleanuped_arr, i
                ini_file_cleanuped_arr(i - 1) = key1 & "=" & ini_file_cleanuped_dict_obj(key0)(key1)
            Next
            i = i + 1
            GrowArr ini_file_cleanuped_arr, i
            ini_file_cleanuped_arr(i - 1) = ""
        End If
    Next

    If i > 0 Then ReDim Preserve ini_file_cleanuped_arr(i - 1) ' upper bound instead of reserve size

    CleanupTotalcmdButtonbar = ini_file_cleanuped_arr
End Function

Function MergeTotalcmdButtonbar(ini_file_to_arr, ini_file_from_arr, insert_from_index, do_make_margin_by_separators_if_not_present)
    MergeTotalcmdButtonbar = Array()

    Dim ini_file_to_dict_obj : Set ini_file_to_dict_obj = ReadIniFileLineArrAsDict(ini_file_to_arr, -1)

    If Not ini_file_to_dict_obj.Exists("Buttonbar") Then Exit Function

    Dim ini_file_from_buttonbar_dict_obj1 : Set ini_file_from_buttonbar_dict_obj1 = CreateObject("Scripting.Dictionary")

    Dim i
    Dim ini_line_from_str
    Dim ini_file_from_arr_ubound : ini_file_from_arr_ubound = UBound(ini_file_from_arr)
    Dim key_
    Dim key_value
    Dim key_value_arr
    Dim section_str
    Dim button_index : button_index = 0
    Dim is_inside_buttonbar_section : is_inside_buttonbar_section = False

    Dim key1_prefix_regexp : Set key1_prefix_regexp = CreateObject("VBScript.RegExp")
    Dim key1_suffix_regexp : Set key1_suffix_regexp = CreateObject("VBScript.RegExp")

    key1_prefix_regexp.Pattern = "^[^{]+"
    key1_suffix_regexp.Pattern = "\{\{BUTTON_INDEX\}\}$"

    ' extract button bar array with expanding into dictionary
    For i = 0 to ini_file_from_arr_ubound : Do ' empty `Do-Loop` to emulate `Continue`
        ini_line_from_str = Trim(ini_file_from_arr(i))

        If ini_line_from_str <> "" Then
            If "[" = Left(ini_line_from_str, 1) Then
                section_str = Trim(Mid(ini_line_from_str, 2, Len(ini_line_from_str) - 2))
                If section_str = "Buttonbar" Then
                    is_inside_buttonbar_section = True
                Else
                    is_inside_buttonbar_section = False
                End If
            ElseIf is_inside_buttonbar_section Then
                If ";" <> Left(ini_line_from_str, 1) Then
                    key_value_arr = Split(ini_line_from_str, "=", 2)
                    If 1 = UBound(key_value_arr) Then
                        key_ = Trim(key_value_arr(0))
                        key_value = Trim(key_value_arr(1))
                        Set key1_prefix_match = key1_prefix_regexp.Execute(key_)
                        Set key1_suffix_match = key1_suffix_regexp.Execute(key_)
                        If key1_prefix_match.Count + key1_suffix_match.Count < 2 Then
                            ini_file_from_buttonbar_dict_obj1(key_) = key_value
                            Exit Do
                        End If

                        ini_file_from_buttonbar_dict_obj1(key1_prefix_match.Item(0) & CStr(button_index)) = key_value
                    End If
                Else
                    If InStr(ini_line_from_str, "%%[BUTTON]") > 0 Then
                        button_index = button_index + 1
                    End If
                End If
            End If
        End If
    Loop While False : Next

    Dim ini_file_in_to_buttonbar_dict_obj1 : Set ini_file_in_to_buttonbar_dict_obj1 = ini_file_to_dict_obj("Buttonbar")
    Dim ini_file_out_to_buttonbar_dict_obj1 : Set ini_file_out_to_buttonbar_dict_obj1 = CreateObject("Scripting.Dictionary")

    Dim key0_prefix_regexp : Set key0_prefix_regexp = CreateObject("VBScript.RegExp")
    Dim key0_suffix_regexp : Set key0_suffix_regexp = CreateObject("VBScript.RegExp")
    Dim key0_prefix_match, key0_suffix_match

    key0_prefix_regexp.Pattern = "^\D+"
    key0_suffix_regexp.Pattern = "\d+$"
    key1_prefix_regexp.Pattern = "^\D+"
    key1_suffix_regexp.Pattern = "\d+$"

    Dim key0, key1
    Dim prev_button_index : prev_button_index = -1
    Dim next_button_index : next_button_index = 0

    ' count buttons
    Dim num_in_to_buttons : num_in_to_buttons = 0
    Dim num_from_buttons : num_from_buttons = 0

    For Each key0 In ini_file_in_to_buttonbar_dict_obj1.Keys() : Do ' empty `Do-Loop` to emulate `Continue`
        Set key0_prefix_match = key0_prefix_regexp.Execute(key0)
        If key0_prefix_match.Count < 1 Then Exit Do

        Set key0_suffix_match = key0_suffix_regexp.Execute(key0)
        If key0_suffix_match.Count >= 1 Then
            button_index = key0_suffix_match.Item(0)
            If prev_button_index <> button_index Then
                next_button_index = next_button_index + 1
                prev_button_index = button_index
            End If
        End If
    Loop While False : Next

    num_in_to_buttons = next_button_index

    prev_button_index = -1
    next_button_index = 0

    For Each key1 In ini_file_from_buttonbar_dict_obj1.Keys() : Do ' empty `Do-Loop` to emulate `Continue`
        Set key1_prefix_match = key1_prefix_regexp.Execute(key1)
        If key1_prefix_match.Count < 1 Then Exit Do

        Set key1_suffix_match = key1_suffix_regexp.Execute(key1)
        If key1_suffix_match.Count >= 1 Then
            button_index = key1_suffix_match.Item(0)
            If prev_button_index <> button_index Then
                next_button_index = next_button_index + 1
                prev_button_index = button_index
            End If
        End If
    Loop While False : Next

    num_from_buttons = next_button_index

    ' negative index counts from the end
    Dim insert_buttonbar_from_index : insert_buttonbar_from_index = insert_from_index
    If insert_buttonbar_from_index < 0 Then
        insert_buttonbar_from_index = num_in_to_buttons + insert_from_index + 2
        If insert_buttonbar_from_index < 0 Then insert_buttonbar_from_index = 0
    ElseIf num_in_to_buttons < insert_buttonbar_from_index Then
        insert_buttonbar_from_index = num_in_to_buttons + 1
    End If

    prev_button_index = -1
    next_button_index = 0

    Dim num_inserted_buttons : num_inserted_buttons = 0
    Dim is_prev_button_separator : is_prev_button_separator = False

    ' merge button bars
    For Each key0 In ini_file_in_to_buttonbar_dict_obj1.Keys() : Do ' empty `Do-Loop` to emulate `Continue`
        Set key0_prefix_match = key0_prefix_regexp.Execute(key0)
        If key0_prefix_match.Count < 1 Then Exit Do

        Set key0_suffix_match = key0_suffix_regexp.Execute(key0)
        If key0_suffix_match.Count < 1 Then
            ini_file_out_to_buttonbar_dict_obj1(key0) = ini_file_in_to_buttonbar_dict_obj1(key0)
        Else
            button_index = key0_suffix_match.Item(0)
            If prev_button_index <> button_index Then
                If next_button_index + 1 >= insert_buttonbar_from_index Then Exit For
                next_button_index = next_button_index + 1
                prev_button_index = button_index
                num_inserted_buttons = num_inserted_buttons + 1
                is_prev_button_separator = False
            End If

            key_ = key0_prefix_match.Item(0)
            key_value = ini_file_in_to_buttonbar_dict_obj1(key0)
            ini_file_out_to_buttonbar_dict_obj1(key_ & CStr(next_button_index)) = key_value

            If "button" = key_ And "" = key_value Then is_prev_button_separator = True
        End If
    Loop While False : Next

    If num_from_buttons > 0 Then
        prev_button_index = -1

        If do_make_margin_by_separators_if_not_present And next_button_index > 0 And Not is_prev_button_separator Then
            next_button_index = next_button_index + 1
            ini_file_out_to_buttonbar_dict_obj1("button" & CStr(next_button_index)) = ""
            num_inserted_buttons = num_inserted_buttons + 1
        End If

        For Each key1 In ini_file_from_buttonbar_dict_obj1.Keys() : Do ' empty `Do-Loop` to emulate `Continue`
            Set key1_prefix_match = key1_prefix_regexp.Execute(key1)
            If key1_prefix_match.Count < 1 Then Exit Do

            Set key1_suffix_match = key1_suffix_regexp.Execute(key1)
            If key1_suffix_match.Count >= 1 Then
                button_index = key1_suffix_match.Item(0)
                If prev_button_index <> button_index Then
                    next_button_index = next_button_index + 1
                    prev_button_index = button_index
                    num_inserted_buttons = num_inserted_buttons + 1
                End If

                key_ = key1_prefix_match.Item(0)
                key_value = ini_file_from_buttonbar_dict_obj1(key1)
                ini_file_out_to_buttonbar_dict_obj1(key_ & CStr(next_button_index)) = key_value
            End If
        Loop While False : Next
    End If

    Dim is_surround_separator_processed : is_surround_separator_processed = False

    prev_button_index = -1
    next_button_index = 0

    For Each key0 In ini_file_in_to_buttonbar_dict_obj1.Keys() : Do ' empty `Do-Loop` to emulate `Continue`
        Set key0_prefix_match = key0_prefix_regexp.Execute(key0)
        If key0_prefix_match.Count < 1 Then Exit Do

        Set key0_suffix_match = key0_suffix_regexp.Execute(key0)
        If key0_suffix_match.Count < 1 Then
            If next_button_index >= insert_buttonbar_from_index Then
                ini_file_out_to_buttonbar_dict_obj1(key0) = ini_file_in_to_buttonbar_dict_obj1(key0)
            End If
        Else
            button_index = key0_suffix_match.Item(0)

            If prev_button_index <> button_index Then
                next_button_index = next_button_index + 1
                prev_button_index = button_index

                If Not is_surround_separator_processed And next_button_index >= insert_buttonbar_from_index Then
                    If do_make_margin_by_separators_if_not_present And ini_file_in_to_buttonbar_dict_obj1.Exists("button" & CStr(button_index)) Then
                        If ini_file_in_to_buttonbar_dict_obj1("button" & CStr(button_index)) <> "" Then
                            num_inserted_buttons = num_inserted_buttons + 1
                            ini_file_out_to_buttonbar_dict_obj1("button" & CStr(num_inserted_buttons)) = ""
                        End If
                    End If
                    is_surround_separator_processed = True
                End If

                If next_button_index >= insert_buttonbar_from_index Then
                    num_inserted_buttons = num_inserted_buttons + 1
                End If
            End If

            If next_button_index >= insert_buttonbar_from_index Then
                key_ = key0_prefix_match.Item(0)
                key_value = ini_file_in_to_buttonbar_dict_obj1(key0)
                ini_file_out_to_buttonbar_dict_obj1(key_ & CStr(num_inserted_buttons)) = key_value
            End If
        End If
    Loop While False : Next

    ini_file_out_to_buttonbar_dict_obj1("Buttoncount") = num_inserted_buttons

    ' rebuild dictionary
    Dim ini_file_out_to_dict_obj : Set ini_file_out_to_dict_obj = CreateObject("Scripting.Dictionary")

    For Each key0 In ini_file_to_dict_obj.Keys()
        If key0 = "Buttonbar" Then
            Set ini_file_out_to_dict_obj(key0) = ini_file_out_to_buttonbar_dict_obj1
        Else
            Set ini_file_out_to_dict_obj(key0) = ini_file_to_dict_obj(key0)
        End If
    Next

    ' generate array
    Dim ini_file_out_to_arr : ini_file_out_to_arr = Array()

    i = 0
    For Each key0 In ini_file_out_to_dict_obj.Keys()
        If key0 <> "" Then
            i = i + 1
            GrowArr ini_file_out_to_arr, i
            ini_file_out_to_arr(i - 1) = "[" & key0 & "]"
        End If
        If ini_file_out_to_dict_obj(key0).Count > 0 Then
            For Each key1 In ini_file_out_to_dict_obj(key0)
                i = i + 1
                GrowArr ini_file_out_to_arr, i
                ini_file_out_to_arr(i - 1) = key1 & "=" & ini_file_out_to_dict_obj(key0)(key1)
            Next
            i = i + 1
            GrowArr ini_file_out_to_arr, i
            ini_file_out_to_arr(i - 1) = ""
        End If
    Next

    If i > 0 Then ReDim Preserve ini_file_out_to_arr(i - 1) ' upper bound instead of reserve size

    MergeTotalcmdButtonbar = ini_file_out_to_arr
End Function
