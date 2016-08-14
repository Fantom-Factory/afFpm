using util

** Runs a Fantom application.
** 
** Executes a pod / method, within an FPM environment.
** 
** If the 'target' option is not specified, then the targeted environment is 
** derived from the containing pod.
** 
** Examples:
**   C:\> fpm run myPod
**   C:\> fpm run -js -target myPod myPod::MyClass
** 
@NoDoc	// Fandoc is only saved for public classes
class RunCmd : FpmCmd {

	@Opt { aliases=["t"]; help="The target pod; maybe used when running scripts" }
	Str?	target

	@Opt { help="Run in Javascript environment" }
	Bool	js

	** @mopUp
	@Arg { help="Arguments to pass to fan"}
	Str[]?	args
	
	new make() : super.make() { }

	override Int go() {
		cmds	:= args ?: Str[,]
		target	:= target
		
		if (cmds.isEmpty) {
			buildPod := BuildPod("build.fan")
			if (buildPod.errMsg != null) {
				log.warn("Could not compile script - ${buildPod.errMsg}")
				return 1
			}
			cmds.add(buildPod.podName)
		}
		
		if (target == null) {
			target = cmds.getSafe(0) ?: ""
			if (target.contains("@"))
				cmds[0] = target[0..<target.index("@")]
	
			// cater for launch pods such as afBedSheet and afReflux
			if (fpmConfig.launchPods.contains(target)) {
				target = cmds.getSafe(1) ?: ""
				if (target.contains("@"))
					cmds[1] = target[0..<target.index("@")]			
			}
		}
		
		if (js)
			cmds.insert(0, "compilerJs::Runner")

		printTitle("FPM: Running " + cmds.join(" "))

		process := ProcessFactory.fanProcess(cmds)
		process.mergeErr = false
		process.env["FAN_ENV"]		= FpmEnv#.qname
		process.env["FPM_DEBUG"]	= debug.toStr
		process.env["FPM_TARGET"]	= target

		return process.run.join
	}
	
	override Bool argsValid() {
		if (args != null && args.size > 1)
			return true
		return `build.fan`.toFile.exists
	}
}
