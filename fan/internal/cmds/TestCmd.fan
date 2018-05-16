
** Tests a Fantom application.
** 
** Executes tests via 'fant' within an FPM environment.
** 
** The target environment is taken to be the containing pod of the executed test.
** It may be explicitly overridden using the '-target' option.
** 
** Examples:
**   C:\> fpm test myPod
**   C:\> fpm test -js -target myPod myPod::TestClass
** 
@NoDoc	// Fandoc is only saved for public classes
class TestCmd : FpmCmd {

	@Opt { aliases=["t"]; help="The target pod" }
	Depend?	target

	@Opt { aliases=["js"]; help="Run in Javascript environment (requies NodeJs)" }
	Bool	javascript

	@Arg { help="The Fantom pod / class / method to test"}
	Str?	pod

	@Arg { help="Arguments to pass to fant"}
	Str[]?	args
	
	new make(|This| f) : super(f) { }
	
	override Int run() {
		if (pod == null) {
			log.warn("Run what!?")
			return invalidArgs
		}

		cmds := Str[pod]
		if (args != null)
			cmds.addAll(args)

		if (javascript)
			throw UnsupportedErr("-js")
			// FIXME run javascript
//			cmds.insert(0, "compilerJs::NodeRunner blah blah blah")

		log.info("FPM testing " + cmds.join(" "))
		
		process := ProcessFactory.fantProcess(cmds)
		process.mergeErr = false
		process.env["FAN_ENV"]		= FpmEnv#.qname
		process.env["FPM_DEBUG"]	= debug.toStr
		if (target != null)
			process.env["FPM_TARGET"]	= target.toStr

		return process.run.join
	}
}
