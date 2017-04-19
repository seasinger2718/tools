while (<STDIN>) {
   # assigns each line in turn to $_
    if ( $_ =~ /\015\012/ ) {	
        print STDOUT $_;
    }
   # assigns each line in turn to $_
    if ( $_ =~ /\015/ ) {	
        print STDOUT $_;
    }

}
