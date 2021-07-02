''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' "check_ctx_quota.wsf"
' Original from
' Fabio Frioni (fabio.frioni@gmail.com)
'
' 
' 11.2011 ver 0.9b (fabio.frioni@gmail.com)
'added support for method (free space|used space), default used space
'Percentage in decimals for data and /w and /c
'added performances
' ---
'
' --------------------------------------------------------------
' This plugin returns the Citrix Cache Quota disk usage, Free And Used space In MB And %
'

Option Explicit

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Const's and Var's
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'Cons for return val's
Const intOK = 0
Const intWarning = 1
Const intCritical = 2
Const intUnknown = 3

Const HKEY_CLASSES_ROOT     = &H80000000
Const HKEY_CURRENT_USER     = &H80000001
Const HKEY_LOCAL_MACHINE    = &H80000002
Const HKEY_USERS            = &H80000003
Const HKEY_CURRENT_CONFIG   = &H80000005
Const HKCR   = &H80000000
Const HKCU   = &H80000001
Const HKLM   = &H80000002
Const HKUS   = &H80000003
Const HKCC   = &H80000005

const REG_SZ = 1
const REG_EXPAND_SZ = 2
const REG_BINARY = 3
const REG_DWORD = 4
const REG_MULTI_SZ = 7

Function getFolderSize(folder)
    dim oFS, oFolder
    set oFS = WScript.CreateObject("Scripting.FileSystemObject")
    set oFolder = oFS.GetFolder(folder)
    getFolderSize = oFolder.Size
    set oFolder = nothing
    set oFS = nothing
End Function


Function RegistryRead(strRegKey)
    Dim WshShell
    Set WshShell = Wscript.CreateObject("Wscript.Shell")
    RegistryRead = WshShell.RegRead(strRegKey)
    Set WshShell = nothing
End Function


Function CPUUSage( ProcID )
    Dim objWMI, objInstance1, perf_instance2, PercentProcessorTime
    Dim N0, D0, N, D, NProbes, I


    Set objWMI = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
    For Each objInstance1 in objWMI.ExecQuery("Select * from Win32_PerfRawData_PerfProc_Process Where IDProcess = '" & ProcID & "'")
        N0 = objInstance1.PercentProcessorTime
        D0 = objInstance1.TimeStamp_Sys100NS
        'Exit For
    Next
    WScript.Sleep(500)
    N = 0
    D = 0
    NProbes = 3
    For I = 1 to NProbes
        For Each perf_instance2 in objWMI.ExecQuery("Select * from Win32_PerfRawData_PerfProc_Process Where IDProcess = '" & ProcID & "'")
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
    unxEcho "The nagios plugins come with ABSOLUTELY NO WARRANTY. You may redistribute"
    unxEcho "copies of the plugins under the terms of the GNU General Public License."
    unxEcho "For more information about these matters, see the file named COPYING."
    unxEcho "Copyright (c) 1999-2001 Ethan Galstad/Hagen Deike (nagios@samurai.inka.de)"
    unxEcho ""
    unxEcho "Author: Fabio Frioni - Intesi Group SPA (ffrioni@intesigroup.com) (fabio.frioni@gmail.com)"
    unxEcho ""
    unxEcho "check_ctx_quota.vbs (nrpe_nt-plugin) 0.99b"
    unxEcho "Optional arguments:"
    unxEcho "/H:name        host name to be checked remotely"
    unxEcho "/regkey:key    the full path of regkey. by default is HKEY_LOCAL_MACHINE\SOFTWARE\Citrix\Rade"
    unxEcho "/w:n           the warning limit for processes. If 0 the limit is Max. If -1, there is no warning limit."
    unxEcho "               By default is -1. No takes effect for service queries"
    unxEcho "/c:n           the critical limit for processes. If 0, there is no critical limit."
    unxEcho "               By default is 0.  No takes effect for service queries"
    unxEcho "/0:n           If defined, the plugin will return the given value when:"
    unxEcho "               if a key is not found."
    unxEcho "/h             this help."
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
Dim objWMIService, objService, colServices, objProcess, colProcess, myObjItem, myObjItemState, myProcessID, myThreadCount
Dim strComputer, strList, ReturnCode, sFound, Idx, Idx2
Dim strCritLimit, strWarnLimit, strCritThrds, strWarnThrds, strWarnCPU, strCritCPU, StrOutput, StrAlerts, StrPerfDt
Dim procList, regKey, hostName, procCount, procRam, procFullName, SvcFullName, myProcCPU
Dim warnLimit, critLimit, warnCPU, critCPU, warnThrds, critThrds, alertWhenZero, StrALERT(4)
Dim countOk, countWarning, countCritical, countUnknown, countOthers
Dim arrResult, arrRegKeyStr, folderSize, cacheSize, percSize

'On Error Resume Next


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
hostName = ""
ReturnCode = 0
sFound = 0

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Help
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
If Wscript.Arguments.Named.Exists("h") Then
    streamEcho "Plugin help screen:"
    ShowUsage()
    Wscript.Quit(intUnknown)
End If

' --------------------------------------------------
arrRegKeyStr = Split("HKLM\SOFTWARE\Citrix\Rade\CacheLocation,HKLM\SOFTWARE\Citrix\Rade\CacheLimitMb",",")
Redim arrResult(UBound(arrRegKeyStr))

If Wscript.Arguments.Named.Exists("H") Then
    hostName = Wscript.Arguments.Named("H")
    procFullName = hostName
End If

If Wscript.Arguments.Named.Exists("regkey") Then
    regKey = Wscript.Arguments.Named("regkey")
    arrRegKeyStr = Split(regKey,",")
    Redim arrResult(UBound(arrRegKeyStr))
End If

if Wscript.Arguments.Named.Exists("w") Then
    warnLimit = CInt(Wscript.Arguments.Named("w"))
End If

if Wscript.Arguments.Named.Exists("c") Then
    critLimit = CInt(Wscript.Arguments.Named("c"))
End If

For Idx = 0 to UBound(arrRegKeyStr)
    arrResult(Idx) = RegistryRead(arrRegKeyStr(Idx))
    If IsEmpty(arrResult(Idx)) Then
        streamEcho "Unknown: bad registry result (" & arrRegKeyStr(Idx) & "). Please check key syntax."
        WScript.quit(3)
    End If
Next

folderSize = Round(GetFolderSize(arrResult(0)) / 1024 / 1024,2)
cacheSize = arrResult(1)

percSize = Round((folderSize * 100) / cacheSize, 2)
ReturnCode=0
if (warnLimit > 0) Then
    strWarnLimit = CStr(warnLimit)
    If (percSize >= warnLimit) Then
        ReturnCode = 1
    End If
Else
    strWarnLimit = ""
End If

if (critLimit > 0) Then
    strCritLimit = CStr(critLimit)
    If (percSize >= critLimit) Then
        ReturnCode = 2
    End If
Else
    strCritLimit = ""
End If

StrPerfDt = "'cacheUsed'=" & percSize & "%;" & strWarnLimit & ";" & strCritLimit & ";; 'cacheUsedMB'=" & folderSize & ";;;; "
If Trim(StrAlerts) = "" Then
    StrOutput = StrALERT(ReturnCode) & ": " & "Cache size: " & cacheSize & "MB; Folder size: " & folderSize & "MB; Perc: " & percSize & "%"
Else
    StrOutput = StrALERT(ReturnCode) & ": " & StrAlerts
End If
StrOutput = StrOutput & "|" & StrPerfDt
streamEcho StrOutput

WScript.quit(ReturnCode)
