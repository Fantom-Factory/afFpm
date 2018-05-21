
** Needs to be public to retain the type doc
@NoDoc
class FpmCmd {
	static const Int invalidArgs	:= 3

	Log log	:= FpmCmd#.pod.log
	
	FpmConfig fpmConfig
	
	@Opt { aliases=["d"]; help="Prints debug information" }
	Bool debug

	new make(|This| f) { f(this) }
	
	virtual Int run() {
		// http://stackoverflow.com/a/24121322/1532548
		return 64	/* command line usage error */
	}
	
	internal static Depend? parseTarget(Str? arg) {
		if (arg == null)			return null
		if (arg.endsWith(".fan"))	return null
		dep := arg.replace("@", " ")
		if (!dep.contains(" "))
			dep += " 0+"
		return Depend(dep, false)
	}
}
