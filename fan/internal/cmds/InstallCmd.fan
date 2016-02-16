using util
using fanr

internal class InstallCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name of the file / fanr repository to publish to" }
	Str repo	:= "default"

	@Opt { aliases=["p"]; help="The pod to query for" }
	Str? pod

	new make() { }

	override Void go() {		
		query := pod.replace("@", " ")
		fpmConfig.fanrRepos.find |url, name->Bool| {
			
			repo  := fpmConfig.fanrRepo(name)
			specs := repo.query(query, 1)
			if (specs.isEmpty) return false
			
			log.info("  Downloading ${specs.first} from ${name}")
			temp := File.createTemp("afFpm-", ".pod")
			out  := temp.out
			repo.read(specs.first).pipe(out)
			out.close
			
			podManager.publishPod(temp, this.repo)
			return true
		}		
	}
	
	override Bool argsValid() {
		pod != null
	}
}