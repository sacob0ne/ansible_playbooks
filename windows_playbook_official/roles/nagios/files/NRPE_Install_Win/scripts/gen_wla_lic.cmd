@echo off

setlocal enableextensions enabledelayedexpansion

set lsmon="C:\Program Files (x86)\Computers and Structures\Sentinel RMS 8.5 Utilities\lsmon.exe"
set wla_tmp="C:\Program Files\NSClient++\scripts\wla_lic.tmp"
set wla_file="C:\Program Files\NSClient++\scripts\wla_lic.txt"

echo\ | !lsmon! localhost 1>!wla_tmp! 2>&1

del !wla_file!
rename !wla_tmp! wla_lic.txt

echo WLA License Usage File Generated