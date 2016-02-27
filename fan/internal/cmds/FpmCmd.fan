using util
using concurrent

** Needs to be public to retain the type doc
@NoDoc
abstract class FpmCmd : AbstractMain {
	override Log	log 	:= StdLogger()
		FpmConfig	fpmConfig	:= (Env.cur as FpmEnv)?.fpmConfig ?: FpmEnv().fpmConfig
		PodManager	podManager	:= PodManagerImpl {
			it.fpmConfig	= this.fpmConfig
			it.log			= this.log
		}

	new make() : super.make() { }
	
	final override Int run() {
		title := "Fantom Pod Manager ${typeof.pod.version}"
		log.info("\n${title}")
		log.info("".padl(title.size, '=') + "\n")

		argsOk := Env.cur.args.isEmpty ? true : super.parseArgs(Env.cur.args[1..-1])
		if (!argsOk || !argsValid || helpOpt) {
			usage
			if (!helpOpt) log.err("Missing arguments")
			return 1
		}

		return go
	}

	virtual Int go() { return 0 }
	virtual Bool argsValid() { false }

	override Str appName() {
		this.typeof.name.replace("Cmd", "").fromDisplayName
	}
	
	Int err(Str msg) {
		throw CmdErr(msg)
	}
}

internal const class StdLogger : Log {
	private const AtomicRef lead := AtomicRef("")

	new make() : super.make("StdLogger", false) { }
	override Void log(LogRec rec) {
		rec.msg.split('\n', false).each {
			echo(lead.val.toStr + it)
		}
	}

	Void indent(Str msg, |->| f) {
		info(msg)
		lead.val = lead.val.toStr + "  "
		try f()
		finally
			lead.val = lead.val.toStr[0..<-2]
	}
}

internal const class CmdErr : Err {
	new make(Str msg) : super(msg) { }
}