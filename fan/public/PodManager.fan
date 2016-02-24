
** (Service) -
** The public API - manager is a shite name though!
const class PodManager {
	const Log 			log 			:= PodManager#.pod.log

	const FpmConfig		fpmConfig

	private const CorePods	corePods	:= CorePods()

	@NoDoc
	new make(|This|? in := null) {
		in?.call(this)
		if (fpmConfig == null)
			fpmConfig = FpmConfig()
	}

	** Publishes a pod file to the given named repository.
	** 
	** 'repo' should be the name of a local file repository, or a directory path.
	** Directory paths may be in URI form or an OS path.
	** 
	**   syntax: fantom
	**   publishPod(podFile, "default") 
	**   publishPod(podFile, "C:\\repo")
	**  
	** Returns a 'PodFile' of the pod in the repository.
	** 
	** 'repo' defaults to 'default' if not specified.
	PodFile publishPod(File pod, Str? repo := null) {
		_publishPod(PodFile(pod), repo)
	}

//	Void installToLocal() {
//		// TODO check if pod is a local file
//		query := pod.replace("@", " ")
//		fpmConfig.fanrRepos.find |url, name->Bool| {
//			
//			repo  := fpmConfig.fanrRepo(name)
//			specs := repo.query(query, 1)
//			if (specs.isEmpty) return false
//			
//			log.info("  Downloading ${specs.first} from ${name}")
//			temp := File.createTemp("afFpm-", ".pod")
//			out  := temp.out
//			repo.read(specs.first).pipe(out)
//			out.close
//			
//			podManager.publishPod(temp, this.repo)
//			return true
//		}
//		
//	}


	Void uninstallPod(Str pod, Str repo) {
		// TODO check repo exists
		podDep := Depend(pod.replace("@", " "), true)
		podFile := fpmConfig.fileRepos[repo] + podDep.name.toUri.plusSlash + (podDep.toStr.replace(" ", "-") + ".pod").toUri
		if (podFile.exists.not) {
			log.info("Pod does not exist - ${podFile.osPath}")
			return
		}
		podFile.delete
		log.info("Deleted Pod - ${podFile.osPath}")
	}

	** Publishes all pods from the given directory.
	**  
	** 'repo' should be the name of a local file repository, or a directory path.
	** Directory paths may be in URI form or an OS path.
	**  
	** 'repo' defaults to 'default' if not specified.
	Void installAllPodsFromDir(File dir, Str? repo := null) {
		log.info("Publishing pods from ${dir.osPath} into repo '" +  (repo ?: "default") + "'...")
		podFiles := dir.listFiles(".+\\.pod".toRegex).exclude {
			corePods.isCorePod(it.basename) || it.basename == "afFpm"
		}
		if (podFiles.isEmpty)
			log.info("  No pods found")
		
		podFiles.each |file| {
			podFile := PodFile(file)
			_publishPod(podFile, repo)
		}
	}

	PodFile? findPodFile(Str query, Bool checked := true) {
		findAllPodFiles(query).last ?: (checked ? throw Err("Could not find pod '${query}'") : null)
	}

	PodFile[] findAllPodFiles(Str query) {
		query = query.replace("@", " ")
		if (query.contains(" ").not)
			query += " 0+" 
		return PodResolvers(fpmConfig, File#.emptyList, FileCache()).resolve(Depend(query)).sort.map { it.toPodFile }
	}
	
	** Returns a 'PodFile' of the pod in the repository.
	private PodFile _publishPod(PodFile podFile, Str? repo := null) {
		if (podFile.file.exists.not)
			throw IOErr(ErrMsgs.mgr_podFileNotFound(podFile.file))

		dstPodUrl	:= null as Uri
		
		// note the manual indent!
		repoName := repo ?: "default"
		log.info("  Publishing ${podFile} to ${repoName}")

		// publish to a file repo
		if (fpmConfig.fileRepos.containsKey(repoName)) {
			repoFile := fpmConfig.fileRepos[repoName] + `${podFile.name}/${podFile.name}-${podFile.version}.pod`
			podFile.file.copyTo(repoFile, ["overwrite" : true])
			dstPodUrl = repoFile.normalize.uri
		} else
		
		// publish to a named fanr repo
		if (fpmConfig.fanrRepos.containsKey(repoName)) {
			fpmConfig.fanrRepo(repoName).publish(podFile.file)
			dstPodUrl = fpmConfig.fanrRepos[repoName].plusSlash + `pod/${podFile.name}/${podFile.version}`
		} else

		// publish to an explicit fanr repo
		if (repoName.startsWith("http:") || repoName.startsWith("https:")) {
			FpmConfig.toFanrRepo(repoName.toUri).publish(podFile.file)
			dstPodUrl = repoName.toUri.plusSlash + `pod/${podFile.name}/${podFile.version}`
		}

		// allow repo to be a dir path, but then remove the version suffix
		else {
			repoFile := FileUtils.toRelDir(File(``), repo) + `${podFile.name}.pod`
			podFile.file.copyTo(repoFile, ["overwrite" : true])
			dstPodUrl = repoFile.normalize.uri
		}

		return PodFile {
			it.name 	= podFile.name
			it.version	= podFile.version
			it.url		= dstPodUrl
		}
	}
}
