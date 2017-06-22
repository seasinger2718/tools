#!/usr/bin/env bash

# Run many ssh tasks in parallel

# elb_ip_addr "backup-vpc"
IP_LIST="10.96.6.236 10.96.5.119 10.96.5.6 10.96.5.213 10.96.6.109 10.96.6.181 10.96.5.60 10.96.5.61 10.96.6.61 10.96.6.62 10.96.6.135 10.96.6.161 10.96.6.162 10.96.6.59"

total_ips=$(echo "${IP_LIST}" | awk '{print NF}' | head -1)

output_dir="/tmp/logs"
mkdir -p "${output_dir}"
output_file="${output_dir}/many.out"
rm -rf $output_file

single_command() {
  echo "$(date) Starting to process ${1}:/var/log/backup/service_access.log" >> $output_file
  scp -q -C -o CompressionLevel=9 ${1}:/var/log/backup/service_access.log /tmp/backup_logs/${1}.service_access.log 2>&1 >> $output_file
  scp -q -C -o CompressionLevel=9 ${1}:/var/log/backup/service_app.log /tmp/backup_logs/${1}.service_app.log 2>&1 >> $output_file
  echo "$(date) Finished processing ${1}:/var/log/backup/service_access.log" >> $output_file
}

pids=""
for ip in $IP_LIST
do
  single_command  ${ip} &
  pid="$!"
  pids="${pids} $pid"
done

wait $pids
