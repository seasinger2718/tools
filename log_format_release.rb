#!/usr/bin/env ruby

require 'date'
require 'net/http'
require 'json'

DEBUG=false

OUTPUT_SEPERATOR="\t"

MAX_DESCRIPTION_LENGTH=80

GIT_BASE_LOG_CMD='git log  --format=medium'

def usage
  puts "Usage: log_format_release [-b <starting branch> <ending branch>] [-c <starting commit> <ending commit>]"
end

JIRA_AUTH=ENV['JIRA_AUTH'] || "unknown"

#puts "#{ARGV}"
branch_specs = nil
if ARGV.size == 0
  branch_specs = nil
elsif ARGV.size == 3
  if ARGV[0] == '-b'
    branch_specs = "origin/#{ARGV[1]}..origin/#{ARGV[2]}"
  elsif ARGV[0] == '-c'
    branch_specs = "#{ARGV[1]}..#{ARGV[2]}"
  else
    usage
    exit 1
  end
else  
  usage
  exit 1
end

def format_log_entry(log_entry)
  puts "format_log_entry #{log_entry}" if DEBUG
  if log_entry[:error]
    "#{log_entry[:jira_number]}#{OUTPUT_SEPERATOR}Unknown#{OUTPUT_SEPERATOR}Unknown#{OUTPUT_SEPERATOR}Unknown#{OUTPUT_SEPERATOR}#{log_entry[:author]}#{OUTPUT_SEPERATOR}Unknown#{OUTPUT_SEPERATOR}#{log_entry[:short_sha]}#{OUTPUT_SEPERATOR}Error processing this JIRA. Maybe it was deleted?"
    #"#{log_entry[:jira_number]}#{OUTPUT_SEPERATOR}#{log_entry[:author]}#{OUTPUT_SEPERATOR}#{log_entry[:short_sha]}#{OUTPUT_SEPERATOR}Error processing this JIRA. Maybe it was deleted?"
  else
  #"#{log_entry[:short_sha]}#{OUTPUT_SEPERATOR}#{log_entry[:jira_number]}#{OUTPUT_SEPERATOR} #{log_entry[:first_line]}#{OUTPUT_SEPERATOR}#{log_entry[:author]}#{OUTPUT_SEPERATOR}#{log_entry[:date]}"
    "#{log_entry[:jira_number]}#{OUTPUT_SEPERATOR}#{log_entry[:status]}#{OUTPUT_SEPERATOR}#{log_entry[:priority]}#{OUTPUT_SEPERATOR}#{log_entry[:summary]}#{OUTPUT_SEPERATOR}#{log_entry[:reporter]}#{OUTPUT_SEPERATOR}#{log_entry[:assignee]}#{OUTPUT_SEPERATOR}#{log_entry[:short_sha]}"
  end
end

def get_JIRA_info(jira_ticket_number, git_sha = nil)
  begin
    curl_cmd = "curl -X GET -H \"Authorization: Basic #{JIRA_AUTH}\" -H \"Content-Type: application/json\" \"https://jira.corp.lookout.com/rest/api/latest/issue/#{jira_ticket_number.gsub(/:/,'-')}\""
    #puts curl_cmd if DEBUG
    json_out = `#{curl_cmd} 2>/dev/null`
    if json_out =~ /Unauthorized/
      raise "Unauthorized"
    end
    #puts json_out if DEBUG
    json = JSON.parse(json_out)
    #puts json if DEBUG
    if json.has_key?('errorMessages') 
      if json['errorMessages'].size > 0
        STDERR.puts json_out if DEBUG
        raise "errors found during parsing"
      end
    end
    if json.has_key?('errors') 
      if json['errors'].size > 0
        STDERR.puts json_out if DEBUG
        raise "errors found during parsing"
      end
    end
    return json
  rescue Exception => e 
    puts "Exception \"#{e}\"" if DEBUG
    STDERR.puts "ERROR: Unable to process JIRA: #{jira_ticket_number} from commit #{git_sha || ''} " if DEBUG
    return nil
  end
  
end

def get_JIRA_entry(jira_ticket_number, git_sha = nil)
  thingy = get_JIRA_info(jira_ticket_number, git_sha)
  if thingy
    puts JSON.pretty_generate(thingy) if DEBUG
    summary = thingy['fields']['summary']
    status = thingy["fields"]['status']['name']
    priority = thingy['fields']['priority']['name']
    assignee = thingy['fields']['assignee']['displayName']
    reporter = thingy['fields']['reporter']['displayName']
  
    #puts "summary: \"#{summary}\" status: #{status} priority: #{priority} assignee: #{assignee} reporter: #{reporter}"
    return summary, status, priority, assignee, reporter
  else
    return nil, nil, nil, nil, nil
  end
end

def parse_JIRA_line(line)
  line.sub(/^JIRA:/,'').strip.chomp.split(' ')
end
  
def generate_JIRA_entry(jira)
  jira_number = jira.strip.chomp
  log_entry = {}
  log_entry[:jira_number] = jira_number
  summary, status, priority, assignee, reporter = get_JIRA_entry(jira_number, log_entry[:short_sha])
  if summary
    log_entry[:summary] = summary
    log_entry[:status] = status
    log_entry[:priority] = priority
    log_entry[:assignee] = assignee
    log_entry[:reporter] = reporter
    log_entry[:error] = false
  else
    log_entry[:error] = true
  end
  log_entry
end

git_log_cmd = "#{GIT_BASE_LOG_CMD} #{branch_specs.nil? ? '' : branch_specs}"
puts git_log_cmd if DEBUG

raw_log=`#{git_log_cmd}`

log_entry = {}
raw_log.split("\n").each do |log_line|
  puts "x #{log_line}" if DEBUG
  log_line = log_line.strip.chomp
  next if log_line == ""
  if log_line =~ /^commit/
    if log_entry.size != 0 
      # Dump and reset
      #puts "Dumping log entry \n#{log_entry}"
      puts format_log_entry(log_entry)
      log_entry = {}
    end
    short_sha = log_line.split(' ')[1].strip.chomp[0...7]
    log_entry[:short_sha] = short_sha
    next
  end
  if log_line =~ /^Author/
    full_author = log_line.sub(/^Author:/,'').strip.chomp
    email_start = full_author.index('<')
    author = full_author[0...email_start].strip.chomp
    log_entry[:author] = author
    next
  end
  if log_line =~ /^Date/
    full_date_string = log_line.sub(/^Date:/,'').strip.chomp
    #Tue Mar 1 15:59:04 2016 -0500
    full_date = DateTime.parse(full_date_string)
    date_string = full_date.strftime(format='%Y-%m-%d')
    log_entry[:date] = date_string
    next
  end
  if log_line =~ /^JIRA/
    # Deal with multiple JIRA entries on same line
    jira_numbers = parse_JIRA_line(log_line)
    puts "jira_numbers #{jira_numbers}" if DEBUG
    *rest, last = jira_numbers
    rest.each do |jira_number|
      partial_log_entry = generate_JIRA_entry(jira_number)
      current_log_entry = log_entry.merge(partial_log_entry)
      puts format_log_entry(current_log_entry)
    end

    # Let the last entry drop through as in regular processing
    partial_log_entry = generate_JIRA_entry(last)
    log_entry = log_entry.merge(partial_log_entry)

    next
  end
  unless log_entry.has_key?(:first_line)
    log_entry[:first_line] = log_line.gsub(/\t/,' ').strip.chomp[0..MAX_DESCRIPTION_LENGTH]
  end
end

# Remember to dump the last one
puts format_log_entry(log_entry)
