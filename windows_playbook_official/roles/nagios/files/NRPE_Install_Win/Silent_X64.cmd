start /wait msiexec /q /package \\sasv0158\Nagios_Setup$\NRPE_Install_Win\NSClient++-0.3.9-x64.msi

robocopy "\\sasv0158\Nagios_Setup$\NRPE_Install_Win\scripts" "%ProgramW6432%\Nsclient++\scripts" /MIR

xcopy "\\sasv0158\Nagios_Setup$\NRPE_Install_Win\NSC.ini" "%ProgramW6432%\Nsclient++\NSC.ini" /Y

net start NSClientpp