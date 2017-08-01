#!/usr/bin/env ruby

require 'date'
require 'net/http'
require 'json'
#
# List all the JIRA issues in a project for a given component

JIRA_PROJECT="CSRV"
JIRA_COMPONENT="Backup"
JIRA_AUTH=ENV['JIRA_AUTH'] || "unknown"

OUTPUT_SEPARATOR='|'



def get_issues(start_at = 0, max_results = 50) 
  
  curl_cmd = "curl -X GET -H \"Authorization: Basic #{JIRA_AUTH}\" -H \"Content-Type: application/json\"   \"https://jira.corp.lookout.com/rest/api/2/search?jql=project%20%3D%20#{JIRA_PROJECT}%20AND%20status%20in%20(Open%2C%20%22In%20Progress%22%2C%20Reopened%2C%20Blocked%2C%20%22In%20Review%22)%20AND%20component%20%3D%20#{JIRA_COMPONENT}&startAt=#{start_at}&maxResults=#{max_results}\""

  #puts curl_cmd
  
  raw_out = `#{curl_cmd} 2>/dev/null`

  json_out = JSON.parse(raw_out)

  issues = json_out['issues']

  keep_going = true
  how_many = issues.length
  if how_many < max_results
    keep_going = false
  end
  
  issues.each do |issue|
    key = issue['key']
    summary = issue['fields']['summary']
    url = issue['self']
    puts "#{key}#{OUTPUT_SEPARATOR}#{summary}#{OUTPUT_SEPARATOR}#{url}"
  end

  start_at = start_at.to_i + max_results
  return start_at, keep_going, how_many
end

start_at = 0
max_results = 50
keep_going = true
how_many = 0
grand_total = 0 

until ! keep_going
  #puts "calling get_issues start_at #{start_at} max_results #{max_results} how_many #{how_many}"
  start_at, keep_going, how_many = get_issues(start_at, max_results)
  grand_total += how_many
end

#puts "grand total #{grand_total}"




