# chromium-latest-windows
Scripts to download and run the latest Windows build of Chromium, 
as described here https://www.chromium.org/getting-involved/download-chromium.
<br/>
tested on Windows 7(sp1), 8, 8.1, 10
<br/>
pre-requisites:
* MingW MSYS http://www.mingw.org/ (sh.exe) 
	or Git Bash from Git for Windows https://gitforwindows.org/
* Curl (optional) https://packages.msys2.org/package/mingw-w64-x86_64-curl or https://curl.haxx.se/windows/
* Sigcheck (optional) https://docs.microsoft.com/en-us/sysinternals/downloads/sigcheck from SysinternalsSuite

## short description
* <code>README.md</code> - this file
* <code>update.sh</code> - main script, checks and gets latest chromium version, downloads installer and run it synchronously, prints out signature and version info.
* <code>update-chromium.cmd</code> - batch file to be executed by Windows Task Scheduler (<code>%windir%\system32\taskschd.msc /s</code>).
* <code>wget.js</code> auxiliary js script for Windows Scripting Host e.g. cscript.exe: performs http requests and returns result or download contents to file, if <code>curl</code> is not accessible.
* <code>img/screenshot.png</code> - script output, just in case

## short user guide
Download distributable files to any directory %SCRIPT_DIR% (e.g. <code>/c/shell</code>)
* Optionally allow cscript ar install curl and make it accessible from bash shell.
* run bash.exe
* run ${SCRIPT_DIR}/update.sh
* wait a bit for process to complete.
### Expected output:

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

## to do/to be enhanced
add checksum test, if distribution checksum will be available (now it's not provided along with mini-installer or zip)
