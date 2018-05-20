If InStr(LCase(WScript.FullName),"syswow64") Then
  CreateObject("WScript.Shell").Run """%systemroot%\sysnative\wscript.exe"" """ & WScript.ScriptFullName & """"
  WScript.Quit
End If
Set oShell = CreateObject("Shell.Application")  
 oShell.ShellExecute "powershell", "-WindowStyle Hidden -nologo -noprofile -NonInteractive -executionpolicy bypass C:\VMware_IT\Installs\Show-Progress.ps1", "", "runas", 0