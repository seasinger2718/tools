#!/usr/bin/ruby

#--
#  uninstall_pkg.rb
#
#  $Id: voter_aquery_controller.rb 35 2006-05-08 02:07:50Z tracy $
#++

require 'rdoc/usage'
require 'pp'
require 'fileutils'
require 'getoptlong'
require 'logger'

#--
# From ActiveSupport
# Extends the class object with class and instance accessors for class attributes,
# just like the native attr* accessors for instance attributes.
#++
class Class # :nodoc:
  def cattr_reader(*syms)
    syms.flatten.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__)
        unless defined? @@#{sym}
          @@#{sym} = nil
        end

        def self.#{sym}
          @@#{sym}
        end

        def #{sym}
          @@#{sym}
        end
      EOS
    end
  end

  def cattr_writer(*syms)
    syms.flatten.each do |sym|
      class_eval(<<-EOS, __FILE__, __LINE__)
        unless defined? @@#{sym}
          @@#{sym} = nil
        end

        def self.#{sym}=(obj)
          @@#{sym} = obj
        end

        def #{sym}=(obj)
          @@#{sym} = obj
        end
      EOS
    end
  end

  def cattr_accessor(*syms)
    cattr_reader(*syms)
    cattr_writer(*syms)
  end
end

class BomEntry

  attr_accessor :file_path, :file_size
  
  def initialize(bom_line)
    bom_fields = bom_line.split(' ')
    @file_path = bom_fields[0]
    @file_size = bom_fields[3]
  end
  
end

# == Synopsis
#
# UninstallPkg provides a tool to uninstall a Mac OS X package.
#
# == Usage
#
# === Command-line
#
#   ruby uninstall_pkg.rb [options] package_file_path
#
# === From within Ruby
#
#  All arguments can be passed via the ARGV array or by setting defaults (see below)
#
#  For example:
#  
#    require 'uninstall_pkg'
#    ARGV = [ '--bomfile' , '/Library/Receipts/pgsql-8.1.3.pkg/Contents/Archive.bom']
#    UninstallPkg.uninstall
#
#   Or:
#
#    require 'uninstall_pkg'
#    UninstallPkg.standard_package_bom_file_location = '/Library/Receipts/pgsql-8.1.3.pkg/Contents'
#    UninstallPkg.standard_package_bom_file = 'Archive.bom'
#    UninstallPkg.uninstall
#
# == Defaults
#
# === Command-line 
#
# Defaults can be changed on the command-line using GNU option syntax
#
# Available options are:
# 
#  --help | -h Help
#  --bomfile <name> | -b <name> - Absolute path of BOM file, './Contents/Archive.bom' by default
#  --absolute_path true|false | -a true|false - Interpret BOM entries as absolute paths, true by default
#  --logfile <path> | -l <path> - Log file name, '/tmp/uninstall_pkg.log' by default
#  --extended_search true|false | -s true|false - Use standard executable, library and include directories to match BOM entries, true by default
#
# === From within Ruby
#
# Defaults can be changed before using any methods using the syntax:
# 
#   UninstallPkg.<option_name> = <option_value>
# 
# Available defaults are:
#  UninstallPkg.standard_package_bom_file -  Name of BOM file, 'Archive.bom' by default
#  UninstallPkg.standard_package_bom_file_location - Location of BOM file, './Contents' by default
#  UninstallPkg.absolute_path - Interpret BOM entries as absolute paths, true by default
#  UninstallPkg.standard_logfile - Log file name, '/tmp/uninstall_pkg.log' by default
#  UninstallPkg.extended_search - Use standard executable, library and include directories to match BOM entries, true by default
#
# == Author
# Tracy Flynn, SmartOWL Consulting - tracy.flynn@smartowl.net
# 
# == Copyright
# Copyright (c) 2006 Tracy Flynn
#
# Licensed under the same terms as Ruby.
class UninstallPkg

  # Specify the standard name of the BOM file for an MAC OS X package
  cattr_accessor :standard_package_bom_file 
  @@standard_package_bom_file = 'Archive.bom'
  
  # Specify the standard package location for the BOM file
  cattr_accessor :standard_package_bom_file_location
  @@standard_package_bom_file_location = 'Contents'

  # Specify that the BOM entries are to be interpreted as absolute paths
  cattr_accessor :absolute_path
  @@absolute_path = true
  
  # Specify the log file name and location
  cattr_accessor :standard_logfile
  @@standard_logfile = "/tmp/uninstall_pkg.log"
  
  # Specify an extended search of the path, library and include directories
  cattr_accessor :extended_search
  @@extended_search = true
  
  # Specify set of executable directories to search
  cattr_accessor :executable_dirs
  @@executable_dirs = ENV['PATH'].split(':')
  
  # Specify set of library directories to search
  cattr_accessor :library_dirs
  @@library_dirs = %w(/usr/lib /usr/local/lib)
  
  # Specify set of include directories to search
  cattr_accesor :include_dirs
  @@include_dirs = %w(/usr/include /usr/local/include)
  
  # Create a new instance
  #
  # All arguments are passed via the command-line or the ARGV array
  #
  # <em>package_file_path</em> - Path to package file
  #
  # <em>options</em> - See RDOC documentation for available options
  #
  def initialize #:notnew:
    if ARGV.length == 0
      help
      exit 1
    end
    
    options = GetoptLong.new(
      [ "--bomfile", "-b", GetoptLong::REQUIRED_ARGUMENT],
      [ "--help", "-h", GetoptLong::NO_ARGUMENT],
      [ "--absolute_path", "-a", GetoptLong::NO_ARGUMENT],
      [ "--logfile", "-l", GetoptLong::REQUIRED_ARGUMENT],
      [ "--extended_search", "-s", GetoptLong::REQUIRED_ARGUMENT]
    )
    @command_line_options = {}
    options.each do |opt,value|
      @command_line_options[opt] = value
    end
    @package_file_path = ARGV.join(' ')
    
    # Set up default values
    @bom_file_name_rel = @command_line_options["--bomfile"] || "#{@@standard_package_bom_file_location}/#{@@standard_package_bom_file}"
    @bom_file_name_absolute = "#{@package_file_path}/#{@bom_file_name_rel}"
    @@absolute_path = @command_line_options["--absolute_path"] == "false" ? false : @@absolute_path

    @@logfile = @command_line_options["--logfile"] || "#{@@standard_logfile}"
    @logger = Logger.new(@@logfile)
    @logger.level = Logger::DEBUG
    @logger.datetime_format = "%H:%M:%S"
    @logger.info("UninstallPkg: initializing")

    @extended_search = @command_line_options['--extended_search'] == "false" ? false : @@extended_search
    
    @default_path = ENV['PATH'].split(':')
    
    #puts "@package_file_path #{@package_file_path}"
    #puts "@bom_file_name_rel #{@bom_file_name_rel}"
    #puts "@bom_file_name_absolute #{@bom_file_name_absolute}"
    
  end
  
  
  def UninstallPkg.uninstall
    package_uninstaller = UninstallPkg.new
    package_uninstaller.uninstall
    return package_uninstaller
  end
  
  def uninstall
    loadBomFile
  end
  
  private

  
  
  def loadBomFile
    bomFileContents = `lsbom #{@bom_file_name_absolute}`
    @bomfileEntries = []
    bomFileContents.each do |input_line| 
      bomEntry = BomEntry.new(input_line)
      if @@absolute_path
        bomEntry.file_path = bomEntry.file_path[1,bomEntry.file_path.length - 1]
      end
      @bomfileEntries << bomEntry
      #puts "#{bomEntry.file_path} #{bomEntry.file_size}"
    end
  end
  
  def help
    puts <<'HELP_TEXT'
Description:

UninstallPkg - Uninstall a Mac OS X package

Command Line: 

ruby uninstall_pkg.rb [options] package_file_path

Example:

ruby uninstall_pkg.rb /Library/Receipts/pgsql-8.1.3.pkg

Most of the time, just specify the package file name. The standard options should work.

There is RDOC documentation in the file. Please refer to it for further information.

Copyright: Tracy Flynn (c) 2006 - Licensed under the same terms as Ruby.
HELP_TEXT
  end
end

if $0 == __FILE__
  #ARGV = [ '--bomfile' , '/Library/Receipts/pgsql-8.1.3.pkg/Contents/Archive.bom']
  UninstallPkg.uninstall 
end

#uninstallPkg=$1

#if [ X$1 == X ]
#then
#	exit 1
#fi

#pkgFiles=`lsbom $uninstallPkg/Contents/Archive.bom | awk '{print substr($1,2)}'`
#for pkgFile in $pkgFiles
#do
#  unqualifiedPkgFile=`basename $pkgFile`
#  qualifiedPkgFile=`xwhereis $unqualifiedPkgFile`
#  locatedPkgFile=`xwhereis unqualifiedPkgFile`
#  
#  if [ grep ]
#  echo 'Processing: ' $pkgFile
#  if [ -f $pkgFile ]
#  then
#    echo 'About to delete file: ' $pkgFile
#  fi
#  if [ -d $pkgFile ]
#  then
#    echo 'Directory: ' $pkgFile
#  fi
#  
#done

#exit 0

