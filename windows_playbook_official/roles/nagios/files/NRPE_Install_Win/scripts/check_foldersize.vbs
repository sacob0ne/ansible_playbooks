'Create Marek Pastier 18.03.2010
'Easy script for check space folder. You need NRPE_NT daemon on win computer
'##########################################################'
'Install'
'##########################################################'
'1.copy file to c:\ for example... c:\nrpe_nt\bin\check_folder_size.vbs'
'2.set your nrpe.cfg for command for example 
'command[check_foldersize]=c:\windows\system32\cscript.exe //NoLogo //T:30 c:\nrpe_nt\bin\check_folder_size.vbs c:\yourfolder 50 78
'50 70 are parameters for warning and critical value in MB'
'3.restart your nrpe_nt daemon in command prompt example.. net stop nrpe_nt and net start nrpe_nt'
'4. try from linux example.: ./check_nrpe -H yourcomputer -c check_foldersize and result can be OK:22,8 MB'
'it is all'
'##########################################################'

Dim strfolder
Dim intwarning
Dim intcritic
Dim wsh
Dim intvelkost
Dim intjednotka

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set wsh = CreateObject("WScript.Shell")

If Wscript.Arguments.Count = 3 Then

	strfolder  = Wscript.Arguments(0)
	intwarning = Wscript.Arguments(1)
	intcritic  = Wscript.Arguments(2)

	Set objFolder = objFSO.GetFolder(strfolder)
	intjednotka = 1048576 '1MB->bytes'
	intvelkost = objFolder.Size/intjednotka

 	if (objFolder.Size/1024000) > Cint(intcritic) then

  		Wscript.Echo "CRITICAL: " & round (objFolder.Size / 1048576,1) & "MB | Size=" & round (objFolder.Size /1048576,1) & "MB"
  		Wscript.Quit(1)

  	elseif (objFolder.Size/1024000) > Cint(intwarning) then
  
  		Wscript.Echo "WARNING: " & round (objFolder.Size / 1048576,1) & "MB | Size=" & round (objFolder.Size /1048576,1) & "MB"
  		Wscript.Quit(2)

  	else
  		Wscript.Echo "OK: " & round (objFolder.Size /1048576,1) & "MB | Size=" & round (objFolder.Size /1048576,1) & "MB"
  		Wscript.Quit(0)
  	end if

else
	Wscript.Echo "UNKNOWN: "& strfolder &"-" & intwarning & "-" & intcritic
	Wscript.Quit(3)
End If
