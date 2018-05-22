
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
			log.warn("Test what!?")
			return invalidArgs
		}

		// allow for explicit targets -> afFpm afGame@2.0
		targetNotSet := target == null
		dep := parseTarget(pod)
		if (dep != null) {
			if (targetNotSet)
				target = dep
			pod = dep.name
		}

		cmds := Str[pod]
		if (args != null)
			cmds.addAll(args)

		if (javascript) {
			cmds.insert(0, "-test")
			cmds.insert(0, "compilerJs::NodeRunner")
		}

		log.info("FPM testing " + cmds.join(" "))
		
		process := javascript ? ProcessFactory.fanProcess(cmds) : ProcessFactory.fantProcess(cmds)
		process.mergeErr = false
		process.env["FAN_ENV"]		= FpmEnv#.qname
		process.env["FPM_DEBUG"]	= debug.toStr
		process.env["FPM_TARGET"]	= target?.toStr ?: ""	// always set this, even to an empty string, to clear any existing env vars

		return process.run.join
	}
}
