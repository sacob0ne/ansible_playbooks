@echo off
:: *****************************************************************************
:: File:    win_service_restart.cmd
:: Author:  Vadims Zenins http://vadimszenins.blogspot.com
:: Version: 1.05
:: Date:    24/11/2009 18:26:41
:: Windows Failed Service restart batch file for Nagios Event Handler
::
::  Copy win_service_restart.cmd to \NSClient++\scripts\ folder.
::
:: Nagios commands.cfg:
:: define command{
::        command_name    win_service_restart
::        command_line    $USER1$/check_nrpe -H $HOSTADDRESS$ -p 5666 -c win_service_restart -a "$SERVICEDESC$" $SERVICESTATE$ $SERVICESTATETYPE$ $SERVICEATTEMPT$
::        }
::
:: Nagios template-services_common-win.cfg
:: define service{
::         name                    generic-service-win-wuauserv
::         service_description     wuauserv
::         display_name            Automatic Updates
::         event_handler           win_service_restart
::         event_handler_enabled   1
::         check_command           check_nt!SERVICESTATE!-d SHOWALL -l $SERVICEDESC$
::         }
::
:: NSCLIENT++ NSC.ini:
::   [NRPE]
::   allowed_hosts=192.168.1.1/32  ; your Nagios server IP
::   allow_arguments=1
::   [External Script]
::   allow_arguments=1
::   allow_nasty_meta_chars=1
::   [NRPE Handlers]
::   command[win_service_restart]=scripts\win_service_restart.cmd "$ARG1$" $ARG2$ $ARG3$ $ARG4$
::
:: Additional examples on http://vadimszenins.blogspot.com/2008/12/nagios-restart-windows-failed-services.html
::
:: Tested platform:
:: Windows 2003 R2 x64 SP2, Nagios 3.2.0, NSClient++ 0.3.6.316 2009-02-04 w32
::
:: Version 1.05 revision:
:: Logging changes, stop and start services commands nave changed. Logs examples added.
:: Version 1.04 revision:
:: Double restart of the servise is fixed
:: Version 1.03 revision:
:: Description is changed
:: Version 1.02 revision:
:: @NET changed to @SC
:: Version 1.01 revision:
:: Service name's with spase problem is fixed
::
:: This code is made available as is, without warranty of any kind. The entire
:: risk of the use or the results from the use of this code remains with the user.
:: *****************************************************************************

::echo 1: %1    2: %2    3: %3    4: %4

@SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
:: Grab a file name and extension only
SET SCRIPTNAME=%~nx0
:: Replace "
SET SCRIPTNAME=%SCRIPTNAME:"=%
SET LOGDIR=C:\Program Files\NSClient++\logs
SET SERVICENAME=%1
:: Replace "
SET SERVICENAME1=%SERVICENAME:"=%
SET LOGFILE=%1
SET LOGFILE=%LOGFILE:"=%
:: Replace space by _
SET LOGFILE=%LOGFILE: =_%
SET LOGFILE=%LOGDIR%\%LOGFILE%.log

if "%SERVICENAME1%"=="" SET LOGFILE=%LOGDIR%\NO_SERVICENAME.log
::@echo servicename:  %SERVICENAME%
::@echo logfile: %LOGFILE%
::@echo SERVICENAME1: %SERVICENAME1%

:: =============================================================================

if not exist %LOGDIR% md %LOGDIR%
echo. 																									>>%LOGFILE%
echo =============================================================================  					>>%LOGFILE%
echo %DATE% %TIME% %SCRIPTNAME% has started 															>>%LOGFILE%
echo =============================================================================  					>>%LOGFILE%

@if "%SERVICENAME1%"=="" goto usage
@if "%SERVICENAME1%"=="/?" goto usage
@if "%SERVICENAME1%"=="-?" goto usage

@echo Variables 1: %1   2: %2   3: %3   4: %4 															>>%LOGFILE%

@SC query %SERVICENAME% 																				>>%LOGFILE%

@SC query %SERVICENAME% | FIND /I "RUNNING" 															>>%LOGFILE%
if .%ERRORLEVEL%.==.0. (
	SET RETURN=Service %SERVICENAME% is running
	goto END
)

:RESTART
@echo %DATE% %TIME% Restarting %SERVICENAME% services... 												>>%LOGFILE%
@SC stop %SERVICENAME% 																					>>%LOGFILE% 2>&1
@sleep 2
SET RETURN=Service %SERVICENAME% start pending
@SC start %SERVICENAME% | FIND /I "FAILED"
if .%ERRORLEVEL%.==.0. (
	SET RETURN=Start Service %SERVICENAME% FAILED
	@SC start %SERVICENAME% 																			>>%LOGFILE% 2>&1
	goto END
)
@sleep 5
@SC query %SERVICENAME% | FIND /I "RUNNING"
if .%ERRORLEVEL%.==.0. (
	SET RETURN=Service %SERVICENAME% has started
	@SC query %SERVICENAME% 																			>>%LOGFILE%
	goto END
)
@goto end

:USAGE
@echo Usage: >>%LOGFILE%
@echo  win_service_restart "^<SERVICENAME^>" ^<SERVICESTATE^> ^<SERVICESTATETYPE^> ^<SERVICEATTEMPT^> 	>>%LOGFILE%
@echo  ^<SERVICENAME^> is "Service name", do not mix with "Display name" 								>>%LOGFILE%
@echo  ^<SERVICESTATE^>, ^<SERVICESTATETYPE^> and ^<SERVICEATTEMPT^> are optional 						>>%LOGFILE%
::exit 128

:END
echo %DATE% %TIME% %SCRIPTNAME% has finished with code 													>>%LOGFILE%
echo %RETURN% 																							>>%LOGFILE%
@echo %SCRIPTNAME%: %RETURN%
exit 0

