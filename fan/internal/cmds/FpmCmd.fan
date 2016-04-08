using util
using concurrent

** Needs to be public to retain the type doc
@NoDoc
abstract class FpmCmd : AbstractMain {

	@Opt { aliases=["d"]; help="Prints debug information" }
	Bool debug

	override Log	log 		:= StdLogger()
		FpmConfig	fpmConfig
		PodManager	podManager

	new make(|This|? in := null) : super.make() {
		in?.call(this)
		if (fpmConfig == null)
			fpmConfig = (Env.cur as FpmEnv)?.fpmConfig ?: FpmEnv().fpmConfig
		if (podManager == null)
			podManager = PodManagerImpl {
				it.fpmConfig	= this.fpmConfig
				it.log			= this.log
			}
	}
	
	override Int run() {
		argsOk := Env.cur.args.isEmpty ? true : parseArgs(Env.cur.args[1..-1])
		if (!argsOk || !argsValid || helpOpt) {
			printTitle
			usage
			if (!helpOpt) log.err("Missing arguments")
			return 1
		}

		if (debug)
			Log.get("afFpm").level = LogLevel.debug
		return go
	}
	
	Void printTitle() {
		title := "Fantom Pod Manager ${typeof.pod.version}"
		log.info("\n${title}")
		log.info("".padl(title.size, '=') + "\n")		
	}

	virtual Int go() { return 0 }
	virtual Bool argsValid() { false }

	override Str appName() {
		this.typeof.name.replace("Cmd", "").fromDisplayName
	}
	
	Int err(Str msg) {
		throw CmdErr(msg)
	}
	
	// ---- Arg Parsing ----
	
	**
	** Parse the command line and set this instances fields.
	** Return false if not all of the arguments were passed.
	**
	override Bool parseArgs(Str[] toks) {
		args := argFields
		opts := optFields
		varArgs		:= !args.isEmpty && args.last.type.fits(List#)
		mopUp 		:= varArgs && args.last.doc?.trim == "@mopUp"
		moppingUp	:= false
		argi := 0
		for (i:=0; i<toks.size; ++i) {
			tok := toks[i]
			Str? next := i+1 < toks.size ? toks[i+1] : null
			
			if (moppingUp) {
				addToVarArgs(args.last, tok)
				continue
			}
			
			if (tok.startsWith("-")) {
				if (parseOpt(opts, tok, next)) ++i
			}
			else if (argi < args.size) {
				if (parseArg(args[argi], tok))
					++argi
				else
					moppingUp = true
			}
			else {
				log.warn("Unexpected arg: $tok")
			}
		}
		if (argi == args.size) return true
		if (argi == args.size-1 && varArgs) return true
		return false // missing args
	}

	private Bool parseOpt(Field[] opts, Str tok, Str? next) {
		n := tok[1..-1]
		for (i:=0; i<opts.size; ++i) {
			// if name doesn't match opt or any of its aliases then continue
			field := opts[i]
			faset := (Opt)field.facet(Opt#)
			aliases := faset
			if (optName(field) != n && !faset.aliases.contains(n)) continue

			// if field is a bool we always assume the true value
			if (field.type == Bool#) {
				field.set(this, true)
				return false // did not consume next
			}

			// check that we have a next value to parse
			if (next == null || next.startsWith("-")) {
				log.err("Missing value for -$n")
				return false // did not consume next
			}

			try {
				// parse the value to proper type and set field
				field.set(this, parseVal(field.type, next))
			}
			catch (Err e) log.err("Cannot parse -$n as $field.type.name: $next")
			return true // we *did* consume next
		}

		log.warn("Unknown option -$n")
		return false // did not consume next
	}

	private Bool parseArg(Field field, Str tok) {
		isList := field.type.fits(List#)
		try {
			// if not a list, this is easy
			if (!isList) {
				field.set(this, parseVal(field.type, tok))
				return true // increment argi
			}

			// if list, then parse list item and add to end of list
			addToVarArgs(field, tok)
		}
		catch (Err e) log.err("Cannot parse argument as $field.type.name: $tok")
		return !isList // increment argi if not list
	}
	
	private Void addToVarArgs(Field field, Str tok) {
		of := field.type.params["V"]
		val :=	parseVal(of, tok)
		list := field.get(this) as Obj?[]
		if (list == null) field.set(this, list = List.make(of, 8))
		list.add(val)		
	}

	private Str argName(Field f) {
		if (f.name.endsWith("Arg")) return f.name[0..<-3]
		return f.name
	}

	private Str optName(Field f) {
		if (f.name.endsWith("Opt")) return f.name[0..<-3]
		return f.name
	}

	private Obj? parseVal(Type of, Str tok) {
		of = of.toNonNullable
		if (of == Str#) return tok
		if (of == File#) {
			if (tok.contains("\\"))
				return File.os(tok).normalize
			else
				return File.make(tok.toUri, false)
		}
		return of.method("fromStr").call(tok)
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

	Void indent() {
		lead.val = lead.val.toStr + "  "
	}

	Void unindent() {
		tab := (Str) lead.val 
		lead.val = tab[0..tab.size-2]
	}
	
//	Void indent(Str msg, |->| f) {
//		info(msg)
//		lead.val = lead.val.toStr + "  "
//		try f()
//		finally
//			lead.val = lead.val.toStr[0..<-2]
//	}
}

internal const class CmdErr : Err {
	new make(Str msg) : super(msg) { }
}