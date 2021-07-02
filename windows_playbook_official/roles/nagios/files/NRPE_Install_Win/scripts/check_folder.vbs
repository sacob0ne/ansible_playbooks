'#==============================================================#
'# check_disk.wsf -   check disk capacity                       #
'#                    This is a porting to work with NSClient   #
'#==============================================================#
'#                                                              #
'#                      check_disk.wsf v1.0b                    #
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
' On Error Resume Next


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
    unxEcho "check_folder (nrpe_nt-plugin) 1.0"
    unxEcho "The nagios plugins come with ABSOLUTELY NO WARRANTY. You may redistribute"
    unxEcho "copies of the plugins under the terms of the GNU General Public License."
    unxEcho "For more information about these matters, see the file named COPYING."
    unxEcho "Copyright (c) 1999-2001 Ethan Galstad/Hagen Deike (nagios@samurai.inka.de)"
    unxEcho ""
    unxEcho "Author: Fabio Frioni - Intesi Group SPA (ffrioni@intesigroup.com) (fabio.frioni@gmail.com)"
    unxEcho ""
    unxEcho "Required arguments:"
    unxEcho "/path:path_name   the path name to check, use :b: for blanks"
    unxEcho ""
    unxEcho "DEPTH: path -> file -> match"
    unxEcho ""
    unxEcho "Optional arguments:"
    unxEcho "/file:file_name    The file name to check, all pattern match, use :b: for blanks"
    unxEcho "/filx:file_name    The file name to check, exactly what are you looking for, use :b: for blanks"
    unxEcho "/lookup:type       LookuUp type:"
    unxEcho "                   one:one     one path for one file, this meansh paths and files have to be the same number of items"
    unxEcho "                   many:many   each path for each file"
    unxEcho "/recursive         Recursively read all forders starting from the specified."
    unxEcho "/match:regexp      The matching string in a text file (using a regular expression too), use :b: for blanks"
    unxEcho "/matchepoch:time   Epoch limit for file age, use 'v' to define 'minor'. (Ex. 7d,4h => 7 days and 4 hours old)."
    unxEcho "/true:n,n,n        If defined, exit code will be the given value: path_exist -> file_exist -> matched"
    unxEcho "/false:n,n,n       If defined, exit code will be the given value: path_not_exist -> file_not_exist -> not_matched"
    unxEcho "/warn_age:[v]n     Warning limit for file age, use 'v' to define 'minor'. (Ex. 7d,4h => 7 days and 4 hours old)."
    unxEcho "/crit_age:[v]n     Critical limit for file age, use 'v' to define 'minor'. (Ex. 7d,4h => 7 days and 4 hours old)."
    unxEcho "/warn_size:[v]n    Warning limit for file size (kb), use 'v' to define 'minor then'."
    unxEcho "/crit_size:[v]n    Critical limit for file size (kb), use 'v' to define 'minor then'."
    unxEcho "/perf:itemList     performance data item list, valid items: tot;size;age."
    unxEcho "/h                 This help."
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


function date2epoch(myDate)
    date2epoch = DateDiff("s", "01/01/1970 00:00:00", myDate)
end function


function epoch2date(myEpoch)
    epoch2date = DateAdd("s", myEpoch, "01/01/1970 00:00:00")
end function


Function cnvtime(ML_STRVAL,STYPE,OUTFMT,DELIM)
    Dim STRVAL,DNOW,UN,RET,VAL
    Dim aSTRVAL, idxSTRVAL, TotRET, aSTR(4), aUNT(4), idx
    
    If VarType(DELIM) <= 1 Then
		If InStrRev(ML_STRVAL,".") Then
			DELIM = "."
		End If
		If InStrRev(ML_STRVAL,":") Then
			DELIM = ":"
		End If
		If InStrRev(ML_STRVAL,";") Then
			DELIM = ";"
		Else
			DELIM = ","
		End If
		
    End If
    aSTRVAL = Split(ML_STRVAL,DELIM)
    aUNT(0)="d"
    aUNT(1)="h"
    aUNT(2)="m"
    aUNT(3)="s"

    TotRET = 0
    RET=0
    For idxSTRVAL = LBound(aSTRVAL) to UBound(aSTRVAL)
        STRVAL = aSTRVAL(idxSTRVAL)
        If IsDate(STRVAL) Then
            STRVAL=date2epoch(STRVAL)
        End If
        DNOW=date2epoch(now())
        UN=UCase(mid(STRVAL,len(STRVAL),1))
        RET=0
        If UN >= CHR(48) AND UN <= CHR(57) Then
            VAL=mid(STRVAL,1,len(STRVAL))
            UN="S"
        Else
            VAL=mid(STRVAL,1,len(STRVAL)-1)
        End If

        Select Case UN
            Case "S"
                RET=VAL
            Case "M"
                RET=(VAL*60)
            Case "H"
                RET=(VAL*3600)
            Case "D"
                RET=(VAL*86400)
        End Select
        
        If NOT IsNull(STYPE) Then
            If InStr(UCase(STYPE),"SINCE") > 0 Then
                RET = DNOW - RET
            End If
            If InStr(UCase(STYPE),"DAY") > 0 Then
                RET = (RET / 86400)+1
            End If
            If InStr(UCase(STYPE),"SEC") > 0 Then
                RET = RET
            End If
        End If
        If vartype(RET) >= 2 AND vartype(RET) <= 6 Then
            TotRET = TotRET + RET
        End If
    Next

    If InStr(UCase(STYPE),"DAY") = 0 Then
        If IsNull(OUTFMT) OR OUTFMT = "" Then
            cnvtime = TotRET
        ElseIf UCase(OUTFMT) = "STR" Then
            aSTR(0)=Int(TotRET/86400)
            aSTR(1)=Int((TotRET - (aSTR(0)*86400)) / 3600)
            aSTR(2)=Int((TotRET - (aSTR(0)*86400) - (aSTR(1)*3600)) / 60)
            aSTR(3)=Int((TotRET - (aSTR(0)*86400) - (aSTR(1)*3600) - (aSTR(2)*60)))
            cnvtime = ""
            For idx=LBound(aSTR) to UBound(aSTR)
                If aSTR(idx) <> 0 Then
                    cnvtime = cnvtime & aSTR(idx) & aUNT(idx) & " "
                End If
            Next
            cnvtime = trim(cnvtime)
        ElseIf UCase(OUTFMT)="FMT" Then
            cnvtime = FormatDateTime(epoch2date(TotRET),0)
        Else
        End If
    End If
End Function


Sub scanFolders(objFolder)
    Dim objFileFolder, idx, pSize, DoIt
    For Each objFileFolder In objFolder.Files
        pSize = pSize + objFileFolder.Size
        If IsArray(listFileName) Then
            If lookupType <> "one:one" Then
                For idx=LBound(listFileName) To UBound(listFileName)
                    If listFileName(idx) <> "" Then
                        DoIt = False
                        if exactFile Then
                            If (LCase(objFileFolder.Name) = LCase(listFileName(idx))) Then
                                DoIt = True
                            End If
                        Else
                            If patternMatch(objFileFolder.Name ,listFileName(idx),0) Then
                                DoIt = True
                            End If
                        End If
                        If DoIt Then
							If (date2epoch(objFileFolder.DateLastModified) * listepochToAnalyzeDir(idx)) > (epochToAnalyze(idx) * listepochToAnalyzeDir(idx)) Then
								listFileSize(idx) = listFileSize(idx) + objFileFolder.Size
								listFileCount(idx) = listFileCount(idx) + 1
								If date2epoch(objFileFolder.DateLastModified) > listFileUpdTime(idx) Then
									listFileUpdTime(idx) = date2epoch(objFileFolder.DateLastModified)
									listFilesLastUpd(idx) = objFileFolder.Path
								End If
							End If
                            If IsArray(listMatchString) Then
                                If listMatchString(idx) <> "" Then
                                    If Not ifMatchOnyLastEpochFiles Then
                                        listMatched(idx) = patternMatch(ReadStream("%COMSPEC% /c type " & chr(34) & objFileFolder.Path & chr(34)) ,listMatchString(idx),0)
                                    End If
                                End If
                            End If
                        End If
                    Else
                        listFileCount(idx) = listFileCount(idx) + 1
                        If date2epoch(objFileFolder.DateLastModified) > listFileUpdTime(idx) Then
                            listFileUpdTime(idx) = date2epoch(objFileFolder.DateLastModified)
                        End If
                    End If
                Next
            Else
                If listFileName(idxPath) <> "" Then
                    DoIt = False
                    if exactFile Then
                        If (LCase(objFileFolder.Name) = LCase(listFileName(idxPath))) Then
                            DoIt = True
                        End If
                    Else
                        If patternMatch(objFileFolder.Name ,listFileName(idxPath),0) Then
                            DoIt = True
                        End If
                    End If
                    If DoIt Then
						If (date2epoch(objFileFolder.DateLastModified) * listepochToAnalyzeDir(idxPath)) > (epochToAnalyze(idxPath) * listepochToAnalyzeDir(idxPath)) Then
							listFileSize(idxPath) = listFileSize(idxPath) + objFileFolder.Size
							listFileCount(idxPath) = listFileCount(idxPath) + 1
							If date2epoch(objFileFolder.DateLastModified) > listFileUpdTime(idxPath) Then
								listFileUpdTime(idxPath) = date2epoch(objFileFolder.DateLastModified)
                                listFilesLastUpd(idxPath) = objFileFolder.Path
                            End If
                        End If
                        If IsArray(listMatchString) Then
                            If listMatchString(idxPath) <> "" Then
                                If Not ifMatchOnyLastEpochFiles Then
                                    listMatched(idxPath) = patternMatch(ReadStream("%COMSPEC% /c type " & chr(34) & objFileFolder.Path & chr(34)) ,listMatchString(idxPath),0)
                                End If
                            End If
                        End If
                    End If
                Else
                    listFileCount(idxPath) = listFileCount(idxPath) + 1
                    If date2epoch(objFileFolder.DateLastModified) > listFileUpdTime(idxPath) Then
                        listFileUpdTime(idxPath) = date2epoch(objFileFolder.DateLastModified)
                    End If
                End If
            End If
        End If
    Next
    If ifMatchOnyLastEpochFiles  AND IsArray(listMatchString) Then
        If lookupType <> "one:one" Then
            For idx=LBound(listFileName) To UBound(listFileName)
                If listFilesLastUpd(idx) <> "" Then
                    listMatched(idx) = patternMatch(ReadStream("%COMSPEC% /c type " & chr(34) & listFilesLastUpd(idx) & chr(34)) ,listMatchString(idx),0)
                End If
            Next
        Else
            If listFilesLastUpd(idxPath) <> "" Then
                listMatched(idxPath) = patternMatch(ReadStream("%COMSPEC% /c type " & chr(34) & listFilesLastUpd(idxPath) & chr(34)) ,listMatchString(idxPath),0)
            End If
        End If
    End If
    pathSize = pathSize + pSize
    If DoRecursive Then
        ScanSubFolders objFolder
    End If
End Sub


Sub scanSubFolders(objFolder)
    Dim colFolders, objSubFolder, colFiles, objFileFolder, idx, pSize, DoIt
    Set colFolders = objFolder.SubFolders
    pSize = 0
    For Each objSubFolder In colFolders
        pathCount = pathCount + 1
        Set colFiles = objSubFolder.Files
        For Each objFileFolder in colFiles
            pSize = pSize + objFileFolder.Size
            'wscript.echo "                            " & objFileFolder.Name & "  " & objFileFolder.Size  & "Bytes"
            If IsArray(listFileName) Then
                If lookupType <> "one:one" Then
                    For idx=LBound(listFileName) To UBound(listFileName)
                        If listFileName(idx) <> "" Then
                            DoIt = False
                            if exactFile Then
                                If (LCase(objFileFolder.Name) = LCase(listFileName(idx))) Then
                                    DoIt = True
                                End If
                            Else
                                If patternMatch(objFileFolder.Name ,listFileName(idx),0) Then
                                    DoIt = True
                                End If
                            End If
                            If DoIt Then
								If (date2epoch(objFileFolder.DateLastModified) * listepochToAnalyzeDir(idx)) > (epochToAnalyze(idx) * listepochToAnalyzeDir(idx)) Then
									listFileSize(idx) = listFileSize(idx) + objFileFolder.Size
									listFileCount(idx) = listFileCount(idx) + 1
									If date2epoch(objFileFolder.DateLastModified) > listFileUpdTime(idx) Then
										listFileUpdTime(idx) = date2epoch(objFileFolder.DateLastModified)
										listFilesLastUpd(idx) = objFileFolder.Path
									End If
								End If
                                If IsArray(listMatchString) Then
                                    If listMatchString(idx) <> "" Then
                                        If Not ifMatchOnyLastEpochFiles Then
                                            listMatched(idx) = patternMatch(ReadStream("%COMSPEC% /c type " & chr(34) & objFileFolder.Path & chr(34)) ,listMatchString(idx),0)
                                        End If
                                    End If
                                End If
                            End If
                        Else
                            listFileCount(idx) = listFileCount(idx) + 1
                            If date2epoch(objFileFolder.DateLastModified) > listFileUpdTime(idx) Then
                                listFileUpdTime(idx) = date2epoch(objFileFolder.DateLastModified)
                            End If
                        End If
                    Next
                Else
                    If listFileName(idxPath) <> "" Then
                        DoIt = False
                        if exactFile Then
                            If (LCase(objFileFolder.Name) = LCase(listFileName(idxPath))) Then
                                DoIt = True
                            End If
                        Else
                            If patternMatch(objFileFolder.Name ,listFileName(idxPath),0) Then
                                DoIt = True
                            End If
                        End If
                        If DoIt Then
							If (date2epoch(objFileFolder.DateLastModified) * listepochToAnalyzeDir(idxPath)) > (epochToAnalyze(idxPath) * listepochToAnalyzeDir(idxPath)) Then
								listFileSize(idxPath) = listFileSize(idxPath) + objFileFolder.Size
								listFileCount(idxPath) = listFileCount(idxPath) + 1
								If date2epoch(objFileFolder.DateLastModified) > listFileUpdTime(idxPath) Then
									listFileUpdTime(idxPath) = date2epoch(objFileFolder.DateLastModified)
									listFilesLastUpd(idxPath) = objFileFolder.Path
								End If
							End If
                            If IsArray(listMatchString) Then
                                If listMatchString(idxPath) <> "" Then
                                    If Not ifMatchOnyLastEpochFiles Then
                                        listMatched(idxPath) = patternMatch(ReadStream("%COMSPEC% /c type " & chr(34) & objFileFolder.Path & chr(34)) ,listMatchString(idxPath),0)
                                    End If
                                End If
                            End If
                        End If
                    Else
                        listFileCount(idxPath) = listFileCount(idxPath) + 1
                        If date2epoch(objFileFolder.DateLastModified) > listFileUpdTime(idxPath) Then
                            listFileUpdTime(idxPath) = date2epoch(objFileFolder.DateLastModified)
                        End If
                    End If
                End If
            End If
        Next
        If ifMatchOnyLastEpochFiles AND IsArray(listMatchString) Then
            If lookupType <> "one:one" Then
                For idx=LBound(listFileName) To UBound(listFileName)
                    If listFilesLastUpd(idx) <> "" Then
                        listMatched(idx) = patternMatch(ReadStream("%COMSPEC% /c type " & chr(34) & listFilesLastUpd(idx) & chr(34)) ,listMatchString(idx),0)
                    End If
                Next
            Else
                If listFilesLastUpd(idxPath) <> "" Then
                    listMatched(idxPath) = patternMatch(ReadStream("%COMSPEC% /c type " & chr(34) & listFilesLastUpd(idxPath) & chr(34)) ,listMatchString(idxPath),0)
                End If
            End If
        End If
        pathSize = pathSize + pSize
        ScanSubFolders objSubFolder
    Next
End Sub


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

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Global variables
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Dim objFSO, objFolder, colFiles, objProcess, colProcess, myObjItem, myObjItemState, myProcessID, myThreadCount
Dim strComputer, strList, listReturnCode, ReturnCode, sFound
Dim strCritical, strWarning, strCritSize, strWarnSize, StrOutput, StrAlerts, StrPerfData, StrAGE
Dim listPathName, pathSize, pathCount, fileList, lookupType, idxPath, DoRecursive, epochToAnalyze, listepochToAnalyzeDir, ifMatchOnyLastEpochFiles
Dim exactFile, aFileName, listFileName, listFileSize, listFileCount, listMatchString, matchString, listFileUpdTime, listMatched, listFilesLastUpd
Dim listWarnTime, listWarnTimeDir, listCritTime, listCritTimeDir, listWarnSize, listWarnSizeDir, listCritSize, listCritSizeDir
Dim listAlertWhenFalse, listAlertWhenTrue, MinChar, MaxChar
Dim StrALERT(4), idx, ArgsDelimiter, lastUpdSince, arrTemp, listPerfData, aPerfData(3)
Dim countOk, countWarning, countCritical, countUnknown, countOthers

StrALERT(0) = "OK"
StrALERT(1) = "WARNING"
StrALERT(2) = "CRITICAL"
StrALERT(3) = "UNKNOWN"
StrAlerts = ""
StrOutput = ""
pathSize = 0
pathCount = 0
lookupType="one:one"
ArgsDelimiter = ","
MinChar="v"
MaxChar="^"
aPerfData(0) = true
aPerfData(1) = true
aPerfData(2) = true
exactFile = true
DoRecursive = False
ifMatchOnyLastEpochFiles = False

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Help
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
If Not Wscript.Arguments.Named.Exists("path") Then
    streamEcho "Plugin help screen:"
    ShowUsage()
    Wscript.Quit(intUnknown)
End If

' --------------------------------------------------
If Wscript.Arguments.Named.Exists("path") Then
    listPathName = Split(Wscript.Arguments.Named("path"),ArgsDelimiter)
    For idx = LBound(listPathName) to UBound(listPathName)
        listPathName(idx) = Replace(listPathName(idx),":b:"," ")
    Next
    Redim listFilesLastUpd(0)
    Redim listFileUpdTime(0)
    Redim listFileSize(0)
    Redim listWarnTime(0)
    Redim listCritTime(0)
    Redim listWarnSize(0)
    Redim listCritSize(0)
    Redim listWarnTimeDir(0)
    Redim listCritTimeDir(0)
    Redim listWarnSizeDir(0)
    Redim listCritSizeDir(0)
    Redim listAlertWhenFalse(0)
    Redim listAlertWhenTrue(0)
    Redim listMatched(0)
    Redim listFileCount(0)
    Redim listReturnCode(0)
    Redim epochToAnalyze(0)
	Redim listepochToAnalyzeDir(0)
End If

If Wscript.Arguments.Named.Exists("lookup") Then
    lookupType = Wscript.Arguments.Named("lookup")
End If

If Wscript.Arguments.Named.Exists("recursive") Then
    DoRecursive = True
End If

If Wscript.Arguments.Named.Exists("file") OR Wscript.Arguments.Named.Exists("filx") Then
    exactFile = False
    if Wscript.Arguments.Named.Exists("file") Then
        aFileName = Wscript.Arguments.Named("file")
    Else
        exactFile = True
        aFileName = Wscript.Arguments.Named("filx")
    End If

    listFileName = Split(aFileName,ArgsDelimiter)
    Redim epochToAnalyze(UBound(listFileName)+1)
    Redim listFileUpdTime(UBound(listFileName)+1)
    Redim listFilesLastUpd(UBound(listFileName)+1)
    Redim listFileSize(UBound(listFileName)+1)
    Redim listWarnTime(UBound(listFileName)+1)
    Redim listCritTime(UBound(listFileName)+1)
    Redim listWarnSize(UBound(listFileName)+1)
    Redim listCritSize(UBound(listFileName)+1)
    Redim listWarnTimeDir(UBound(listFileName)+1)
    Redim listCritTimeDir(UBound(listFileName)+1)
    Redim listWarnSizeDir(UBound(listFileName)+1)
    Redim listCritSizeDir(UBound(listFileName)+1)
	Redim listepochToAnalyzeDir(UBound(listFileName)+1)
    Redim listMatched(UBound(listFileName)+1)
    Redim listFileCount(UBound(listFileName)+1)
    Redim listReturnCode(UBound(listFileName)+1)
    listAlertWhenTrue = Split("0,0,2",ArgsDelimiter)
    listAlertWhenFalse = Split("2,2,0",ArgsDelimiter)

    For idx = LBound(listFileName) to UBound(listFileName)
        listFileName(idx) = Replace(listFileName(idx),":b:"," ")
        listFileUpdTime(idx) = 0
        listFilesLastUpd(Idx) = ""
        listWarnTime(Idx) = -1
        listCritTime(Idx) = -1
        listWarnSize(Idx) = -1
        listCritSize(Idx) = -1
        listMatched(idx) = false
        listFileCount(Idx) = 0
        listReturnCode(Idx) = 0
        listWarnTimeDir(Idx) = 1
        listCritTimeDir(Idx) = 1
        listWarnSizeDir(Idx) = 1
        listCritSizeDir(Idx) = 1
        epochToAnalyze(Idx) = 0
		listepochToAnalyzeDir(Idx) = 1
    Next
End If

If Wscript.Arguments.Named.Exists("match") Then
    listMatchString = Split(Wscript.Arguments.Named("match"),ArgsDelimiter)
    For idx = LBound(listMatchString) to UBound(listMatchString)
        listMatchString(idx) = Replace(listMatchString(idx),":b:"," ")
    Next
End If

If Wscript.Arguments.Named.Exists("matchepoch") Then
    epochToAnalyze = Split(Wscript.Arguments.Named("matchepoch"),ArgsDelimiter)
    For idx = LBound(epochToAnalyze) to UBound(epochToAnalyze)
        If InStrRev(epochToAnalyze(idx),MinChar) Then
            listepochToAnalyzeDir(Idx) = -1
        End If
        epochToAnalyze(idx) = Replace(Replace(epochToAnalyze(idx),MinChar,""),MaxChar,"")
        epochToAnalyze(idx) = cnvtime(epochToAnalyze(idx),"SINCE","",null)
    Next
    ifMatchOnyLastEpochFiles = True
End If

If Wscript.Arguments.Named.Exists("perf") Then
    listPerfData = Split(Wscript.Arguments.Named("perf"),ArgsDelimiter)
    For idx = LBound(aPerfData) to UBound(aPerfData)
        aPerfData(idx) = false
    Next
    For idx = LBound(listPerfData) to UBound(listPerfData)
        Select Case lcase(trim(mid(listPerfData(idx),1,3)))
            Case "tot"
                aPerfData(0) = true
            Case "age"
                aPerfData(1) = true
            Case "siz"
                aPerfData(2) = true
        End Select
    Next
End If

if Wscript.Arguments.Named.Exists("warn_age") Then
    listWarnTime = Split(Wscript.Arguments.Named("warn_age"),ArgsDelimiter)
    For idx = LBound(listWarnTime) to UBound(listWarnTime)
        If InStrRev(listWarnTime(idx),MinChar) Then
            listWarnTimeDir(Idx) = -1
        End If
        listWarnTime(idx) = Replace(Replace(listWarnTime(idx),MinChar,""),MaxChar,"")
        listWarnTime(idx) = cnvtime(listWarnTime(idx),"SEC","",null)
    Next
End If

if Wscript.Arguments.Named.Exists("crit_age") Then
    listCritTime = Split(Wscript.Arguments.Named("crit_age"),ArgsDelimiter)
    For idx = LBound(listCritTime) to UBound(listCritTime)
        If InStrRev(listCritTime(idx),MinChar) Then
            listCritTimeDir(Idx) = -1
        End If
        listCritTime(idx) = Replace(Replace(listCritTime(idx),MinChar,""),MaxChar,"")
        listCritTime(idx) = cnvtime(listCritTime(idx),"SEC","",null)
    Next
End If

if Wscript.Arguments.Named.Exists("warn_size") Then
    listWarnSize = Split(Wscript.Arguments.Named("warn_size"),ArgsDelimiter)
    For idx = LBound(listWarnSize) to UBound(listWarnSize)
        If InStrRev(listWarnSize(idx),MinChar) Then
            listWarnSizeDir(Idx) = -1
        End If
        listWarnSize(idx) = Replace(Replace(Replace(listWarnSize(idx),":b:"," "),MinChar,""),MaxChar,"")
    Next
End If

if Wscript.Arguments.Named.Exists("crit_size") Then
    listCritSize = Split(Wscript.Arguments.Named("crit_size"),ArgsDelimiter)
    For idx = LBound(listCritSize) to UBound(listCritSize)
        If InStrRev(listCritSize(idx),MinChar) Then
            listCritSizeDir(Idx) = -1
        End If
        listCritSize(idx) = Replace(Replace(Replace(listCritSize(idx),":b:"," "),MinChar,""),MaxChar,"")
    Next
End If

if Wscript.Arguments.Named.Exists("false") Then
    listAlertWhenFalse = Split(Wscript.Arguments.Named("false"),ArgsDelimiter)
End If

if Wscript.Arguments.Named.Exists("true") Then
    listAlertWhenTrue = Split(Wscript.Arguments.Named("true"),ArgsDelimiter)
End If

if Wscript.Arguments.Named.Exists("list") Then
    procList = 1
End If

if vartype(listFileName) > 0 Then
    If lookupType = "one:one" AND UBound(listFileName) <>  UBound(listPathName) Then
        ReturnCode=3
        streamEcho StrALERT(ReturnCode) & ": Paths and files list have to be the same in number until lookup type is " & lookupType & ", otherwise use many:many."
        WScript.quit(ReturnCode)
    End If
End If
pathSize = 0
For idxPath = LBound(listPathName) To UBound(listPathName)
    set objFSO=CreateObject("Scripting.FileSystemObject")
    On error Resume Next
    Set objFolder = objFSO.GetFolder(listPathName(idxPath))
    On Error goto 0
    If VarType(objFolder) <= 1 Then
        ReturnCode=2
        If UBound(listAlertWhenFalse) > 0 Then
            ReturnCode=listAlertWhenFalse(0)
        End If
        streamEcho StrALERT(ReturnCode) & ": Path " & listPathName(idxPath) & " not found!"
        WScript.quit(ReturnCode)
    End if
    ScanFolders objFolder
    
    Set objFolder = nothing
    set objFSO = nothing
Next

StrOutput = "Paths size:" & round(pathSize/1024,2) & "kb"
StrPerfData = ""
If aPerfData(0) Then
    StrPerfData = "pathSize=" & round(pathSize/1024,2) & "kb;;;;"
End If

If IsArray(listFileName) Then
    For idx = LBound(listFileName) To UBound(listFileName)
        If listFileCount(idx) >= 1 Then
			StrPerfData = StrPerfData & " " & "fileCount_grp" & idx+1 & "=" & listFileCount(idx) & "ct;;;;"
            listReturnCode(idx) = 0
            If IsArray(listAlertWhenTrue) Then
                listReturnCode(idx) = listAlertWhenTrue(1)
            End If
            lastUpdSince = cnvtime(listFileUpdTime(idx),"SINCE","STR"," ")
            StrOutput = StrOutput & "; GROUP"&idx+1&"={File:" & listFileName(idx) & ", Count:" & listFileCount(idx) & ", Updated:" & lastUpdSince & ",Size:" & round(listFileSize(idx)/1024,2) & "kb}"
            lastUpdSince = cnvtime(listFileUpdTime(idx),"SINCE",""," ")

            If IsArray(listMatchString) Then
                If listMatched(idx) Then
                    StrOutput = StrOutput & " text match:'" & listMatchString(idx) & "'"
                    ReturnCode = 0
                    If UBound(listAlertWhenTrue) > 1 Then
                        ReturnCode=listAlertWhenTrue(2)
                    End If
                    listReturnCode(idx) = ReturnCode
                Else
                    StrOutput = StrOutput & " text no match:'" & listMatchString(idx) & "'"
                    ReturnCode = 2
                    If UBound(listAlertWhenFalse) > 1 Then
                        ReturnCode=listAlertWhenFalse(2)
                    End If
                    listReturnCode(idx) = ReturnCode
                End If
            End If

            strWarning = ""
            StrAGE = ""
            if IsArray(listWarnSize) Then
                If CDbl(listWarnSize(idx)) >=0 Then
                    strWarning = CStr(listWarnSize(idx))
                    If (CDbl(listFileSize(idx)) * listWarnSizeDir(idx)) >= ((CDbl(listWarnSize(idx))*1024) * listWarnSizeDir(idx)) Then
                        StrAGE = " FILE SIZE GRP"&idx+1&"!"
                        listReturnCode(idx) = 1
                    End If
                Else
                    strWarning = ""
                End If
            End If
            strCritical = ""
            if IsArray(listCritSize) Then
                if CDbl(listCritSize(idx)) >= 0 Then
                    strCritical = CStr(listCritSize(idx))
                    If (CDbl(listFileSize(idx))* listCritSizeDir(idx)) >= ((CDbl(listCritSize(idx))*1024) * listCritSizeDir(idx)) Then
                        StrAGE = " FILE SIZE GRP"&idx+1&"!"
                        listReturnCode(idx) = 2
                    End If
                Else
                    strCritical = ""
                End If
            End If
            If aPerfData(2) Then
                StrPerfData = StrPerfData & " " & "fileSize_grp" & idx+1 & "=" & round(listFileSize(idx)/1024,2) & "kb;"& strWarning &";"& strCritical &";;"
            End If

            strWarning = ""
            if IsArray(listWarnTime) Then
                if CDbl(listWarnTime(idx)) >=0 Then
                    strWarning = CStr(listWarnTime(idx))
                    If (CDbl(lastUpdSince) * listWarnTimeDir(idx)) >= (CDbl(listWarnTime(idx)) * listWarnTimeDir(idx)) Then
                        StrAGE = StrAGE & " FILE AGE GRP"&idx+1&"!"
                        listReturnCode(idx) = 1
                    End If
                Else
                    strWarning = ""
                End If
            End If
            strCritical = ""
            if IsArray(listCritTime) Then
                if CDbl(listCritTime(idx)) >= 0 Then
                    strCritical = CStr(listCritTime(idx))
                    If (CDbl(lastUpdSince) * listCritTimeDir(idx)) >= (CDbl(listCritTime(idx)) * listCritTimeDir(idx)) Then
                        StrAGE = StrAGE & " FILE AGE GRP"&idx+1&"!"
                        listReturnCode(idx) = 2
                    End If
                Else
                    strCritical = ""
                End If
                If aPerfData(1) Then
                    StrPerfData = StrPerfData & " " & "fileUpd_grp" & idx+1 & "=" & cnvtime(listFileUpdTime(idx),"SINCE",""," ") & "s;"& strWarning &";"& strCritical &";;"
                End If
            End If

        Else
            StrOutput = StrOutput & "; GROUP"&idx+1&"={File not found!'" & listFileName(idx) & "'}"
			StrPerfData = StrPerfData & " " & "fileCount_grp" & idx+1 & "=" & listFileCount(idx) & "ct;;;;"
			StrPerfData = StrPerfData & " " & "fileSize_grp" & idx+1 & "=0kb;;;;"
			StrPerfData = StrPerfData & " " & "fileUpd_grp" & idx+1 & "=0s;;;;"
            listReturnCode(idx) = listAlertWhenFalse(1)
        End If
    Next
End If
ReturnCode=0
For idx = LBound(listReturnCode) To UBound(listReturnCode)
    If ReturnCode < CInt(listReturnCode(idx)) Then
        ReturnCode = CInt(listReturnCode(idx))
    End If
Next
if ReturnCode < 0 OR ReturnCode > 2 Then
    ReturnCode = 3
End If
streamEcho StrALERT(ReturnCode) & StrAGE & " " & StrOutput & "|" & StrPerfData

'WScript.Stdout.Write StrOutput
WScript.Quit(ReturnCode)
