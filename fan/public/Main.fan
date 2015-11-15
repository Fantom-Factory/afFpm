using util

class Main : AbstractMain {
	
	@Arg
	Str? cmd
	
	override Int run() {
		echo("cmd")
//		if (cmd == "publish")
		return 0
	}
}

