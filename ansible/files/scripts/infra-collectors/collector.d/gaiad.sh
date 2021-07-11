#!/usr/bin/env bash
#
# managed by Ansible
#
set -uo pipefail

metric_name='gaiad_latest_block_time'
/usr/bin/env cat <<EOF
# HELP ${metric_name} gaiad latest block time"
# TYPE ${metric_name} gauge
EOF
echo -n "${metric_name} "
latest_block_time=$(
  HOME='/root' /usr/bin/env gaiad status 2>&1 |
    /usr/bin/env jq -Mr '.SyncInfo.latest_block_time' 2>/dev/null
)
if [[ -n "${latest_block_time}" ]]; then
  /usr/bin/env date -d "${latest_block_time}" +"%s"
else
  echo 0
fi
