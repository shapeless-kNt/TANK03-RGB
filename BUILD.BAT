@echo off
setlocal
clang -target i686-pc-windows-msvc -c TANKRGB.S -o TANKRGB.OBJ
if errorlevel 1 exit /b 1
lld-link /subsystem:windows /entry:mainCRTStartup /nodefaultlib /safeseh:no /opt:ref /fixed /out:TANKRGB.EXE TANKRGB.OBJ
if errorlevel 1 exit /b 1
for %%F in (TANKRGB.EXE) do echo Built %%~zF bytes: %%F
endlocal
