''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' "check_devcon.vbs"
' Original from
' Fabio Frioni
'
' 05.09.2011 ver 1.0
' Read all devices from registry (for USB check)
' --------------------------------------------------------------
'

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

Function ShowUsage()
    unxEcho "check_devcon (nrpe_nt-plugin) 1.5"
    unxEcho "The nagios plugins come with ABSOLUTELY NO WARRANTY. You may redistribute"
    unxEcho "copies of the plugins under the terms of the GNU General Public License."
    unxEcho "For more information about these matters, see the file named COPYING."
    unxEcho "Copyright (c) 1999-2001 Ethan Galstad/Hagen Deike (nagios@samurai.inka.de)"
    unxEcho ""
    unxEcho "Fabio Frioni - Intesi Group SPA (ffrioni@intesigroup.com) (fabio.frioni@gmail.com)"
    unxEcho ""
    unxEcho "Note: DEVCON.EXE must exists in C:\"
    unxEcho ""
    unxEcho "Required arguments:"
    unxEcho "/H:host      Host name (just for description)"
    unxEcho "/s:string    the license name, the string can be an array of strings with ',' (comma) separated"
    unxEcho ""
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
    Dim strCommand, strArgs
    
    strCommand = left(WScript.ScriptFullName,(Len(WScript.ScriptFullName))-(len(WScript.ScriptName))) & "devcon.exe"
    strArgs = "find *"
    Set objShell = CreateObject("WScript.Shell")
    Set objWshScriptExec = objShell.Exec("%COMSPEC% /c " & Chr(34) & strCommand & Chr(34) & " " & strArgs)
'    Set objWshScriptExec = objShell.Exec("%COMSPEC% /c C:\Lavori\Nagios\plugins\check-keyspan\devcon find *")
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

Dim StrOutput, ReturnCode, StrALERT(4), arrStream, strStream, iLF, iLF_O, HostName
Dim strSearch, arrSearch
Dim Idx, Idx1, Idx2, Months, iFound

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
If Not Wscript.Arguments.Named.Exists("s") Then
    streamEcho "Plugin help screen:"
    ShowUsage()
    Wscript.Quit(intUnknown)
End If
strSearch = UCase(Trim(Replace(Wscript.Arguments.Named("s"),"","")))

HostName = ""
If Wscript.Arguments.Named.Exists("H") Then
    HostName = UCase(Trim(Replace(Wscript.Arguments.Named("H"),"","")))
End If

On Error Resume Next

StrALERT(0) = "OK"
StrALERT(1) = "WARNING"
StrALERT(2) = "CRITICAL"
StrALERT(3) = "UNKNOWN"

'strStream = Replace(ReadStream(),CHR(13),"")
strStream = ReadStream()
arrStream = Split(ReadStream(),CHR(13)+CHR(10))

if Wscript.Arguments.Named.Exists("list") Then
    licList = 1
End If

if (licList = 1) Then
    streamEcho strStream
    Wscript.Quit(0)
End If

Idx1 = 1
Idx2 = 1
iLF = 1
iLF_O = 1
iFound = 1
ReturnCode = 0
StrOutput = "Device found"

Idx1 = 0
For Idx = 0 to UBound(arrStream)
    iFound = patternMatch(arrStream(Idx), strSearch, 0)
    If iFound Then
        strFound = "string '" & Replace(arrStream(Idx),"  ","") & "'"
        Idx1 = Idx1 + 1
    End If
Next
If Idx1 = 0 then
    ReturnCode = 2
    strFound = "pattern '" & strSearch & "'"
    StrOutput = "No device found"
End If
StrOutput = StrALERT(ReturnCode) & ": DEVCON - " & StrOutput & " with " & strFound & " (" & HostName & ")"
streamEcho StrOutput
Wscript.Quit(ReturnCode)
