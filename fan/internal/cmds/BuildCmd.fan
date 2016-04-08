using util

** Builds a Fantom application.
** 
** Runs build tasks from 'build.fan' within an FPM environment.   
** 
** The targeted environment is derived from the 'depends' pod list defined in 
** 'build.fan'.
** 
** 'build.fan' should be in the current directory.
** 
** If (and only if) a repository is specified, then any pod built is installed 
** into it.
** 
** Examples:
**   C:\> fpm build
**   C:\> fpm build -repo default compile
** 
@NoDoc	// Fandoc is only saved for public classes
class BuildCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name or location of the repository to install built pods to (defaults to 'default')" }
	Str? repo

	** @mopUp
	@Arg { help="The build tasks to execute (defaults to 'compile')" }
	Str[]?	tasks	:= ["compile"]

	new make() : super.make() { }

	override Int go() {
		printTitle
		fanFile	:= Env.cur.os == "win32" ? `bin/fan.bat` : `bin/fan`
		fanCmd	:= (Env.cur.homeDir + fanFile).normalize.osPath
		cmds	:= tasks
		target	:= "build.fan"
		cmds.insert(0, target)
		cmds.insert(0, fanCmd)

		log.info("Running build task: " + cmds[2..-1].join(" "))

		process := Process(cmds)
		process.mergeErr = false
		process.env["FAN_ENV"]		= FpmEnv#.qname
		process.env["FPM_DEBUG"]	= debug.toStr
		process.env["FPM_TARGET"]	= target
		retVal := process.run.join
		if (retVal != 0)
			return retVal

		buildPod := BuildPod(target)
		if (buildPod == null) {
			log.warn("Could not compile script: ${target}")
			return 1
		}

		if (repo != null) {
			podFile	 := buildPod.outPodDir.plusSlash.plusName(buildPod.podName  + ".pod").toFile.normalize
			
			if (podFile.exists.not) {
				// there could be an env mis-match, so try again
				podFile	 = (fpmConfig.workDirs.first + `lib/fan/` + `${buildPod.podName}.pod`).normalize

				if (podFile.exists.not) {				
					log.warn("Pod file does not exist: ${podFile.osPath}")
					return 1
				}
			}
			
			log.info("")
			log.info("Publishing Pod:")
			podManager.publishPod(podFile, repo)

			log.info("  Deleting ${podFile.normalize.osPath}")
			podFile.delete

		}

		log.info("")
		log.info("Done.")
		return 0
	}
	
	override Bool argsValid() { true }

}
