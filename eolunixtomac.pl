  
   while (<STDIN>) {     # assigns each line in turn to $_
           	   s/\012/\015/g;	
               print STDOUT $_;
           }
   
