using util

**
** Executes tests within the FPM environment.
** 
@NoDoc	// Fandoc is only saved for public classes
class TestCmd : FpmCmd {

	@Opt { help="Run in Javascript environment" }
	Bool	js
	
	@Arg
	Str[]?	args
	
	override Int go() {
		fanFile	:= Env.cur.os == "win32" ? `bin/fant.bat` : `bin/fant`		
		fanCmd	:= (Env.cur.homeDir + fanFile).normalize.osPath
		cmds	:= args

		target	:= args.first ?: ""
		if (target.contains("@"))
			cmds[0] = target[0..<target.index("@")]
		
		if (js)
			cmds.insert(0, "-js")
		cmds.insert(0, fanCmd)

		log.info("Testing " + cmds[1..-1].join(" "))
		
		process := Process(cmds)
		process.mergeErr = false
		process.env["FPM_TARGET"] = target
		return process.run.join
	}
	
	override Bool argsValid() {
		args.size > 0
	}
}
