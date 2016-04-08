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
		fanFile	:= Env.cur.os == "win32" ? `bin/fan.bat` : `bin/fan`
		fanCmd	:= (Env.cur.homeDir + fanFile).normalize.osPath
		cmds	:= args
		target	:= target
		
		if (target == null) {
			target = args.getSafe(0) ?: ""
			if (target.contains("@"))
				cmds[0] = target[0..<target.index("@")]
	
			// cater for launch pods such as afBedSheet and afReflux
			if (fpmConfig.launchPods.contains(target)) {
				target = args.getSafe(1) ?: ""
				if (target.contains("@"))
					cmds[1] = target[0..<target.index("@")]			
			}
		}
		
		if (js)
			cmds.insert(0, "compilerJs::Runner")
		cmds.insert(0, fanCmd)

		log.info("Running " + cmds[1..-1].join(" "))

		process := Process(cmds)
		process.mergeErr = false
		process.env["FAN_ENV"]		= FpmEnv#.qname
		process.env["FPM_DEBUG"]	= debug.toStr
		process.env["FPM_TARGET"]	= target
		return process.run.join
	}
	
	override Bool argsValid() { true }
}
