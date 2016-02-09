using util

internal class Main {
	
	Void main(Str[] args) {
		
		cmd := args.first

		// TODO: print out some basic FPM info, like repo dir & paths
		
		switch (cmd) {
			case "publish":
				PublishCmd().run

			case "setup":
				SetupCmd().run
		
			case "update":
				UpdateCmd().run
		
			case "install":
				InstallCmd().run
		
		  default:
		    throw ArgErr("Unknown cmd: ${cmd}")
		}
		
	}
}

