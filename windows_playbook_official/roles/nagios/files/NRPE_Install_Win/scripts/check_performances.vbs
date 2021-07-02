''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' "check_performances.vbs"
'
' The nagios plugins come with ABSOLUTELY NO WARRANTY. You may redistribute
' copies of the plugins under the terms of the GNU General Public License.
' For more information about these matters, see the file named COPYING.
' Copyright (c) 1999-2001 Ethan Galstad/Hagen Deike (nagios@samurai.inka.de)
' --------------------------------------------------------------
' check_performances.vbs
' Fabio Frioni - Intesi Group SPA (ffrioni@intesigroup.com) (fabio.frioni@gmail.com)
' 28.10.2011 ver 1.0
' Read performance counters
' --------------------------------------------------------------
'

Option Explicit
' On Error Resume Next

'
' This Function is mainly used with Win32_PerfRawData_PerfProc_Process Class
Function CPUUSage( ProcID )
    Dim objWMI, objInstance1, perf_instance2, PercentProcessorTime
    Dim N0, D0, N, D, NProbes, I

    
    'Set objWMI = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
    'For Each objInstance1 in objWMI.ExecQuery("Select * from Win32_PerfRawData_PerfProc_Process Where IDProcess = '" & ProcID & "'")
    For Each objInstance1 in GetObject("WINMGMTS:{impersonationLevel=impersonate}!\\.\ROOT\cimv2:Win32_PerfRawData_PerfProc_Process.IDProcess=""" & ProcID & """")
        N0 = objInstance1.PercentProcessorTime
        D0 = objInstance1.TimeStamp_Sys100NS
        'Exit For
    Next
    WScript.Sleep(500)
    N = 0
    D = 0
    NProbes = 3
    For I = 1 to NProbes
        For Each perf_instance2 in GetObject("WINMGMTS:{impersonationLevel=impersonate}!\\.\ROOT\cimv2:Win32_PerfRawData_PerfProc_Process.IDProcess=""" & ProcID & """")
            N = N + (perf_instance2.PercentProcessorTime - N0)
            D = D + (perf_instance2.TimeStamp_Sys100NS - D0)
            N0 = perf_instance2.PercentProcessorTime
            D0 = perf_instance2.TimeStamp_Sys100NS
            'Exit For
        Next
        WScript.Sleep(500)
    Next
    ' CounterType - PERF_100NSEC_TIMER_INV
    ' Formula - (1- ((N2 - N1) / (D2 - D1))) x 100

    N = N / NProbes
    D = D / NProbes
    PercentProcessorTime = (N/D)  * 100
    Set objWMI = nothing
    CPUUSage = Round(PercentProcessorTime,2)
End Function


Function findItem(arrMeta,match,evaluate)
    Dim I, J, arrMatch, strResult
    
    strResult = ""
    findItem = 0
    arrMatch = split(match,":")
    For I = LBound(arrMeta) to UBound(arrMeta)
        For J = 0 to UBound(arrMatch)
            If StrComp(Trim(arrMatch(J)), Trim(arrMeta(I)),1) = 0 Then
                if strResult = "" Then
                    strResult = CStr(I)
                Else
                    strResult = strResult & ":" & CStr(I)
                End If
                If evaluate = 1 Then
                    If NOT IsArray(eval(arrMeta(I))) Then
                        findItem = -2
                    End If
                End If
            End If
        Next
    Next
    If strResult = "" Then
        findItem = -1
    Else
        If findItem = 0 Then
            findItem = split(strResult,":")
        End If
    End If
End Function


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
    unxEcho "check_performances.vbs"
    unxEcho "The nagios plugins come with ABSOLUTELY NO WARRANTY. You may redistribute"
    unxEcho "copies of the plugins under the terms of the GNU General Public License."
    unxEcho "For more information about these matters, see the file named COPYING."
    unxEcho "Copyright (c) 1999-2001 Ethan Galstad/Hagen Deike (nagios@samurai.inka.de)"
    unxEcho ""
    unxEcho "Author: Fabio Frioni - Intesi Group SPA (ffrioni@intesigroup.com) (fabio.frioni@gmail.com)"
    unxEcho ""
    unxEcho "Required arguments:"
    unxEcho "/h                             this help."
    unxEcho "/class:win32_class             Win32 class name or '?' to show all known classes."
    unxEcho "/property:class_property       Win32 class property or '?' to show all properties of specified class. You can specify more properties separated by a colon (:)"
    unxEcho ""
    unxEcho "Optional arguments:"
    unxEcho "/nprobes:n                     How many counts before take value."
    unxEcho "/sleep:ms                      time in milliseconds to delay each probe, beste results with 1000."
    unxEcho ""
    unxEcho "Optional arguments (list arguments):"
    unxEcho "/keyval:key                    depends by the choosen class, it refers to the index key value needed for filter the context.  You can specify more properties separated by a colon (:)"
    unxEcho "/scale:n                       specifies a number describing a scale factor, in order to obtain the real value. By default is 1000. You can specify more properties separated by a colon (:)"
    unxEcho "/w:meta                        specifies a value describing a warning limit. By default is 0 (none). You can specify more properties separated by a colon (:)"
    unxEcho "/c:meta                        specifies a value describing a critical limit. By default is 0 (none). You can specify more properties separated by a colon (:)"
    unxEcho "/d:string                      specifies a string to use as prefix description. You can specify more properties separated by a colon (:)"
    unxEcho "/u:string                      specifies a units. You can specify more properties separated by a colon (:)"
    unxEcho ""
    unxEcho "NOTE: for each defined list arguments, if any, has to be honoured the same number of values."
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
    Set objShell = CreateObject("WScript.Shell")
    Set objWshScriptExec = objShell.Exec("%COMSPEC% /c schtasks.exe /Query /V /FO CSV /NH")
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
    Set objWshScriptExec = objShell.Exec("%COMSPEC% /c schtasks.exe /Query /V /FO CSV /NH")
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
    Pieces = Split(strField,",")
    eval_Time = date2epoch(CDate(Pieces(1) & " " & Pieces(0)))
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


Function setReturnCode(prevValue,actual)
    setReturnCode = actual
    If prevValue > actual Then
        setReturnCode = prevValue
    End If
End Function

'***********************************************************
'
' Main
'
'
'***********************************************************
'Cons for return val's
Const intOK = 0
Const intWarning = 1
Const intCritical = 2
Const intUnknown = 3

Dim myDebug
Dim oWMI, WQL, Instances, Instance, argClass, argProperty, YouWantTheList
Dim StrOutput,ReturnCode,StrPerfData,StrALERT(4),arrStream,strStream,arrLic
Dim nProbes, tProbes, I, idxClass, idxProperty, idxClassI, idxPropertyI, myNumWarn, myNumCrit, myStrWarn, myStrCrit, myDescription
Dim GlobalVal, PartialVal, myKeyVal, myScale, myUnits, D, D0

Dim Win32_PerfData, _
    Win32_PerfRawData_PerfDisk_LogicalDisk, _
    Win32_PerfFormattedData_PerfDisk_LogicalDisk, _
    Win32_PerfFormattedData_PerfDisk_PhysicalDisk, _
    Win32_PerfRawData_PerfOS_Processor, _
    Win32_PerfRawData_PerfDisk_PhysicalDisk

myDebug = 0
YouWantTheList = 0
tProbes = 1000
nProbes = 3
myStrWarn = ""
myStrCrit = ""
myKeyVal = array("_Total")
myScale = array(1000)
myDescription = array("")
myNumWarn = array(0)
myNumCrit = array(0)
myUnits = array("")

Win32_PerfData  = array( _
"*Win32_PerfRawData_ASP_ActiveServerPages", _
"*Win32_PerfRawData_ContentFilter_IndexingServiceFilter", _
"*Win32_PerfRawData_ContentIndex_IndexingService", _
"*Win32_PerfRawData_InetInfo_InternetInformationServicesGlobal", _
"*Win32_PerfRawData_ISAPISearch_HttpIndexingService", _
"*Win32_PerfRawData_MSDTC_DistributedTransactionCoordinator", _
"*Win32_PerfRawData_NTFSDRV_SMTPNTFSStoreDriver", _
"Win32_PerfRawData_PerfDisk_LogicalDisk", _
"Win32_PerfRawData_PerfDisk_PhysicalDisk", _
"*Win32_PerfRawData_PerfNet_Browser", _
"*Win32_PerfRawData_PerfNet_Redirector", _
"*Win32_PerfRawData_PerfNet_Server", _
"*Win32_PerfRawData_PerfNet_ServerWorkQueues", _
"*Win32_PerfRawData_PerfOS_Cache", _
"*Win32_PerfRawData_PerfOS_Memory", _
"*Win32_PerfRawData_PerfOS_Objects", _
"*Win32_PerfRawData_PerfOS_PagingFile", _
"Win32_PerfRawData_PerfOS_Processor", _
"*Win32_PerfRawData_PerfOS_System", _
"*Win32_PerfRawData_PerfProc_FullImage_Costly", _
"*Win32_PerfRawData_PerfProc_Image_Costly", _
"*Win32_PerfRawData_PerfProc_JobObject", _
"*Win32_PerfRawData_PerfProc_JobObjectDetails", _
"*Win32_PerfRawData_PerfProc_Process", _
"*Win32_PerfRawData_PerfProc_ProcessAddressSpace_Costly", _
"*Win32_PerfRawData_PerfProc_Thread", _
"*Win32_PerfRawData_PerfProc_ThreadDetails_Costly", _
"*Win32_PerfRawData_PSched_PSchedFlow", _
"*Win32_PerfRawData_PSched_PSchedPipe", _
"*Win32_PerfRawData_RemoteAccess_RASPort", _
"*Win32_PerfRawData_RemoteAccess_RASTotal", _
"*Win32_PerfRawData_RSVP_ACSRSVPInterfaces", _
"*Win32_PerfRawData_RSVP_ACSRSVPService", _
"*Win32_PerfRawData_SMTPSVC_SMTPServer", _
"*Win32_PerfRawData_Spooler_PrintQueue", _
"*Win32_PerfRawData_TapiSrv_Telephony", _
"*Win32_PerfRawData_Tcpip_ICMP", _
"*Win32_PerfRawData_Tcpip_IP", _
"*Win32_PerfRawData_Tcpip_NBTConnection", _
"*Win32_PerfRawData_Tcpip_NetworkInterface", _
"*Win32_PerfRawData_Tcpip_TCP", _
"*Win32_PerfRawData_Tcpip_UDP", _
"*Win32_PerfRawData_TermService_TerminalServices", _
"*Win32_PerfRawData_TermService_TerminalServicesSession", _
"*Win32_PerfRawData_W3SVC_WebService", _
"*Win32_PerfFormattedData_ASP_ActiveServerPages", _
"*Win32_PerfFormattedData_ContentFilter_IndexingServiceFilter", _
"*Win32_PerfFormattedData_ContentIndex_IndexingService", _
"*Win32_PerfFormattedData_InetInfo_InternetInformationServicesGlobal", _
"*Win32_PerfFormattedData_ISAPISearch_HttpIndexingService", _
"*Win32_PerfFormattedData_MSDTC_DistributedTransactionCoordinator", _
"*Win32_PerfFormattedData_NTFSDRV_SMTPNTFSStoreDriver", _
"Win32_PerfFormattedData_PerfDisk_LogicalDisk", _
"Win32_PerfFormattedData_PerfDisk_PhysicalDisk", _
"*Win32_PerfFormattedData_PerfNet_Browser", _
"*Win32_PerfFormattedData_PerfNet_Redirector", _
"*Win32_PerfFormattedData_PerfNet_Server", _
"*Win32_PerfFormattedData_PerfNet_ServerWorkQueues", _
"*Win32_PerfFormattedData_PerfOS_Cache", _
"*Win32_PerfFormattedData_PerfOS_Memory", _
"*Win32_PerfFormattedData_PerfOS_Objects", _
"*Win32_PerfFormattedData_PerfOS_PagingFile", _
"*Win32_PerfFormattedData_PerfOS_Processor", _
"*Win32_PerfFormattedData_PerfOS_System", _
"*Win32_PerfFormattedData_PerfProc_FullImage_Costly", _
"*Win32_PerfFormattedData_PerfProc_Image_Costly", _
"*Win32_PerfFormattedData_PerfProc_JobObject", _
"*Win32_PerfFormattedData_PerfProc_JobObjectDetails", _
"*Win32_PerfFormattedData_PerfProc_Process", _
"*Win32_PerfFormattedData_PerfProc_ProcessAddressSpace_Costly", _
"*Win32_PerfFormattedData_PerfProc_Thread", _
"*Win32_PerfFormattedData_PerfProc_ThreadDetails_Costly", _
"*Win32_PerfFormattedData_PSched_PSchedFlow", _
"*Win32_PerfFormattedData_PSched_PSchedPipe", _
"*Win32_PerfFormattedData_RemoteAccess_RASPort", _
"*Win32_PerfFormattedData_RemoteAccess_RASTotal", _
"*Win32_PerfFormattedData_RSVP_ACSRSVPInterfaces", _
"*Win32_PerfFormattedData_RSVP_ACSRSVPService", _
"*Win32_PerfFormattedData_SMTPSVC_SMTPServer", _
"*Win32_PerfFormattedData_Spooler_PrintQueue", _
"*Win32_PerfFormattedData_TapiSrv_Telephony", _
"*Win32_PerfFormattedData_Tcpip_ICMP", _
"*Win32_PerfFormattedData_Tcpip_IP", _
"*Win32_PerfFormattedData_Tcpip_NBTConnection", _
"*Win32_PerfFormattedData_Tcpip_NetworkInterface", _
"*Win32_PerfFormattedData_Tcpip_TCP", _
"*Win32_PerfFormattedData_Tcpip_UDP", _
"*Win32_PerfFormattedData_TermService_TerminalServices", _
"*Win32_PerfFormattedData_TermService_TerminalServicesSession", _
"*Win32_PerfFormattedData_W3SVC_WebService" _
)

Win32_PerfRawData_PerfDisk_LogicalDisk = array( _
"AvgDiskBytesPerRead", _
"AvgDiskBytesPerRead_Base", _
"AvgDiskBytesPerTransfer", _
"AvgDiskBytesPerTransfer_Base", _
"AvgDiskBytesPerWrite", _
"AvgDiskBytesPerWrite_Base", _
"AvgDiskQueueLength", _
"AvgDiskReadQueueLength", _
"AvgDiskSecPerRead", _
"AvgDiskSecPerRead_Base", _
"AvgDiskSecPerTransfer", _
"AvgDiskSecPerTransfer_Base", _
"AvgDiskSecPerWrite", _
"AvgDiskSecPerWrite_Base", _
"AvgDiskWriteQueueLength", _
"Caption", _
"CurrentDiskQueueLength", _
"Description", _
"DiskBytesPerSec", _
"DiskReadBytesPerSec", _
"DiskReadsPerSec", _
"DiskTransfersPerSec", _
"DiskWriteBytesPerSec", _
"DiskWritesPerSec", _
"FreeMegabytes", _
"Frequency_Object", _
"Frequency_PerfTime", _
"Frequency_Sys100NS", _
"Name", _
"PercentDiskReadTime", _
"PercentDiskReadTime_Base", _
"PercentDiskTime", _
"PercentDiskTime_Base", _
"PercentDiskWriteTime", _
"PercentDiskWriteTime_Base", _
"PercentFreeSpace", _
"PercentFreeSpace_Base", _
"PercentIdleTime", _
"PercentIdleTime_Base", _
"SplitIOPerSec", _
"Timestamp_Object", _
"Timestamp_PerfTime", _
"Timestamp_Sys100NS" _
)

Win32_PerfFormattedData_PerfDisk_LogicalDisk = array( _
"AvgDiskBytesPerRead", _
"AvgDiskBytesPerTransfer", _
"AvgDiskBytesPerWrite", _
"AvgDiskQueueLength", _
"AvgDiskReadQueueLength", _
"AvgDiskSecPerRead", _
"AvgDiskSecPerTransfer", _
"AvgDiskSecPerWrite", _
"AvgDiskWriteQueueLength", _
"Caption", _
"CurrentDiskQueueLength", _
"Description", _
"DiskBytesPerSec", _
"DiskReadBytesPerSec", _
"DiskReadsPerSec", _
"DiskTransfersPerSec", _
"DiskWriteBytesPerSec", _
"DiskWritesPerSec", _
"FreeMegabytes", _
"Frequency_Object", _
"Frequency_PerfTime", _
"Frequency_Sys100NS", _
"Name", _
"PercentDiskReadTime", _
"PercentDiskTime", _
"PercentDiskWriteTime", _
"PercentFreeSpace", _
"PercentIdleTime", _
"SplitIOPerSec", _
"Timestamp_Object", _
"Timestamp_PerfTime", _
"Timestamp_Sys100NS" _
)

Win32_PerfFormattedData_PerfDisk_PhysicalDisk = array( _
"AvgDiskBytesPerRead", _
"AvgDiskBytesPerTransfer", _
"AvgDiskBytesPerWrite", _
"AvgDiskQueueLength", _
"AvgDiskReadQueueLength", _
"AvgDiskSecPerRead", _
"AvgDiskSecPerTransfer", _
"AvgDiskSecPerWrite", _
"AvgDiskWriteQueueLength", _
"Caption", _
"CurrentDiskQueueLength", _
"Description", _
"DiskBytesPerSec", _
"DiskReadBytesPerSec", _
"DiskReadsPerSec", _
"DiskTransfersPerSec", _
"DiskWriteBytesPerSec", _
"DiskWritesPerSec", _
"Frequency_Object", _
"Frequency_PerfTime", _
"Frequency_Sys100NS", _
"Name", _
"PercentDiskReadTime", _
"PercentDiskTime", _
"PercentDiskWriteTime", _
"PercentIdleTime", _
"SplitIOPerSec", _
"Timestamp_Object", _
"Timestamp_PerfTime", _
"Timestamp_Sys100NS" _
)

Win32_PerfRawData_PerfOS_Processor = array( _
"C1TransitionsPerSec", _
"C2TransitionsPerSec", _
"C3TransitionsPerSec", _
"Caption", _
"Description", _
"DPCRate", _
"DPCsQueuedPerSec", _
"Frequency_Object", _
"Frequency_PerfTime", _
"Frequency_Sys100NS", _
"InterruptsPerSec", _
"Name", _
"PercentC1Time", _
"PercentC2Time", _
"PercentC3Time", _
"PercentDPCTime", _
"PercentIdleTime", _
"PercentInterruptTime", _
"PercentPrivilegedTime", _
"PercentProcessorTime", _
"PercentUserTime", _
"Timestamp_Object", _
"Timestamp_PerfTime", _
"Timestamp_Sys100NS" _
)

Win32_PerfRawData_PerfDisk_PhysicalDisk = array( _
"AvgDiskBytesPerRead", _
"AvgDiskBytesPerRead_Base", _
"AvgDiskBytesPerTransfer", _
"AvgDiskBytesPerTransfer_Base", _
"AvgDiskBytesPerWrite", _
"AvgDiskBytesPerWrite_Base", _
"AvgDiskQueueLength", _
"AvgDiskReadQueueLength", _
"AvgDiskSecPerRead", _
"AvgDiskSecPerRead_Base", _
"AvgDiskSecPerTransfer", _
"AvgDiskSecPerTransfer_Base", _
"AvgDiskSecPerWrite", _
"AvgDiskSecPerWrite_Base", _
"AvgDiskWriteQueueLength", _
"Caption", _
"CurrentDiskQueueLength", _
"Description", _
"DiskBytesPerSec", _
"DiskReadBytesPerSec", _
"DiskReadsPerSec", _
"DiskTransfersPerSec", _
"DiskWriteBytesPerSec", _
"DiskWritesPerSec", _
"Frequency_Object", _
"Frequency_PerfTime", _
"Frequency_Sys100NS", _
"Name", _
"PercentDiskReadTime", _
"PercentDiskReadTime_Base", _
"PercentDiskTime", _
"PercentDiskTime_Base", _
"PercentDiskWriteTime", _
"PercentDiskWriteTime_Base", _
"PercentIdleTime", _
"PercentIdleTime_Base", _
"SplitIOPerSec", _
"Timestamp_Object", _
"Timestamp_PerfTime", _
"Timestamp_Sys100NS" _
)

StrALERT(0) = "OK"
StrALERT(1) = "WARNING"
StrALERT(2) = "CRITICAL"
StrALERT(3) = "UNKNOWN"

If Not Wscript.Arguments.Named.Exists("class") AND Not Wscript.Arguments.Named.Exists("property") Then
    streamEcho "Plugin help screen:"
    ShowUsage()
    Wscript.Quit(intUnknown)
End If
argClass = Wscript.Arguments.Named("class")
argProperty = Wscript.Arguments.Named("property")
idxClass = findItem(Win32_PerfData, argClass,1)

YouWantTheList = 0
If IsArray(idxClass) Then
    For idxClassI = 0 to UBound(idxClass)
        If InStr(argProperty,"?") > 0 Then
            YouWantTheList = 1
            For I=LBound(eval(Win32_PerfData(idxClass(idxClassI)))) TO UBound(eval(Win32_PerfData(idxClass(idxClassI))))
                unxEcho eval(Win32_PerfData(idxClass(idxClassI)))(I)
            Next
        Else
            idxProperty = findItem(eval(Win32_PerfData(idxClass(idxClassI))), argProperty,0)
            If Not IsArray(idxProperty) Then
                streamEcho StrALERT(3) & ": Property not found in class " & Win32_PerfData(idxClass) & "! Please check..."
                wscript.quit(3)
            End If
            Redim myNumWarn(UBound(idxProperty))
            Redim myKeyVal(UBound(idxProperty))
            Redim myScale(UBound(idxProperty))
            Redim myDescription(UBound(idxProperty))
            Redim myNumWarn(UBound(idxProperty))
            Redim myNumCrit(UBound(idxProperty))
            Redim myUnits(UBound(idxProperty))
            For idxPropertyI = 0 To UBound(idxProperty)
                myKeyVal(idxPropertyI)      = "_Total"
                myScale(idxPropertyI)       = 1000
                myDescription(idxPropertyI) = ""
                myNumWarn(idxPropertyI)     = 0
                myNumCrit(idxPropertyI)     = 0
                myUnits(idxPropertyI)       = ""
            Next
        End If
    Next
Else
    streamEcho StrALERT(3) & ": Class not implemented yet! Please check..."
    wscript.quit(3)
End If

If YouWantTheList = 1 Then
    wscript.quit(3)
End If


If Wscript.Arguments.Named.Exists("nprobes") Then
    nProbes = Wscript.Arguments.Named("nprobes")
End If

If Wscript.Arguments.Named.Exists("sleep") Then
    tProbes = Wscript.Arguments.Named("sleep")
End If

If Wscript.Arguments.Named.Exists("keyval") Then
    myKeyVal = Split(Wscript.Arguments.Named("keyval"),":")
End If

If Wscript.Arguments.Named.Exists("Scale") Then
    myScale = Split(Wscript.Arguments.Named("Scale"),":")
    If UBound(myScale) <> UBound(idxProperty) Then
        streamEcho "Plugin help screen:"
        ShowUsage()
        Wscript.Quit(intUnknown)
    End If
    For idxPropertyI = 0 To UBound(myScale)
        If myScale(idxPropertyI) = 0 Then
            myScale(idxPropertyI) = 1
        End IF
    Next
End If

If Wscript.Arguments.Named.Exists("w") Then
    myNumWarn = Split(Wscript.Arguments.Named("w"),":")
    If UBound(myNumWarn) <> UBound(idxProperty) Then
        streamEcho "Plugin help screen:"
        ShowUsage()
        Wscript.Quit(intUnknown)
    End If
End If

If Wscript.Arguments.Named.Exists("c") Then
    myNumCrit = Split(Wscript.Arguments.Named("c"),":")
    If UBound(myNumCrit) <> UBound(idxProperty) Then
        streamEcho "Plugin help screen:"
        ShowUsage()
        Wscript.Quit(intUnknown)
    End If
End If

If Wscript.Arguments.Named.Exists("d") Then
    myDescription = Split(Wscript.Arguments.Named("d"),":")
    If UBound(myDescription) <> UBound(idxProperty) Then
        streamEcho "Plugin help screen:"
        ShowUsage()
        Wscript.Quit(intUnknown)
    End If
End If

If Wscript.Arguments.Named.Exists("u") Then
    myUnits = Split(Wscript.Arguments.Named("u"),":")
    If UBound(myUnits) <> UBound(idxProperty) Then
        streamEcho "Plugin help screen:"
        ShowUsage()
        Wscript.Quit(intUnknown)
    End If
End If

If Wscript.Arguments.Named.Exists("debug") Then
    myDebug = Wscript.Arguments.Named("debug")
End If

If Wscript.Arguments.Named.Exists("?") OR Wscript.Arguments.Named.Exists("h") Then
    streamEcho "Plugin help screen:"
    ShowUsage()
    Wscript.Quit(intUnknown)
End If

If InStr(argClass,"?") > 0 Then
    unxEcho "* Indicates class not available"
    unxEcho "-------------------------------"
    
    For I=LBound(Win32_PerfData) TO UBound(Win32_PerfData)
        unxEcho Win32_PerfData(I)
    Next
    Wscript.Quit(intUnknown)
End If

'Get base WMI object, "." means computer name (local)
Set oWMI = GetObject("WINMGMTS:\\.\ROOT\cimv2")

'GlobalVal = 0
'For I=1 to nProbes
'    Set Instance = oWMI.Get(Win32_PerfData(idxClass) & ".Name=""" & "C:" & """")
'    unxEcho Win32_PerfData(idxClass) & ".Name"
'    GlobalVal = eval("Instance." & eval(Win32_PerfData(idxClass))(idxProperty)) - PartialVal
'    'Get the instance of Win32_PerfData_PerfDisk_LogicalDisk 
'                    
'    'Do something with the instance
'    ' Wscript.Echo Instance.AvgDiskBytesPerRead 'or other property name
'    PartialVal = eval("Instance." & eval(Win32_PerfData(idxClass))(idxProperty))
'    unxEcho GlobalVal & " - " & eval("Instance." & eval(Win32_PerfData(idxClass))(idxProperty))
'    'Wait for some time to get next value
'    Wscript.Sleep tProbes
'Next


If UBound(myKeyVal) < 0 Then
    'Create a WMI query text
    For idxClassI = 0 to UBound(idxClass)
        WQL = "Select * from " & Win32_PerfData(idxClass(idxClassI))
        Set Instances = oWMI.ExecQuery(WQL)
        I=0
        For Each Instance In Instances
            I=I+1
            'Do something with the instance
            For idxPropertyI = 0 To UBound(idxProperty)
                unxEcho I & " - " & Instance.Name & " - " & eval("Instance." & eval(Win32_PerfData(idxClass(idxClassI)))(idxProperty(idxPropertyI))) 'or other property name
            Next
        Next 'Instance
    Next
Else
    Redim GlobalVal(UBound(idxProperty) + UBound(idxClass))
    Redim PartialVal(UBound(idxProperty) + UBound(idxClass))
    D = 0.0
    D0 = 0.0
    ' On Error Resume Next
    For I=1 to nProbes
        For idxClassI = 0 to UBound(idxClass)
            'Wait for some time to get next value
            Set Instance = GetObject("WINMGMTS:\\.\ROOT\cimv2:" & Win32_PerfData(idxClass(idxClassI)) & ".Name=""" & myKeyVal(idxClassI) & """")
            For idxPropertyI = 0 to UBound(idxProperty)
                If I > 1 Then
                    GlobalVal(idxPropertyI) = GlobalVal(idxPropertyI) + (eval("CDbl(Instance." & eval(Win32_PerfData(idxClass(idxClassI)))(idxProperty(idxPropertyI)) & ")" ) - PartialVal(idxPropertyI))
                    D = D + (CDbl(Instance.Timestamp_Sys100NS) - D0)
                    If myDebug > 0 Then
                        unxEcho mydebug & ": " & eval(Win32_PerfData(idxClass(idxClassI)))(idxProperty(idxPropertyI)) & " = " & GlobalVal(idxPropertyI) & " - " & eval("CDbl(Instance." & eval(Win32_PerfData(idxClass(idxClassI)))(idxProperty(idxPropertyI)) & ")" )
                    End If
                'unxEcho GlobalVal & " - " & eval("Instance." & eval(Win32_PerfData(idxClass))(idxProperty)) & " - " & Instance.name
                End If
                PartialVal(idxPropertyI) = eval("CDbl(Instance." & eval(Win32_PerfData(idxClass(idxClassI)))(idxProperty(idxPropertyI)) & ")" )
                D0 = CDbl(Instance.Timestamp_Sys100NS)
                If myDebug > 1 Then
                    unxEcho mydebug & ": " & eval(Win32_PerfData(idxClass(idxClassI)))(idxProperty(idxPropertyI)) & " = " & GlobalVal(idxPropertyI) & " - " & eval("CDbl(Instance." & eval(Win32_PerfData(idxClass(idxClassI)))(idxProperty(idxPropertyI)) & ")" )
                End If
            Next
        Next
        Wscript.Sleep tProbes
    Next
End If

ReturnCode = 0
strPerfData = ""
strOutput = ""
For idxClassI = 0 To UBound(idxClass)
    For idxPropertyI = 0 To UBound(idxProperty)
        GlobalVal(idxPropertyI) = CDbl((GlobalVal(idxPropertyI) / (nProbes-1)))
        D = CDbl((D / (nProbes-1)))
        GlobalVal(idxPropertyI) = Round(GlobalVal(idxPropertyI) / myScale(idxPropertyI),5)

        myStrWarn = ""
        If myNumWarn(idxPropertyI) > 0 Then
            myStrWarn = CStr(myNumWarn(idxPropertyI))
            If CDbl(GlobalVal(idxPropertyI)) > CDbl(myNumWarn(idxPropertyI)) Then 
                ReturnCode = setReturnCode(ReturnCode,1)
            End If
        End If

        myStrCrit = ""
        If myNumCrit(idxPropertyI) > 0 Then
            myStrCrit = CStr(myNumCrit(idxPropertyI))
            If CDbl(GlobalVal(idxPropertyI)) > CDbl(myNumCrit(idxPropertyI)) Then
                ReturnCode = setReturnCode(ReturnCode,2)
            End If
        End If
        GlobalVal(idxPropertyI) = Replace(GlobalVal(idxPropertyI),",",".")
        strOutput = strOutput & strALERT(ReturnCode) & ": " & Trim(myDescription(idxPropertyI)) &  eval(Win32_PerfData(idxClass(idxClassI)))(idxProperty(idxPropertyI)) & "=" & GlobalVal(idxPropertyI) & "; "
        strPerfData = strPerfData & "'" & eval(Win32_PerfData(idxClass(idxClassI)))(idxProperty(idxPropertyI)) & "'=" & GlobalVal(idxPropertyI) & myUnits(idxPropertyI) & ";" & myStrWarn & ";" & myStrCrit & ";; "
    Next
Next

streamEcho strOutput & "|" & strPerfData
wscript.quit(ReturnCode)