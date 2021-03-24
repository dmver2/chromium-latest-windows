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
# su tcadm logrotate -dvf /etc/logrotate.d/tomcat -s /home/tcadm/logbackup/logrotate.status
# *	real operational run:
# su tcadm logrotate -vf /etc/logrotate.d/tomcat -s /home/tcadm/logbackup/logrotate.status
# truncated file expected as a result: /u00/tomcat/logs/catalina.YYYY-MM-DD.log.gz
##
# source $HOME/.bashrc expected, but no $HOME available in a process spawned from cron usually.
# setup PATH, ENV manually
export PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin

proc_mode=batch

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
  -discrete)
    proc_mode=discrete
    ;;
  esac
done

export BKPPOLICY

PROGNAME=$(basename $0)
BASEDIR=$(dirname $0)
### delete processed logs older than $EXPIRY_DAYS days, i.e. modification time < $(date) - ${EXPIRY_DAYS}
EXPIRY_DAYS=30
### LOG_MMIN -- backup only logs, modified earlier than 60 min ago
### to filter-out files, which might be in-use by backend services at the moment.
### bypass fresher files, backup them in the next run, later.
LOG_MMIN=60
PROCIMG=java

export BKPPLANNER=full_logs_daily

RCPT_TO=will.jiang@vtb.com

#NOTIFYMSG=${BASEDIR}/${PROGNAME/\.*/}-$(date -I).msg
declare -a LOGDIRS=(
  "/u00/mca/logs"
  "/u00/mca/startlogs"
  "/u00/mcm/logs"
  "/u00/mcm/startlogs"
  "/u00/router/logs"
  "/u00/router/startlogs"
  "/u00/tomcat/logs"
)

###
#filter=$(printf "! -name %s " $(cat ${skiplist}))

export FILTER="! -name catalina.out \
 ! -name eweb.*-CronJob.log \
 ! -name router.DF*-Cronjob-Thread.log \
 ! -name router.DF*-Recevie-Thread.log \
 ! -name router.DF*-Receive-Thread.log"

export BPBACKUP=/usr/openv/netbackup/bin/bpbackup
LOGROTATE=/usr/sbin/logrotate

if [ -z ${testmode} ]; then
  SENDMAIL=echo$()
  SENDMAILCMD=
  # SENDMAIL="/usr/sbin/sendmail"
  # SENDMAILCMD="${SENDMAIL} ${RCPT_TO} < ${NOTIFYMSG}"
else
  SENDMAIL=echo
fi

die() {
  # echo $* | ${SENDMAIL} ${RCPT_TO}
  echo "   _____  .__  .__                   __                          __    __   "
  echo "  /  _  \ |  | |  |   ____   ______ |  | _______  ______  __ ___/  |_ /  |_ "
  echo " /  /_\  \|  | |  | _/ __ \ /  ___/ |  |/ /\__  \ \____ \|  |  \   __\\   __\\"
  echo "/    |    \  |_|  |_\  ___/ \___ \  |    <  / __ \|  |_> >  |  /|  |  |  |  "
  echo "\____|__  /____/____/\___  >____  > |__|_ \(____  /   __/|____/ |__|  |__|  "
  echo "        \/               \/     \/       \/     \/|__|                      "
  echo ""

  echo $*
  exit 7
}

notify() {
  echo $* 2>&1
}

move_files() {
  from=${1}
  to=${2}
  find ${from}/ -type f -print0 | xargs -r0 mv -nv -t "${to}/" 2>&1
  return $?
}

drain_unprocessed() {
  #  set -x
  if [[ -d "${1}" ]]; then
    move_files "${1}" "${2}" && rmdir ${1}
  fi
  #  set +x
}

fixauxdir() {
  module_path=$(dirname ${1})
  echo "fixing ${module_path}..."
  localdir=$(basename ${1})

  export new_taped_dir=${module_path}/~${localdir}-taped
  # make sure log old directories exists
  mkdir -p ${new_taped_dir} || notify "Error creating aux directory: ${new_taped_dir}"
  drain_unprocessed "${module_path}/~taped" "${new_taped_dir}"
  drain_unprocessed "${module_path}/~inprocess" "${1}"
  drain_unprocessed "${module_path}/~notsaved" "${1}"
}

backup_logs() {
  log_dir=${1}

  if [[ ! -d ${log_dir} ]]; then
    echo "module logs [$1] not found - bypassed"
    return 1
  fi

  notify "processing ${log_dir}..."
  fixauxdir ${log_dir}
  taped_dir=${new_taped_dir}

  module=$(dirname "${log_dir}")
  ### files in use by java
  ofl=$(ps -eoppid,pid,cmd | awk -v module="${module}" -v img="${PROCIMG}" \
    'BEGIN{split("", x, ",");} $3 ~ img {cmdls="ls -l /proc/"$2"/fd/"; while \
  ((cmdls | getline line) > 0) {split(line, a, "->"); output=a[2]; if(!x[output] \
  && output ~ module) {x[output]=1;print output; }}; status=close(cmdls);}' 2>/dev/null)

#  ofl=$(ps -efl | awk -v module="${module}" -v img="vim" \
#    'BEGIN{split("", x, ",");} $6 ~ img {cmdls="ls -l /proc/"$2"/fd/"; while \
#  ((cmdls | getline line) > 0) {split(line, a, "->"); output=a[2]; if(!x[output] && output ~ \
#  module) {x[output]=1;print output; }}; status=close(cmdls);}' 2>/dev/null)

  export ofl
  echo -e "OPENED:[${ofl}]\n"

  ## find ${log_dir} -regex ".*\.\(log\|zip\)" -type f -mtime +1 -exec mv -nv {} ${backup_dir}/ \; -print >>${NOTIFYMSG} 2>&1
  # find ${log_dir} ! -name 'catalina.out' -type f -mmin +${LOG_MMIN} -exec mv -nv {}
  # ${backup_dir}/ \; -print 2>&1

  case ${proc_mode} in
  batch)
    IFS=$'\n' read -r -d '' -a range < <(find ${log_dir}/ -type f -mmin +${LOG_MMIN} ${FILTER} 2>/dev/null)
    if (("${#range[@]}" > 0)); then
      filtered=() # filter out opened files
      for f in "${range[@]}"; do
        if [[ ! $(echo "${ofl}" | grep -Fw "${f}") ]]; then
          filtered+=("${f}")
        else
          notify "in ise, skipped: ${f}"
        fi
      done

      notify "backup ${filtered[@]}"
      ${BPBACKUP} -p ${BKPPOLICY} -s ${BKPPLANNER} -w "${filtered[@]}" &&
        if [ -z ${testmode} ]; then mv -nv "${filtered[@]}" -t ${taped_dir}/ 2>&1; fi
      unset filtered
    fi
    ;;
  *)
    #	Discrete mode
    export log_dir
    export taped_dir
    export testmode

    find ${log_dir}/ -type f -mmin +${LOG_MMIN} ${FILTER} -exec sh -c '
			for f do
        if [[ ! $(echo "${ofl}" | grep -Fw "${f}") ]]; then
				  printf "backup [%s]\n" "${f}"
				  ${BPBACKUP} -p ${BKPPOLICY} -s ${BKPPLANNER} -w "${f}" 2>&1	&& if [ -z ${testmode} ];	then mv -nv "${f}" ${taped_dir}/ 2>&1; fi
        else
          echo "in ise, skipped: ${f}"
				fi
			done
		' exec-sh {} +
    ;;
  esac
  unset ofl
}

onexit() {
  #	${SENDMAILCMD}
  # remove all outdated logs, older than 2 weeks

  if [ -z ${testmode} ]; then
    for logdir in "${LOGDIRS[@]}"; do
      taped=$(dirname ${logdir})/~$(basename ${logdir})-taped
      find "${taped}/" -type f -mtime +${EXPIRY_DAYS} -print0 | xargs -r0 rm -fv 2>&1
    done
  else
    for logdir in "${LOGDIRS[@]}"; do
      taped=$(dirname ${logdir})/~$(basename ${logdir})-taped
      find "${taped}/" -type f -mtime +${EXPIRY_DAYS} -print0 | xargs -r0 echo "to delete:::"
    done
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
  export BPBACKUP="echo ${BPBACKUP}"
#  export LOGROTATE="echo ${LOGROTATE}"
fi

# test whether system logrotate has been performed
# or uncomment forced call below
# logrotate -v -f ${BASEDIR}/rotate-tomcat.conf -s ${BASEDIR}/logrotate.status 2>&1
# unset testmode ### only for surefire test run
for logrule in "${LOGDIRS[@]}"; do
  backup_logs "${logrule}"
done
notify "End of ${PROGNAME}"
onexit
