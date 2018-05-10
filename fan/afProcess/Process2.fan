using [java] fanx.interop::Interop
using [java] java.lang::IllegalThreadStateException	as JIllegalThreadStateException
using [java] java.lang::Process						as JProcess
using [java] java.lang::ProcessBuilder				as JProcessBuilder
using [java] java.util::Map$Entry					as JEntry
using concurrent::Actor
using concurrent::ActorPool

** Process manages spawning external OS processes.
** Goes one better than the standard 'sys::Process' as this constantly stream keyboard input to the new process.
internal class Process2 {
	
	private JProcess?		jProc
	private PipeInToOut?	inPipe
	private PipeInToOut?	outPipe
	private PipeInToOut?	errPipe
	
	** The 'ActorPool' used to control the in / out / err stream threads.
	** Leave as 'null' to create a default 'ActorPool'.
	ActorPool?	actorPool {
		set { checkRun; &actorPool = it }		
	}

	** Command argument list used to launch process.
	** The first item is the executable itself, then rest are the parameters.
	Str[] command {
		set { checkRun; &command = it }
	}

	** Working directory of process.
	File? dir {
		set { checkRun; &dir = it }
	}

	** If true, then stderr is redirected to the output stream configured via the 'out' field, and the 'err'
	** field is ignored.  The default is true.
	Bool mergeErr := true {
		set { checkRun; &mergeErr = it }
	}

	** The output stream used to sink the process stdout.
	** Default is to send to `Env.out`.  If set to null, then output is silently consumed like /dev/null.
	OutStream? out := Env.cur.out {
		set { checkRun; &out = it }
	}

	** The output stream used to sink the process stderr.
	** Default is to send to `Env.err`.  
	** If set to 'null', then output is silently consumed like /dev/null.  
	** Note this field is ignored if `mergeErr` is set true, in which case stderr goes to the stream configured via 'out'.
	OutStream? err := Env.cur.err {
		set { checkRun; &err = it }
	}

	** The input stream used to source the process stdin.
	** If 'null', then the new process will block if it attempts to read stdin.  Default is null.
	InStream? in := Env.cur.in {
		set { checkRun; &in = it }
	}
	
	** Environment variables to pass to new process as a mutable map of string key/value pairs.
	** This map is initialised with the current process environment.
	Str:Str env {
		set { checkRun; &env = it }		
	}
	
	@NoDoc
	Duration throttle	:= 20ms	// ~ 1 Jiffy

	** Construct a Process instanced used to launch an external OS process with the specified command arguments.
	** The first item in the 'cmd' list is the executable itself, then rest are the parameters.
	new make(Str[] cmd := Str[,], File? dir := null) {
		this.command = cmd
		this.dir	 = dir
		
		&env = Str:Str[:]
		itr := JProcessBuilder((Str[]) Str#.emptyList).environment.entrySet.iterator
		while (itr.hasNext) {
			entry := (JEntry) itr.next
			&env[entry.getKey] = entry.getValue
		}
	}

	** Spawn this process.
	** See `join` to wait until the process has finished and get the exit code.
	** Return this.
	This run() {
		checkRun

		builder := JProcessBuilder(command)
		
		envMap	:= builder.environment
		env.each |v, k| {
			envMap.put(k, v)
		}

		if (dir != null)
			builder.directory(Interop.toJava(dir))
		
		builder.redirectErrorStream(mergeErr)
		
		jProc = builder.start
		
		stdInStream		:= Interop.toFan(jProc.getOutputStream, 0)
		stdOutStream	:= Interop.toFan(jProc.getInputStream,  0)
		stdErrStream	:= Interop.toFan(jProc.getErrorStream,  0)
		&actorPool	 	= actorPool ?: ActorPool() { it.name = "Process: ${command.first}" }
		
		// now launch threads to pipe std in, out, and err
		inPipe  = PipeInToOut(actorPool, this, this.in,   stdInStream, throttle).pipe
		outPipe = PipeInToOut(actorPool, this, stdOutStream, this.out, throttle).pipe
		if (!mergeErr)
			errPipe = PipeInToOut(actorPool, this, stdErrStream, this.err, throttle).pipe
		
		return this
	}

	** Wait for this process to exit and return the exit code.
	** This method may only be called once after 'run'.
	Int join() {
		if (jProc == null) throw Err("Process not running")
		try { 
			result := jProc.waitFor
			inPipe?.join
			outPipe?.join
			errPipe?.join
			return result
		}
		finally {
			actorPool.stop
			&in		= null
			&out	= null
			&err	= null
			jProc	= null
		}
	}

	** Kill this process.  Returns this.
	This kill() {
		if (jProc == null) throw Err("Process not running")
		try {
			jProc.destroy
			return this
		}
		finally {
			actorPool.stop
			&in		= null
			&out	= null
			&err	= null
			jProc	= null
		}
	}
	
	Bool isAlive() {
		// hacky to use exception for flow control, but there
		// doesn't seem to be any other way to check state
		try {
			jProc.exitValue
		} catch (Err err) {
			if (Interop.toJava(err) is JIllegalThreadStateException)
				return true
		}
		return false
	}
	
	private Void checkRun() {
		if (jProc != null) throw Err.make("Process already run")
	}

	private Void checkNotRun() {
		if (jProc == null) throw Err.make("Process has not been created")
	}
}

internal const class PipeInToOut {
	private const Synchronized		thread
	private const Unsafe			inStreamRef
	private const Unsafe			outStreamRef
	private const Unsafe			processRef
	private const Duration			throttle
	
	new make(ActorPool actorPool, Process2 process, InStream? inStream, OutStream? outStream, Duration throttle) {
		this.thread			= Synchronized(actorPool)
		this.outStreamRef	= Unsafe(outStream)
		this.inStreamRef	= Unsafe(inStream)
		this.processRef		= Unsafe(process)
		this.throttle		= throttle
	}

	This pipe() {
		thread.async |->| {
			inStream	:= (InStream? )	inStreamRef .val
			outStream	:= (OutStream?)	outStreamRef.val
			process		:= (Process2)	processRef.val
			flushRequired := false
			
			if (inStream != null) {
				while (process.isAlive) {
					drain(inStream, outStream)

					// lets not hammer the thread waiting for key inputs!
					Actor.sleep(throttle)
				}
				drain(inStream, outStream)
			}
		}
		return this
	}
	
	Void join() {
		thread.actor.pool.stop
		thread.actor.pool.join
	}
	
	private Void drain(InStream inStream, OutStream? outStream) {
		flushRequired := false
		
		// read whole characters
		while (inStream.avail > 0) {
			ch := inStream.readChar
			if (ch != null) {
				flushRequired = true
				outStream?.writeChar(ch)
			}
		}
		if (flushRequired)
			outStream?.flush
	}
}
