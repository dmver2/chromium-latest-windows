# chromium-latest-windows
Scripts to download and run the latest Windows build of Chromium, 
as described here https://www.chromium.org/getting-involved/download-chromium.
tested on Windows 7(sp1), 8, 8.1, 10
pre-requisites:
* MingW MSYS http://www.mingw.org/ (sh.exe) 
	or Git Bash from Git for Windows https://gitforwindows.org/
* Curl (optional)
* Sigcheck (optional) https://docs.microsoft.com/en-us/sysinternals/downloads/sigcheck from SysinternalsSuite

## short description
* README.md - this file
* update.sh - main script, checks and gets latest chromium version, downloads installer and run it synchronously, prints out signature and version info.
* update-chromium.cmd - batch file to be executed by Windows Task Scheduler (%windir%\system32\taskschd.msc /s).
* wget.js auxiliary js script for Windows Scripting Host e.g. cscript.exe: performs http requests and returns result or write it down to file.
* img/screenshot.png - script output, just in case

## short user guide
download distibutable files to any directory %UDIR% (e.g. '/c/shell')
* Optionally allow cscript ar install curl and make it accessible from bash shell.
* run bash.exe
* run ${UDIR}/update.sh
* wait a bit for process to complete

<pre><code>
dmver@ossifrage MINGW64 ~
$ /c/shell/chromium-latest-windows/update.sh
latest revision is 816556
fetching https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Win%2F816556%2Fmini_installer.exe?alt=media ... #=#=#                    ######################################################################## 100,0%
done
Contemporary distro for update: -rwxr-xr-x 1 dmver 197609 58313728 Oct 13 19:04 /c/shell/chromium-latest-windows/816556-mini_installer.exe
Running installer...
c:\shell\chromium-latest-windows\816556-mini_installer.exe:
        Verified:       Unsigned
        Link date:      8:00 04.10.2020
        Publisher:      n/a
        Company:        The Chromium Authors
        Description:    Chromium Installer
        Product:        Chromium Installer
        Prod version:   88.0.4292.0
        File version:   88.0.4292.0
        MachineType:    32-bit
Removing out of date files /c/shell/chromium-latest-windows/*-mini_installer.exe ...
removed '/c/shell/chromium-latest-windows/815937-mini_installer.exe'
...  done
Removing temporary installation directories...
removed '/c/shell/chromium-latest-windows/CR_CFE5A.tmp/setup.exe'
removed directory '/c/shell/chromium-latest-windows/CR_CFE5A.tmp'

dmver@ossifrage MINGW64 ~
$ 
</code></pre>

