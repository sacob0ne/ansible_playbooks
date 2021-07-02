'#==============================================================#
'# kill_proc.vbs - check status of process or services       #
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
Dim strComputer, strList, ReturnCode, RCStart, sFound, tempString
Dim strCritLimit, strWarnLimit, strCritThrds, strWarnThrds, strWarnCPU, strCritCPU, StrOutput, StrAlerts, StrPerfDt
Dim procList, procName, procCount, procRam, procFullName, procStatus, SvcName, SvcDisplayName, myProcCPU
Dim cpuUse_check, cpuUse_Items, cpuUse_InitialMS, cpuUse_DelayMS, cpuUse_NumberOfTests
Dim warnLimit, critLimit, warnCPU, critCPU, warnThrds, critThrds, alertWhenZero, StrALERT(4)
Dim countOk, countWarning, countCritical, countUnknown, countOthers
Dim restartEnabled, restartString, restartState
Dim prevOutput, prevStateType, prevStatusId
Dim KillProc,ifkill

' On Error Resume Next

ReturnCode = 0
procName = "WRONG_PROCESSES"

Redim restartState(2)
restartState(0) = 2
restartState(1) = "HARD"

' --------------------------------------------------
If Wscript.Arguments.Named.Exists("p") Then
    procName = Wscript.Arguments.Named("p")
    procName = Replace(procName,":b:"," ")
    procFullName = procName
End If



    strComputer = "."

    Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
    Set colProcess = objWMIService.ExecQuery("Select * from Win32_Process where name Like '%" & procName & "%'")
    For Each objProcess in colProcess
        objProcess.terminate()
        ReturnCode = 2
    Next
WScript.Stdout.Write ReturnCode & vblf
WScript.Quit(ReturnCode)

' End of List Process Example VBScript
