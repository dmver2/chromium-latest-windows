#!/bin/sh
BASEDIR=$(dirname "$0")
PROGNAME=$(basename "$0")

LOGFILE="${BASEDIR}/${PROGNAME%.*}.log"

find=/bin/find

warn() {
echo "    _____  .__  .__                  .__                          __.   __.  "
echo "   /  _  \ |  | |  |   ____   ______ |  | _______  ______  __ ___/  |__/  |_ "
echo "  /  /_\  \|  | |  | _/ __ \ /  ___/ |  |/ /\__  \ \____ \|  |  \   __\   __\\"
echo " /    |    \  |_|  |_\  ___/ \___ \  |    <  / __ \|  |_> >  |  /|  |  |  |  "
echo " \____|__  /____/____/\___  >____  > |__|_ \(____  /   __/|____/ |__|  |__|  "
echo "         \/               \/     \/       \/     \/|__|                      "
log "${PROGNAME}: $@"
}

die() {
    warn $*
	cleanup
    exit 1
} 

download() {
	if [[ -f "${CURLEXE}" ]]; then
		"${CURLEXE}" -# $1 > $2
	else
		cscript "//nologo" ${BASEDIR}/wget.js $1 $2
	fi
	if [ $? != 0 ] ; then
	  die "Download failed!"
	fi
} 

fetch() {
	if [[ -f "${CURLEXE}" ]]; then
		echo `"${CURLEXE}" -s -S $1`
	else
		echo $(cscript "//nologo" ${BASEDIR}/wget.js $1 | sed 's/[\r\n ]//g')
	fi
} 

cleanup() {
    echo "Removing temporary installation directories..."
	rm -rfv "${BASEDIR}/"CR_*.tmp
#    exit
}

log() {
	echo $(date --iso-8601=seconds) $* 2>&1 | tee -a ${LOGFILE}
}

### variables
LASTCHANGE_URL="https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Win%2FLAST_CHANGE?alt=media"
CURLEXE=$(which curl 2>/dev/null)
SIGCHECK="/c/bin/SysinternalsSuite/sigcheck"

### main()
trap cleanup INT TERM
log "Starting ${PROGNAME} at ${BASEDIR}..." 
#REVISION=$(curl -s -S $LASTCHANGE_URL)
REVISION=$(fetch $LASTCHANGE_URL)

if [[ -z ${REVISION} ]]; then
	die "Failed getting latest revision"
fi
log "latest revision is $REVISION"

ZIP_FILE="${BASEDIR}/${REVISION}-mini_installer.exe"

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
chmod a+x $ZIP_FILE
if [ $? != 0 ] ; then
  die "chmod error"
fi
log "done"

log "Contemporary distro for update:" $(ls -l $ZIP_FILE)
log "Running installer..." 
$ZIP_FILE
wait $!
if [ $? != 0 ] ; then
  die "$ZIP_FILE installation failed"
fi

if [[ -x $SIGCHECK ]]; then 
   ${SIGCHECK} -nobanner "$ZIP_FILE" 2>&1 | tee -a ${LOGFILE}
   VERSION=$(${SIGCHECK} -nobanner -n "$ZIP_FILE")
else
   VERSION=""
fi

printf "Removing out of date files %s/*-mini_installer.exe ...\n" "${BASEDIR}"
${find} "${BASEDIR}" -name "*-mini_installer.exe" -type f -mtime +2 | xargs rm -fv {}
printf "...  done\n"

log "Done: latest revision $REVISION is INSTALLED (version: ${VERSION})"
cleanup
