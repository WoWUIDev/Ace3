@echo off
for /D %%i in (*-?.*) do call :splitone %%i
move Ace3.toc Ace3.toc.unsplit
echo ##Interface: 20400 > Ace3.toc
echo ##Title: Lib: Ace3 >> Ace3.toc
echo ##OptionalDeps: AceAddon-3.0, AceConsole-3.0, AceConfig-3.0 >> Ace3.toc
echo LibStub\LibStub.lua >> Ace3.toc
echo Ace3.lua  >> Ace3.toc
goto :eof

:splitone
echo Splitting off %1...
echo %1 >> split.txt
echo ##Interface: 20400 > %1\%1.toc
echo ##Title: Lib: %1 >> %1\%1.toc
if not "%1" == "CallbackHandler-1.0" echo ##OptionalDeps: LibStub, CallbackHandler-1.0, AceGUI-3.0, AceConsole-3.0 >> %1\%1.toc
echo ##LoadWith: Ace3 >> %1\%1.toc
echo %1.xml >> %1\%1.toc
move %1 ..
goto :eof