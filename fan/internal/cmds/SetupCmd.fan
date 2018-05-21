
** Sets up FPM in the current Fantom environment.
** 
**   C:\> fan afFpm setup
** 
** Setup performs the following operations:
** 
**  1. Creates 'fpm.bat' in the 'bin/' directory of the current Fantom 
**     installation. Or creates an 'fpm' executable script on nix systems.
** 
**  2. Creates a default 'fpm.props' config file in the Fantom 'etc/afFpm/' 
**     directory.
** 
** After setup you should be able to run FPM from the command prompt with the 
** 'fpm' command.
** 
** Example:
**   fpm setup
**   fpm help setup
@NoDoc	// Fandoc is only saved for public classes
class SetupCmd : FpmCmd {

	new make(|This| f) : super(f) { }

	override Int run() {
		log.info("Settin up FPM...")
		log.info("")
		doRun()
		log.info("FPM setup complete.")
		log.info("")

		log.info("Current Configuration:")
		log.info(FpmConfig().dump)

		log.info("Have fun! :)")
		log.info("")
		return 0
	}
	
	Void doRun() {
		win			:= Env.cur.os.startsWith("win")
		ext 		:= win ? ".bat" : ""
		fpmFile		:= fpmConfig.homeDir + `bin/fpm${ext}`
		fanResFile	:= typeof.pod.file(`/res/fpm${ext}`)
		if (fpmFile.exists.not) {
			log.info("Creating: ${fpmFile.osPath}")
			fanResFile.copyTo(fpmFile)
		} else
			log.info("Already exists: ${fpmFile.osPath}")
		
		if (!win) {
			try		Process2(["chmod", "+x", fpmFile.osPath], fpmFile.parent).run.join
			catch	log.warn("Could not set execute permissions on: ${fpmFile.osPath}")
		}
		log.info("")

	
		configFile		:= fpmConfig.workDirs.first + `etc/afFpm/fpm.props`
		configResFile	:= typeof.pod.file(`/res/fpm.props`)
		if (configFile.exists.not) {
			log.info("Creating: ${configFile.osPath}")
			contents := configResFile.readAllStr.replace("#{File.pathSep}", File.pathSep)
			configFile.out.writeChars(contents).close
		} else
			log.info("Already exists: ${configFile.osPath}")
		log.info("")
	}
}
