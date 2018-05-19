
internal class TestArgParser : Test {
	
	Void testArgs() {
		cmd := null as FpmArgs

		cmd = parse("".split)
		verifyEq(cmd.cmd, 		"")
		verifyEq(cmd.targetStr, "")
		verifyEq(cmd.args,		Str[,])

		cmd = parse("cmd".split)
		verifyEq(cmd.cmd, 		"cmd")
		verifyEq(cmd.targetStr, "")
		verifyEq(cmd.args,		Str[,])

		cmd = parse("cmd target".split)
		verifyEq(cmd.cmd, 		"cmd")
		verifyEq(cmd.targetStr, "target")
		verifyEq(cmd.args,		Str[,])

		cmd = parse("cmd target arg1".split)
		verifyEq(cmd.cmd, 		"cmd")
		verifyEq(cmd.targetStr, "target")
		verifyEq(cmd.args,		Str["arg1"])

		cmd = parse("cmd target arg1 arg2".split)
		verifyEq(cmd.cmd, 		"cmd")
		verifyEq(cmd.targetStr, "target")
		verifyEq(cmd.args,		Str["arg1", "arg2"])
	}

	Void testOpts() {
		cmd := null as FpmArgs
		
		cmd = parse("".split)
		verifyEq(cmd.repo, 			"")
		verifyEq(cmd.offline, 		false)
		verifyEq(cmd.debug,			false)
		verifyEq(cmd.javascript,	false)

		cmd = parse("-d".split)
		verifyEq(cmd.repo, 			"")
		verifyEq(cmd.offline, 		false)
		verifyEq(cmd.debug,			true)
		verifyEq(cmd.javascript,	false)

		cmd = parse("--debug".split)
		verifyEq(cmd.repo, 			"")
		verifyEq(cmd.offline, 		false)
		verifyEq(cmd.debug,			true)
		verifyEq(cmd.javascript,	false)

		cmd = parse("-d -o".split)
		verifyEq(cmd.repo, 			"")
		verifyEq(cmd.offline, 		true)
		verifyEq(cmd.debug,			true)
		verifyEq(cmd.javascript,	false)

		cmd = parse("-d --offline".split)
		verifyEq(cmd.repo, 			"")
		verifyEq(cmd.offline, 		true)
		verifyEq(cmd.debug,			true)
		verifyEq(cmd.javascript,	false)

		cmd = parse("-js -d -o".split)
		verifyEq(cmd.repo, 			"")
		verifyEq(cmd.offline, 		true)
		verifyEq(cmd.debug,			true)
		verifyEq(cmd.javascript,	true)

		cmd = parse("-r repo -js -d -o".split)
		verifyEq(cmd.repo, 			"repo")
		verifyEq(cmd.offline, 		true)
		verifyEq(cmd.debug,			true)
		verifyEq(cmd.javascript,	true)

		cmd = parse("-js --repo repo -d -o".split)
		verifyEq(cmd.repo, 			"repo")
		verifyEq(cmd.offline, 		true)
		verifyEq(cmd.debug,			true)
		verifyEq(cmd.javascript,	true)
	}
	
	Void testMixed() {
		cmd := null as FpmArgs
		
		cmd = parse("-js cmd --repo repo target arg1 -d --arg2 -o arg3".split)
		verifyEq(cmd.cmd, 			"cmd")
		verifyEq(cmd.targetStr, 	"target")
		verifyEq(cmd.args,			Str["arg1", "--arg2", "arg3"])		
		verifyEq(cmd.repo, 			"repo")
		verifyEq(cmd.offline, 		true)
		verifyEq(cmd.debug,			true)
		verifyEq(cmd.javascript,	true)
	}

	FpmArgs parse(Str[] args) {
		fieldData	:= ArgParser().parse(args, FpmArgs#)
		itBlock		:= Field.makeSetFunc(fieldData)
		return FpmArgs#.make([itBlock])
	}
}

internal const class FpmArgs {
	
	@Arg
	const Str	cmd			:= ""
	
	@Arg
	const Str	targetStr	:= ""		// file (.pod or .fan) / dir / fpmUri	
	
	@Arg
	const Str[]	args		:= Str#.emptyList

	@Opt { aliases=["r"] }
	const Str	repo		:= ""		// named or a dir
	
	@Opt { aliases=["o"] }
	const Bool	offline

	@Opt { aliases=["d"] }
	const Bool	debug

	@Opt { aliases=["js"] }
	const Bool	javascript

	const Uri?	target
	
	new make(|This| f) { f(this) }
}


