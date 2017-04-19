BEGIN 	{

			# Set input for Unix line termination
			RS = "\n"
			
			# Set output for DOS line termination
			ORS = "\r\n"

			# debug = 1 for debug output			
			debug = 0

			skip = 0

			alreadyprocessed = ""
			
			summarystart = 0
			descriptionstart = 0
			duestart = 0
			description = ""
			completed = 0
			
			print "BEGIN:VCALENDAR"
			print "VERSION:2.0"
			print "X-WR-CALNAME:TracyToDo"
			print "PRODID:-//Mozilla.org/NONSGML Mozilla Calendar V1.0//EN"
			#print "X-WR-RELCALID:CBD5EA26-874F-11D9-B1E0-000393CC5C5A"
			print "X-WR-TIMEZONE:US/Eastern"
			print "CALSCALE:GREGORIAN"
			print "BEGIN:VTIMEZONE"
			print "TZID:US/Eastern"
			print "LAST-MODIFIED:" MODIFYDATE "Z"
			print "BEGIN:STANDARD"
			print "DTSTART:20041031T060000"
			print "TZOFFSETTO:-0500"
			print "TZOFFSETFROM:+0000"
			print "TZNAME:EST"
			print "END:STANDARD"
			print "BEGIN:DAYLIGHT"
			print "DTSTART:20050403T010000"
			print "TZOFFSETTO:-0400"
			print "TZOFFSETFROM:-0500"
			print "TZNAME:EDT"
			print "END:DAYLIGHT"
			print "END:VTIMEZONE"
		}
		
		{
			debugmsg("Raw input line: +" $0 "+")

			if ($0 == "") {
				debugmsg("skipping blank line")
				next
			}
			
		}


/ITEMSTART/ {
			item_id = $2
			if (index(alreadyprocessed, item_id) != 0 ){
				# We've already seen this item, skip it
				#print "Have seen this item already " item_id " skipping ...  "
				skip = 1
				next
			}
			else {
				alreadyprocessed = alreadyprocessed " " item_id
				skip = 0
			}
			print "BEGIN:VTODO"
			print "UID:" item_id
			print  "SEQ:0"
			}

(skip == 1) {
				# Skip items we've seen already	
				#print "Skipping " $0
				next
			}
			
/MODIFIEDSTART/	{
			# Clear modified vars
			modified_year = ""
			modified_month = ""
			modified_day = ""
			modified_hour = ""
			modified_min = ""
			modified_sec = ""
			completed = 0
			
			}
			
/MODIFIEDYEAR/	{ modified_year = $2 }

/MODIFIEDMONTH/	{ modified_month = leftpad($2,2)}
					
/MODIFIEDDAY/	{ modified_day = leftpad($2,2) }

/MODIFIEDTIME/ {
				raw_time = $6
				modified_hour = substr(raw_time,1,2)
				modified_min = substr(raw_time,4,2)
				modified_sec = substr(raw_time,7,2)
			}

/MODIFIEDEND/	{
			# print modified date
			print "DTSTART;TZID=US/Eastern:" modified_year modified_month modified_day "T" modified_hour modified_min modified_sec		
			next
			}			
			
/COMPLETED/	{
				#20050306T050000Z
				if ($2 == "true") {
					print "COMPLETED:" modified_year modified_month modified_day "T050000Z"
					next
				}
			}			
			
/SUMMARYSTART/ 	{ 
				summarystart = 1
				debugmsg("skipping SUMMARYSTART")
				# remember to skip ourselves
				next
			}
		
/UMMARYEND/ { 
				summarystart = 0
				debugmsg("skipping SUMMARYEND")
				# remember to skip ourselves
				next
			}
(summarystart == 1)  {
				debugmsg("summarystart == 1 : " $0)
				
				# need to strip actual \n sequences
				gsub("\\n","",$0)
				print "SUMMARY:" $0
				next
			}
/DESCRIPTIONSTART/ 	{ 
				descriptionstart = 1
				description = ""
				debugmsg("skipping DESCRIPTIONSTART")
				#print "DESCRIPTION:"
				# remember to skip ourselves
				next
			}
		
/DESCRIPTIONEND/ { 
				debugmsg("skipping DESCRIPTIONEND")
				print "DESCRIPTION:" description
				descriptionstart = 0
				description = ""
				# remember to skip ourselves
				next
			}

			
(descriptionstart == 1)  {
				debugmsg("descriptionstart == 1 " $0)
				# need to strip actual \n sequences
				gsub("\\n","",$0)
				description = description " " $0
				#print $0
				# remember to skip ourselves
				next
			}
	
/PRIORITY/	{
				print "PRIORITY:" $2
				next
			}
			
/DUESTART/ { 
				debugmsg("skipping DUESTART")
				duestart = 1
				due_date = ""
				# remember to skip ourselves
				next
			}
		
/DUEEND/ { 
				debugmsg("skipping DUEEND")
				duestart = 0
				# print from here
				if ( due_date != "") {
					print "DUE;VALUE=DATE:" due_date
				}
				# remember to skip ourselves
				next
			}

			
(duestart == 1)  {
				debugmsg("duestart == 1 " $0)
				raw_due_date = $0
				if (raw_due_date == "never") {
					#skip
					due_date = ""
				}
				else {
					due_year = $3
					due_month = leftpad(getMonthFromShortName($2),2)
					due_day = leftpad($1,2)
					due_date = due_year due_month due_day
				}
				# remember to skip ourselves
				next
			}
	
/ITEMEND/ {
			print "END:VTODO"
			
			}

END 	{

			print "END:VCALENDAR"
			#print ""
		}

function leftpad(unpadded,paddedlength) {
				raw_string = "000000000000000" unpadded
				#print "unpadded: +" unpadded "+ paddedlength: " paddedlength 
				#print "raw_string +" raw_string "+"
				#print "length(raw_string) " length(raw_string)
				padded_length = int(paddedlength)
				truncate_start = length(raw_string) + int(1) - padded_length
				#print "truncate_start " truncate_start
				padded_string = substr(raw_string, truncate_start, padded_length)
				#print "padded_string +" padded_string "+"
				return padded_string
			}
			
function getMonthFromShortName(name) {
		shortname = tolower(name)
		returnmonth = ""
		if ( shortname == "jan" ) {
			returnmonth = "1"
		}
		else if ( shortname == "jan" ) {
			returnmonth = "1"
		}
		else if ( shortname == "feb" ) {
			returnmonth = "2"
		}
		else if ( shortname == "mar" ) {
			returnmonth = "3"
		}
		else if ( shortname == "apr" ) {
			returnmonth = "4"
		}
		else if ( shortname == "may" ) {
			returnmonth = "5"
		}
		else if ( shortname == "jun" ) {
			returnmonth = "16"
		}
		else if ( shortname == "jul" ) {
			returnmonth = "7"
		}
		else if ( shortname == "aug" ) {
			returnmonth = "8"
		}
		else if ( shortname == "sep" ) {
			returnmonth = "9"
		}
		else if ( shortname == "oct" ) {
			returnmonth = "10"
		}
		else if ( shortname == "nov" ) {
			returnmonth = "11"
		}
		else if ( shortname == "dec" ) {
			returnmonth = "12"
		}
		return returnmonth
}

function debugmsg(string) {
	if (debug == 1) {
		print string
	}
}