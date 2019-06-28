#!/bin/sh -xe
DIRNAME=$(dirname "$0")
PROGNAME=$(basename "$0")

warn() {
echo "   _____  .__  .__                   __                          __    __   "
echo "   /  _  \ |  | |  |   ____   ______ |  | _______  ______  __ ___/  |__/  |_ "
echo "  /  /_\  \|  | |  | _/ __ \ /  ___/ |  |/ /\__  \ \____ \|  |  \   __\   __\\"
echo " /    |    \  |_|  |_\  ___/ \___ \  |    <  / __ \|  |_> >  |  /|  |  |  |  "
echo " \____|__  /____/____/\___  >____  > |__|_ \(____  /   __/|____/ |__|  |__|  "
echo "         \/               \/     \/       \/     \/|__|                      "
echo "${PROGNAME}: $*"
}

die() {
    warn $*
    exit 1
} 

download() {
	if [ -f ${curlexe} ]; then
		${curlexe} -# $1 > $2
	else
		cscript "//nologo" $DIRNAME/wget.js $1 $2
	fi
	if [ $? != 0 ] ; then
	  die "Download failed!"
	fi
} 

fetch() {
	if [ -f ${curlexe} ]; then
		echo `${curlexe} -s -S $1`
	else
		echo $(cscript "//nologo" $DIRNAME/wget.js $1 | sed 's/[\r\n ]//g')
	fi
} 

### main()
LASTCHANGE_URL="https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Win%2FLAST_CHANGE?alt=media"
curlexe=$(which curl 2>/dev/null)

#REVISION=$(curl -s -S $LASTCHANGE_URL)
REVISION=$(fetch $LASTCHANGE_URL)

if [[ -z REVISION ]]; then
	die "Failed getting latest revision"
fi
echo "latest revision is $REVISION"

ZIP_FILE="${REVISION}-mini_installer.exe"

if [ -f $ZIP_FILE ] ; then
  die "already have latest version"
fi

ZIP_URL="https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Win%2F${REVISION}%2Fmini_installer.exe?alt=media"

printf "fetching %s ... " $ZIP_URL

#curl -# $ZIP_URL > $ZIP_FILE
download $ZIP_URL $ZIP_FILE
if [ ! -f $ZIP_FILE ]; then
	die "Nothing downloaded!"
fi
chmod a+x ./$ZIP_FILE
if [ $? != 0 ] ; then
  die "chmod error"
fi
echo "done"

echo "Updated distro:" $(ls -l ./$ZIP_FILE)
echo "Running installer..." 
./$ZIP_FILE
wait $!
if [ $? != 0 ] ; then
  die "installation failed"
fi

printf "removing out of date distros ... "
find ./*-mini_installer.exe -mtime +1 | xargs rm -fv {}
printf "...  done\n"

echo "Done: latest revision $REVISION is INSTALLED"
