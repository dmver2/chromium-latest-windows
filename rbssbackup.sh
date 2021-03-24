#!/bin/bash

## template for RBSS log backup

## expected logrotate has been already set up as following:
# /etc/logrotate.conf
# or
#
# /etc/logrotate.d/tomcat.conf :
#
# /u00/tomcat/logs/catalina.out
# {
# su tcadm tcadm
# daily
# rotate 14
# compress
# notifempty
# missingok
# copytruncate
# dateext
# dateyesterday
# create 640 tcadm tcadm
# }

# test logrotate:
# *	dry run with --debug:
# su [-] tcadm logrotate -dvf /etc/logrotate.d/tomcat -s /home/tcadm/logbackup/logrotate.status
# *	real operational run:
# su tcadm logrotate -vf /etc/logrotate.d/tomcat -s /home/tcadm/logbackup/logrotate.status
# truncated file expected as a result: /u00/tomcat/logs/catalina.YYYY-MM-DD.log.gz
##
# source $HOME/.bashrc expected, but no $HOME available in a process spawned from cron usually.
# setup PATH, ENV manually
export PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin

BKPPOLICY=tomcat_logs_daily

for p in "$@"; do
  case $p in
  -test)
    testmode=1
    BKPPOLICY=non_existent_policy
    ;;
  -testpolicy)
    BKPPOLICY=test_tomcat_logs
    ;;
  esac
done

PROGNAME=$(basename $0)
BASEDIR=$(dirname $0)

BKPPLANNER=full_logs_daily

RCPT_TO=will.jiang@vtb.com
APPROOT_DIR=/u00

#NOTIFYMSG=${BASEDIR}/${PROGNAME/\.*/}-$(date -I).msg
declare -a MODULES=("mca" "mcm" "router" "tomcat")

BPBACKUP=/usr/openv/netbackup/bin/bpbackup
LOGROTATE=/usr/sbin/logrotate

if [ -z ${testmode} ]; then
  SENDMAIL=echo
  SENDMAILCMD=
  # SENDMAIL="/usr/sbin/sendmail"
  # SENDMAILCMD="${SENDMAIL} ${RCPT_TO} < ${NOTIFYMSG}"
else
  SENDMAIL=echo
fi

die() {
  # echo $* | ${SENDMAIL} ${RCPT_TO}
  echo $*
  exit 7
}

notify() {
  echo $* 2>&1
}

backup_module() {
  MODULE_DIR=$1
  LOG_SOURCE_DIR=$2

  if [[ ! -d ${APPROOT_DIR}/${MODULE_DIR}/${LOG_SOURCE_DIR} ]]; then
    echo "module $1 not found - bypassed"
    return 1
  fi

  logdir=${APPROOT_DIR}/${MODULE_DIR}/${LOG_SOURCE_DIR}
  backup_dir=${APPROOT_DIR}/${MODULE_DIR}/~inprocess
  taped_dir=${APPROOT_DIR}/${MODULE_DIR}/~taped
  notsaved_dir=${APPROOT_DIR}/${MODULE_DIR}/~notsaved

  notify "processing ${logdir}..."
  # make sure log backup directory exists
  mkdir -p ${backup_dir} ${taped_dir} ${notsaved_dir} || notify "Error creating aux directory: ${backup_dir} ${taped_dir} ${notsaved_dir}"

  ## find ${logdir} -regex ".*\.\(log\|zip\)" -type f -mtime +1 -exec mv -nv {} ${backup_dir}/ \; -print >>${NOTIFYMSG} 2>&1
  find ${logdir} ! -name 'catalina.out' ! -name 'catalina.out' ! -name 'catalina.out' -type f -mmin +5 -exec mv -nv {}
  ${backup_dir}/ \;
  -print 2>&1

  files2bkp=$(find ${backup_dir} -type f -print0 | xargs -0)
  if [[ 0 == ${#files2bkp} ]]; then
    notify "[${MODULE_DIR}] No appropriate files in ${logdir} found."
    return
  fi
  set -x
  ${BPBACKUP} -p ${BKPPOLICY} -s ${BKPPLANNER} -w ${files2bkp} 2>&1
  rc=$?
  set +x
  if [[ 0 != ${rc} ]]; then
    notify "Backup ${MODULE_DIR} failed with ${rc}."
    mv -nv ${backup_dir}/* ${notsaved_dir}/ 2>&1
  else
    notify "Backup ${MODULE_DIR} succeeded with ${rc}."
    mv -nv ${backup_dir}/* ${taped_dir}/ 2>&1
    ## or move links only
    # find ${backup_dir} -xtype l | xargs rm -f {}
  fi
}

move_unprocessed() {
  for module in "${MODULES[@]}"; do
    notify "test unprocessed files in ${module}"
    mv -nv ${APPROOT_DIR}/${module}/~inprocess/* ${APPROOT_DIR}/${module}/logs/ 2>&1
  done
}

onexit() {
  #	${SENDMAILCMD}
  # remove all outdated logs, older than 2 weeks
  move_unprocessed
  if [ -z ${testmode} ]; then
    find ${APPROOT_DIR} -path '*/~taped/*' -type f -mtime +14 -print0 | xargs -0 rm -fv
  else
    find ${APPROOT_DIR} -path '*/~taped/*' -type f -mtime +14 -print0 | xargs -0 echo "to delete:::"
  fi
}

#main
trap onexit INT TERM

if [ -z ${testmode} ]; then
  if [[ ! -x ${BPBACKUP} ]]; then
    notify "FATAL! Executable ${BPBACKUP} not found"
    exit 1
  fi
else
  notify "===test mode==="
  if [[ ! -x ${BPBACKUP} ]]; then notify "WARNING! Executable ${BPBACKUP} not found"; fi
  if [[ ! -x ${LOGROTATE} ]]; then notify "WARNING! Executable ${LOGROTATE} not found"; fi
  BPBACKUP="echo ${BPBACKUP}"
  LOGROTATE="echo ${LOGROTATE}"
fi

# test whether system logrotate has been performed
# or uncomment forced call below
# logrotate -vf ${BASEDIR}/rotate-tomcat.conf -s ${BASEDIR}/logrotate.status 2>&1

for module in "${MODULES[@]}"; do
  backup_module ${module} "logs"
done
notify "End of ${PROGNAME}"
onexit
