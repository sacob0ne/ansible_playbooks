Option Explicit 

'#! /usr/bin/perl -w
'#==============================================================#
'# check_flexlm.vbs - check status of FLEXlm license servers    #
'#                    This is a porting to work with NSClient   #
'#==============================================================#
'#                                                              #
'#                     check_flexlm.vbs v0.9b                   #
'#                                                              #
'# fabio.frioni@gmail.com                       copyright 2011  #
'#==============================================================#
'#                                                              #
'# CHANGELOG:                                                   #
'#                                                              # 
'#==============================================================#
'#                                                              #
'# !!!IMPORTANT!!!	                                       #
'#                                                              #
'# Locate the $path_to_lmutil variable and set the location     #
'# for your lmutil executable, which you must obtain from       #
'# www.macrovision.com for your OS.                             #
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

Function patternMatch(strng, patrn, matchType)
    ' This verify, return a string or return an array of matches in a scring by giving a pattern
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
    unxEcho "check_flexlm.vbs (nrpe_nt-plugin) 1.10b"
    unxEcho ""
    unxEcho "Required arguments:"
    unxEcho "/H:name        host name to be checked remotely"
    unxEcho ""
    unxEcho "Optional arguments:"
    unxEcho "/p:port        remote port where license manager responds"
    unxEcho "/f:feature     if specified, it returns the feature statistics"
    unxEcho "/t:timeout     defines a query timeout"
    unxEcho "/w:n           the warning limit for processes. If 0 the limit is Max. If -1, there is no warning limit."
    unxEcho "               By default is -1. No takes effect for service queries"
    unxEcho "/c:n           the critical limit for processes. If 0, there is no critical limit."
    unxEcho "               By default is 0.  No takes effect for service queries"
    unxEcho "/e             statistics of expiration dates"
    unxEcho "/ew:n          the warning limit for expiration dates. If 0 the limit is Max. If -1, there is no warning limit."
    unxEcho "               By default is -1. No takes effect for service queries"
    unxEcho "/ec:n          the critical limit for expiration dates. If 0, there is no critical limit."
    unxEcho "               By default is 0.  No takes effect for service queries"
    unxEcho "/0:n           If defined, the plugin will return the given value when:"
    unxEcho "               if a key is not found."
    unxEcho "/PATH:path     set custom path for lmutil"
    unxEcho "/userlabel:label     set custom label on performance data"
    unxEcho "/datelabel:label     set custom label on performance data"
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


Function ReadStream(strCmd)
    Dim objShell
    Dim objWshScriptExec
    Dim objStdOut
    Dim arrStream
    
    Set objShell = CreateObject("WScript.Shell")
    Set objWshScriptExec = objShell.Exec(strCmd)
    Set objStdOut = objWshScriptExec.StdOut
    arrStream = objStdOut.ReadAll
    ReadStream = arrStream
    Set objStdOut = nothing
    Set objWshScriptExec = nothing
    Set objShell = nothing
End Function


Function ReadStream2Array(strCmd)
    ReadStream2Array = split(ReadStream(strCmd),CHR(13)+CHR(10))
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

Dim strHostname, strPort, strVendor, strTimeout, strExpire
Dim StrOutput, ReturnCode, StrPerfData, StrUserLabel, StrDateLabel, StrALERT(4), arrStream,arr2Lic,arrLic
Dim StrLicense, ReturnCodeExp
Dim warnLimit,critLimit,strWarnLimit, strCritLimit
Dim warnExpire,critExpire,strWarnExpire, strCritExpire
Dim CheckVersion, licList, StrDaysToExpire, DaysToExpire, StrDErpire, arrDExpire
Dim Idx, Idx2, Months
Dim red_flag,red_feats,yellow_flag,yellow_feats,critical_flag,critical_feats,features,lmdaemon,expireflag,current_use
Dim tot_lic,perc_in_use,str_warn,str_crit,int_limit,available_licenses
Dim LMUTIL_PATH, LMUTIL_CMD, LMUTIL_ARGS, LMUTIL

Redim red_feats(0)
Redim yellow_feats(0)
Redim critical_feats(0)

LMUTIL_PATH = ".\scripts\"
LMUTIL_CMD  = "lmutil.exe"
LMUTIL_ARGS = "lmstat -a -old"
LMUTIL = ""
licList = 0
warnLimit = 0
critLimit = -1
warnExpire = -1
critExpire = -1
strHostname = ""
strPort = ""
strVendor = ""
strTimeout = ""
tot_lic=0
current_use=0
StrALERT(0) = "OK"
StrALERT(1) = "WARNING"
StrALERT(2) = "CRITICAL"
StrALERT(3) = "UNKNOWN"
StrUserLabel="InUse"
StrDateLabel="nDaysToExpire"


Months="JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC"
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Help
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
If Not Wscript.Arguments.Named.Exists("H") Then
    streamEcho "Plugin help screen:"
    ShowUsage()
    Wscript.Quit(intUnknown)
End If
strHostname = Trim(Wscript.Arguments.Named("H"))

if Wscript.Arguments.Named.Exists("p") Then
    strPort = Wscript.Arguments.Named("p")
End If

if Wscript.Arguments.Named.Exists("f") Then
    strVendor = " -f " & Wscript.Arguments.Named("f")
End If

if Wscript.Arguments.Named.Exists("userlabel") Then
    StrUserLabel = Wscript.Arguments.Named("userlabel")
End If

if Wscript.Arguments.Named.Exists("datelabel") Then
    StrDateLabel = Wscript.Arguments.Named("datelabel")
End If

if Wscript.Arguments.Named.Exists("PATH") Then
    LMUTIL_PATH = Wscript.Arguments.Named("PATH")
End If

if Wscript.Arguments.Named.Exists("e") Then
    strExpire = " -i "
End If

if Wscript.Arguments.Named.Exists("t") Then
    strTimeout = " -t " & Wscript.Arguments.Named("t")
End If

if Wscript.Arguments.Named.Exists("w") Then
    warnLimit = CInt(Wscript.Arguments.Named("w"))
End If

if Wscript.Arguments.Named.Exists("c") Then
    critLimit = CInt(Wscript.Arguments.Named("c"))
End If

if Wscript.Arguments.Named.Exists("ew") Then
    warnExpire = CInt(Wscript.Arguments.Named("ew"))
End If

if Wscript.Arguments.Named.Exists("ec") Then
    critExpire = CInt(Wscript.Arguments.Named("ec"))
End If

if Wscript.Arguments.Named.Exists("list") Then
    licList = 1
End If

arrStream = ReadStream2Array("%COMSPEC% /c " & LMUTIL_PATH & LMUTIL_CMD & " " & LMUTIL_ARGS & " " & strTimeout & strExpire & strVendor & " -c " & strPort & "@" & strHostname)

For Idx = 0 to UBound(arrStream)
    If features = 0 Then
        If patternMatch(arrStream(Idx),".*([Cc]annot|[Uu]nable|[Rr]efused|[Dd]own|[Ww]in[Ss]ock).*",0) Then
            red_flag = red_flag + 1
            Redim preserve red_feats(red_flag)
            red_feats(red_flag-1) = Trim(arrStream(Idx))
        End If
    Else
        If patternMatch(arrStream(Idx),".*([Uu]ncounted).*",0) Then
            tot_lic = -1
        ElseIf patternMatch(arrStream(Idx),"Users of (.*): .* ([0-9]+) .* unsupported .*",0) Then
            red_flag = red_flag + 1
            Redim preserve red_feats(red_flag)
            red_feats(red_flag-1) = Trim(arrStream(Idx))
        Else
            arrLic = patternMatch(arrStream(Idx),"Users of (.*): .* of ([0-9]+) .* issued; .* of ([0-9]+) .* use",2)
            if (IsArray(arrLic)) Then
                available_licenses = available_licenses + (arrLic(1) - arrLic(2))
                current_use  = current_use + CInt(arrLic(2))
                tot_lic = tot_lic + CInt(arrLic(1))
                perc_in_use = Round((current_use/tot_lic)*100,2)
            End If
        End If
    End If

    If patternMatch(arrStream(Idx),".*(Feature usage info:|Users of features served by " & strVendor & ").*",0) Then
        features = features + 1
    End If
Next

strWarnLimit = ""
strCritLimit = ""
strWarnExpire = ""
strCritExpire = ""
StrOutput=""
StrPerfData=""

ReturnCode = 0
ReturnCodeExp = 0

' Check only if tot_lic is greater than 2
If tot_lic > 2 Then
    ' Check when users are using the features
    strWarnLimit = CStr(warnLimit)
    if (CInt(warnLimit) > 0) Then
        If (CInt(current_use) >= CInt(warnLimit)) Then
            ReturnCode = 1
        End If
    ElseIf (CInt(warnLimit) = 0) Then
        strWarnLimit = CStr(tot_lic)
        If (CInt(current_use) >= CInt(tot_lic)) Then
            ReturnCode = 1
        End If
    Else
        strWarnLimit = ""
    End If

    strCritLimit = CStr(critLimit)
    if (CInt(critLimit) > 0) Then
        If (CInt(current_use) >= CInt(critLimit)) OR red_flag > 0 Then
            ReturnCode = 2
        End If
    ElseIf (CInt(critLimit) = 0) Then
        strCritLimit = CStr(tot_lic)
        If (CInt(current_use) >= CInt(tot_lic)) Then
            ReturnCode = 2
        End If
    Else
        strCritLimit = ""
    End If

End If

If tot_lic < 0 Then
    ReturnCode = 0
    StrOutput   = StrOutput & StrALERT(ReturnCode) & ": FLEXLm unlimited"
else    
    StrOutput   = StrOutput & StrALERT(ReturnCode) & ": FLEXLm installed: " & tot_lic & " In use: " & current_use
    StrPerfData = StrPerfData & "'" & StrUserLabel & "'=" & current_use & ";" & strWarnLimit & ";" & strCritLimit & ";;"
End If

If strExpire <> "" AND tot_lic > 0 Then
    ReturnCodeExp = 0
    ' Check when the feature is expired
    StrDaysToExpire = " Days to expire: " & DaysToExpire
    strWarnExpire = CStr(warnExpire)
    if (CInt(warnExpire) >= 0) Then
        If (DaysToExpire <= CInt(warnExpire)) Then
            ReturnCodeExp = 1
            StrDaysToExpire = StrALERT(ReturnCodeExp) & StrDaysToExpire
        End If
    Else
        strWarnExpire = ""
    End If

    strCritExpire = CStr(critExpire)
    if (CInt(critExpire) >= 0) Then
        If (DaysToExpire <= CInt(critExpire)) Then
            ReturnCodeExp = 2
            StrDaysToExpire = StrALERT(ReturnCodeExp) & StrDaysToExpire
        End If
    Else
        strCritExpire = ""
    End If
    StrOutput   = StrOutput & " " & StrALERT(ReturnCodeExp) & StrDaysToExpire
    StrPerfData = StrPerfData & " '" & StrDateLabel & "'=" & DaysToExpire & "days;" & strWarnExpire & ";" & strCritExpire & ";; "
End If

If StrPerfData <> "" Then
    streamEcho StrOutput & "|" & StrPerfData
Else
    streamEcho StrOutput
End If

If ReturnCodeExp > ReturnCode Then
    Wscript.Quit(ReturnCodeExp)
Else
    Wscript.Quit(ReturnCode)
End If
