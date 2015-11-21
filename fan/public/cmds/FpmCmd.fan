using util

abstract class FpmCmd : AbstractMain {
	override Log 		log 	:= FpmCmd#.pod.log
	
	override Int run() {
		super.parseArgs(Env.cur.args[1..-1])
		go
		return 0
	}

	virtual Void go() { }
}
