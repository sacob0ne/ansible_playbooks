Option Explicit

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' "check_schtasks.vbs"
' Original from
'
' The nagios plugins come with ABSOLUTELY NO WARRANTY. You may redistribute
' copies of the plugins under the terms of the GNU General Public License.
' For more information about these matters, see the file named COPYING.
' Copyright (c) 1999-2001 Ethan Galstad/Hagen Deike (nagios@samurai.inka.de)
'
' Fabio Frioni - Intesi Group SPA (ffrioni@intesigroup.com) (fabio.frioni@gmail.com)
' 2011 ver 1.0
' 2012 ver 1.5
' Read scheduled tasks
' --------------------------------------------------------------
'
'"HostName","TaskName","Next Run Time","Status","Logon Mode","Last Run Time","Last Result","Author","Task To Run","Start In","Comment","Scheduled Task State","Idle Time","Power Management","Run As User","Delete Task If Not Rescheduled","Stop Task If Runs X Hours and X Mins","Schedule","Schedule Type","Start Time","Start Date","End Date","Days","Months","Repeat: Every","Repeat: Until: Time","Repeat: Until: Duration","Repeat: Stop If Still Running"
 
Function check_OS_Version()
    Dim dtmConvertedDate, strComputer, objWMIService, colOperatingSystems, objOperatingSystem
    
    Set dtmConvertedDate = CreateObject("WbemScripting.SWbemDateTime")

    strComputer = "."
    Set objWMIService = GetObject("winmgmts:" _
        & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")

    Set colOperatingSystems = objWMIService.ExecQuery _
        ("Select * from Win32_OperatingSystem")

    For Each objOperatingSystem in colOperatingSystems
        REM Wscript.Echo "Boot Device: " & objOperatingSystem.BootDevice
        REM Wscript.Echo "Build Number: " & objOperatingSystem.BuildNumber
        REM Wscript.Echo "Build Type: " & objOperatingSystem.BuildType
        REM Wscript.Echo "Caption: " & objOperatingSystem.Caption
        REM Wscript.Echo "Code Set: " & objOperatingSystem.CodeSet
        REM Wscript.Echo "Country Code: " & objOperatingSystem.CountryCode
        REM Wscript.Echo "Debug: " & objOperatingSystem.Debug
        REM Wscript.Echo "Encryption Level: " & objOperatingSystem.EncryptionLevel
        REM dtmConvertedDate.Value = objOperatingSystem.InstallDate
        REM dtmInstallDate = dtmConvertedDate.GetVarDate
        REM Wscript.Echo "Install Date: " & dtmInstallDate 
        REM Wscript.Echo "Licensed Users: " & _
            REM objOperatingSystem.NumberOfLicensedUsers
        REM Wscript.Echo "Organization: " & objOperatingSystem.Organization
        REM Wscript.Echo "OS Language: " & objOperatingSystem.OSLanguage
        REM Wscript.Echo "OS Product Suite: " & objOperatingSystem.OSProductSuite
        REM Wscript.Echo "OS Type: " & objOperatingSystem.OSType
        REM Wscript.Echo "Primary: " & objOperatingSystem.Primary
        REM Wscript.Echo "Registered User: " & objOperatingSystem.RegisteredUser
        REM Wscript.Echo "Serial Number: " & objOperatingSystem.SerialNumber
        REM Wscript.Echo "Version: " & objOperatingSystem.Version

        check_OS_Version = objOperatingSystem.OSLanguage
    Next
End Function


Function streamEcho(str)
    WScript.Stdout.Write str
    streamEcho = 0
End Function

Function unxEcho(str)
    WScript.Stdout.Write str & vblf
    unxEcho = 0
End Function

Function dosEcho(str)
    WScript.Stdout.Write str & vbcrlf
    dosEcho = 0
End Function

Function ShowUsage()
    unxEcho "check_schtasks.vbs"
    unxEcho "The nagios plugins come with ABSOLUTELY NO WARRANTY. You may redistribute"
    unxEcho "copies of the plugins under the terms of the GNU General Public License."
    unxEcho "For more information about these matters, see the file named COPYING."
    unxEcho "Copyright (c) 1999-2001 Ethan Galstad/Hagen Deike (nagios@samurai.inka.de)"
    unxEcho ""
    unxEcho "Author: Fabio Frioni - Intesi Group SPA (ffrioni@intesigroup.com) (fabio.frioni@gmail.com)"
    unxEcho "2012 ver 1.5"
    unxEcho ""
    unxEcho "Required arguments:"
    unxEcho "/task:task_name    the scheduled task name"
    unxEcho ""
    unxEcho "Optional arguments:"
    unxEcho "/h                this help."
    unxEcho "/check:n          the limit to activate alerts (valid values: 86400s, 1d, 8h, 30m, ecc.)"
    unxEcho "/older:n          valid values: 0,1,2,3. When check is reached, returns the code you specified"
    unxEcho "/lastrun:n        valid values: 0,1,2,3. When check is reached, returns the code you specified"
    unxEcho "/disabled:n       valid values: 0,1,2,3. When it occurs, returns the code you specified"
    unxEcho "/login:n          valid values: 0,1,2,3. When it occurs, returns the code you specified"
'    unxEcho "/status:n         valid values: 0,1,2,3. When it occurs, returns the code you specified"
    unxEcho "/fpos:list        fills the template with a new ordered list of field positions, Field1=Pos0."
    unxEcho "                  template: LASTRUN_pos,NEXTRUN_pos,LASTRESULT_pos,STATUS_pos,TASKNAME_pos"
    unxEcho ""
End Function


function date2epoch(myDate)
    date2epoch = DateDiff("s", "01/01/1970 00:00:00", myDate)
end function


function epoch2date(myEpoch)
    epoch2date = DateAdd("s", myEpoch, "01/01/1970 00:00:00")
end function


Function cnvtime(STRVAL,STYPE,OUTFMT)
    Dim NDAY,NHRS,NMIN,NSEC,DNOW,UN,RET,VAL

    If IsDate(STRVAL) Then
        STRVAL=date2epoch(STRVAL)
    End If
    DNOW=date2epoch(now())
    UN=UCase(mid(STRVAL,len(STRVAL),1))
    RET=0
    If UN >= CHR(48) AND UN <= CHR(57) Then
        VAL=mid(STRVAL,1,len(STRVAL))
        UN="S"
    Else
        VAL=mid(STRVAL,1,len(STRVAL)-1)
    End If

    Select Case UN
        Case "S"
            RET=VAL
        Case "M"
            RET=(VAL*60)
        Case "H"
            RET=(VAL*3600)
        Case "D"
            RET=(VAL*86400)
    End Select
    
    If NOT IsNull(STYPE) Then
        If InStr(UCase(STYPE),"SINCE") > 0 Then
            RET = DNOW - RET
        End If
        If InStr(UCase(STYPE),"DAY") > 0 Then
            RET = (RET / 86400)+1
        End If
        If InStr(UCase(STYPE),"SEC") > 0 Then
            RET = RET
        End If
    End If

    If InStr(UCase(STYPE),"DAY") = 0 Then
        If IsNull(OUTFMT) OR OUTFMT = "" Then
            cnvtime = RET
        ElseIf UCase(OUTFMT) = "STR" Then
            NDAY=Int(RET/86400)
            NHRS=Int((RET - (NDAY*86400)) / 3600)
            NMIN=Int((RET - (NDAY*86400) - (NHRS*3600)) / 60)
            NSEC=Int((RET - (NDAY*86400) - (NHRS*3600) - (NMIN*60)))
            cnvtime = NDAY & "d," & NHRS & "h," & NMIN & "m," & NSEC & "s"
        ElseIf UCase(OUTFMT)="FMT" Then
            cnvtime = FormatDateTime(epoch2date(RET),0)
        Else
        End If
    End If
End Function


Function LeftPad( strText, intLen, chrPad )
    'LeftPad( "1234", 7, "x" ) = "1234xxx"
    'LeftPad( "1234", 3, "x" ) = "123"
    LeftPad = Left( strText & String( intLen, chrPad ), intLen )
End Function

Function RightPad( strText, intLen, chrPad )
    'RightPad( "1234", 7, "x" ) = "xxx1234"
    'RightPad( "1234", 3, "x" ) = "234"
    RightPad = Right( String( intLen, chrPad ) & strText, intLen )
End Function


Function strReadStream()
    Dim objShell
    Dim objWshScriptExec
    Dim objStdOut
    ' "HostName"  ,"TaskName"       ,"Next Run Time"      ,"Status","Logon Mode","Last Run Time","Last Result","Creator","Schedule","Task To Run","Start In","Comment","Scheduled Task State","Scheduled Type","Start Time","Start Date","End Date","Days","Months","Run As User","Delete Task If Not Rescheduled","Stop Task If Runs X Hours and X Mins","Repeat: Every","Repeat: Until: Time","Repeat: Until: Duration","Repeat: Stop If Still Running","Idle Time","Power Management"
    ' "Nome host" ,"Nome operazione","Prossima esecuzione","Stato" ,"Ultima esecuzione","Ultimo esito","Autore","Pianificazione","Operazione da eseguire","Avvia in","Commento","Stato operazione pianificata","Tipo di pianificazione","Ora di avvio","Data di avvio","Data di fine","giorni","mesi","Esegui come utente","Elimina l'operazione se non ripianificata","Interrompi l'operazione se è in esecuzione da X ore e X minuti","Ripeti: Ogni","Ripeti: Fino a: Ora","Ripeti: Fino a: Durata","Ripeti: Interrompi se ancora in esecuzione","Tempi inattività","Risparmio energia"
    ' "HostName"  ,"TaskName"       ,"Next Run Time"      ,"Status","Logon Mode","Last Run Time","Last Result","Author","Task To Run","Start In","Comment","Scheduled Task State","Idle Time","Power Management","Run As User","Delete Task If Not Rescheduled","Stop Task If Runs X Hours and X Mins","Schedule","Schedule Type","Start Time","Start Date","End Date","Days","Months","Repeat: Every","Repeat: Until: Time","Repeat: Until: Duration","Repeat: Stop If Still Running"    Set objShell = CreateObject("WScript.Shell")
    Set objWshScriptExec = objShell.Exec("%COMSPEC% /c schtasks.exe /Query /V /FO CSV")
    Set objStdOut = objWshScriptExec.StdOut
    strStream = objStdOut.ReadAll
    strStream = Replace(strStream,CHR(34)&",","|")
    strReadStream = Replace(strStream,CHR(34),"")
End Function


Function arrReadStream(filterCriteria)
    Dim objShell
    Dim objWshScriptExec
    Dim objStdOut
    Dim strStream
    Dim arrStream
    
    ' "Nome host","Nome operazione","Prossima esecuzione","Stato","Ultima esecuzione","Ultimo esito","Autore","Pianificazione","Operazione da eseguire","Avvia in","Commento","Stato operazione pianificata","Tipo di pianificazione","Ora di avvio","Data di avvio","Data di fine","giorni","mesi","Esegui come utente","Elimina l'operazione se non ripianificata","Interrompi l'operazione se è in esecuzione da X ore e X minuti","Ripeti: Ogni","Ripeti: Fino a: Ora","Ripeti: Fino a: Durata","Ripeti: Interrompi se ancora in esecuzione","Tempi inattività","Risparmio energia"
    Set objShell = CreateObject("WScript.Shell")
    Set objWshScriptExec = objShell.Exec("%COMSPEC% /c schtasks.exe /Query /V /FO CSV")
    Set objStdOut = objWshScriptExec.StdOut
    strStream = objStdOut.ReadAll
    strStream = Replace(strStream,CHR(34)&",","|")
    strStream = Replace(strStream,CHR(34),"")
    arrStream = Split(strStream,CHR(13) & CHR(10))
    If NOT IsNull(filterCriteria) Then
        arrStream = Filter(arrStream,filterCriteria,1)
    End If
    If UBound(arrStream) >= 0 Then
        arrReadStream = arrStream(0)
    Else
        arrReadStream = ""
    End If
End Function


Function eval_Time(strField)
    Dim Pieces
' "HostName","TaskName","Next Run Time","Status","Logon Mode","Last Run Time","Last Result","Creator","Schedule","Task To Run","Start In","Comment","Scheduled Task State","Scheduled Type","Start Time","Start Date","End Date","Days","Months","Run As User","Delete Task If Not Rescheduled","Stop Task If Runs X Hours and X Mins","Repeat: Every","Repeat: Until: Time","Repeat: Until: Duration","Repeat: Stop If Still Running","Idle Time","Power Management"    
' "Nome host","Nome operazione","Prossima esecuzione","Stato","Ultima esecuzione","Ultimo esito","Autore","Pianificazione","Operazione da eseguire","Avvia in","Commento","Stato operazione pianificata","Tipo di pianificazione","Ora di avvio","Data di avvio","Data di fine","giorni","mesi","Esegui come utente","Elimina l'operazione se non ripianificata","Interrompi l'operazione se è in esecuzione da X ore e X minuti","Ripeti: Ogni","Ripeti: Fino a: Ora","Ripeti: Fino a: Durata","Ripeti: Interrompi se ancora in esecuzione","Tempi inattività","Risparmio energia"
    strField = replace(strField," ",",")
    Pieces = Split(strField,",")
    eval_Time = date2epoch(CDate(Pieces(0) & " " & Pieces(UBound(Pieces))))
End Function


Function get_Time(arrSched,nField)
    Dim Item, Idx
    Dim xHour, xDate
' "HostName","TaskName","Next Run Time","Status","Logon Mode","Last Run Time","Last Result","Creator","Schedule","Task To Run","Start In","Comment","Scheduled Task State","Scheduled Type","Start Time","Start Date","End Date","Days","Months","Run As User","Delete Task If Not Rescheduled","Stop Task If Runs X Hours and X Mins","Repeat: Every","Repeat: Until: Time","Repeat: Until: Duration","Repeat: Stop If Still Running","Idle Time","Power Management"    
' "Nome host","Nome operazione","Prossima esecuzione","Stato","Ultima esecuzione","Ultimo esito","Autore","Pianificazione","Operazione da eseguire","Avvia in","Commento","Stato operazione pianificata","Tipo di pianificazione","Ora di avvio","Data di avvio","Data di fine","giorni","mesi","Esegui come utente","Elimina l'operazione se non ripianificata","Interrompi l'operazione se è in esecuzione da X ore e X minuti","Ripeti: Ogni","Ripeti: Fino a: Ora","Ripeti: Fino a: Durata","Ripeti: Interrompi se ancora in esecuzione","Tempi inattività","Risparmio energia"
    If InStr(UCase(arrSched(2)),"DISAB") Then
        get_Time = -10
    ElseIf InStr(UCase(arrSched(2)),"ACCESS") Then
        get_Time = -9
    ElseIf InStr(UCase(arrSched(2)),"NEVER")  OR InStr(UCase(arrSched(2)),"MAI") Then
        get_Time = -8
    Else
        get_Time = eval_Time(arrSched(nField))
    End If
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Main
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Const's and Var's
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

'Cons for return val's
Const intOK = 0
Const intWarning = 1
Const intCritical = 2
Const intUnknown = 3

Dim StrOutput,ReturnCode,StrPerfData,StrALERT(4),arrStream,strStream,arrLic
Dim strTaskName,ReturnCodeExp
Dim lastExec, nextExec, valAlert, valLastrun, valDisabled, valLogin, valOlder
Dim warnLimit,critLimit,strWarnLimit, strCritLimit, strLastRun, strNextRun
Dim warnExpire,critExpire,strWarnExpire, strCritExpire
Dim CheckVersion, licList, StrDaysToExpire, DaysToExpire, StrDErpire, arrDExpire
Dim Idx, Idx2, Months, arrFields

licList = 0
warnLimit = -1
critLimit = -1
warnExpire = -1
critExpire = -1
CheckVersion = 0

valLastrun = 2
valOlder = 1
valDisabled = 2
valLogin = 1

Months="JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC"

CheckVersion = check_OS_Version()
' Fill fields as LASTRUN,NEXTRUN,LASTRESULT,STATUS,TASKNAME
arrFields = array(5,2,6,3,1)
If CheckVersion = 1040 Then
    arrFields = array(4,2,5,3,1)
ElseIf CheckVersion = 1033 Then 
    arrFields = array(5,2,6,3,1)
End If

If Not Wscript.Arguments.Named.Exists("task") Then
    streamEcho "Plugin help screen:"
    ShowUsage()
    Wscript.Quit(intUnknown)
End If

on error resume next
strTaskName = Trim(Replace(Replace(Wscript.Arguments.Named("task"),":b:"," "),"",""))

if Wscript.Arguments.Named.Exists("check") Then
    valAlert = Wscript.Arguments.Named("check")
End If

if Wscript.Arguments.Named.Exists("fpos") Then
    arrFields = split(Wscript.Arguments.Named("fpos"),",")
    if err then
        ShowUsage()
        Wscript.Quit(intUnknown)
    End If
End If

if Wscript.Arguments.Named.Exists("lastrun") Then
    valLastrun = CInt(Wscript.Arguments.Named("lastrun"))
    if err then
        ShowUsage()
        Wscript.Quit(intUnknown)
    End If
End If

if Wscript.Arguments.Named.Exists("older") Then
    valOlder = CInt(Wscript.Arguments.Named("older"))
    if err then
        ShowUsage()
        Wscript.Quit(intUnknown)
    End If
End If

if Wscript.Arguments.Named.Exists("disabled") Then
    valDisabled = CInt(Wscript.Arguments.Named("disabled"))
    if err then
        ShowUsage()
        Wscript.Quit(intUnknown)
    End If
End If

if Wscript.Arguments.Named.Exists("login") Then
    valLogin = CInt(Wscript.Arguments.Named("login"))
    if err then
        ShowUsage()
        Wscript.Quit(intUnknown)
    End If
End If

on error goto 0

if Wscript.Arguments.Named.Exists("list") Then
    licList = 1
End If

'On Error Resume Next

StrALERT(0) = "OK"
StrALERT(1) = "WARNING"
StrALERT(2) = "CRITICAL"
StrALERT(3) = "UNKNOWN"

if (licList = 1) Then
    unxEcho strReadStream()
    Wscript.Quit(0)
Else
    strStream = arrReadStream(strTaskName)
    If strStream = "" Then
        StrOutput = StrALERT(3) & ": Task " & strTaskName & " does not exist, please check!"
        streamEcho StrOutput
        Wscript.Quit(3)
    End If
End If

ReturnCode=0
lastExec=0
nextExec=0

arrStream = Split(strStream,"|")
strTaskName = arrStream(arrFields(4))

lastExec=get_Time(arrStream,arrFields(0))

If lastExec = -10 Then
    lastExec=0
    nextExec=0
    StrOutput = "This task is disabled! - "
    ReturnCode = valDisabled
ElseIf  lastExec = -9 Then
    lastExec = 0
    nextExec = 0
    StrOutput="This task runs only on login access!Is It correct? - "
    ReturnCode = valLogin
Else
    If  lastExec = -8 Then
        lastExec = eval_Time(arrStream(arrFields(0)))
        nextExec = 0
        StrOutput="This task will never run again!Is is correct? - "
        ReturnCode = valLogin
    Else
        StrOutput=""
        nextExec=get_Time(arrStream,arrFields(1))
        nextExec = cnvtime(nextExec,"since","")
    End If

    lastExec = CDbl(cnvtime(lastExec,"since",""))
End If

'If Trim(arrStream(arrFields(3))) <> "" AND Trim(UCase(arrStream(arrFields(3)))) <> "READY" AND Trim(UCase(arrStream(arrFields(3)))) <> "PRONTO" Then
'    StrOutput = StrOutput & " Status: " & Trim(arrStream(arrFields(3))) & " "
'    ReturnCode = valOlder
'End If
If CInt(arrStream(arrFields(2))) <> 0 Then
    StrOutput = StrOutput & " Last scheduled run failed! (" & arrStream(arrFields(2)) & ")"
    ReturnCode = valLastrun
End If

if (valAlert <> "") Then
    critLimit = CDbl(cnvtime(valAlert,"",""))
    strCritLimit = CStr(critLimit)
    If (lastExec >= critLimit) Then
        ReturnCode = valOlder
    End If
Else
    strCritLimit = ""
End If

StrOutput = StrOutput & "(last run: " & cnvtime(lastExec,"","str") & ")"

strLastRun = "'lastrun'=" & lastExec & "sec;;" & strCritLimit & ";; "
IF valOlder = 2 Then
    strLastRun = "'lastrun'=" & lastExec & "sec;;" & strCritLimit & ";; "
ElseIf valOlder = 1 Then
    strLastRun = "'lastrun'=" & lastExec & "sec;" & strCritLimit & ";;; "
End If
strNextRun = "'nextrun'=" & nextExec & "sec;;;; "

StrOutput = StrALERT(ReturnCode) & ": " & strTaskName & " " & StrOutput & "|" & strLastRun & " " & strNextRun & " "
streamEcho StrOutput
Wscript.Quit(ReturnCode)

