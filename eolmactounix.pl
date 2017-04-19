  
   while (<STDIN>) {     # assigns each line in turn to $_
           	   s/\015/\012/g;	
               print STDOUT $_;
           }
   
