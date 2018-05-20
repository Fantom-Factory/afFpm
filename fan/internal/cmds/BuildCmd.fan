
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
**   C:\> fpm build compileTask -repo release
** 
@NoDoc	// Fandoc is only saved for public classes
class BuildCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name or location of the repository to install built pods to (defaults to 'default')" }
	Repository? repo

	@Arg { help="The build tasks to execute (defaults to 'compile')" }
	Str[]?	tasks	:= ["compile"]

	new make(|This| f) : super(f) { }

	override Int run() {
		fanFile	:= Env.cur.os == "win32" ? `bin/fan.bat` : `bin/fan`
		fanCmd	:= (Env.cur.homeDir + fanFile).normalize.osPath
		cmds	:= tasks
		target	:= "build.fan"
		cmds.insert(0, target)
		cmds.insert(0, fanCmd)

		buildPod := BuildPod(target)

//		// FIXME if a build pod is not found, lets just run the build.fan
//		if (buildPod.errCode == "notBuildPod")
//			return RunCmd() {
//				if (it.args == null)
//					it.args = Str[,]
//				it.args.add("build.fan")
//			}.run

		if (buildPod.errMsg != null) {
			log.warn("Could not compile script - ${buildPod.errMsg}")
			return 1
		}

		log.info("FPM building ${buildPod}")

		process := Process2(cmds)
		process.mergeErr = false
		process.env["FAN_ENV"]		= FpmEnv#.qname
		process.env["FPM_DEBUG"]	= debug.toStr
		process.env["FPM_TARGET"]	= target
		retVal := process.run.join
		if (retVal != 0)
			return retVal

		if (repo != null) {
			file := buildPod.outPodDir.plusSlash.plusName(buildPod.podName  + ".pod").toFile.normalize
			
			if (file.exists.not) {
				// there could be an env mis-match, so try again
				file = (fpmConfig.workDirs.first + `lib/fan/` + `${buildPod.podName}.pod`).normalize

				if (file.exists.not) {				
					log.warn("Pod file does not exist: ${file.osPath}")
					return 1
				}
			}
			
			podFile := PodFile(file)
			
			log.info("")
			log.info("Installing Pod:")
			podFile.installTo(repo)

			log.info("  Deleting ${file.normalize.osPath}")
			podFile.delete
		}

		return 0
	}
}
