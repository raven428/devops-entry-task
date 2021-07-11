#!/usr/bin/env bash
#
# infra collectors poller
# managed by Ansible
#
set -uo pipefail
exit_flag=0
clean_temp() {
  trap - HUP INT QUIT ABRT KILL TERM STOP EXIT
  rm -fv ${tmp_pfx}* | while read filename; do
    echo "[${filename}] by clean_temp"
  done
  exit_flag=1
}
cleanup() {
  clean_temp
}
trap cleanup HUP INT QUIT ABRT KILL TERM STOP EXIT
tmp_pfx="/var/tmp/infra-collectors-$$-"
tmp_file=$(mktemp ${tmp_pfx}XXXXX)
my_bin="$(readlink -f $0)"
my_dir="$(dirname ${my_bin})"
poller_interval='30'
poller_dir='poller.d'
textfile_dir='/var/lib/node_exporter'
for d in /etc/node_exporter "${my_dir}" .; do
  for confname in poller-conf.sh poller-priv.sh; do
    if [[ -e "${d}/${confname}" ]]; then
      source "${d}/${confname}" &&
        echo config [${d}/${confname}] sourced
    fi
  done
done
echo 'entering endless loop… '
iter=0
while [[ 1 ]]; do
  iter=$((${iter} + 1))
  iter_begin=$(/usr/bin/env date +%s)
  echo "begin [${iter}] iteration"
  for d in "/etc/node_exporter/${poller_dir}" \
    "${my_dir}/${poller_dir}" "./${poller_dir}"; do
    # FIXME: replace loops bellow by GNU parallel
    for f in $(/usr/bin/env ls ${d} 2>/dev/null | /usr/bin/env sort -V); do
      fp="${d}/${f}"
      id=$(echo ${fp} | /usr/bin/env sed -r s/[^a-z0-9]/_/Ig)
      epoch=$(/usr/bin/env date +%s)
      next_cv="${id}_next_call"
      set +u
      if [[ x"${!next_cv}" != x ]]; then
        if [[ ${!next_cv} -gt ${epoch} ]]; then
          echo "skipping [${fp}] for [${!next_cv}] of [${epoch}] epoch"
          continue
        fi
      fi
      set -u
      min_call_period=0
      if [[ -x "${fp}" ]]; then
        echo -n "calling [${fp}]… "
        ${fp} | /usr/bin/env sponge "${textfile_dir}/${id}.prom"
        echo 'done!'
      else
        echo -n "sourcing [${fp}]… "
        source "${fp}"
        echo -n 'calling infra_poller… '
        infra_poller | /usr/bin/env sponge "${textfile_dir}/${id}.prom"
        echo 'called!'
      fi
      if [[ ${min_call_period} -gt 0 ]]; then
        epoch=$(/usr/bin/env date +%s)
        next_call=$((${epoch} + ${min_call_period}))
        eval "${id}_next_call=\${next_call}"
      fi
    done
  done
  iter_end=$(/usr/bin/env date +%s)
  time2sleep=$((${poller_interval} + ${iter_begin} - ${iter_end}))
  if [[ ${time2sleep} -lt 1 ]]; then
    time2sleep=1
  fi
  if [[ x"${exit_flag}" != x"0" ]]; then
    echo 'exit requested, bye-bye'
    break
  fi
  echo -n "sleeping [${time2sleep}] seconds… "
  sleep ${time2sleep}
  echo 'slept!'
done
rm -vf "${tmp_file}"
clean_temp
