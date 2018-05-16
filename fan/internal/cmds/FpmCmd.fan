
** Needs to be public to retain the type doc
@NoDoc
class FpmCmd {
	static const Int invalidArgs	:= 3

	Log log	:= FpmCmd#.pod.log
	
	FpmConfig fpmConfig := FpmConfig()	// TODO set this explicitly
	
	@Opt { aliases=["d"]; help="Prints debug information" }
	Bool debug

	virtual Int run() {
		// http://stackoverflow.com/a/24121322/1532548
		return 64	/* command line usage error */
	}
}


class PodManager {
	
	const FpmConfig fpmConfig
	
	new make(FpmConfig fpmConfig) {
		this.fpmConfig = fpmConfig
	}
}