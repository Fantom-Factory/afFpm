using util

** Tests a Fantom application.
** 
** Executes tests via 'fant' within an FPM environment.
** 
** If the 'target' option is not specified, then the targeted environment is 
** derived from the containing pod of the first test.
** 
** Examples:
**   C:\> fpm test myPod
**   C:\> fpm test -js -target myPod myPod::TestClass
** 
@NoDoc	// Fandoc is only saved for public classes
class TestCmd : FpmCmd {

	@Opt { aliases=["t"]; help="The target pod" }
	Str?	target

	@Opt { help="Run in Javascript environment" }
	Bool	js

	** @mopUp
	@Arg { help="Arguments to pass to fant"} 
	Str[]?	args
	
	new make() : super.make() { }
	
	override Int go() {
		fanFile	:= Env.cur.os == "win32" ? `bin/fant.bat` : `bin/fant`		
		fanCmd	:= (Env.cur.homeDir + fanFile).normalize.osPath
		cmds	:= args
		target	:= target
		
		if (target == null) {
			target = args.first ?: ""
			if (target.contains("@"))
				cmds[0] = target[0..<target.index("@")]
		}
		
		if (js)
			cmds.insert(0, "-js")
		cmds.insert(0, fanCmd)

		log.info("Testing " + cmds[1..-1].join(" "))
		
		process := Process(cmds)
		process.mergeErr = false
		process.env["FAN_ENV"]		= FpmEnv#.qname
		process.env["FPM_DEBUG"]	= debug.toStr
		process.env["FPM_TARGET"]	= target
		return process.run.join
	}
	
	override Bool argsValid() {
		args.size > 0
	}
}
