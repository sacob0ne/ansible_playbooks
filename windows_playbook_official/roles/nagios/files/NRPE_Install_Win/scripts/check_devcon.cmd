@echo off
REM
REM By Fabio Frioni
REM Intesi Group S.p.A
REM http://www.intesigroup.com
REM ffrioni@intesigroup.com
REM
REM esegue devcon per la lista di devices nel file registro di una macchina remota
REM
REM %1 (obbligatorio) il server (o alias) remoto su cui c'e' il device caricato
REM %2 (obbligatorio) un filtro di stringa da trovare
REM %3 (obbligatorio) un'ulteriore filtro stringa da trovare
REM

REM -----------------
REM Take the date time format

REM :: Test for REG.EXE Version
REG QUERY "HKCU\Control Panel\International\sShortDate" 2> NUL
IF %errorlevel% == 0 GOTO REGNEW

:REG30
FOR /F "tokens=3" %%A IN ('REG QUERY "HKCU\Control Panel\International" /v sShortDate') DO (
    SET sShortDate=%%A
)
GOTO CONT

:REGNEW
REM :: For earlier REG.EXE versions
FOR /F "tokens=3" %%A IN ('REG QUERY "HKCU\Control Panel\International\sShortDate"') DO (
    SET sShortDate=%%A
)

:CONT
ECHO %sShortDate% | FINDSTR /R /B /I /C:"dd*[-/]mm*[-/]yyyy" >NUL
IF %ERRORLEVEL% == 0 (
    For /F "tokens=1,2,3 delims=-/ " %%A in ('Date /t') do ( 
        Set Day=%%A
        Set Month=%%B
        Set Year=%%C
        Set AllDate=%%C%%B%%A
    )
)
IF NOT %ERRORLEVEL% == 0 (
    ECHO %sShortDate% | FINDSTR /R /B /I /C:"mm*[-/]dd*[-/]yyyy" >NUL
    IF %ERRORLEVEL% == 0 (
        For /F "tokens=1,2,3 delims=-/ " %%A in ('Date /t') do ( 
            Set Day=%%B
            Set Month=%%A
            Set Year=%%C
            Set AllDate=%%C%%A%%B
        )
    )
)
IF NOT %ERRORLEVEL% == 0 (
    ECHO %sShortDate% | FINDSTR /R /I /C:"yy*[-/]mm*[-/]dd" >NUL
    IF %ERRORLEVEL% == 0 (
        For /F "tokens=1,2,3 delims=-/ " %%A in ('Date /t') do ( 
            Set Day=%%C
            Set Month=%%B
            Set Year=%%A
            Set AllDate=%%C%%B%%C
        )
    )
)

For /F "tokens=1,2,3 delims=.: " %%A in ('Time /t') do ( 
    Set Hours=%%A
    Set Minutes=%%B
    Set Seconds=%%C
    Set AllTime=%%A%%B%%C
)


cd "C:\Program Files\NSClient++\scripts"
devcon find * | find "%2"  | find /c "%3" > devcon_%AllDate%%AllTime%.txt
FOR /F %%A IN (devcon.txt) DO (
if %%A EQU 0 GOTO CRITICAL
if %%A EQU 1 GOTO OK
if %%A GTR 1 GOTO WARNING
)
GOTO UNKNOWN

:OK
ECHO OK: DEVCON - Device found with string "%2 %3" on %1
SET RC=0
GOTO FINE
ECHO WARNING: DEVCON - More Devices found with string "%2 %3" on %1
:WARNING
SET RC=1
GOTO FINE
:CRITICAL
ECHO CRITICAL: DEVCON - No Device found with string "%2 %3" on %1
SET RC=2
GOTO FINE
:UNKNOWN
ECHO UNKNOWN: An error occurred searching Device with string "%2 %3" on %1
SET RC=3

:FINE
exit %RC%
