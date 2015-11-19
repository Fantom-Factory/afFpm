using util

abstract class FpmCmd : AbstractMain {
//	static const Log 		log 	:= FpmCmd#.pod.log
	
	static const FpmConfig	config	:= FpmConfig()
	
	override Int run() {
		super.parseArgs(Env.cur.args[1..-1])
		go
		return 0
	}

	virtual Void go() { }
}
