
** Runs a Fantom application.
** 
** Executes a pod / method, within an FPM environment.
** 
** The target environment is taken to be the containing pod of the executed method.
** It may be explicitly overridden using the '-target' option.
** 
** Examples:
**   C:\> fpm run myPod
**   C:\> fpm run -js -target myPod2 myPod::MyClass
** 
@NoDoc	// Fandoc is only saved for public classes
class RunCmd : FpmCmd {
	
	@Opt { aliases=["t"]; help="The target pod; maybe used when running scripts" }
	Depend?	target

	@Opt { aliases=["js"]; help="Run in Javascript environment (requies NodeJs)" }
	Bool	javascript

	@Arg { help="The Fantom pod / class / method to run"}
	Str?	pod

	@Arg { help="Arguments to pass to fan"}
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

		log.info("FPM running " + cmds.join(" "))

		process := ProcessFactory.fanProcess(cmds)
		process.mergeErr = false
		process.env["FAN_ENV"]		= FpmEnv#.qname
		process.env["FPM_DEBUG"]	= debug.toStr
		if (target != null)
			process.env["FPM_TARGET"]	= target.toStr

		return process.run.join
	}
}
