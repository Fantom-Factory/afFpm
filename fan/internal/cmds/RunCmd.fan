
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

		// allow for explicit targets -> afFpm afGame@2.0
		targetNotSet := target == null
		dep := parseTarget(pod)
		if (dep != null) {
			if (targetNotSet)
				target = dep
			pod = dep.name
		}
		
		// cater for launch pods such as afBedSheet and afReflux
		if (fpmConfig.launchPods.contains(pod)) {
			dep = parseTarget(args.getSafe(0))
			if (dep != null) {
				if (targetNotSet)
					target = dep
				args[0] = dep.name
			}
		}

		cmds := Str[pod]
		if (args != null)
			cmds.addAll(args)

		if (javascript) {
			cmds.insert(0, "-run")
			cmds.insert(0, "compilerJs::NodeRunner")
		}

		log.info("FPM running " + cmds.join(" "))

		process := ProcessFactory.fanProcess(cmds)
		process.mergeErr = false
		process.env["FAN_ENV"]		= FpmEnv#.qname
		process.env["FPM_DEBUG"]	= debug.toStr
		process.env["FPM_TARGET"]	= target?.toStr ?: pod	// always set this, to clear any existing env vars. Use 'pod' as fall back to pass the .fan scripts in 

		return process.run.join
	}	
}
