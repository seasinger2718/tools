BEGIN {total = 0}
 { 
   total = total + $0 
 }
END {print total}