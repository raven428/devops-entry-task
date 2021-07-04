#
# $Id: .bash_profile,v 1.13 2020/10/12 02:34:12 raven Exp $
#

# load defaults
test -f /etc/bashrc && source /etc/bashrc

scrrr() {
 if [[
  -n "${SSH_AUTH_SOCK}" &&
  -e "${SSH_AUTH_SOCK}"
 ]]; then
  SSH_AUTH_SOCK_REAL="$(readlink -f ${SSH_AUTH_SOCK})"
  if [[ -S "${SSH_AUTH_SOCK_REAL}" ]]; then
   SSH_AUTH_SOCK_NEW="${HOME}/.ssh/authsock-${HOSTNAME%%.*}"
   /bin/rm -f "${SSH_AUTH_SOCK_NEW}"
   /bin/ln -sf "${SSH_AUTH_SOCK_REAL}" "${SSH_AUTH_SOCK_NEW}"
   export SSH_AUTH_SOCK="${SSH_AUTH_SOCK_NEW}"
  fi
 fi
 case $OSTYPE in
  *linux*)
   screen=/usr/bin/screen
  ;;
  *bsd*)
   screen=/usr/local/bin/screen
  ;;
 esac
 $screen -wipe
 $screen -D -RR
# if [[ 
#  ! -z "${SSH_AUTH_SOCK_REAL}" &&
#  ! -e "${SSH_AUTH_SOCK_REAL}"
# ]]; then
#  /bin/rm -rvf "$(dirname ${SSH_AUTH_SOCK_REAL})" 2>/dev/null
# fi
 exit
}

# disable history purging
export HISTSIZE=
export HISTFILESIZE=
# append to the history file, don't overwrite it
shopt -s histappend
# modifications of PROMPT_COMMAND:
[[ -z "${PROMPT_COMMAND}" ]] && PROMPT_COMMAND='true'
# write and read new history after each command
PROMPT_COMMAND+='; history -a'

# forcing ssh-dss keys support
ssh -Q key >/dev/null 2>&1
res=$?
mkdir -vp ~/.ssh
ssh_dir=${HOME}/.ssh
rm -f ${ssh_dir}/config
if [[ "x$res" = "x0" ]]; then
 ln -s ${ssh_dir}/config-new ${ssh_dir}/config
else
 ln -s ${ssh_dir}/config-old ${ssh_dir}/config
fi

# load local
test -f ~/.bash_profile_local && source ~/.bash_profile_local
