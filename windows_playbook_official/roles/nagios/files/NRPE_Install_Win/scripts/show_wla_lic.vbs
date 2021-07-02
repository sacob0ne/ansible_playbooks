Dim WshShell, oExec, Found

Set objArgs = WScript.Arguments

Set wshShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

Set objInPutFile = objFSO.OpenTextFile("C:\Program Files\NSClient++\scripts\wla_lic.txt")

Found = false

REM WScript.Echo objArgs.Count

strLIC = chr(34) & objArgs(0) & chr(34)

if objArgs.Count = 1 then
	strVER = chr(34) & chr(34)
else
	strVER = chr(34) & objArgs(1) & chr(34)

end if

'WScript.Echo "Searching: " & strLIC & " Version: " & strVER

Do until objInPutFile.AtEndOfStream

	strwla = objInPutFile.ReadLine
	strwla = Trim(strwla)

	If inStr(strwla,strLIC) Then

		Found = true

	End if

	if inStr(strwla,"Feature version") and Not inStr(strwla,strVER) Then

		Found = false

	End if

	If inStr(strwla,"Allowed on VM") Then

		Found = false

	End if

	if Found = true Then

		if Not IsEmpty(strwla) and Not IsNull(strwla) and Len(strwla) > 0 Then

			if inStr(strwla,"Feature") or inStr(strwla,"tokens") or inStr(strwla,"Expiration") or inStr(strwla,"concurrent") Then
				prtwla = Mid(strwla,4)
				WScript.Echo prtwla
			End if
		End if
	End if

Loop

objInPutFile.close