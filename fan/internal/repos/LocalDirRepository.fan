
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

	override Void upload(PodFile podFile) {
		newFile := download(podFile)
		podFile.file.copyTo(newFile, ["overwrite" : true])
	}

	override File download(PodFile podFile) {
		dir.plus(`${podFile.name}.pod`)
	}

	override Void delete(PodFile podFile) {
		download(podFile).delete
	}

	override PodFile[] resolveAll() {
		dir.listFiles(Regex.glob("*.pod")).map { getOrMake(it) }.exclude { it == null }
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
