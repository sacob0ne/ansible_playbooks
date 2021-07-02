@echo off

set lic=%1

pdlice.exe -M | findstr /R /C:" %lic%  Reserved:" /C:" %lic%  Seats:" /C:" %lic%[^a-zA-Z0-9]" /C:"Expires" /C:"Service"
