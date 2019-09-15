#!/usr/bin/env bash

if [[ -z "$1" ]]; then
  while true
  do
    read -p "Enter user name: " user_name
    if [[ -n "$user_name" ]]; then
      break
    fi
  done
else
  user_name="$1"
fi

shift

if [[ -z "$1" ]]; then
  while true
  do
    read -p "Enter MFA token for $user_name " mfa_token
    if [[ -n "$mfa_token" ]]; then
      break
    fi
  done
else
  mfa_token="$1"
fi

temporary_credentials=$(aws sts get-session-token --serial-number arn:aws:iam::097064421904:mfa/$user_name --token-code $mfa_token | jq -r '.Credentials')
export AWS_ACCESS_KEY_ID=$(echo $temporary_credentials | jq -r '.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $temporary_credentials | jq -r '.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $temporary_credentials | jq -r '.SessionToken')
export AWS_SESSION_TOKEN_EXPIRATION=$(echo $temporary_credentials | jq -r '.Expiration')

bash_bin=$(which bash)
exec $bash_bin
