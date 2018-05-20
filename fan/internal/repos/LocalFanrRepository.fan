
internal const class LocalFanrRepository : Repository {
	private static const Regex	podRegex	:= "(.+)-(.+)\\.pod".toRegex

	override const Str		name
	override const Uri		url
	override const Bool		isLocal			:= true
	override const Bool		isFanrRepo		:= true
	private  const LocalRef	fileCacheRef	:= LocalRef(#fileCache.qname) |->Obj?| { File:PodFile?[:] }
	private  const LocalRef	nameCacheRef	:= LocalRef(#nameCache.qname) |->Obj?| { Str:PodName[][:] }
	private  const File		dir
	private  File:PodFile?	fileCache()		{ fileCacheRef.val }
	private  Str:PodName[]	nameCache()		{ nameCacheRef.val }

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
		dir.plus(`${podFile.name}/${podFile.name}-${podFile.version}.pod`)
	}

	override Void delete(PodFile podFile) {
		download(podFile).delete
	}

	override PodFile[] resolve(Depend depend, Str:Obj? options) {
		podNames := (PodName[]) nameCache.getOrAdd(depend.name) |->PodName[]| {
			podDir := dir.plus(depend.name.toUri.plusSlash, true)
			return podDir.listFiles(podRegex).map |file->PodName?| { PodName(file) }.exclude { it == null }
		}
		return podNames.findAll { it.fits(depend) }.map { getOrMake(it.file) }
	}

	override PodFile[] resolveAll() {
		dir.listDirs.map |repoDir->PodName?| {
			repoDir.listFiles(podRegex).map { PodName(it) }.exclude { it == null }.sort.last
		}.exclude { it == null }.map |PodName pod->PodFile| { getOrMake(pod.file) }
	}
	
	override Void cleanUp() {
		fileCacheRef.cleanUp
		nameCacheRef.cleanUp
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

internal class PodName {
	private static const Regex	podRegex	:= "(.+)-(.+)\\.pod".toRegex

	Str		name
	Version	ver
	File	file

	static new makeFromFile(File file) {
		matcher := podRegex.matcher(file.name)
		if (!matcher.find)
			return null

		name	:= matcher.group(1)
		version := Version(matcher.group(2), false)

		if (version == null)
			return null

		return PodName {
			it.file = file
			it.name = name
			it.ver	= version
		}
	}

	private new make(|This| f) { f(this) }
	
	Bool fits(Depend depend) {
		depend.name == this.name && depend.match(this.ver)
	}

	override Int compare(Obj that) {
		ver <=> (that as PodName).ver
	}
}
