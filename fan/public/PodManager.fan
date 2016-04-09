
//** (Service) -
** The public API for FPM.
const mixin PodManager {
	
	** Creates a 'PodManager' instance.
	static new make(FpmConfig? fpmConfig := null) {
		fpmConfig == null
			? PodManagerImpl()
			: PodManagerImpl { it.fpmConfig = fpmConfig }
	}
	
	** Returns 'PodFiles' from the local repositories that match the given query.
	abstract PodFile[] queryLocalRepositories(Str query)

	** Publishes a pod file to the given repository.
	** 
	** 'repo' may be:
	**  - a named local repository. Example, 'default'
	**  - a named remote repository. Example, 'fantomFactory'
	**  - the directory of a local repository. Example, 'C:\repo-release\'
	**  - the URL of a remote repositry. Example, 'http://pods.fantomfactory.org/fanr/'
	**  
	** Returns a 'PodFile' representing the newly published pod.
	** 
	** 'repo' defaults to 'default' if not specified.
	abstract PodFile publishPod(File pod, Str? repo := null, Str? username := null, Str? password := null)
	
	** Deletes the named pod from the local repository.
	abstract Void unPublishPod(Str pod, Str? repo)
	
}

@NoDoc
const class PodManagerImpl : PodManager {
	const Log 			log 			:= PodManager#.pod.log

	const FpmConfig		fpmConfig
	
	@NoDoc	// used by afBuild::PublishPodTask
	static new makeWithLog(Log log) {
		PodManagerImpl { it.log = log }
	}

	@NoDoc
	new make(|This|? in := null) {
		in?.call(this)
		if (fpmConfig == null)
			fpmConfig = FpmConfig()
	}

	override PodFile[] queryLocalRepositories(Str query) {
		query = query.replace("@", " ")
		if (query.contains(" ").not)
			query += " 0+" 
		return PodResolvers(fpmConfig, File#.emptyList, FileCache()).resolve(Depend(query)).sort.map { it.toPodFile }
	}
	
	override PodFile publishPod(File file, Str? repo := null, Str? username := null, Str? password := null) {
		if (file.exists.not)
			throw IOErr(ErrMsgs.mgr_podFileNotFound(file))

		podFile		:= PodFile(file)
		dstPodUrl	:= null as Uri
		
		// note the manual indent!
		repoName := repo ?: "default"

		// publish to a file repo
		if (fpmConfig.fileRepos.containsKey(repoName)) {
			repoFile := fpmConfig.fileRepos[repoName] + `${podFile.name}/${podFile.name}-${podFile.version}.pod`
			log.info("Publishing ${podFile} to ${repoName} (${repoFile.osPath})")

			podFile.file.copyTo(repoFile, ["overwrite" : true])
			dstPodUrl = repoFile.normalize.uri
		} else
		
		// publish to a named fanr repo
		if (fpmConfig.fanrRepos.containsKey(repoName)) {
			fanrRepo := fpmConfig.fanrRepo(repoName, username, password)
			log.info("Publishing ${podFile} to ${repoName} (${fanrRepo.uri})")

			fanrRepo.publish(podFile.file)
			dstPodUrl = fpmConfig.fanrRepos[repoName].plusSlash + `pod/${podFile.name}/${podFile.version}`
		} else

		// publish to an explicit fanr repo
		if (repoName.startsWith("http:") || repoName.startsWith("https:")) {
			fanrRepo := FpmConfig.toFanrRepo(repoName.toUri)
			log.info("Publishing ${podFile} to ${repoName} (${fanrRepo.uri})")
			
			fanrRepo.publish(podFile.file)
			dstPodUrl = repoName.toUri.plusSlash + `pod/${podFile.name}/${podFile.version}`
		}

		// allow repo to be a dir path, but then remove the version suffix
		else {
			repoFile := FileUtils.toRelDir(File(``), repo) + `${podFile.name}.pod`
			log.info("Publishing ${podFile} to ${repoName} (${repoFile.osPath})")

			podFile.file.copyTo(repoFile, ["overwrite" : true])
			dstPodUrl = repoFile.normalize.uri
		}

		return PodFile {
			it.name 	= podFile.name
			it.version	= podFile.version
			it.url		= dstPodUrl
		}
	}

	override Void unPublishPod(Str pod, Str? repo) {
		repoName := repo ?: "default"
		repoDir := fpmConfig.fileRepos[repoName]
		if (repoDir == null)
			repoDir = FileUtils.toFile(repoName)
		if (repoDir.exists.not) {
			log.info("Repo does not exist: ${repoDir.osPath}")
			return
		}
		podDep := Depend(pod.replace("@", " "), true)
		podFile := repoDir + podDep.name.toUri.plusSlash + (podDep.toStr.replace(" ", "-") + ".pod").toUri
		if (podFile.exists.not) {
			log.info("Pod does not exist: ${podFile.osPath}")
			return
		}
		podFile.delete
		log.info("Deleted Pod - ${podFile.osPath}")
	}
}
