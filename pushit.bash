#!/usr/bin/env bash
source /etc/bashrc
echo "DEBUG    aliases "
alias

#echo "DEBUG  set"
#set

echo $PATH
git_active_branch
active_branch=${RET_VAL}
git push origin ${active_branch}
