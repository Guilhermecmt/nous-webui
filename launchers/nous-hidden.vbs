' Nous - inicia o servidor SEM janela de console (usado pelo atalho/iniciar.bat).
' Nao precisa de ps2exe: roda o start-nous.ps1 escondido (window style 0).
Dim sh, fso, dir
Set sh  = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
dir = fso.GetParentFolderName(WScript.ScriptFullName)
sh.Run "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & dir & "\start-nous.ps1""", 0, False
