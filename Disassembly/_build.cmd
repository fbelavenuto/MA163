@echo off

echo Building software
docker run --rm -it -e TZ=America/Sao_Paulo -v %cd%:/src fbelavenuto/8bitcompilers make clean all
IF ERRORLEVEL 1 GOTO error


echo Comparing ROM
fc /b apple.rom apple.bin

goto ok

:error
echo Ocorreu algum erro!
:ok
echo.
pause
