
internal class ProcessFactory {

	static Process fanProcess(Str[] cmd) {
		makeJavaProcess("fanx.tools.Fan", "fan", cmd)
	}

	static Process fantProcess(Str[] cmd) {
		makeJavaProcess("fanx.tools.Fant", "fant", cmd)
	}
	
	private static Process makeJavaProcess(Str javaCmd, Str fanCmd, Str[] cmd) {
		homeDir		:= Env.cur.homeDir.normalize
		classpath	:= [homeDir + `lib/java/sys.jar`, homeDir + `lib/java/jline.jar`].join(File.pathSep) { it.osPath } 
		javaOpts	:= Env.cur.config(Pod.find("sys"), "java.options", "")
		args 		:= ["java", javaOpts, "-cp", classpath, "-Dfan.home=${homeDir.osPath}", javaCmd].addAll(cmd)
		process		:= Process(args)
		processRef	:= Unsafe(process)
		processCmd	:= Unsafe(fanCmd)

		Env.cur.addShutdownHook |->| {
			try  {
				pro := (Process) processRef.val
				Env.cur.err.printLine("Killing Process: ${processCmd.val} " + pro.command[6..-1].join(" "))
				pro.kill
			} catch (Err err) {
				Env.cur.err.printLine("Kill failed: ${err.msg}")
			}
		}

		return process
	}
}
