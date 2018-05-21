
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
**   C:\> fpm build compileTask -r release
** 
@NoDoc	// Fandoc is only saved for public classes
class BuildCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name or location of the repository to install built pods to (defaults to 'default')" }
	Repository repo

	@Arg { help="The build tasks to execute (defaults to 'compile')" }
	Str[]	tasks	:= ["compile"]

	new make(|This| f) : super(f) {
		if (repo == null) repo = fpmConfig.repository("default")
	}

	** Note this is VERY similar to the RUN command - but with 'build.fan' as the default pod
	override Int run() {
		target	:= "build.fan"
		cmds	:= [target].addAll(tasks)

		buildPod := BuildPod(target)

		// if a build pod is not found, lets just run the build.fan
		if (buildPod.errCode == "notBuildPod")
			return RunCmd() {
				it.pod = "build.fan"
				it.args = tasks
			}.run

		if (buildPod.errMsg != null) {
			log.warn("Could not compile script - ${buildPod.errMsg}")
			return 1
		}

		log.info("FPM building ${buildPod}")

		process := ProcessFactory.fanProcess(cmds)
		process.mergeErr = false
		process.env["FAN_ENV"]		= FpmEnv#.qname
		process.env["FPM_DEBUG"]	= debug.toStr
		process.env["FPM_TARGET"]	= target
		retVal := process.run.join
		if (retVal != 0)
			return retVal

		file := buildPod.outPodDir.plusSlash.plusName(buildPod.podName  + ".pod").toFile.normalize
		
		if (file.exists.not) {
			// there could be an env mis-match, so try again
			file = (fpmConfig.workDirs.first + `lib/fan/` + `${buildPod.podName}.pod`).normalize
		}

		if (file.exists.not) {				
			log.warn("Pod file does not exist: ${file.osPath}")
			return 1
		}
		
		podFile := PodFile(file)
		
		log.info("")
		log.info("Installing ${podFile.depend} to ${repo.name} (${repo.url})")
		podFile.installTo(repo)

		log.info("  Deleting ${file.normalize.osPath}")
		podFile.delete

		return 0
	}
}
