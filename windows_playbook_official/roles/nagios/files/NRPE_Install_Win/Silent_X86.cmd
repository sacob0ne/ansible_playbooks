start /wait msiexec /q /package \\sasv0158\Nagios_Setup$\NRPE_Install_Win\NSClient++-0.3.9-Win32.msi

robocopy "\\sasv0158\Nagios_Setup$\NRPE_Install_Win\scripts" "%ProgramFiles%\Nsclient++\scripts" /MIR

xcopy "\\sasv0158\Nagios_Setup$\NRPE_Install_Win\NSC.ini" "%ProgramFiles%\Nsclient++\NSC.ini" /Y

net start NSClientpp