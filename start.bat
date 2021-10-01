@ECHO OFF
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& './converter.ps1'"
set isexists=
FOR /F "delims=" %%i IN ('docker images  ^| findstr /i "%1"') DO set "isexists=%%i"
echo "%isexists%"

set dobuild=
if "%isexists%" == "" (set dobuild=y)
set param2=%2
if NOT "%param2%"=="%param2:forcebuild=%" (set dobuild=y)
if "%dobuild%" == "y" (docker build . -t %1)

set currdir=%cd%
docker run -it --rm -v %currdir%:/root/ -v //var/run/docker.sock:/var/run/docker.sock --add-host kubernetes:127.0.0.1 --name %1 %1
PAUSE
