using concurrent
using compiler

** (Service) - 
** Compiles Fantom source code and afPlastic models into usable Fantom code.
** 
** Note: This class is available as a service in IoC v3 under the 'root' scope with an ID of 'afPlastic::PlasticCompiler'.
internal class PlasticCompiler {
	
	private static const AtomicInt podIndex	:= AtomicInt(1)

	** When generating code snippets to report compilation Errs, this is the number of lines of src 
	** code the erroneous line should be padded with. 
	** 
	** Value is mutable. Defaults to '5'.  
	public Int 	srcCodePadding := 5

	** Creates a 'PlasticCompiler'.
	new make(|This|? in := null) { in?.call(this) }
	
	** Compiles the given Fantom code into a pod. 
	** If no pod name is given, a unique one will be generated.
	Pod compileCode(Str fantomPodCode, Str? podName := null) {
		podName = podName ?: generatePodName

//		if (Pod.of(this).log.isDebug)
//			Pod.of(this).log.debug("Compiling code for pod: ${podName}\n${fantomPodCode}")
		
		try {
			input 		    := CompilerInput()
			input.podName 	= podName
	 		input.summary 	= "Alien-Factory Transient Pod"
			input.version 	= Version.defVal
			input.log.level = LogLevel.silent	// we'll raise our own Errs - less noise to std.out
			input.isScript 	= true
			input.output 	= CompilerOutputMode.transientPod
			input.mode 		= CompilerInputMode.str
			input.srcStrLoc	= Loc(podName)
			input.srcStr 	= fantomPodCode
	
			compiler 		:= Compiler(input)
			pod 			:= compiler.compile.transientPod
			return pod		

		} catch (CompilerErr err) {
			srcCode := SrcCodeSnippet(`${podName}`, fantomPodCode)
			throw CompilationErr(srcCode, err.line, err.msg, srcCodePadding)
		}
	}
	
	** Different pod names prevents "sys::Err: Duplicate pod name: <podName>".
	** We internalise podName so we can guarantee no duplicate pod names
	Str generatePodName() {
		index := podIndex.getAndIncrement.toStr.padl(3, '0')		
		return "afPlastic${index}"
	}
}

