using util

class Main : AbstractMain {
	
	@Arg
	Str? cmd
	
	override Int run() {
		
		// TODO: print out some basic FPM info, like repo dir & paths
		
		switch (cmd) {
			case "setup":
				SetupCmd().go
		
		  default:
		    
		}
		
		return 0
	}
}

