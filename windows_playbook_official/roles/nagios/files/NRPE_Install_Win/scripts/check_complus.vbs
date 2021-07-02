''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' NAME:		check_complus.vbs
' VERSION:	0.1
' AUTHOR:	Original from Alexander Rudolf (alexander.rudolf@saxsys.de) 2008
'
' COMMENT:	Script for checking COM+ applications and their process performance counter
'		for use with Nagios and NSClient++
'
' UPDATE:   2012
' VERSION:  1.0b
' AUTHOR:   Fabio Frioni - Intesi Group SPA (ffrioni@intesigroup.com) (fabio.frioni@gmail.com)
' CHANGELOG:
' - regular expression function added
' - multi performance request added
'
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Option explicit

Function patternMatch(strng, patrn, matchType)
    ' This verify, return a string or return an array of matches in a string by giving a pattern
    ' strng is the target string
    ' patrn is the pattern
    ' matchType is the type of match (0=just verify, 1=return the matched string, 2=return an array or a single filed value)
    Dim regEx, Match, Matches, Idx, matchField, matchPattern, IsField   ' Create variable.

    Set regEx = New RegExp   ' Create a regular expression.
    regEx.Pattern = patrn   ' Set pattern.
    regEx.IgnoreCase = True   ' Set case insensitivity.
    regEx.Global = True   ' Set global applicability.
    patternMatch = ""
    If IsNull(matchType) Then
        matchType = 0
    End If
    
    Select Case matchType
        Case 0
            patternMatch = regEx.Test(strng)

        Case 1
            patternMatch = ""
            If regEx.Test(strng) Then
                patternMatch = strng
            End If

        Case 2
            If regEx.Test(strng) Then
                Idx = 0
                matchPattern = "$" & Idx
                Redim Matches(Idx)
                IsField = True
                Do While IsField = True
                    Idx = Idx + 1
                    matchPattern = "$" & Idx
                    Match = regEx.Replace(strng,matchPattern)
                    Match = Left(Match, Len(Match)-1 )
                    If Match = matchPattern Then
                        IsField = False
                        Exit Do
                    End If
                    Redim Preserve Matches(Idx)
                    Matches(Idx-1) = Match
                Loop
                patternMatch = Matches
            End If

        Case Else
            patternMatch = ""
    End Select
    Set regEx = nothing
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

Function ShowUsage(arrCounters)
    Dim strCounter

    unxEcho "check_complus (nrpe_nt-plugin) 0.2"
    unxEcho "The nagios plugins come with ABSOLUTELY NO WARRANTY. You may redistribute"
    unxEcho "copies of the plugins under the terms of the GNU General Public License."
    unxEcho "For more information about these matters, see the file named COPYING."
    unxEcho "Copyright (c) 1999-2001 Ethan Galstad/Hagen Deike (nagios@samurai.inka.de)"
    unxEcho ""
    unxEcho "VERSION:	0.1"
    unxEcho "AUTHOR:	Original from Alexander Rudolf (alexander.rudolf@saxsys.de) 2008"
    unxEcho ""
    unxEcho "COMMENT:	Script for checking COM+ applications and their process performance counter"
    unxEcho "        for use with Nagios and NSClient++"
    unxEcho ""
    unxEcho "UPDATE:   2012"
    unxEcho "VERSION:  1.0b"
    unxEcho "AUTHOR:   Fabio Frioni - Intesi Group SPA (ffrioni@intesigroup.com) (fabio.frioni@gmail.com)"
    unxEcho "CHANGELOG:"
    unxEcho "   - regular expression function added"
    unxEcho "   - multi performance request added"
    unxEcho ""
    unxEcho ""
    unxEcho "Required arguments:"
    unxEcho "/app:name              COM+ application name, use :b: in name if it contains blanks"
    unxEcho ""
    unxEcho "Optional arguments:"
    unxEcho "/counter:name,..,name  Counter list for performances."
    unxEcho "/w:n,..,n              the warning limit for processes. If 0 the limit is Max. If -1, there is no warning limit."
    unxEcho "                       by default is -1. No takes effect for service queries"
    unxEcho "/c:n,..,n              the critical limit for processes. If 0, there is no critical limit."
    unxEcho "                       by default is 0.  No takes effect for service queries"
    unxEcho "/0:n                   If defined, the plugin will return the given value when:"
    unxEcho "                       if process not found and if service not found or in 'start pending' state"
    unxEcho "/r[:string]            If defined and only for windows services, the plugin will try to restart the requested service"
    unxEcho "                       the provided 'string' needs to automate the behavior, has to be always the macro $SERVICEOUTPUT$"
    unxEcho "/lstate:stateid;string  If defined and only with restart flag, provides the last state"
    unxEcho "                       provides the last state ID and the last state type, by default $SERVICESTATEID$ and $SERVICESTATETYPE$"
    unxEcho ""

	for each strCounter in arrCounters
		unxEcho vbTab & "* " & strCounter
	Next
    unxEcho ""
	unxEcho "** Please be aware that some counters are non numerical and therefore unusable. **"
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

Const wbemFlagReturnImmediately = &h10
Const wbemFlagForwardOnly = &h20


Dim strAppID
Dim strAppPID
Dim strCOMAppName
Dim strCounter
Dim strWMIQuery
Dim objArgs
Dim objApp
Dim objApplications
Dim objApplicationInstances
Dim objCatalog
Dim objItem
Dim colItems
Dim arrCounters
Dim valResult
Dim valMaxWarn
Dim valMaxCrit
Dim i,j

Dim objWMIService, objService, colServices, objProcess, colProcess, myObjItem, myObjItemState, myProcessID, myThreadCount
Dim strComputer, strList, ReturnCode, RCStart, sFound
Dim strCritThrds, strWarnThrds, StrOutput, StrAlerts, StrPerfDt
Dim warnThrds, critThrds, alertWhenZero, StrALERT(4)
Dim procList, procName, procCount, procRam, procFullName, SvcName, SvcDisplayName, myProcCPU, is_perfCPU
Dim countOk, countWarning, countCritical, countUnknown, countOthers
Dim restartEnabled, restartString, restartState, arrTest, arrUN

' On Error Resume Next

arrCounters = array ("Caption","CreatingProcessID","Description","ElapsedTime","Frequency_Object","Frequency_PerfTime","Frequency_Sys100NS" _
	,"HandleCount","IDProcess","IODataBytesPersec","IODataOperationsPersec","IOOtherBytesPersec","IOOtherOperationsPersec","IOReadBytesPersec" _
	,"IOReadOperationsPersec","IOWriteBytesPersec","IOWriteOperationsPersec","Name","PageFaultsPersec","PageFileBytes","PageFileBytesPeak" _
	,"PercentPrivilegedTime","PercentProcessorTime","PercentUserTime","PoolNonpagedBytes","PoolPagedBytes","PriorityBase","PrivateBytes" _
	,"ThreadCount","Timestamp_Object","Timestamp_PerfTime","Timestamp_Sys100NS","VirtualBytes","VirtualBytesPeak","WorkingSet","WorkingSetPeak")
	
strCounter = array()
StrALERT(0) = "OK"
StrALERT(1) = "WARNING"
StrALERT(2) = "CRITICAL"
StrALERT(3) = "UNKNOWN"
warnThrds = array()
critThrds = array()
alertWhenZero = -1
StrAlerts = ""
StrOutput = ""
procList = 0
procCount = 0
procRam = 0
procName = ""
ReturnCode = 0
sFound = 0
restartEnabled = false
restartString = ""
is_perfCPU = false

Redim restartState(2)
restartState(0) = 2
restartState(1) = "HARD"
myObjItemState = "NOTFOUND"

Set objArgs = WScript.Arguments

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Help
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
If Not objArgs.Named.Exists("app") Then
    streamEcho "Plugin help screen:"
    ShowUsage(arrCounters)
    Wscript.Quit(3)
End If

' --------------------------------------------------
If objArgs.Named.Exists("app") Then
    strCOMAppName = objArgs.Named("app")
    strCOMAppName = Replace(strCOMAppName,":b:"," ")
    strCOMAppName = UCase(Trim(strCOMAppName))
    if objArgs.Named.Exists("r") Then
        restartEnabled = true
        restartString = ""
        If Trim(objArgs.Named("r")) <> "" Then
            restartString = objArgs.Named("r")
        End If
        if objArgs.Named.Exists("lstate") Then
            restartState = Split(objArgs.Named("lstate"),",")
        End If
    End If
End If

if objArgs.Named.Exists("counter") Then
    strCounter = Split(objArgs.Named("counter"),",")
    Redim arrUN(UBound(strCounter)+1)
    Redim valResult(UBound(strCounter)+1)
    Redim warnThrds(UBound(strCounter)+1)
    Redim critThrds(UBound(strCounter)+1)
    j = 1
    For each i in strCounter
        sFound = Filter(arrCounters,i,true,1)
        If ubound(sFound) < 0 Then
            unxEcho "UNKNOWN: Requested counter in position " & j & " ('" & i & "') not found or not yet implemented. State:UNKNOWN"
            WScript.Quit(3)
        End If
        warnThrds(j) = -1
        critThrds(j) = -1
        valResult(j) = 0
        arrUN(j) = ""
        j = j + 1
    Next
End If

if objArgs.Named.Exists("w") Then
    warnThrds = Split(objArgs.Named("w"),",")
End If

if objArgs.Named.Exists("c") Then
    critThrds = Split(objArgs.Named("c"),",")
End If


if objArgs.Named.Exists("0") Then
    alertWhenZero = CInt(objArgs.Named("0"))
End If

Set objCatalog = CreateObject("ComAdmin.COMAdminCatalog")
Set objApplications = objCatalog.GetCollection("Applications")
Set objApplicationInstances = objCatalog.GetCollection("ApplicationInstances")

objApplications.Populate
objApplicationInstances.Populate

strAppID = ""
for i = 0 to objApplications.Count - 1
    Set objApp = objApplications.item(i)
    If patternMatch(objApp.Value("Name"),strCOMAppName,0) Then
        SvcDisplayName = objApp.Value("Name")
        strAppID = Cstr(objApp.Value("ID"))
    End If
Next

If strAppID = "" Then
    unxEcho "UNKNOWN: COM+ application '" + strCOMAppName + "' not found. State:UNKNOWN"
    WScript.Quit(3)
End if

strAppPID = ""
for i = 0 to objApplicationInstances.Count - 1
    Set objApp = objApplicationInstances.item(i)
    If objApp.Value("Application") = strAppID Then
        strAppPID = objApp.Value("ProcessID")
    End If
Next

If strAppPID = "" Then
    ReturnCode = 2
    If restartEnabled AND patternMatch(UCase(restartString),".*(STOPPED).*",0) then
        StrOutput = restartString
        If restartState(0) <> 0 AND ucase(restartState(1)) = "HARD" Then
            If Not patternMatch(UCase(restartString),".*(RESTART FAILED).*",0) Then
                If Not patternMatch(UCase(restartString),".*(TRYING TO START).*",0) Then
                    ' 'restart' requested, so we try to restart cause the state is 'stopped', any other state are unpredictable
                    ' Trying to start service
                    RCStart = objCatalog.StartApplication(SvcDisplayName)
                    StrOutput = "Action:TRYING TO START ON " & restartString
                Else
                    StrOutput = "Issue:RESTART FAILED ON " & restartString
                End If
            End If
        End If
    Else
        StrOutput = "CRITICAL: COM+ application (" & SvcDisplayName & ") seems not be running. State:STOPPED"
    End If
    unxEcho StrOutput
    WScript.Quit(ReturnCode)
End if

Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2")
strWMIQuery = "SELECT * FROM Win32_PerfFormattedData_PerfProc_Process WHERE IDProcess = " & strAppPID
Set colItems = objWMIService.ExecQuery(strWMIQuery, "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly)

j = 0
If ubound(strCounter) > -1 Then
    For Each objItem In colItems
        For each i in strCounter
            arrUN(j) = ""
            Select case i
                Case "Caption" valResult(j) = Cdbl(objItem.Caption)
                Case "CreatingProcessID" valResult(j) = Cdbl(objItem.CreatingProcessID)
                Case "Description" valResult(j) = Cdbl(objItem.Description)
                Case "ElapsedTime" valResult(j) = Cdbl(objItem.ElapsedTime)
                               arrUN(j) = "s"
                Case "Frequency_Object" valResult(j) = Cdbl(objItem.Frequency_Object)
                               arrUN(j) = "Hz"
                Case "Frequency_PerfTime" valResult(j) = Cdbl(objItem.Frequency_PerfTime)
                               arrUN(j) = "Hz"
                Case "Frequency_Sys100NS" valResult(j) = Cdbl(objItem.Frequency_Sys100NS)
                               arrUN(j) = "s"
                Case "HandleCount" valResult(j) = Cdbl(objItem.HandleCount)
                Case "IDProcess" valResult(j) = Cdbl(objItem.IDProcess)
                Case "IODataBytesPersec" valResult(j) = Cdbl(objItem.IODataBytesPersec)
                               arrUN(j) = "b"
                Case "IODataOperationsPersec" valResult(j) = Cdbl(objItem.IODataOperationsPersec)
                Case "IOOtherBytesPersec" valResult(j) = Cdbl(objItem.IOOtherBytesPersec)
                               arrUN(j) = "b"
                Case "IOOtherOperationsPersec" valResult(j) = Cdbl(objItem.IOOtherOperationsPersec)
                Case "IOReadBytesPersec" valResult(j) = Cdbl(objItem.IOReadBytesPersec)
                               arrUN(j) = "b"
                Case "IOReadOperationsPersec" valResult(j) = Cdbl(objItem.IOReadOperationsPersec)
                Case "IOWriteBytesPersec" valResult(j) = Cdbl(objItem.IOWriteBytesPersec)
                               arrUN(j) = "b"
                Case "IOWriteOperationsPersec" valResult(j) = Cdbl(objItem.IOWriteOperationsPersec)
                Case "Name" valResult(j) = Cdbl(objItem.Name)
                Case "PageFaultsPersec" valResult(j) = Cdbl(objItem.PageFaultsPersec)
                Case "PageFileBytes" valResult(j) = Cdbl(objItem.PageFileBytes)
                               arrUN(j) = "b"
                Case "PageFileBytesPeak" valResult(j) = Cdbl(objItem.PageFileBytesPeak)
                               arrUN(j) = "b"
                Case "PercentPrivilegedTime" valResult(j) = Cdbl(objItem.PercentPrivilegedTime)
                               arrUN(j) = "%"
                Case "PercentProcessorTime" valResult(j) = Cdbl(objItem.PercentProcessorTime)
                               arrUN(j) = "%"
                Case "PercentUserTime" valResult(j) = Cdbl(objItem.PercentUserTime)
                               arrUN(j) = "%"
                Case "PoolNonpagedBytes" valResult(j) = Cdbl(objItem.PoolNonpagedBytes)
                               arrUN(j) = "b"
                Case "PoolPagedBytes" valResult(j) = Cdbl(objItem.PoolPagedBytes)
                               arrUN(j) = "b"
                Case "PriorityBase" valResult(j) = Cdbl(objItem.PriorityBase)
                Case "PrivateBytes" valResult(j) = Cdbl(objItem.PrivateBytes)
                               arrUN(j) = "b"
                Case "ThreadCount" valResult(j) = Cdbl(objItem.ThreadCount)
                Case "Timestamp_Object" valResult(j) = Cdbl(objItem.Timestamp_Object)
                               arrUN(j) = "s"
                Case "Timestamp_PerfTime" valResult(j) = Cdbl(objItem.Timestamp_PerfTime)
                               arrUN(j) = "s"
                Case "Timestamp_Sys100NS" valResult(j) = Cdbl(objItem.Timestamp_Sys100NS)
                               arrUN(j) = "s"
                Case "VirtualBytes" valResult(j) = Cdbl(objItem.VirtualBytes)
                               arrUN(j) = "b"
                Case "VirtualBytesPeak" valResult(j) = Cdbl(objItem.VirtualBytesPeak)
                               arrUN(j) = "b"
                Case "WorkingSet" valResult(j) = Cdbl(objItem.WorkingSet)
                               arrUN(j) = "b"
                Case "WorkingSetPeak" valResult(j) = Cdbl(objItem.WorkingSetPeak)
                               arrUN(j) = "b"
                Case Else
            End Select
            j = j + 1
        Next
    Next
End If

j = 0
StrOutput = ""
StrPerfDt = ""
ReturnCode = 0
If ubound(strCounter) > -1 Then
    StrPerfDt = "|"
    For each i in strCounter
        strWarnThrds = ""
        strCritThrds = ""

        If ReturnCode < 2 Then
            if (UBound(critThrds) >= 0) Then
                if (critThrds(j) > 0) Then
                    strCritThrds = CStr(critThrds(j))
                    If (valResult(j) >= critThrds(j)) Then
                        ReturnCode = 2
                    End If
                End If
            End If
        End If

        If ReturnCode < 1 Then
            if (UBound(critThrds) >= 0) Then
                if (warnThrds(j) > 0) Then
                    strWarnThrds = CStr(warnThrds(j))
                    If (valResult(j) >= warnThrds(j)) Then
                        ReturnCode = 1
                    End If
                End If
            End If
        End If

        StrPerfDt = StrPerfDt & "'" & i & "'=" & valResult(j) & arrUN(j) & ";" & strWarnThrds & ";" & strCritThrds & ";; "
        j = j + 1
    Next

End If

StrOutput = StrALERT(ReturnCode) & ": COM+ (" & SvcDisplayName & ") running.  State:RUNNING " & StrPerfDt
WScript.Stdout.Write StrOutput
WScript.Quit(ReturnCode)
