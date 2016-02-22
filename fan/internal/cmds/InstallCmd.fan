using util
using fanr

** Installs a pod to a repository.
internal class InstallCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name or location of the repository to install to." }
	Str repo	:= "default"

	@Opt { aliases=["p"]; help="The pod to install. May be a file location or a search query." }
	Str? pod

	override Int go() {
//		if (pod.exists.not)
//			pod = podManager.findPodFile(pod.toStr, false)?.file ?: pod
//		podManager.publishPod(pod, repo)

		
		// TODO check if pod is a local file
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
		
		return 0
	}
	
	override Bool argsValid() {
		pod != null
	}	
}
