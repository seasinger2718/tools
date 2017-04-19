		{
			numpaths = split($0, paths , ":")
			
			for (i = 1;  i <= numpaths ; i++) {
				print paths[i]
			}
	    }		