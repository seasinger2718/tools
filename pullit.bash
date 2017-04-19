#!/usr/bin/env bash

git_active_branch
active_branch=${RET_VAL}
git pull origin ${active_branch}

