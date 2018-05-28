
** A repository of pods; usually a local directory or a fanr repository.
** 
** Repository classes are instantiated by `FpmConfig`.
const mixin Repository {

	** Name of the repository.
	abstract Str name()
	
	** URL of where the repository is located.
	abstract Uri url()

	** Installs the given pod.
	** Returns the newly installed 'PodFile'.
	abstract PodFile	upload		(PodFile podFile)

	** Returns a file representation of the given pod.
	abstract File		download	(PodFile podFile)
	
	** Deletes the given pod.
	abstract Void		delete		(PodFile podFile)
	
	** Returns 'true' if this repository is local / hosted on the file system.
	abstract Bool		isLocal		()

	** Returns 'true' if this repository is remote / hosted on the Internet.
			 Bool		isRemote	() { !isLocal }
	
	** Returns 'true' if this repository is backed by fanr.
	abstract Bool		isFanrRepo	()

	** Returns 'true' if this repository is just a single directory of pods.
		 	 Bool		isDirRepo	() { !isFanrRepo }
	
	** Cleans up any cached information this repository may hold.
	abstract Void 		cleanUp		()
	
	** Returns the latest version of all pods this repository holds.
	abstract PodFile[]	resolveAll	()
	
	** Returns a list of all 'PodFiles' that match the given dependency.
	** 
	** Options are targeted at remote fanr repositories and may include:
	**  - 'maxPods  (Int)'     - the maximum number of pods to return. (defaults to 5).
	**  - 'corePods (Bool)'    - also query for core pods.
	**  - 'minVer   (Version)' - the min pod version to query for.
	**  - 'log      (Log)'     - query results will be logged to this.
	abstract PodFile[]	resolve		(Depend depend, Str:Obj? options)
	
	@NoDoc override Str toStr() 			{ "$name - $url" }
	@NoDoc override Int hash() 				{ url.hash }
	@NoDoc override Bool equals(Obj? that)	{ (that as Repository)?.url == url }
}

