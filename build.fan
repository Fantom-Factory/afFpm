using build

class Build : BuildPod {

	new make() {
		podName = "afFpm"
		summary = "Fantom Pod Manager"
		version = Version("0.0.1")

		meta = [
			"proj.name"		: "Fantom Pod Manager",	
			"repo.tags"		: "sys",
			"repo.public"	: "false"
		]

		depends = [
			"sys   1.0.67 - 1.0",
			"util  1.0.67 - 1.0",
			"build 1.0.67 - 1.0",
//			"fanr  1.0.67 - 1.0",
			"compiler  1.0.67 - 1.0",			
		]

		srcDirs = [`test/`, `fan/`, `fan/public/`, `fan/public/cmds/`, `fan/internal/`, `fan/afPlastic/`]
		resDirs = [`doc/`]
	}
	
	@Target { help = "Compile to pod file and associated natives" }
	override Void compile() {
		// remove test pods from final build
		testPods := "afBounce afSizzle".split
		depends = depends.exclude { testPods.contains(it.split.first) }

		super.compile
		
//		afFpm::PublishCmd(this).run
	}
}

