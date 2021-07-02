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

	unxEcho "check_kill_on_str (nrpe_nt-plugin) 1.0"
	unxEcho "The nagios plugins come with ABSOLUTELY NO WARRANTY. You may redistribute"
	unxEcho "copies of the plugins under the terms of the GNU General Public License."
	unxEcho "For more information about these matters, see the file named COPYING."
	unxEcho "Copyright (c) 1999-2001 Ethan Galstad/Hagen Deike (nagios@samurai.inka.de)"
	unxEcho "Fabio Frioni - Intesi Group SPA (ffrioni@intesigroup.com) (fabio.frioni@gmail.com)"
	unxEcho ""
	unxEcho "Required arguments:"
	unxEcho "/p:name        the process name"
	unxEcho "/s:name	the service name [ NOT IMPLEMENTED]"
	unxEcho ""
	unxEcho "</p:> or </s:> are mandatory"
	unxEcho ""
	unxEcho "/ks:[string]   input string to check for pattern </km> = $SERVICEOUTPUT$"
	unxEcho "/km:[string]   pattern to be found in </ks> in order to kill process"
	unxEcho ""
	unxEcho "/as:[string]   input string to check for patter </am> = $SERVICEOUTPUT$"
	unxEcho "/am:[string]	pattern to be found in </as> in order NOT to kill process"
	unxEcho ""
	unxEcho "</ks:> + </km:> work in couple and are mandatory"
	unxEcho "</as:> + </am:> work in couple but are not mandatory"
	unxEcho ""
	unxEcho "Optional arguments:"
	unxEcho "/h             this help"
	unxEcho ""

End Function

Function LeftPad( strText, intLen, chrPad )

	LeftPad = Left( strText & String( intLen, chrPad ), intLen )

End Function

Function RightPad( strText, intLen, chrPad )

	RightPad = Right( String( intLen, chrPad ) & strText, intLen )

End Function

Const intOK = 0
Const intWarning = 1
Const intCritical = 2
Const intUnknown = 3

Dim objWMIService, objService, colServices, objProcess, colProcess, myObjItem, myObjItemState, myProcessID, myThreadCount
Dim strComputer, strList, ReturnCode, RCStart, sFound, strCheck
Dim strCritLimit, strWarnLimit, strCritThrds, strWarnThrds, strWarnCPU, strCritCPU, StrOutput, StrAlerts, StrPerfDt
Dim procList, procName, procCount, procRam, procFullName, SvcName, SvcDisplayName, myProcCPU
Dim cpuUse_check, cpuUse_Items, cpuUse_InitialMS, cpuUse_DelayMS, cpuUse_NumberOfTests
Dim warnLimit, critLimit, warnCPU, critCPU, warnThrds, critThrds, alertWhenZero, StrALERT(4)
Dim countOk, countWarning, countCritical, countUnknown, countOthers
Dim restartEnabled, restartString, restartState

Dim strKill, strAlive, strKillMatch, strAliveMatch, killPID, serviceName, serviceFullName, strMatch
Dim killHIM, killMatch, aliveMatch, isService, isProc, match, cntPID

StrALERT(0) = "OK"
StrALERT(1) = "WARNING"
StrALERT(2) = "CRITICAL"
StrALERT(3) = "UNKNOWN"

strKill = ""
strAlive = ""
strKillMatch = ""
strAliveMatch = ""
strComputer = "."

killPID = ""

isProc = false
procName = ""
procFullName = ""

isService = false
serviceName = ""
serviceFullName = ""

StrOutput = ""

cntPID = 0
ReturnCode = 0

killHIM = false
killMatch = false
aliveMatch = false

If Not Wscript.Arguments.Named.Exists("p") AND Not Wscript.Arguments.Named.Exists("s") Then

	streamEcho "Plugin help screen:"
	streamEcho "at least on of options </p:> or </s:> must be used"
    	ShowUsage()
    	Wscript.Quit(intUnknown)

Else

	If Wscript.Arguments.Named.Exists("p") Then

		procName = Wscript.Arguments.Named("p")
		procName = Replace(procName,":b:"," ")
		procFullName = procName
		isProc = true

	Else 

		If Wscript.Arguments.Named.Exists("s") Then

			serviceName = Wscript.Arguments.Named("s")
			serviceName = Replace(serviceName,":b:"," ")
			serviceFullName = serviceName
			isService = true

		End If
	End If
End If

If Not Wscript.Arguments.Named.Exists("ks") AND Not Wscript.Arguments.Named.Exists("km") Then

	streamEcho "Plugin help screen:"
	streamEcho "options </ks:> and </km:> must be used toghether"
    	ShowUsage()
    	Wscript.Quit(intUnknown)

Else

	strKill = Wscript.Arguments.Named("ks")
	strKill = Replace(strKill,":b:"," ")

	strKillMatch = Wscript.Arguments.Named("km")
	strKillMatch = Replace(strKillMatch,":b:"," ")

 	If patternMatch(strKill,strKillMatch,0) Then

		'unxEcho "setting killMatch to vero"
		killMatch = true

	Else
		
		'unxEcho "setting killMatch to false"
		killMatch = false

	End If
End If

If Wscript.Arguments.Named.Exists("as") AND Wscript.Arguments.Named.Exists("am") Then

	strAlive = Wscript.Arguments.Named("as")
	strAlive = Replace(strAlive,":b:"," ")

	strAliveMatch = Wscript.Arguments.Named("am")
	strAliveMatch = Replace(strAliveMatch,":b:"," ")

	If Not patternMatch(strAlive,strAliveMatch,0) Then

		'unxEcho "setting aliveMatch to false"
		aliveMatch = false
	Else
	
		'unxEcho "setting aliveMatch to true"
		aliveMatch = true

	End If
End If

If killMatch AND aliveMatch Then

	ReturnCode = 0
	StrOutput = "Both killMatch (" & killMatch & ") and aliveMatch (" & aliveMatch & ") are TRUE, nothing to do"
	unxEcho StrALERT(ReturnCode) & ": " & StrOutput
	WScript.Quit(ReturnCode)

End If

if Not killMatch AND aliveMatch Then

	ReturnCode = 0
	StrOutput = "killMatch FALSE and aliveMatch TRUE, nothing to do"
	unxEcho StrALERT(ReturnCode) & ": " & StrOutput
	WScript.Quit(ReturnCode)

End If

if killMatch AND Not aliveMatch Then

	killHIM = true

Else

	ReturnCode = 0
	StrOutput = "Both killMatch (" & killMatch & ") and aliveMatch (" & aliveMatch & ") are FALSE, nothing to do"
	unxEcho StrALERT(ReturnCode) & ": " & StrOutput
	WScript.Quit(ReturnCode)

End If

Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")

if isProc Then

	Set colProcess = objWMIService.ExecQuery("Select * from Win32_Process where name = '" & procFullName & "'")
End If

if isService Then

	Set colServices = objWMIService.ExecQuery("Select * from Win32_Services where DisplayName = '" & serviceFullName & "'")
End If

if killHIM Then

	For Each objProcess in colProcess
	
		cntPID = cntPID + 1
		objProcess.Terminate()
		If Not patternMatch(killPID,"Killed PID:",0) Then

			killPID = "Killed PID: " & objProcess.ProcessID
		Else
			killPID = killPID & ", " & objProcess.ProcessID
		End If
	Next

End If

If cntPID > 0 Then

		StrOutput = killPID

Else

	StrOutPut = "No Process Found with name: " & procFullName
	
End If

unxEcho StrALERT(ReturnCode) & ": " & StrOutput
WScript.Quit(ReturnCode)

