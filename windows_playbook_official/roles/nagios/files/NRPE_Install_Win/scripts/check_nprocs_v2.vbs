'#==============================================================#
'# check_nprocs.vbs - check status of process or services       #
'#                    This is a porting to work with NSClient   #
'#==============================================================#
'#                                                              #
'#                     check_nprocs.vbs v0.9b                   #
'#                                                              #
'# fabio.frioni@gmail.com                       copyright 2011  #
'#==============================================================#
'#                                                              #
'# CHANGELOG:                                                   #
'#                                                              # 
'#==============================================================#
'#                                                              #
'# You may use and modify this software freely.                 #
'# You may not profit from it in any way, nor remove the        #
'# copyright information.  Please document changes clearly and  #
'# preserve the header if you redistribute it.                  #
'#                                                              #
'# 2011-11-28 Update: Porting in VBScript                       #
'# Fabio Frioni, Intesi Group SPA                               #
'# ffrioni@intesigroup.com                                      #
'# fabio.frioni@gmail.com                                       #
'#                                                              #
'#==============================================================#
'
Option Explicit

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


Function CPUUSage( ProcID, InitialMS, DelayMS, NumberOfTests )
    Dim objWMI, objInstance1, perf_instance2, PercentProcessorTime
    Dim N0, D0, N, D, NProbes, I


    Set objWMI = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
    For Each objInstance1 in objWMI.ExecQuery("Select * from Win32_PerfRawData_PerfProc_Process Where IDProcess = '" & ProcID & "'")
        N0 = objInstance1.PercentProcessorTime
        D0 = objInstance1.TimeStamp_Sys100NS
        'Exit For
    Next
    WScript.Sleep(InitialMS)
    N = 0
    D = 0
    NProbes = NumberOfTests
    For I = 1 to NProbes
        For Each perf_instance2 in objWMI.ExecQuery("Select * from Win32_PerfRawData_PerfProc_Process Where IDProcess = '" & ProcID & "'")
            N = N + (perf_instance2.PercentProcessorTime - N0)
            D = D + (perf_instance2.TimeStamp_Sys100NS - D0)
            N0 = perf_instance2.PercentProcessorTime
            D0 = perf_instance2.TimeStamp_Sys100NS
            'Exit For
        Next
        WScript.Sleep(DelayMS)
    Next
    ' CounterType - PERF_100NSEC_TIMER_INV
    ' Formula - (1- ((N2 - N1) / (D2 - D1))) x 100

    N = N / NProbes
    D = D / NProbes
    PercentProcessorTime = (N/D)  * 100
    Set objWMI = nothing
    CPUUSage = Round(PercentProcessorTime,2)
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
    unxEcho "check_nprocs (nrpe_nt-plugin) 1.0"
    unxEcho "The nagios plugins come with ABSOLUTELY NO WARRANTY. You may redistribute"
    unxEcho "copies of the plugins under the terms of the GNU General Public License."
    unxEcho "For more information about these matters, see the file named COPYING."
    unxEcho "Copyright (c) 1999-2001 Ethan Galstad/Hagen Deike (nagios@samurai.inka.de)"
    unxEcho ""
    unxEcho "Fabio Frioni - Intesi Group SPA (ffrioni@intesigroup.com) (fabio.frioni@gmail.com)"
    unxEcho ""
    unxEcho "Required arguments:"
    unxEcho "/p:name        the process name (the executable)"
    unxEcho "(or)"
    unxEcho "/s:service     the service display name (use :b: to emulate spaces)"
    unxEcho ""
    unxEcho "Optional arguments:"
    unxEcho "/h      this help."
    unxEcho "/w:n    the warning limit for processes. If 0 the limit is Max. If -1, there is no warning limit."
    unxEcho "        By default is -1. No takes effect for service queries"
    unxEcho "/c:n    the critical limit for processes. If 0, there is no critical limit."
    unxEcho "        By default is 0.  No takes effect for service queries"
    unxEcho "/wc:n   the warning CPU limit for processes. If 0 the limit is Max. If -1, there is no warning limit."
    unxEcho "        By default is -1. No takes effect for service queries"
    unxEcho "/cc:n   the critical CPU limit for processes. If 0, there is no critical limit."
    unxEcho "        By default is 0.  No takes effect for service queries"
    unxEcho "/wt:n   the warning limit for threads. If 0 the limit is Max. If -1, there is no warning limit."
    unxEcho "        By default is -1. No takes effect for service queries"
    unxEcho "/ct:n   the critical limit for threads. If 0, there is no critical limit."
    unxEcho "        By default is 0.  No takes effect for service queries"
    unxEcho "/0:n    If defined, the plugin will return the given value when:"
    unxEcho "        if process not found and if service not found or in 'start pending' state"
    unxEcho "/r[:string]                If defined and only for windows services, the plugin will try to restart the requested service"
    unxEcho "                           the provided 'string' needs to automate the behavior, has to be always the macro $SERVICEOUTPUT$"
    unxEcho "/lstate:stateid,string     If defined and only with restart flag, provides the last state ID and the last state type"
    unxEcho "                           by default $SERVICESTATEID$ and $SERVICESTATETYPE$"
    unxEcho "/cpu[:initMS,delayMS,ntests]   if used, set the cpu performance data, in addition you can define (in ms)"
    unxEcho "                               the initial time, the delay time each test and the number of tests"
    unxEcho ""
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

Dim objWMIService, objService, colServices, objProcess, colProcess, myObjItem, myObjItemState, myProcessID, myThreadCount
Dim strComputer, strList, ReturnCode, RCStart, sFound
Dim strCritLimit, strWarnLimit, strCritThrds, strWarnThrds, strWarnCPU, strCritCPU, StrOutput, StrAlerts, StrPerfDt
Dim procList, procName, procCount, procRam, procFullName, SvcName, SvcDisplayName, myProcCPU
Dim cpuUse_check, cpuUse_Items, cpuUse_InitialMS, cpuUse_DelayMS, cpuUse_NumberOfTests
Dim warnLimit, critLimit, warnCPU, critCPU, warnThrds, critThrds, alertWhenZero, StrALERT(4)
Dim countOk, countWarning, countCritical, countUnknown, countOthers
Dim restartEnabled, restartString, restartState

' On Error Resume Next


StrALERT(0) = "OK"
StrALERT(1) = "WARNING"
StrALERT(2) = "CRITICAL"
StrALERT(3) = "UNKNOWN"
warnLimit = 0
critLimit = 0
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
cpuUse_check = false
Redim cpuUse_Items(0)
cpuUse_InitialMS = 300
cpuUse_DelayMS = 300
cpuUse_NumberOfTests = 2

Redim restartState(2)
restartState(0) = 2
restartState(1) = "HARD"

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Help
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
If Not Wscript.Arguments.Named.Exists("p") AND Not Wscript.Arguments.Named.Exists("s") Then
    streamEcho "Plugin help screen:"
    ShowUsage()
    Wscript.Quit(intUnknown)
End If

' --------------------------------------------------
If Wscript.Arguments.Named.Exists("p") Then
    procName = Wscript.Arguments.Named("p")
    procName = Replace(procName,":b:"," ")
    procFullName = procName
End If

If Wscript.Arguments.Named.Exists("s") Then
    procName = Wscript.Arguments.Named("s")
    procName = Replace(procName,":b:"," ")
    SvcDisplayName = ProcName
    procName = UCase(Trim(ProcName))
    if Wscript.Arguments.Named.Exists("r") Then
        restartEnabled = true
        restartString = ""
        If Trim(Wscript.Arguments.Named("r")) <> "" Then
            restartString = Wscript.Arguments.Named("r")
        End If
        if Wscript.Arguments.Named.Exists("lstate") Then
            restartState = Split(Wscript.Arguments.Named("lstate"),",")
        End If
    End If
End If

if Wscript.Arguments.Named.Exists("w") Then
    warnLimit = CInt(Wscript.Arguments.Named("w"))
End If

if Wscript.Arguments.Named.Exists("c") Then
    critLimit = CInt(Wscript.Arguments.Named("c"))
End If

if Wscript.Arguments.Named.Exists("wc") Then
    warnCPU = CDbl(Wscript.Arguments.Named("wc"))
End If

if Wscript.Arguments.Named.Exists("cc") Then
    critCPU = CDbl(Wscript.Arguments.Named("cc"))
End If

if Wscript.Arguments.Named.Exists("wt") Then
    warnThrds = CInt(Wscript.Arguments.Named("wt"))
End If

if Wscript.Arguments.Named.Exists("ct") Then
    critThrds = CInt(Wscript.Arguments.Named("ct"))
End If

if Wscript.Arguments.Named.Exists("cpu") Then
    cpuUse_Items = Split(Wscript.Arguments.Named("cpu"),",")
    If UBound(cpuUse_Items) >= 2 Then
        cpuUse_InitialMS        = cpuUse_Items(0)
        cpuUse_DelayMS          = cpuUse_Items(1)
        cpuUse_NumberOfTests    = cpuUse_Items(2)
        dosEcho cpuUse_NumberOfTests & " - " & cpuUse_DelayMS  & " - " & cpuUse_InitialMS
    End If
    cpuUse_check = true
End If

if Wscript.Arguments.Named.Exists("list") Then
    procList = 1
End If
if Wscript.Arguments.Named.Exists("0") Then
    alertWhenZero = CInt(Wscript.Arguments.Named("0"))
End If

If Wscript.Arguments.Named.Exists("s") Then
' SERVICE QUERY --------------------------------------------------
    strComputer = "."
    Set objWMIService = GetObject( "winmgmts:\\" & strComputer & "\root\CIMV2")
    Set colServices = objWMIService.ExecQuery( "SELECT * FROM Win32_Service",,48)
    sFound = 0
    procRam = 0
    procCount = 0
    myThreadCount = 0
    myProcCPU = 0
    For Each objService in colServices
        if procList = 1 Then
            dosEcho "'" & objService.DisplayName & "'   '" & objService.Name & "'  -> " & objService.State & " -> " & objService.Status
        End If
        If InStr(Trim(UCase(objService.DisplayName)),ProcName) > 0 OR InStr(Trim(UCase(objService.Name)),ProcName) Then
            set myObjItem = objService
            MyProcessID = objService.ProcessId
            If MyProcessID > 0 Then
                Set colProcess = objWMIService.ExecQuery("Select * from Win32_Process WHERE ProcessID=" & MyProcessID)
                For Each objProcess in colProcess
                    myThreadCount = myThreadCount + objProcess.ThreadCount
                    procCount = procCount + 1
                    procFullName = objProcess.Name
                    procRam = procRam + (objProcess.WorkingSetSize / 1024)
                    if cpuUse_check Then
                        myProcCPU = myProcCPU + CPUUsage( MyProcessID, cpuUse_InitialMS, cpuUse_DelayMS, cpuUse_NumberOfTests )
                    End If
                Next
                Set colProcess = nothing
            End If
            sFound = 1
            Exit For
        End If
    Next

    myObjItemState = "NOTFOUND"
    If sFound > 0 Then
        myObjItemState = myObjItem.State
        SvcDisplayName = objService.DisplayName
        SvcName = objService.Name
        Select case myObjItem.State
            Case "Stopped"
                ReturnCode = 2
            Case "Start Pending"
                ReturnCode = alertWhenZero
            Case "Stop Pending"
                ReturnCode = 2
            Case "Running"
                ReturnCode = 0
            Case "Continue Pending"
                ReturnCode = 2
            Case "Pause Pending"
                ReturnCode = 2
            Case "Paused"
                ReturnCode = 2
            Case "Unknown"
                ReturnCode = 2
        End Select
    End If

    Set colServices = nothing

    If sFound = 0 and alertWhenZero <> -1 then
        StrAlerts = "No services with the DisplayName: '" & SvcDisplayName & "'"
        ReturnCode = alertWhenZero
    Else
        If procList = 0 Then
            if (critLimit > 0) Then
                strCritLimit = CStr(critLimit)
                If (procCount >= critLimit) Then
                    ReturnCode = 2
                End If
            Else
                strCritLimit = ""
            End If

            if (warnLimit > 0) Then
                strWarnLimit = CStr(warnLimit)
                If (procCount >= warnLimit) Then
                    ReturnCode = 1
                End If
            Else
                strWarnLimit = ""
            End If

            If ReturnCode = 0 Then
                if (critThrds > 0) Then
                    strCritThrds = CStr(critThrds)
                    If (myThreadCount >= critThrds) Then
                        ReturnCode = 2
                    End If
                Else
                    strCritThrds = ""
                End If

                if (warnThrds > 0) Then
                    strWarnThrds = CStr(warnThrds)
                    If (myThreadCount >= warnThrds) Then
                        ReturnCode = 1
                    End If
                Else
                    strWarnThrds = ""
                End If
            End If

            If ReturnCode = 0 Then
                if (critCPU > 0) Then
                    strCritCPU = CStr(critCPU)
                    If (myProcCPU >= critCPU) Then
                        ReturnCode = 2
                    End If
                Else
                    strCritCPU = ""
                End If

                if (warnCPU > 0) Then
                    strWarnCPU = CStr(warnCPU)
                    If (myProcCPU >= warnCPU) Then
                        ReturnCode = 1
                    End If
                Else
                    strWarnCPU = ""
                End If
            End If
        End If
    End If

    select case ReturnCode
        case 0
            countOk = 1
            countWarning = 0
            countCritical = 0
            countUnknown = 0
            countOthers = 0
        case 1
            countOk = 0
            countWarning = 1
            countCritical = 0
            countUnknown = 0
            countOthers = 0
        case 2
            countOk = 0
            countWarning = 0
            countCritical = 1
            countUnknown = 0
            countOthers = 0
        case 3
            countOk = 0
            countWarning = 0
            countCritical = 0
            countUnknown = 1
            countOthers = 0
        case else
            countOk = 0
            countWarning = 0
            countCritical = 0
            countOthers = 1
    End Select

    StrPerfDt = "ok=" & countOk & ";;;; warning=" & countWarning & ";;;; critical=" & countCritical & ";;;; unknown=" & countUnknown & ";;;; others=" & countOthers & ";;;; 'proc_nbr'=" & procCount & "Qty;" & strWarnLimit & ";" & strCritLimit & ";;  Threads=" & myThreadCount & "Qty;" & strWarnThrds & ";" & strCritThrds & ";; proc_ram=" & procRam & "kb;;;; cpu=" & myProcCPU & "%;" & strWarnCPU & ";" & strCritCPU & ";; "
    If Trim(StrAlerts) = "" Then
        StrOutput = StrALERT(ReturnCode) & ": " & "Service Name:" & SvcDisplayName & " (" & procFullName & ") State: " & myObjItemState
    Else
        StrOutput = StrALERT(ReturnCode) & ": " & StrAlerts
    End If

    myObjItemState = UCase(myObjItemState)
    If myObjItemState = "STOPPED" AND restartEnabled Then
        If Not patternMatch(UCase(restartString),".*(RESTART FAILED).*",0) Then
            If Not patternMatch(UCase(restartString),".*(TRYING TO START).*",0) Then
                If restartState(0) <> 0 AND ucase(restartState(1)) = "HARD" Then
                    ' 'restart' requested, so we try to restart cause the state is 'stopped', any other state are unpredictable
                    ' Trying to start service
                    Set colServices = objWMIService.ExecQuery("Select * from Win32_Service Where Name = '" & SvcName & "'")
                    For Each objService in colServices
                        RCStart = objService.StartService()
                    Next
                    StrOutput = "Action:TRYING TO START ON " & StrOutput
                End If
            Else
                StrOutput = "Issue:RESTART FAILED ON " & StrOutput
            End If
        Else
            StrOutput = "Issue:RESTART FAILED ON " & StrOutput
        End If
    End If
    
    StrOutput = StrOutput & "|" & StrPerfDt
End If

If Wscript.Arguments.Named.Exists("p") Then
' PROCESS QUERY --------------------------------------------------
    strComputer = "."

    Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
    Set colProcess = objWMIService.ExecQuery("Select * from Win32_Process where name Like '%" & procName & "%'")
    If procList = 1 Then
        For Each objProcess in colProcess
            dosEcho(objProcess.Name & " - " & (objProcess.WorkingSetSize / 1024) & "KB")
        Next
        Wscript.Quit(intOK)
    Else
        procRam = 0
        procCount = 0
        myThreadCount = 0
        myProcCPU = 0
        For Each objProcess in colProcess
            'If (InStr(1,objProcess.Name,procName,1) > 0) Then
            if cpuUse_check Then
                myProcCPU = myProcCPU + CPUUsage( objProcess.ProcessID, cpuUse_InitialMS, cpuUse_DelayMS, cpuUse_NumberOfTests )
            End If
            procFullName = objProcess.Name
            myThreadCount = myThreadCount + objProcess.ThreadCount
            procCount = procCount + 1
            procRam = procRam + (objProcess.WorkingSetSize / 1024)
            'End If
        Next
        if procCount = 0 and alertWhenZero <> -1 then
            StrAlerts = "No running processes found!"
            ReturnCode = alertWhenZero
        end if
    End If

    If ReturnCode < 0 or ReturnCode > 3 Then
        ReturnCode = 3
    Else
        If procList = 0 Then
            if (critLimit > 0) Then
                strCritLimit = CStr(critLimit)
                If (procCount >= critLimit) Then
                    ReturnCode = 2
                End If
            Else
                strCritLimit = ""
            End If

            if (warnLimit > 0) Then
                strWarnLimit = CStr(warnLimit)
                If (procCount >= warnLimit) Then
                    ReturnCode = 1
                End If
            Else
                strWarnLimit = ""
            End If

            If ReturnCode = 0 Then
                if (critThrds > 0) Then
                    strCritThrds = CStr(critThrds)
                    If (myThreadCount >= critThrds) Then
                        ReturnCode = 2
                    End If
                Else
                    strCritThrds = ""
                End If

                if (warnThrds > 0) Then
                    strWarnThrds = CStr(warnThrds)
                    If (myThreadCount >= warnThrds) Then
                        ReturnCode = 1
                    End If
                Else
                    strWarnThrds = ""
                End If
            End If

            If ReturnCode = 0 Then
                if (critCPU > 0) Then
                    strCritCPU = CStr(critCPU)
                    If (myProcCPU >= critCPU) Then
                        ReturnCode = 2
                    End If
                Else
                    strCritCPU = ""
                End If

                if (warnCPU > 0) Then
                    strWarnCPU = CStr(warnCPU)
                    If (myProcCPU >= warnCPU) Then
                        ReturnCode = 1
                    End If
                Else
                    strWarnCPU = ""
                End If
            End If
        End If
    End If

    If Trim(StrAlerts) = "" Then
        
        StrOutput = StrALERT(ReturnCode) & ": " & procFullName & " " & procCount & " running (" & procRam & "KB used ram)"
    Else
        StrOutput = StrALERT(ReturnCode) & ": " & StrAlerts
    End If

    StrPerfDt = "'proc_nbr'=" & procCount & "Qty;" & strWarnLimit & ";" & strCritLimit & ";; 'Threads'=" & myThreadCount & "Qty;" & strWarnThrds & ";" & strCritThrds & ";; 'proc_ram'=" & procRam & "kb;;;; 'cpu'=" & myProcCPU & "%;" & strWarnCPU & ";" & strCritCPU & ";; "
    StrOutput = StrOutput & "|" & StrPerfDt
End If

WScript.Stdout.Write StrOutput
WScript.Quit(ReturnCode)

' End of List Process Example VBScript
