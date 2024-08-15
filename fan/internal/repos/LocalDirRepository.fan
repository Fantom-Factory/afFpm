
internal const class LocalDirRepository : Repository {
	override const Str		name
	override const Uri		url
	override const Bool		isLocal			:= true
	override const Bool		isFanrRepo		:= false
	private  const LocalRef	fileCacheRef	:= LocalRef(#fileCache.qname) |->Obj?| { File:PodFile?[:] }
	private  const File		dir
	private  File:PodFile?	fileCache()		{ fileCacheRef.val }
	
	new make(Str name, File dir) {
		this.name	= name
		this.dir	= dir.normalize
		this.url	= this.dir.uri
		
		if (!dir.isDir)
			throw IOErr("Not a directory: ${this.dir.osPath}")
	}

	override PodFile upload(PodFile podFile) {
		newFile := download(podFile)

		// turns out that file locking is a REAL problem on Windows and happens ALL the time
		// a comment in this stackoverflow post suggests avoiding Java NIO - which Fantom.copyTo() now uses
		// https://stackoverflow.com/questions/4179145/release-java-file-lock-in-windows
		// https://github.com/fantom-lang/fantom/commit/5ad35635544534e697ae5329cda76bcb85272633
		out :=  newFile.out
		try		podFile.file.in.pipe(out)
		finally	out.close

		// or... herein enter file locking problems on Windows!
//		podFile.file.copyTo(newFile, ["overwrite" : true])

		return getOrMake(newFile)
	}

	override File download(PodFile podFile) {
		dir.plus(`${podFile.name}.pod`)
	}

	override Void delete(PodFile podFile) {
		download(podFile).delete
	}

	override PodFile[] resolveAll() {
		dir.listFiles(Regex.glob("*.pod")).map { getOrMake(it) }.exclude { it == null }.sort
	}

	override PodFile[] resolve(Depend depend, Str:Obj? options) {
		file 	:= dir.plus(`${depend.name}.pod`)
		podFile	:= getOrMake(file)

		if (podFile == null)
			return PodFile#.emptyList
		
		if (!podFile.fits(depend))
			return PodFile#.emptyList
		
		return [podFile]
	}
	
	override Void cleanUp() {
		fileCacheRef.cleanUp
	}
	
	override Str dump() {
		str := ""
		str += "Local Dir Repo @ ${dir.osPath}\n"
		if (dir.exists == false)
			str += " - (Dir does not exist)\n"
		num := 0
		fileCache.vals.sort.each |PodFile pod| {
			if (pod.isCorePod)
				num ++
			else
				str += " - $pod.name $pod.version\n"
		}
		if (num > 0)
			str += " - ${num} x Fantom core pods\n"
		return str
	}

	private PodFile? getOrMake(File file) {
		fileCache.getOrAdd(file) |->PodFile?| {
			metaProps		:= readMetaProps(file)
			if (metaProps == null)
				return null
			podName			:= metaProps["pod.name"]
			podVersion		:= Version(metaProps["pod.version"], true)
			podDependsOn	:= metaProps["pod.depends"].split(';').exclude { it.isEmpty }.map { Depend(it, true) }
			return PodFile(podName, podVersion, podDependsOn, file.uri, this)
		}
	}

	private [Str:Str]? readMetaProps(File file) {
		// pods may not exist, but they must be valid
		if (file.exists.not)
			return null		
		return FileUtils.readMetaProps(file)
	}
}
