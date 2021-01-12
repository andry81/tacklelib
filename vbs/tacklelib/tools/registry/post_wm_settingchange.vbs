Set objShell = WScript.CreateObject("WScript.Shell")
Set objSystemEnv = objShell.Environment("System")
' triggers WM_SETTINGCHANGE
objSystemEnv("Path") = objSystemEnv("Path")
