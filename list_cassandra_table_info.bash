#!/usr/bin/env bash

output_file="cassandra_table_info.txt"
rm -rf $output_file
echo "Sending output to ${output_file}"
ip_addresses=$(cat cassandra_hosts)

keyspace="backup"
table_list="vcards calls photos"

for host_ip in ${ip_addresses}
do
  echo $host_ip | tee -a $output_file
  for table in $table_list
  do
    cmd="ssh ${host_ip} nodetool cfstats -- ${keyspace}.${table}"
    echo ${cmd}
    ${cmd} | tee -a $output_file
  done
done

