using afBuild
using build

class Build : BuildPod {

	new make() {
		podName = "afFpm"
		summary = "Fantom Pod Manager"
		version = Version("0.0.1.003")

		meta = [
			"proj.name"		: "Fantom Pod Manager",	
			"testPods"		: "afBounce afSizzle",
			"repo.tags"		: "sys",
			"repo.public"	: "false"
		]

		depends = [
			"sys        1.0.67 - 1.0",
			"fanr       1.0.67 - 1.0",
			"util       1.0.67 - 1.0",
			"concurrent 1.0.67 - 1.0",			
			"compiler   1.0.67 - 1.0",	// for afPlastic			
		]

		srcDirs = [`fan/`, `fan/afPlastic/`, `fan/internal/`, `fan/internal/cmds/`, `fan/internal/util/`, `fan/public/`, `test/`]
		resDirs = [`doc/`, `res/`]
		
		docApi	= true
		docSrc	= true
	}
	
	@Target { help = "Compile to pod file and associated natives" }
	override Void compile() {
		BuildTask(this) { it.publishPod = false }.run
	}

	@Target { help = "Builds, publishes, and Hg tags a new pod release" }
	Void release() {
		ReleaseTask(this).run
	}
}

