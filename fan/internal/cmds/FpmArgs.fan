
const class FpmArgs {
	
	@Arg
	const Str	cmd			:= ""
	
	@Arg
	const Str	targetStr	:= ""		// file (.pod or .fan) / dir / fpmUri	
	
	const Str[]	args		:= Str[,]

	@Opt { aliases=["r"] }
	const Str	repo		:= ""		// named or a dir
	
	@Opt { aliases=["o"] }
	const Bool	offline

	@Opt { aliases=["d"] }
	const Bool	debug

	@Opt { aliases=["js"] }
	const Bool	javascript

	new make(|This| f) { f(this) }
}


facet class Arg {
	** Usage help, should be a single short line summary
	const Str help := ""
}

facet class Opt {
	** Usage help, should be a single short line summary
	const Str help := ""
	
	** Aliases for the option
	const Str[] aliases := Str[,]
}


class PodManager {
	
	const FpmConfig fpmConfig
	
	new make(FpmConfig fpmConfig) {
		this.fpmConfig = fpmConfig
	}
	
	
	
}