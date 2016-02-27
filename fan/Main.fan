using util

internal class Main {
	
	Int main(Str[] args) {
		
		cmd := args.first
		
		if (cmd == null)
			return HelpCmd().run
		
		switch (cmd) {
			case "build":
				return BuildCmd().run

			case "run":
				return RunCmd().run

			case "test":
				return TestCmd().run

			case "setup":
				return SetupCmd().run
		
			case "update":
				return UpdateCmd().run
		
			case "install":
				return InstallCmd().run
		
			case "uninstall":
				return UnInstallCmd().run

			case "help":
				return HelpCmd().run

		  default:
		    throw ArgErr("Unknown cmd: ${cmd}")
		}
	}
}

