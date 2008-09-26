@echo off
for /F %%i in (split.txt) do move ..\%%i .
del split.txt
del Ace3.toc
move Ace3.toc.unsplit Ace3.toc

