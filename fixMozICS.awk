BEGIN 	{

			# Set input for DOS line termination
			RS = "\r\n"
			
			# Set output for DOS line termination !!
			ORS = "\r\n"

			firstline = 1
			summary = 0
		}
		
(firstline == 1) {
			print $0
			firstline = 0
			next
		}
		
/DTSTART/	{
				print("DTSTART;TZID=US/Eastern")
				next
			}
			
/SUMMARY/ 	{
				print "SUMMARY"
				summary = 1
				next
			}
( summary == 1 ) {
				summary = 0
				strippedline = stripDOSEOL($0)
				#print "printing stripped summary line +" strippedline "+"
				sub(/\:/,":Maddy ", strippedline)
				print strippedline
				next
		}
		
		{
			
			print stripDOSEOL($0)
			next
		}
		

function stripDOSEOL(line) {
	return substr(line, 2, length(line) - 1)
}