using util
using fanr

internal class InstallCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name of the file / fanr repository to publish to" }
	Str repo	:= "default"

	@Arg { help="The pod to query for" }
	Str? query
	
	new make() { }

	override Void go() {
		
		fpmConfig.fanrRepos.find |url, id->Bool| {
			repo	:= fpmConfig.fanrRepo(id)
			specs	:= repo.query(query.replace("@", " "), 1)
			if (specs.isEmpty) return false
			
			log.info("  Downloading ${specs.first} from ${id}")
			temp := File.createTemp("afFpm-", ".pod")
			out  := temp.out
			repo.read(specs.first).pipe(out)
			out.close
			
			podManager.publishPod(temp, this.repo)
			return true
		}		
	}
	
	override Bool argsValid() {
		true
	}
}