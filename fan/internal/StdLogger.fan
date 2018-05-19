using concurrent::AtomicRef

internal const class StdLogger : Log {
	private const AtomicRef lead := AtomicRef("")

	// Loggers named "afFpm" logs don't seem to pickup log levels from log.props
	// see http://fantom.org/forum/topic/2546
	new make() : super.make("StdLogger", false) { }
	override Void log(LogRec rec) {
		if (!isEnabled(rec.level)) return
		rec.msg.split('\n', false).each {
			echo(lead.val.toStr + it)
		}
	}

	Void indent() {
		lead.val = lead.val.toStr + "  "
	}

	Void unindent() {
		tab := (Str) lead.val 
		lead.val = tab[0..tab.size-2]
	}
}