@echo off

dsquery user -name %1 |dsget user -samid -acctexpires | findstr %1