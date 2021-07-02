'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' "check_memory.vbs"
' Original from
' Fabio Frioni (fabio.frioni@gmail.com)
'
' Inspired from:
' ///////////////////////////////////////////////////////////////////////////////
' // ActiveXperts Network Monitor  - VBScript based checks
' // ActiveXperts Software B.V.
' //
' // For more information about ActiveXperts Network Monitor and VBScript, please
' // visit the online ActiveXperts Network Monitor VBScript Guidelines at:
' //    http://www.activexperts.com/support/network-monitor/online/vbscript/
' // 
' ///////////////////////////////////////////////////////////////////////////////
'  
' 13.09.2011 ver 1.0
' Complete check monitor memory in WMI. For help, type check_memory /h
' -------------------------------------------------------------------------------------
'

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Main
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

Option Explicit


Const  retvalUnknown = 3

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Const's and Var's
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'Cons for return val's
Const intOK = 0
Const intWarning = 1
Const intCritical = 2
Const intUnknown = 3

Dim SYSDATA, SYSEXPLANATION  ' Used by Network Monitor, don't change the names
Dim StrOutput, ReturnCode, StrPerfData, StrALERT(4), arrStream,arr2Lic,arrLic
Dim strQueryType
Dim arrWarning(3),arrCritica(3)
Dim warnExpire,critExpire,strWarnExpire, strCritExpire
Dim CheckVersion, licList, StrDaysToExpire, DaysToExpire, StrDErpire, arrDExpire
Dim Idx, Idx2, Months

arrWarning(0) = 0
arrWarning(1) = 0
arrWarning(2) = 0
arrCritica(0) = 0
arrCritica(1) = 0
arrCritica(2) = 0

Months="JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC"
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Help
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
on error resume next

If Not Wscript.Arguments.Named.Exists("q") Then
    streamEcho "Plugin help screen:"
    ShowUsage()
    Wscript.Quit(intUnknown)
End If
strQueryType = LCase(Trim(Replace(Wscript.Arguments.Named("q"),"","")))

if Wscript.Arguments.Named.Exists("w") AND Wscript.Arguments.Named("w") <> "" Then
    arrWarning(0) = Cdbl(Wscript.Arguments.Named("w"))
End If
if Wscript.Arguments.Named.Exists("c") AND Wscript.Arguments.Named("c") Then
    arrCritica(0) = Cdbl(Wscript.Arguments.Named("c"))
End If

Select case strQueryType
    Case "commit"
    Case "page"
    Case "memuse"
        if Wscript.Arguments.Named.Exists("wp") AND  Wscript.Arguments.Named("wp") <> "" Then
            arrWarning(1) = Cdbl(Wscript.Arguments.Named("wp"))
        End If
        if Wscript.Arguments.Named.Exists("cp") AND Wscript.Arguments.Named("cp") Then
            arrCritica(1) = Cdbl(Wscript.Arguments.Named("cp"))
        End If
        if Wscript.Arguments.Named.Exists("ws") AND Wscript.Arguments.Named("ws") Then
            arrWarning(2) = Cdbl(Wscript.Arguments.Named("ws"))
        End If
        if Wscript.Arguments.Named.Exists("cs") AND Wscript.Arguments.Named("cs") Then
            arrCritica(2) = Cdbl(Wscript.Arguments.Named("cs"))
        End If

        if Wscript.Arguments.Named.Exists("list") Then
            licList = 1
        End If

    Case Else
        streamEcho "Plugin help screen:"
        ShowUsage()
        Wscript.Quit(intUnknown)
End Select


StrALERT(0) = "OK"
StrALERT(1) = "WARNING"
StrALERT(2) = "CRITICAL"
StrALERT(3) = "UNKNOWN"

on error goto 0

Dim bResult
bResult = 0
Select case strQueryType
    Case "memuse"
        bResult =  checkFreeVirtualMemory( "localhost", "", 100 )
        
    Case "commit"
        bResult = CheckCommittedMemory( "localhost", "", 100 )

    Case "page"
        bResult = CheckPagesPerSecond( "localhost", "", 100 )

End Select

streamEcho StrALERT(bResult) & ": " & SYSEXPLANATION & "|" & SYSDATA        
Wscript.Quit(bResult)
' //////////////////////////////////////////////////////////////////////////////

Function checkFreeVirtualMemory( strComputer, strCredentials, nMinMB )

' Description: 
'     Check free memory (MB) on the computer specified by strComputer
' Parameters:
'     1) strComputer As String - Hostname or IP address of the computer you want to check
'     2) strCredentials As String - Specify an empty string to use Network Monitor service credentials.
'         To use alternate credentials, enter a server that is defined in Server Credentials table.
'         (To define Server Credentials, choose Tools->Options->Server Credentials)
'     3) nMinMB As Number - Minimum required free memory (in MB)
' Usage:
'     checkFreeVirtualMemory( "", "", Min_MB )
' Sample:
'     checkFreeVirtualMemory( "localhost", "", 100 )

    Dim objWMIService

    checkFreeVirtualMemory      = retvalUnknown  ' Default return value
    SYSDATA          = ""             ' Initally empty; will contain the number of free MBs
    SYSEXPLANATION   = ""             ' Set initial value

    If( Not getWMIObject( strComputer, strCredentials, objWMIService, SYSEXPLANATION ) ) Then
        Exit Function
    End If

    checkFreeVirtualMemory      = checkFreeVirtualMemoryWMI( objWMIService, strComputer, nMinMB, SYSDATA, SYSEXPLANATION )

End Function

' //////////////////////////////////////////////////////////////////////////////

Function CheckPagesPerSecond( strComputer, strCredentials, nMaxPages )

' Description: 
'     Check pages per second on the computer specified by strComputer
' Parameters:
'     1) strComputer As String - Hostname or IP address of the computer you want to check
'     2) strCredentials As String - Specify an empty string to use Network Monitor service credentials.
'         To use alternate credentials, enter a server that is defined in Server Credentials table.
'         (To define Server Credentials, choose Tools->Options->Server Credentials)
'     3) nMaxPages As Number - Maximum pages per second allowed
' Usage:
'     CheckPagesPerSecond( "", "", Max_Pages )
' Sample:
'     CheckPagesPerSecond( "localhost", "", 5 )

    Dim objWMIService

    CheckPagesPerSecond = retvalUnknown  ' Default return value
    SYSDATA             = ""             ' Initally empty; will contain the number of free MBs
    SYSEXPLANATION      = ""             ' Set initial value

    If( Not getWMIObject( strComputer, strCredentials, objWMIService, SYSEXPLANATION ) ) Then
        Exit Function
    End If

    CheckPagesPerSecond = checkPagesPerSecondWMI( objWMIService, strComputer, nMaxPages, SYSDATA, SYSEXPLANATION )

End Function


' //////////////////////////////////////////////////////////////////////////////

Function CheckCommittedMemory( strComputer, strCredentials, nMaxCommittedMB )

' Description: 
'     Check free memory (MB) on the computer specified by strComputer
' Parameters:
'     1) strComputer As String - Hostname or IP address of the computer you want to check
'     2) strCredentials As String - Specify an empty string to use Network Monitor service credentials.
'         To use alternate credentials, enter a server that is defined in Server Credentials table.
'         (To define Server Credentials, choose Tools->Options->Server Credentials)
'     3) nMaxCommittedMB  As Number - Maximum allowed committed memory (in MB)
' Usage:
'     CheckCommittedMemory( "", "", Max_MB )
' Sample:
'     CheckCommittedMemory( "localhost", "", 800 )

    Dim objWMIService

    CheckCommittedMemory  = retvalUnknown  ' Default return value
    SYSDATA               = ""             ' Initally empty; will contain the number of free MBs
    SYSEXPLANATION        = ""             ' Set initial value

    If( Not getWMIObject( strComputer, strCredentials, objWMIService, SYSEXPLANATION ) ) Then
        Exit Function
    End If

    CheckCommittedMemory      = checkCommittedMemoryWMI( objWMIService, strComputer, nMaxCommittedMB, SYSDATA, SYSEXPLANATION )

End Function



' //////////////////////////////////////////////////////////////////////////////
' //
' // Private Functions
' //   NOTE: Private functions are used by the above functions, and will not
' //         be called directly by the ActiveXperts Network Monitor Service.
' //         Private function names start with a lower case character and will
' //         not be listed in the Network Monitor's function browser.
' //
' //////////////////////////////////////////////////////////////////////////////

Function checkFreeVirtualMemoryWMI( objWMIService, strComputer, nMinMB, BYREF strSysData, BYREF strSysExplanation )

    Dim colItems, objOS, nFreePhisMemMB, nFreeVirtMemMB, nTotPageMemMB, nFreePageMemMB, nTotVirtMemMB, nTotVisiMemMB, nDiffMB
    Dim nTotMemMB(3), nUsedMemMB(3), nFreeMemMB(3), nUsedMemPerc(3), nFreeMemPerc(3), IDX


    checkFreeVirtualMemoryWMI             = retvalUnknown  ' Default return value


    Set colItems = objWMIService.ExecQuery("Select * from Win32_OperatingSystem")
    If( Err.Number <> 0 ) Then
        strSysData          = ""
        strSysExplanation   = "Unable to query WMI on computer [" & strComputer & "]"
        checkFreeVirtualMemoryWMI       = 2
        Exit Function
    End If
    If( colItems.Count <= 0  ) Then
        strSysData         = ""
        strSysExplanation  = "Win32_OperatingSystem class does not exist on computer [" & strComputer & "]"
        checkFreeVirtualMemoryWMI       = 2
        Exit Function
    End If


    For Each objOS In colItems

        If( Err.Number <> 0 ) Then
            checkFreeVirtualMemoryWMI     = retvalUnknown
            strSysData         = ""
            strSysExplanation  = "Unable to queue memory information." 
            Exit Function 
        End If

        nTotMemMB(2)   = CDbl(objOS.SizeStoredInPagingFiles) / 1024
        nFreeMemMB(2)  = CDbl( objOS.FreeSpaceInPagingFiles ) / 1024
        nTotMemMB(1)   = CDbl( objOS.TotalVisibleMemorySize ) / 1024
        nFreeMemMB(1)  = CDbl( objOS.FreePhysicalMemory ) / 1024
        nTotMemMB(0)   = nTotMemMB(1) + nTotMemMB(2)
        nFreeMemMB(0)  = nFreeMemMB(1) + nFreeMemMB(2)
        
        nUsedMemMB(1)   = ( nTotMemMB(1) - nFreeMemMB(1))
        nUsedMemMB(2)   = ( nTotMemMB(2) - nFreeMemMB(2))
        nUsedMemMB(0)   = ( nTotMemMB(0) - nFreeMemMB(0))
        nUsedMemPerc(1) = (nUsedMemMB(1) * 100 ) / nTotMemMB(1)
        nUsedMemPerc(2) = (nUsedMemMB(2) * 100 ) / nTotMemMB(2)
        nUsedMemPerc(0) = (nUsedMemMB(0) * 100 ) / nTotMemMB(0)
        
        checkFreeVirtualMemoryWMI = 0
        For IDX = 0 to 2
            If arrWarning(IDX) > 0 Then
                If nUsedMemPerc(IDX) >= CDbl(arrWarning(IDX)) Then
                    checkFreeVirtualMemoryWMI = 1
                End If
            Else
                arrWarning(IDX) = ""
            End If
            If arrCritica(IDX) > 0 Then
                If nUsedMemPerc(IDX) >= CDbl(arrCritica(IDX)) Then
                    checkFreeVirtualMemoryWMI = 2
                End If
            Else
                arrCritica(IDX) = ""
            End If
        Next

        For IDX=0 to 2
            nTotMemMB(IDX)      = FormatNumber( nTotMemMB(IDX)      , 2, -1, 0, 0 )
            nFreeMemMB(IDX)     = FormatNumber( nFreeMemMB(IDX)     , 2, -1, 0, 0 )
            nUsedMemMB(IDX)     = FormatNumber( nUsedMemMB(IDX)     , 2, -1, 0, 0 )
            nFreeMemPerc(IDX)   = FormatNumber( nFreeMemPerc(IDX)   , 2, -1, 0, 0 )
            nUsedMemPerc(IDX)   = FormatNumber( nUsedMemPerc(IDX)   , 2, -1, 0, 0 )
        Next

        strSysExplanation =   "Virtual tot:"  & nTotMemMB(0) & "mb; used:" & nUsedMemPerc(0) & "%" & _
                            " - Physical tot:" & nTotMemMB(1) & "mb; used:" & nUsedMemPerc(1) & "%" & _
                            " - Paging tot:"   & nTotMemMB(2) & "mb; used:" & nUsedMemPerc(2) & "%"

        strSysData = "'virtual memory perc'="  & nUsedMemPerc(0) & "%;"  & arrWarning(0)  & ";" & arrCritica(0)  & ";; " & _
                     "'physical memory'="      & nUsedMemPerc(1) & "%;"  & arrWarning(1)  & ";" & arrCritica(1)  & ";; " & _
                     "'page memory perc'="     & nUsedMemPerc(2) & "%;"  & arrWarning(2)  & ";" & arrCritica(2)  & ";; "

        For IDX = 0 to 2
            If arrWarning(IDX) <> "" Then
                arrWarning(IDX) = FormatNumber((CDbl(arrWarning(IDX))*nTotMemMB(0))/100 , 2, -1, 0, 0 )
            End If
            If arrCritica(IDX) <> "" Then
                arrCritica(IDX) = FormatNumber((CDbl(arrCritica(IDX))*nTotMemMB(0))/100 , 2, -1, 0, 0 )
            End If
        Next

        strSysData = strSysData & _
                    "'virtual memory size'="  & nUsedMemMB(0)   & "mb;" & arrWarning(0) & ";" & arrCritica(0) & ";; " & _
                    "'physical memory size'=" & nUsedMemMB(1)   & "mb;" & arrWarning(1) & ";" & arrCritica(1) & ";; " & _
                    "'page memory size'="     & nUsedMemMB(2)   & "mb;" & arrWarning(2) & ";" & arrCritica(2) & ";; "
    Next

End Function

' //////////////////////////////////////////////////////////////////////////////

Function checkPagesPerSecondWMI( objWMIService, strComputer, nMaxPages, BYREF strSysData, BYREF strSysExplanation )

    Dim colItems, i, nPages, nDiffPages

    checkPagesPerSecondWMI    = retvalUnknown  ' Default return value


    Set colItems = objWMIService.ExecQuery("Select * from Win32_PerfFormattedData_PerfOS_Memory" )
    If( Err.Number <> 0 ) Then
        strSysData         = ""
        strSysExplanation  = "Unable to query WMI on computer [" & strComputer & "]"
        Exit Function
    End If
    If( colItems.Count <= 0  ) Then
        strSysData         = ""
        strSysExplanation  = "Win32_PerfFormattedData_PerfOS_Memory class does not exist on computer [" & strComputer & "]"
        Exit Function
    End If


    For Each i In colItems: Exit For: Next    'Hack to recover object from collection.

        If( Err.Number <> 0 ) Then
            checkPagesPerSecondWMI = retvalUnknown
            strSysData             = ""
            strSysExplanation      = "Unable to queue memory information." 
            Exit Function 
        End If

        nPages                     = i.PagesPerSec
        
        checkPagesPerSecondWMI = 0
        For IDX = 0 to 0
            If arrWarning(IDX) > 0 Then
                If nPages >= CDbl(arrWarning(IDX)) Then
                    checkPagesPerSecondWMI = 1
                End If
            Else
                arrWarning(IDX) = ""
            End If
            If arrCritica(IDX) > 0 Then
                If nPages >= CDbl(arrCritica(IDX)) Then
                    checkPagesPerSecondWMI = 2
                End If
            Else
                arrCritica(IDX) = ""
            End If
        Next

        strSysExplanation          = "Paging per second:" & nPages
        
        strSysData             =  "'paging'=" & nPages & ";" & arrWarning(0) & ";" & arrCritica(0) & ";; "
        
End Function

' //////////////////////////////////////////////////////////////////////////////

Function checkCommittedMemoryWMI( objWMIService, strComputer, nMaxMB, BYREF strSysData, BYREF strSysExplanation )

    Dim colItems, i, nCommittedMB, nCommitLimMB, nCommittedPerc

    checkCommittedMemoryWMI    = retvalUnknown  ' Default return value


    Set colItems = objWMIService.ExecQuery("Select * from Win32_PerfFormattedData_PerfOS_Memory" )
    If( Err.Number <> 0 ) Then
        strSysData         = ""
        strSysExplanation  = "Unable to query WMI on computer [" & strComputer & "]"
        Exit Function
    End If
    If( colItems.Count <= 0  ) Then
        strSysData         = ""
        strSysExplanation  = "Win32_PerfFormattedData_PerfOS_Memory class does not exist on computer [" & strComputer & "]"
        Exit Function
    End If


    For Each i In colItems: Exit For: Next    'Hack to recover object from collection.

        If( Err.Number <> 0 ) Then
            checkCommittedMemoryWMI    = retvalUnknown
            strSysData         = ""
            strSysExplanation  = "Unable to queue memory information." 
            Exit Function 
        End If

        nCommittedMB           = FormatNumber( i.CommittedBytes / ( 1024 * 1024 ), 2, -1, 0, 0 )
        nCommitLimMB           = FormatNumber( i.CommitLimit / ( 1024 * 1024 ), 2, -1, 0, 0 )
        nCommittedPerc         = FormatNumber((CDbl(nCommittedMB) * 100) / CDbl(nCommitLimMB) , 2, -1, 0, 0)

        checkCommittedMemoryWMI = 0
        For IDX = 0 to 0
            If arrWarning(IDX) > 0 Then
                If CDbl(nCommittedPerc) >= CDbl(arrWarning(IDX)) Then
                    checkCommittedMemoryWMI = 1
                End If
            Else
                arrWarning(IDX) = ""
            End If
            If arrCritica(IDX) > 0 Then
                If CDbl(nCommittedPerc) >= CDbl(arrCritica(IDX)) Then
                    checkCommittedMemoryWMI = 2
                End If
            Else
                arrCritica(IDX) = ""
            End If
        Next

        strSysExplanation      = "Virtual memory limit: " & nCommitLimMB & "mb; Used:" & nCommittedPerc & "%/" & nCommittedMB & "mb"

        strSysData             = "'virtual memory perc'=" & nCommittedPerc & "%;" & arrWarning(0) & ";" & arrCritica(0) & ";; "
        
        For IDX = 0 to 0
            If arrWarning(IDX) <> "" Then
                arrWarning(IDX) = FormatNumber((CDbl(arrWarning(IDX))*CDbl(nCommitLimMB))/100 , 2, -1, 0, 0 )
            End If
            If arrCritica(IDX) <> "" Then
                arrCritica(IDX) = FormatNumber((CDbl(arrCritica(IDX))*CDbl(nCommitLimMB))/100 , 2, -1, 0, 0 )
            End If
        Next

        strSysData = strSysData & _
                     "'virtual memory size'=" & nCommittedMB   & "mb;" & arrWarning(0) & ";" & arrCritica(0) & ";; "

End Function

' //////////////////////////////////////////////////////////////////////////////

Function getWMIObject( strComputer, strCredentials, BYREF objWMIService, BYREF strSysExplanation )	


    Dim objNMServerCredentials, objSWbemLocator, colItems
    Dim strUsername, strPassword

    getWMIObject              = False

    Set objWMIService         = Nothing
    
    If( strCredentials = "" ) Then	
        ' Connect to remote host on same domain using same security context
        Set objWMIService     = GetObject( "winmgmts:{impersonationLevel=Impersonate}!\\" & strComputer &"\root\cimv2" )
    Else
        Set objNMServerCredentials = CreateObject( "ActiveXperts.NMServerCredentials" )

        strUsername           = objNMServerCredentials.GetLogin( strCredentials )
        strPassword           = objNMServerCredentials.GetPassword( strCredentials )

        If( strUsername = "" ) Then
            getWMIObject      = False
            strSysExplanation = "No alternate credentials defined for [" & strCredentials & "]. In the Manager application, select 'Options' from the 'Tools' menu and select the 'Server Credentials' tab to enter alternate credentials"
            Exit Function
        End If
	
        ' Connect to remote host using different security context and/or different domain 
        Set objSWbemLocator   = CreateObject( "WbemScripting.SWbemLocator" )
        Set objWMIService     = objSWbemLocator.ConnectServer( strComputer, "root\cimv2", strUsername, strPassword )

        If( Err.Number <> 0 ) Then
            objWMIService     = Nothing
            getWMIObject      = False
            strSysExplanation = "Unable to access [" & strComputer & "]. Possible reasons: WMI not running on the remote server, Windows firewall is blocking WMI calls, insufficient rights, or remote server down"
            Exit Function
        End If

        objWMIService.Security_.ImpersonationLevel = 3

    End If
	
    If( Err.Number <> 0 ) Then
        objWMIService         = Nothing
        getWMIObject          = False
        strSysExplanation     = "Unable to access '" & strComputer & "'. Possible reasons: no WMI installed on the remote server, no rights to access remote WMI service, or remote server down"
        Exit Function
    End If    

    getWMIObject              = True 

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
    unxEcho "check_memory (nrpe_nt-plugin) 1.0"
    unxEcho "The nagios plugins come with ABSOLUTELY NO WARRANTY. You may redistribute"
    unxEcho "copies of the plugins under the terms of the GNU General Public License."
    unxEcho "For more information about these matters, see the file named COPYING."
    unxEcho "Copyright (c) 1999-2001 Ethan Galstad/Hagen Deike (nagios@samurai.inka.de)"
    unxEcho ""
    unxEcho "Fabio Frioni - Intesi Group SPA (ffrioni@intesigroup.com) (fabio.frioni@gmail.com)"
    unxEcho ""
    unxEcho "Required arguments:"
    unxEcho "/q:query     query type to choose the monitor method, actually possible types:"
    unxEcho "             [ memuse, commit, page ]"
    unxEcho ""
    unxEcho "Optional arguments: for any queries"
    unxEcho "/h           this help."
    unxEcho "/w:n         query type: all. Global warning limit (physical+paged). If 0, there is no limit."
    unxEcho "             by default is 0."
    unxEcho "/c:n         query type: all. Global critical limit (physical+paged). If 0, there is no limit."
    unxEcho "             by default is 0."
    unxEcho ""
    unxEcho "Optional arguments for specific type: memuse"
    unxEcho "/wp:n        query type: memuse. physical warning limit. If 0 the limit is Max. If -1, there is no limit."
    unxEcho "             by default is -1."
    unxEcho "/cp:n        query type: memuse. physical critical limit. If 0 the limit is Max. If -1, there is no limit."
    unxEcho "             by default is -1."
    unxEcho "/ws:n        query type: memuse. Paged warning limit. If 0 the limit is Max. If -1, there is no limit."
    unxEcho "             by default is -1."
    unxEcho "/cs:n        query type: memuse. Paged critical limit. If 0 the limit is Max. If -1, there is no limit."
    unxEcho "             by default is -1."
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


Function ReadStream( strCommand )
' This function reads the stream output of a command
' and put it in a streaming string, the reading is binary type
' Example: "%COMSPEC% /c dir /s c:\*.*"
    Dim objShell
    Dim objWshScriptExec
    Dim objStdOut
    Dim arrStream
    
    If IsNull( strCommand ) Then
        ReadStream = ""
        Exit Function
    End If
    
    If strCommand = "" Then
        ReadStream = ""
        Exit Function
    End If
    
    Set objShell = CreateObject("WScript.Shell")
    Set objWshScriptExec = objShell.Exec( strCommand )
    Set objStdOut = objWshScriptExec.StdOut
    arrStream = objStdOut.ReadAll
    ReadStream = arrStream
End Function

