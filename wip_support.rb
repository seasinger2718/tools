# For git - find anything significant that's changed in the working copy and is not checked in.

class WIP

  WIP_SETTINGS = {:work => { 
                              :ssh => 'tflynn@10.1.10.52', 
                              :work_directory_base => '/Users/tflynn/Everything/ActivitiesHelium', 
                              :personal_directory_base => '/Users/tflynn/Everything/Activities'
                            },
                  :home => {
                              :ssh => 'tracy@tracy.dynalias.net', 
                              :work_directory_base => '/Users/tracy/Everything/ActivitiesHelium', 
                              :personal_directory_base => '/Users/tracy/Everything/Activities'
                            }
                  }
  
  def list_modified_and_untracked
    status_output = `git status`.strip.chomp
    return process_modified_and_untracked(status_output)
  end

  def remote_list_modified_and_untracked
    check_branches
    codebase = get_codebase
    local_settings, remote_settings = get_settings
    local_base_directory, remote_base_directory = get_base_directories
    unless local_base_directory and remote_base_directory
      return nil
    end
    ssh_cmd = %{ssh #{remote_settings[:ssh]} "cd #{remote_base_directory}/#{codebase}; git status"}
    status_output = `#{ssh_cmd}`.strip.chomp    
    return process_modified_and_untracked(status_output)
  end

  def process_modified_and_untracked(status_output)
    
    #puts status_output
    modified = []
    untracked = []
    
    status_lines = status_output.split("\n")
    changes_active = false
    untracked_active = false
    skip = 0
    status_lines.each do |status_line|
      status_line = status_line.strip.chomp
      if skip > 0
        skip -= 1
        next
      end
      if status_line =~ /Changed but not updated/
        changes_active = true
        skip = 2
        next
      end
      if status_line =~ /Untracked files/
        changes_active = false
        untracked_active = true
        skip = 2
        next
      end
      if status_line !~ /^\#/
        changes_active = false
        untracked_active = false
        break
      end
      if changes_active
        if status_line =~ /modified/
          file_name = status_line.gsub(/^.*modified\:/,'').strip.chomp
          #puts "Changed: #{file_name}"
          modified << file_name
        end
      end
      if untracked_active
        file_name = status_line.gsub(/^\#/,'').strip.chomp
        #puts "Untracked: #{file_name}"
        untracked << file_name
      end
    end
    
    return [modified, untracked]
    
  end
  
  # Push from local to remote
  def push(options = {})
    options = {:dry_run => false}.merge(options)
    check_branches
    local_settings, remote_settings = get_settings
    codebase = get_codebase
    modified, untracked = list_modified_and_untracked
    files_to_push = modified + untracked
    local_base_directory, remote_base_directory = get_base_directories
    unless local_base_directory and remote_base_directory
      return :error
    end
    files_to_push.each do |file_to_push|
      scp_source = "#{local_base_directory}/#{codebase}/#{file_to_push}"
      scp_destination = "#{remote_settings[:ssh]}:#{remote_base_directory}/#{codebase}/#{file_to_push}"
      scp_cmd = "scp #{scp_source} #{scp_destination}"
      puts file_to_push
      puts `#{scp_cmd}` unless options[:dry_run]
    end
  end
  
  # Pull from remote to local
  def pull(options = {})
    options = {:dry_run => false}.merge(options)
    check_branches
    local_settings, remote_settings = get_settings
    codebase = get_codebase
    modified, untracked = remote_list_modified_and_untracked
    files_to_pull = modified + untracked
    local_base_directory, remote_base_directory = get_base_directories
    unless local_base_directory and remote_base_directory
      return :error
    end
    files_to_pull.each do |file_to_pull|
      scp_source = "#{remote_settings[:ssh]}:#{remote_base_directory}/#{codebase}/#{file_to_pull}"
      scp_destination = "#{local_base_directory}/#{codebase}/#{file_to_pull}"
      scp_cmd = "scp #{scp_source} #{scp_destination}"
      puts file_to_pull
      puts `#{scp_cmd}` unless options[:dry_run]
    end
  end
  
  def get_locations
    local_location = `cat /etc/shortname`.strip.chomp.to_sym
    remote_location = local_location == :home ? :work : :home
    return local_location, remote_location
  end

  def get_settings
    local_location, remote_location = get_locations
    local_settings = WIP_SETTINGS[local_location]
    remote_settings = WIP_SETTINGS[remote_location]
    return local_settings, remote_settings
  end
  
  def get_activity_type
    current_dir = Dir.getwd 
    main_activity_dir = File.dirname(current_dir)
    local_location, remote_location = get_locations
    local_settings = WIP_SETTINGS[local_location] 
    if local_settings[:work_directory_base] == main_activity_dir
      return :work
    else
      return :personal
    end
  end
  
  def get_codebase
    current_dir = Dir.getwd
    codebase = File.basename(current_dir)
    return codebase
  end
  
  def get_base_directories
    local_settings, remote_settings = get_settings
    activity_type = get_activity_type
    if activity_type == :work
      local_base_directory = local_settings[:work_directory_base]
      remote_base_directory = remote_settings[:work_directory_base]
    elsif activity_type == :personal
      local_base_directory = local_settings[:personal_directory_base]
      remote_base_directory = remote_settings[:personal_directory_base]
    else
      return [nil,nil]
    end
    return [local_base_directory,remote_base_directory]
  end
  
  def check_branches
    local_branch = get_local_branch
    remote_branch = get_remote_branch
    unless local_branch == remote_branch
      puts "Woops - the same branches aren't active - local #{local_branch} remote #{remote_branch}"
      exit 1
    end
  end
  
  def get_active_branch_cmd
    return "git branch | grep '^\*' | sed -e 's/^\* //'"
  end
  
  def get_local_branch
    return `#{get_active_branch_cmd}`.chomp.strip
  end

  def get_remote_branch(options = {})
    codebase = get_codebase
    local_settings, remote_settings = get_settings
    local_base_directory, remote_base_directory = get_base_directories
    unless local_base_directory and remote_base_directory
      return nil
    end
    ssh_cmd = %{ssh #{remote_settings[:ssh]} "cd #{remote_base_directory}/#{codebase}; #{get_active_branch_cmd}"}
    remote_branch = `#{ssh_cmd}`.strip.chomp
    return remote_branch
  end
  
  def remote_branch
    return get_remote_branch
  end
  
  def remote_status
    check_branches
    codebase = get_codebase
    local_settings, remote_settings = get_settings
    local_base_directory, remote_base_directory = get_base_directories
    unless local_base_directory and remote_base_directory
      return ''
    end
    ssh_cmd = %{ssh #{remote_settings[:ssh]} "cd #{remote_base_directory}/#{codebase}; git status"}
    status_output = `#{ssh_cmd}`.strip.chomp    
    return status_output
  end
  
  def remote_pullit
    check_branches
    codebase = get_codebase
    local_settings, remote_settings = get_settings
    local_base_directory, remote_base_directory = get_base_directories
    unless local_base_directory and remote_base_directory
      return ''
    end
    ssh_cmd = %{ssh #{remote_settings[:ssh]} "cd #{remote_base_directory}/#{codebase}; pullit"}
    cmd_output = `#{ssh_cmd}`.strip.chomp    
    return cmd_output
  end
  
  def remote_pushit
    check_branches
    codebase = get_codebase
    local_settings, remote_settings = get_settings
    local_base_directory, remote_base_directory = get_base_directories
    unless local_base_directory and remote_base_directory
      return ''
    end
    ssh_cmd = %{ssh #{remote_settings[:ssh]} "cd #{remote_base_directory}/#{codebase}; pushit"}
    cmd_output = `#{ssh_cmd}`.strip.chomp    
    return cmd_output
  end
  
end