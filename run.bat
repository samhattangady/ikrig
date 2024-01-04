@echo off
set executable=odin-out\ikrig.exe
if exist %executable% (del %executable%)
call timecmd odin build src -out:odin-out\ikrig.exe
if exist %executable% (call %executable%)
goto :done

:done
