
ARGV.each do |arg|
  if arg =~ /gif/ or arg =~ /jpeg/ or arg =~ /jpg/ or arg =~ /\.svn/ or arg =~ /png/ or arg =~ /swf/ or arg =~ /gif/ or arg =~ /eps/ or arg =~ /pstore/
      #puts "SKIP: File #{arg}"
    next
  end
  results = `perl /Users/erocha/bin/find_bad_terminators.pl <#{arg}`.strip.chomp
  if results == ''
    #puts "OK: File #{arg}"
  else
    puts "BAD: File #{arg} has bad terminators"
    # results.split("\n").each do |line|
    #   puts line
    # end
  end
end
