using util

** Runs a build task from 'build.fan'. Should a pod be built, it is installed to the named repository. 
@NoDoc	// Fandoc is only saved for public classes
class BuildCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name or location of the repository to install to." }
	Str? repo

	@Arg
	Str[]?	args
	
	override Int go() {
		fanFile	:= Env.cur.os == "win32" ? `bin/fan.bat` : `bin/fan`
		fanCmd	:= (Env.cur.homeDir + fanFile).normalize.osPath
		cmds	:= args
		target	:= "build.fan"
		if (cmds == null)
			cmds = Str["compile"]
		cmds.insert(0, target)
		cmds.insert(0, fanCmd)

		log.info("Running build task: " + cmds[2..-1].join(" "))

		process := Process(cmds)
		process.mergeErr = false
		process.env["FPM_TARGET"] = target
		retVal := process.run.join
		if (retVal != 0)
			return retVal
		
		buildPod := BuildPod(target)
		if (buildPod == null) {
			log.warn("Could not compile script: ${target}")
			return 1
		}
		podFile	 := buildPod.outPodDir.plusSlash.plusName(buildPod.podName  + ".pod").toFile.normalize
		if (podFile.exists.not) {
			log.warn("Pod file does not exist: ${podFile.osPath}")
			return 1
		}
		
		// if we're not compiling then we don't have a pod to publish!
		if (cmds.last == "compile") {
			log.info("")
			podManager.publishPod(podFile, repo)
		}
		return 0
	}
	
	override Bool argsValid() { true }

}
