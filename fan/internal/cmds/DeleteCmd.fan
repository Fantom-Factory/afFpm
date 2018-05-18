
** Deletes a pod from a local repository. (Remote fanr repositories don't support pod deletion.)
** 
** The repository may be:
**  - a named local repository (e.g. 'default')
**  - the location of directory (e.g. 'C:\lib-release\')
**
** Examples: 
**   C:\> fpm delete myPod
**   C:\> fpm delete myPod@2.0.10 -r release
** 
@NoDoc	// Fandoc is only saved for public classes
class DeleteCmd : FpmCmd {
	
	@Opt { aliases=["r"]; help="Name or location of the repository to delete from (defaults to 'default')" }
	Repository repo

	@Arg { help="The pod to delete" }
	Depend target
	
	new make(|This| f) : super(f) {
		if (repo == null) repo = fpmConfig.repository("default")
	}

	override Int run() {
		podFile := repo.resolve(target, [:]).first
		if (podFile == null) {
			log.warn("$target not found in $repo")
			return invalidArgs
		}
	
		log.info("FPM deleting ${podFile.depend} from ${repo.name}")
		podFile.delete
		return 0
	}	
}
