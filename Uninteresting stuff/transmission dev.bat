@echo off && goto loaded

:loaded
set git="C:\Program Files\Git\bin\git.exe"
set cmake="C:\Program Files\CMake\bin\cmake.exe"
set vcpkg="C:\Transmission\Transmission build\vcpkg\vcpkg.exe"
set vcpkgb="C:\Transmission\Transmission build\vcpkg\bootstrap-vcpkg.bat"

cd /d %~dp0
set batchfile=%~0
if %cd:~-1%==\ (set batchdir=%cd%) else (set batchdir=%cd%\)
set admin=0
net session > nul 2>&1
if %errorlevel% == 0 (set admin=1 && echo Now running as Admin. What was your choice, again?)
goto main

:admin
powershell Start-Process -FilePath '%batchfile%' -ArgumentList '%batchdir%' -verb runas>NUL 2>&1
exit

:main
cd /d %~dp0
echo (V)cpkg (T)ransmission (C)make (W)eb d(E)v web (D)aemon (B)rowser (H)elp
choice /c:vtcwedbh /n
if %ERRORLEVEL%==1 goto vcpkg
if %ERRORLEVEL%==2 goto transmission
if %ERRORLEVEL%==3 goto cmake
if %ERRORLEVEL%==4 goto web
if %ERRORLEVEL%==5 goto dev
if %ERRORLEVEL%==6 goto dae
if %ERRORLEVEL%==7 goto browser
if %ERRORLEVEL%==8 goto help

:vcpkg
if not exist vcpkg %git% clone https://github.com/microsoft/vcpkg && cmd /c %vcpkgb% -disableMetrics
%vcpkg% install curl zlib openssl --triplet=x64-windows
::%vcpkg% install qt5-tools qt5-winextras --triplet=x64-windows
goto main

:transmission
if not exist transmission %git% clone https://github.com/transmission/transmission
::if not exist transmission %git% clone -b 4.0.x https://github.com/transmission/transmission
cd transmission
%git% submodule update --init --recursive
goto main

:cmake
::if %admin%==0 goto admin
cd transmission
%cmake% -B build -DCMAKE_TOOLCHAIN_FILE="C:\Transmission\vcpkg\scripts\buildsystems\vcpkg.cmake" -DENABLE_DAEMON=ON -DENABLE_QT=OFF -DENABLE_UTILS=ON -DENABLE_CLI=ON -DCMAKE_INSTALL_PREFIX="C:\Transmission"
%cmake% --build build --target INSTALL --config Release
goto main

:web
cd /d "transmission\web"
cmd /c "C:\Program Files\nodejs\npm" ci
cmd /c "C:\Program Files\nodejs\npm" run build
xcopy /y C:\Transmission\transmission\web\public_html\transmission-app.js C:\Transmission\bin\public_html\transmission-app.js
xcopy /y C:\Transmission\transmission\web\public_html\index.html C:\Transmission\bin\public_html\index.html
goto main

:dev
cd /d "transmission dev\web"
cmd /c "C:\Program Files\nodejs\npm" ci --no-audit --no-fund --no-progress
cmd /c "C:\Program Files\nodejs\npm" run build
xcopy /y "C:\Transmission\transmission dev\web\public_html\transmission-app.js" C:\Transmission\bin\public_html\transmission-app.js
xcopy /y "C:\Transmission\transmission dev\web\public_html\index.html" C:\Transmission\bin\public_html\index.html
goto main

:dae
start cmd /k "@echo off&&echo Kill this CLI to end daemon.&&C:\Transmission\bin\transmission-daemon.exe -f --log-level=info"
goto main

:browser
start firefox.exe "http://127.0.0.1:9997"
goto main

:help
start cmd /k "@echo off&&echo Kill this CLI to end daemon.&&C:\Transmission\bin\transmission-daemon.exe -h"
goto main

:end
pause