@echo off
echo.
echo Running all -?.x test cases:
echo.

setlocal
if _%lua%_==__ set lua=lua

for %%i in (*-?.*.lua) do call :runtest %%i


echo.
echo -----------------------
echo DONE!
echo.
echo (To point at a specific lua.exe, use "set lua=c:\path\to\lua.exe" prior to executing %0)
echo.
pause
goto :eof


:runtest
echo ----- Running %1:
%lua% %1
goto :eof
