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

Function WMIDateStringToDate(utcDate)
   WMIDateStringToDate = CDate(Mid(utcDate, 5, 2)  & "/" & _
       Mid(utcDate, 7, 2)  & "/" & _
           Left(utcDate, 4)    & " " & _
               Mid (utcDate, 9, 2) & ":" & _
                   Mid(utcDate, 11, 2) & ":" & _
                      Mid(utcDate, 13, 2))
End Function

strComputer = "."
RC=3

If Wscript.Arguments.Count = 0 OR Wscript.Arguments.Named.Exists("h") Then
    dosEcho("The nagios plugins come with ABSOLUTELY NO WARRANTY. You may redistribute")
    dosEcho("copies of the plugins under the terms of the GNU General Public License.")
    dosEcho("For more information about these matters, see the file named COPYING.")
    dosEcho("")
    dosEcho("Author: Fabio Frioni - Intesi Group SPA (ffrioni@intesigroup.com) (fabio.frioni@gmail.com)")
    dosEcho("")
    dosEcho("Plugin help screen:")
    dosEcho("")
    dosEcho("You need to specify at least an argument: try with a domain suffix.")
    dosEcho("getSuffixDns.vbs domain_suffix")
    WScript.Quit RC
End If

suffissoDaCercare = WScript.Arguments(0)

Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")

Set colAdapters = objWMIService.ExecQuery _
    ("SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled = True")

'Set args = WScript.Arguments

n = 1
RC=2
For Each objAdapter in colAdapters
    If Not IsNull(objAdapter.DNSDomainSuffixSearchOrder) Then
        For i = 0 To UBound(objAdapter.DNSDomainSuffixSearchOrder)
            If (StrComp(suffissoDaCercare, objAdapter.DNSDomainSuffixSearchOrder(i), 1) = 0) Then
                WScript.Echo "OK: record " + suffissoDaCercare + " found in the DNS Suffix Search List|" + suffissoDaCercare + "=1"
                WScript.Quit 0
            End If
        Next
    Else
        WScript.Echo "UNKNOWN: Cannot retrieve DNS information, DNS list is empty."
        WScript.Quit 3
    End If
    n = n + 1
Next
WScript.Echo "CRITICAL: record " + suffissoDaCercare + " not found in the DNS Suffix Search List|" + suffissoDaCercare + "=0"
WScript.Quit RC
