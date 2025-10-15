using fanr::Repo
using fanr::PodSpec
using web::WebClient

internal const class RemoteFanrRepository : Repository {
	private  const CorePods	corePods	:= CorePods()
	private	 const Repo		repo
	override const Str		name
	override const Uri		url
	override const Bool		isLocal		:= false
	override const Bool		isFanrRepo	:= true

	new make(Str name, Uri url, Str? username := null, Str? password := null) {
		this.name	= name
		this.url	= url
		this.repo	= Repo.makeForUri(url, username, password)
		
		// TODO maybe online repos can switch themselves off if they find an error - so we can continue to operate without them
	}

	override PodFile upload(PodFile podFile) {
		repo.publish(podFile.file)
		return PodFile(podFile.name, podFile.version, podFile.dependsOn, `fanr://${podFile.name}/${podFile.depend}`, this)
	}
	
	override File download(PodFile podFile) {
		spec := repo.find(podFile.name, podFile.version, true)
		buff := repo.read(spec).readAllBuf
		return buff.toFile(`fanr://${name}/${podFile.depend}`)
	}
	
	override Void delete(PodFile podFile) {
		// we do not depend on afFanr. Instead, directly send a POST request representing afFanr's WebRepo uninstall functionality.
		c:= (WebClient) repo->prepare("POST", `${url.toStr}uninstall/${podFile.name}/${podFile.version}`)
		
		c.writeReq.readRes
		
		// if not 200, then assume a JSON error message 
		if (c.resCode != 200) repo->parseRes(c)

    	Str:Obj? jsonRes := (Str:Obj?) repo->parseRes(c)
		if(!jsonRes.containsKey("uninstalled")) {
			throw Err("Missing 'uninstalled' in JSON response")
		}
		return;
	}
	
	override PodFile[] resolve(Depend depend, Str:Obj? options) {
		corePods := (Bool)		options.get("corePods",  false) 
		maxPods	 := (Int )		options.get("maxPods", 50)
		minVer	 := (Version?)	options.get("minVer", null)
		log		 := (Log?)		options.get("log")
		errLog	 := (Log?)		options.get("errLog")

		if (!corePods && this.corePods.isCorePod(depend.name)) {
			return PodFile#.emptyList
		}

		log?.debug("Querying ${name} for ${depend}" + ((minVer == null) ? "" : " ( > $minVer)"))
		specs := [,]

		
		specs = tryQuery(depend.toStr, maxPods, errLog)

		files  := specs
			.findAll |PodSpec spec->Bool| {
				(minVer == null) ? true : spec.version > minVer
			}
			.map |PodSpec spec->PodFile| {
				PodFile(spec.name, spec.version, spec.depends, `fanr://${name}/${depend}`, this)
			}.sort as PodFile[]

		if (files.size > 0)
			log?.info(" - found ${depend.name} " + files.join(", ") { it.version.toStr })

		return files.sort
	}
	
	
	override PodFile[] resolveAll() {
		PodSpec[] all := tryQuery("*", 11)
		PodSpec[] latestVers := [,];
		all.each |pod| {
			PodSpec? inList := latestVers.find |lv| { lv.name == pod.name };
			if(inList == null) {
				latestVers.add(pod)
			} else {
				if(inList.version < pod.version) {
					latestVers.remove(inList)
					latestVers.add(pod)
				}
			}
		}

		return latestVers.map |PodSpec spec->PodFile| {
			PodFile(spec.name, spec.version, spec.depends, `fanr://${spec.name}/${spec.name} ${spec.version}`, this) 
		}
		
	}

	override Void cleanUp() { }
	
	override Str dump() { "Remote Fanr Repo\n - ${url}" }
	
	** Attempts to query our remote repo. On fail, prints error to errLog and returns an empty list.
	private PodSpec[] tryQuery(Str queryString, Int? maxPods := 11, Log? errLog := null) {
		try {
			return repo.query(queryString, maxPods) // may throw if repo is offline or we pass an invalid parse string
		} catch(Err e) {			
			if(e is IOErr) {	
				errLog?.info("\nUnable to query repo '${name}' (offline?)")
				return PodFile#.emptyList
			}
			
			// we don't want to print a whole stack trace out when not debugging (especially as catching here is common)
			errLog?.info("\nUnable to query repo '${name}':")
			if(errLog.level == LogLevel.debug) {
				errLog?.debug(e.traceToStr)
			} else {
				errLog?.info(e.msg)
			}

			return PodFile#.emptyList
		}
	}
}