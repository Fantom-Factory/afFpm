using util
using concurrent

internal abstract class FpmCmd : AbstractMain {
	override StdLogger 	log 	:= StdLogger()
	
		FpmConfig	fpmConfig	:= FpmConfig()
		PodManager	podManager	:= PodManager() {
			it.fpmConfig	= this.fpmConfig
			it.log			= this.log
		}

	new make() : super.make() { }
	
	final override Int run() {
		title := "Fantom Pod Manager ${typeof.pod.version}"
		echo("\n${title}")
		echo("".padl(title.size, '=') + "\n")
		
		argsOk := super.parseArgs(Env.cur.args[1..-1])
		if (!argsOk || !argsValid || helpOpt) {
			usage
			if (!helpOpt) log.err("Missing arguments")
			return 1
		}

		go
		return 0
	}

	virtual Void go() { }
	virtual Bool argsValid() { false }
	
	override Str appName() {
		this.typeof.name.replace("Cmd", "").fromDisplayName
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
