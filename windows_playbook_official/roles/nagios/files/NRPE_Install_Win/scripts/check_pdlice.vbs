''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' "check_pdlice.vbs"
' Original from
' Stefano Paganini & Fabio Frioni
'
' 23.08.2011 ver 1.5
' Read splm licences from pdlice output
' --------------------------------------------------------------
'

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
    unxEcho "check_pdlice (nrpe_nt-plugin) 1.5"
    unxEcho "The nagios plugins come with ABSOLUTELY NO WARRANTY. You may redistribute"
    unxEcho "copies of the plugins under the terms of the GNU General Public License."
    unxEcho "For more information about these matters, see the file named COPYING."
    unxEcho "Copyright (c) 1999-2001 Ethan Galstad/Hagen Deike (nagios@samurai.inka.de)"
    unxEcho ""
    unxEcho "Fabio Frioni - Intesi Group SPA (ffrioni@intesigroup.com) (fabio.frioni@gmail.com)"
    unxEcho "Stefano Paganini - Omega Sistemi (Application.Administration@saipem.com)"
    unxEcho ""
    unxEcho "Required arguments:"
    unxEcho "/l:lic    the license name"
    unxEcho ""
    unxEcho "Optional arguments:"
    unxEcho "/w:n      the warning limit. If 0 the limit is Max. If -1, there is no warning limit."
    unxEcho "          By default is -1."
    unxEcho "/c:n      the critical limit. If 0 the limit is Max. If -1, there is no critical limit."
    unxEcho "          By default is -1."
    unxEcho "/we:n     the warning days to expire. If -1 there is no warning limit."
    unxEcho "          By default is -1."
    unxEcho "/ce:n     the critical days to expire. If -1 there is no critical limit."
    unxEcho "          By default is -1."
    unxEcho "/h        this help."
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


Function ReadStream()
    Dim objShell
    Dim objWshScriptExec
    Dim objStdOut
    Dim arrStream
    
    Set objShell = CreateObject("WScript.Shell")
    Set objWshScriptExec = objShell.Exec("%COMSPEC% /c pdlice -M")
    Set objStdOut = objWshScriptExec.StdOut
    arrStream = objStdOut.ReadAll
    ReadStream = arrStream
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

Dim StrOutput, ReturnCode, StrPerfData, StrALERT(4), arrStream,arr2Lic,arrLic
Dim StrLicense, ReturnCodeExp
Dim warnLimit,critLimit,strWarnLimit, strCritLimit
Dim warnExpire,critExpire,strWarnExpire, strCritExpire
Dim CheckVersion, licList, StrDaysToExpire, DaysToExpire, StrDErpire, arrDExpire
Dim Idx, Idx2, Months

licList = 0
warnLimit = -1
critLimit = -1
warnExpire = -1
critExpire = -1
CheckVersion = 0
Months="JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC"
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Help
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
If Not Wscript.Arguments.Named.Exists("l") Then
    streamEcho "Plugin help screen:"
    ShowUsage()
    Wscript.Quit(intUnknown)
End If
strLicense = UCase(Trim(Replace(Wscript.Arguments.Named("l"),"","")))

if Wscript.Arguments.Named.Exists("w") Then
    warnLimit = CInt(Wscript.Arguments.Named("w"))
End If
if Wscript.Arguments.Named.Exists("c") Then
    critLimit = CInt(Wscript.Arguments.Named("c"))
End If

if Wscript.Arguments.Named.Exists("we") Then
    warnExpire = CInt(Wscript.Arguments.Named("we"))
End If
if Wscript.Arguments.Named.Exists("ce") Then
    critExpire = CInt(Wscript.Arguments.Named("ce"))
End If

if Wscript.Arguments.Named.Exists("list") Then
    licList = 1
End If

On Error Resume Next

StrALERT(0) = "OK"
StrALERT(1) = "WARNING"
StrALERT(2) = "CRITICAL"
StrALERT(3) = "UNKNOWN"

arrStream = ReadStream()
if (licList = 1) Then
    Wscript.echo arrStream
    Wscript.Quit(0)
End If

CheckVersion = InStr(arrStream,"->" & vbtab & "Tag:")
ReturnCode = 0

If (CheckVersion > 0) Then
    ' Versione 11
    IdxLic = InStr(CheckVersion,arrStream, RightPad(strLicense,6, " "))
    If (IdxLic = 0) Then
        ReturnCode = 2
        streamEcho StrALERT(ReturnCode) & ": License not found, please check license name!"
        Wscript.Quit(ReturnCode)
    End If

    IdxRes = InStr(IdxLic,arrStream, "Reserved:") + Len("Reserved:")
    IdxDaily = InStr(IdxRes,arrStream, "Daily")
    
    ' Used Licenses
    intUsed = Trim(Mid(arrStream,IdxRes,IdxDaily - IdxRes))
        
    IdxLic = InStr(IdxDaily,arrStream, RightPad(strLicense,6, " "))
    If (IdxLic = 0) Then
        ReturnCode = 2
        streamEcho StrALERT(ReturnCode) & ": License not found, please check license name!"
        Wscript.Quit(ReturnCode)
    End If
    
    IdxRes = InStr(IdxLic,arrStream, "Seats:") + Len("Seats:")
    IdxDaily = InStr(IdxRes,arrStream, "Daily")
    
    ' Max number of licenses
    intMax = Trim(Mid(arrStream,IdxRes,IdxDaily - IdxRes))
Else
    'Versione 10
    IdxRSCR = InStr(arrStream, "Regular Seats Currently Reserved") + Len("Regular Seats Currently Reserved")
    IdxOBrk = InStr(IdxRSCR,arrStream, "[")
    IdxCBrk = InStr(IdxOBrk,arrStream, "]")
    strArrLic = Mid(arrStream,IdxOBrk + 1,IdxCBrk - IdxOBrk - 1 )
    strArrLic = Replace(Replace(Replace(Replace(strArrLic,vbcrlf,""),vbtab,""),vblf,"")," ","")
    arrLic = Split(strArrLic,",")
    iFound=0
    For Idx = 0 TO UBound(arrLic)
        If (Instr(arrLic(Idx),strLicense & ":") = 1 ) Then
            iFound = 1
            arr2Lic = Split(arrLic(Idx),":")
            ' Used Licenses
            intUsed = arr2Lic(1)
            Exit For
        End If
    Next
    If (iFound = 0) Then
        ReturnCode = 2
        streamEcho StrALERT(ReturnCode) & ": 1 License not found, please check license name!"
        Wscript.Quit(ReturnCode)
    End If

    IdxRSCR = InStr(arrStream, "No. Of Seats") + Len("No. Of Seats")
    IdxOBrk = InStr(IdxRSCR,arrStream, "[")
    IdxCBrk = InStr(IdxOBrk,arrStream, "]")
    strArrLic = Mid(arrStream,IdxOBrk+1,IdxCBrk - IdxOBrk - 1)
    strArrLic = Replace(Replace(Replace(Replace(strArrLic,vbcrlf,""),vbtab,""),vblf,"")," ","")
    arrLic = Split(strArrLic,",")
    iFound=0
    For Idx = 0 TO UBound(arrLic)
        If (Instr(arrLic(Idx),strLicense & ":") = 1 ) Then
            iFound = 1
            arr2Lic = Split(arrLic(Idx),":")
            ' Max number of licenses
            intMax = arr2Lic(1)
            Exit For
        End If
    Next
    If (iFound = 0) Then
        ReturnCode = 2
        streamEcho StrALERT(ReturnCode) & ": 2 License not found, please check license name!"
        Wscript.Quit(ReturnCode)
    End If
End If

' Find Expiration date
Idx  = InStr(arrStream, "Expires After             ->") + Len("Expires After             ->")
Idx2 = InStr(Idx, arrStream, CHR(10))
StrDExpire = Mid(arrStream,Idx+1,Idx2 - Idx - 1)
arrDExpire = Split(StrDExpire,"-")

' Calc expiration days
If(UBound(arrDExpire) > 0) Then
    DaysToExpire= DateDiff("d", Date, DateSerial(arrDExpire(2),Int(InStr(Months,UCase(arrDExpire(1)))/3)+1,arrDExpire(0)))
Else
    DaysToExpire = -1
End If

' Translate expiration days in string, if expired notify that
If DaysToExpire <= 0 Then
    StrDaysToExpire = "EXPIRED!"
Else
    StrDaysToExpire = CStr(DaysToExpire)
End If

strWarnLimit = CStr(warnLimit)
strCritLimit = CStr(critLimit)
strWarnExpire = ""
strCritExpire = ""

ReturnCode = 0
' Check when users are using the features
if (CInt(critLimit) > 0) Then
    If (CInt(intUsed) >= CInt(critLimit)) Then
        ReturnCode = 2
    End If
ElseIf (CInt(critLimit) = 0) Then
    strCritLimit = CStr(intMax)
    If (CInt(intUsed) >= CInt(intMax)) Then
        ReturnCode = 2
    End If
Else
    strCritLimit = ""
End If

if (CInt(warnLimit) > 0) Then
    If (CInt(intUsed) >= CInt(warnLimit)) Then
        ReturnCode = 1
    End If
ElseIf (CInt(warnLimit) = 0) Then
    strWarnLimit = CStr(intMax)
    If (CInt(intUsed) >= CInt(intMax)) Then
        ReturnCode = 1
    End If
Else
    strWarnLimit = ""
End If

ReturnCodeExp = 0
' Check when the feature is expired
StrDaysToExpire = " Days to expire: " & DaysToExpire
if (CInt(warnExpire) >= 0) Then
    If (DaysToExpire <= CInt(warnExpire)) Then
        ReturnCodeExp = 1
        StrDaysToExpire = StrALERT(ReturnCodeExp) & StrDaysToExpire
    End If
Else
    strWarnLimit = ""
End If

if (CInt(critExpire) >= 0) Then
    If (DaysToExpire <= CInt(critExpire)) Then
        ReturnCodeExp = 2
        StrDaysToExpire = StrALERT(ReturnCodeExp) & StrDaysToExpire
    End If
Else
    strCritLimit = ""
End If

StrOutput=""
StrOutput = StrALERT(ReturnCode) & ": " & strLicense & " Installed: " & intMax & " In use: " & intUsed & ";" &  StrDaysToExpire & "|'InUse'=" & intUsed & ";" & strWarnLimit & ";" & strCritLimit & ";; 'nDaysToExpire'=" & DaysToExpire & "days;" & strWarnExpire & ";" & strCritExpire & ";; "
streamEcho StrOutput
If ReturnCodeExp > ReturnCode Then
    Wscript.Quit(ReturnCodeExp)
Else
    Wscript.Quit(ReturnCode)
End If

