@echo off

pdlice.exe -M | findstr "%1 [Reserved:|Seats:] Expires Service"
