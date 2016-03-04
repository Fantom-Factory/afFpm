using util

**
** Executes a pod / method, within the FPM environment.
** 
@NoDoc	// Fandoc is only saved for public classes
class RunCmd : FpmCmd {
	
	@Opt { help="Run in Javascript environment" }
	Bool	js

	@Arg
	Str[]?	args
	
	override Int go() {
		fanFile	:= Env.cur.os == "win32" ? `bin/fan.bat` : `bin/fan`
		fanCmd	:= (Env.cur.homeDir + fanFile).normalize.osPath
		cmds	:= args

		target	:= args.getSafe(0) ?: ""
		if (target.contains("@"))
			cmds[0] = target[0..<target.index("@")]

		// cater for lauch pods such as afBedSheet and afReflux
		if (fpmConfig.launchPods.contains(target)) {
			target = args.getSafe(1) ?: ""
			if (target.contains("@"))
				cmds[1] = target[0..<target.index("@")]			
		}
		
		if (js)
			cmds.insert(0, "compilerJs::Runner")
		cmds.insert(0, fanCmd)

		log.info("Running " + cmds[1..-1].join(" "))

		process := Process(cmds)
		process.mergeErr = false
		process.env["FPM_TARGET"] = target
		return process.run.join
	}
	
	override Bool argsValid() { true }
}
