using util

** Sets up FPM in the current Fantom environment.
** 
**   C:\> fan afFpm setup
** 
** 'setup' performs the following operations:
** 
**  1. Creates 'fpm.bat' in the 'bin/' directory of the current Fantom 
**     installation. Or creates an 'fpm' executable script on nix systems.
** 
**  2. Creates a default 'fpm.props' config file in the 'etc/afFpm/' directory.
** 
**  3. Publishes all non-core pods found in any Fantom work or home directory.
**     Note, this oprertation is non-destructive; pod files are left intact 
**     and are just *copied* to the local default repository.
** 
@NoDoc	// Fandoc is only saved for public classes
class SetupCmd : FpmCmd {

	private const CorePods	corePods	:= CorePods()

	@Opt { aliases=["r"]; help="Name of the repository to publish to" }
	Str repo	:= "default"

	new make() : super.make() { }

	override Int go() {
		printFpmTitle
		win := Env.cur.os.startsWith("win")

		func := |->| {
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
	
			fpmConfig.workDirs.each {
				installAllPodsFromDir(it.plus(`lib/fan/`), repo)
				log.info("")
			}
	
			fpmConfig.podDirs.each {
				installAllPodsFromDir(it, repo)
				log.info("")
			}
		}

		(log as StdLogger)?.indent
		log.info("Setting up FPM...")
		log.info("")
		func()
		(log as StdLogger)?.unindent

		log.info("Current Configuration")
		log.info(FpmConfig().dump)

		log.info("FPM setup complete.")
		log.info("")
		log.info("Have fun! :)")
		log.info("")
		return 0
	}
	
	override Bool argsValid() { true }
	
	** Publishes all pods from the given directory.
	**  
	** 'repo' should be the name of a local file repository, or a directory path.
	** Directory paths may be in URI form or an OS path.
	**  
	** 'repo' defaults to 'default' if not specified.
	private Void installAllPodsFromDir(File dir, Str? repo := null) {
		log.info("Publishing pods from ${dir.osPath} to repo '" +  (repo ?: "default") + "'...")
		podRegex := ".+\\.pod".toRegex
		podFiles := dir.listFiles.findAll { podRegex.matches(it.name) }.exclude {
			corePods.isCorePod(it.basename) || it.basename == "afFpm"
		}
		if (podFiles.isEmpty)
			log.info("  No non-core pods found")
		
		podFiles.each |file| {
			podManager.publishPod(file, repo)
		}
	}
}
