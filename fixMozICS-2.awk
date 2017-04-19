BEGIN 	{

			# Set input for DOS line termination
			RS = "\r\n"
			
			# Set output for DOS line termination !!
			ORS = "\r\n"

			firstline = 1
			summary = 0
			# Set default timezone to US/Eastern
			TZID = "US/Eastern"
		}

# Fix DOS line termination problems

(firstline != 1) {
			$0 = stripDOSEOL($0)
			}

(firstline == 1) {
			firstline = 0
		}

/SUMMARY/ 	{
				print "SUMMARY"
				summary = 1
				next
			}

( summary == 1 ) {
				summary = 0
				sub(/\:/,":" tag " ", $0)
			}		

/DTSTART/	{	# Patch timezone if needed
				if ( index($0,"TZID") == 0 ) {
					sub(/DTSTART/,"DTSTART" ";TZID=" TZID,$0)
				}
			}

						
		{
			print $0
		}
		

function stripDOSEOL(line) {
	return substr(line, 2, length(line) - 1)
}