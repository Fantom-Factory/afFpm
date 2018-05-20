
internal const class SinglePodRepository : Repository {
	override const Str		name
	override const Uri		url
	override const Bool		isLocal		:= true
	override const Bool		isFanrRepo	:= false
			 const PodFile	podFile
	private	 const File		file
	
	new make(File file) {
		this.name		= file.name
		this.url		= file.normalize.uri
		this.file		= file
		
		metaProps		:= readMetaProps(file)
		podName			:= metaProps["pod.name"]
		podVersion		:= Version(metaProps["pod.version"], true)
		podDependsOn	:= metaProps["pod.depends"].split(';').exclude { it.isEmpty }.map { Depend(it, true) }
		this.podFile	= PodFile(podName, podVersion, podDependsOn, this.url, this)
	}

	override Void		upload		(PodFile podFile)		{ throw UnsupportedErr() }
	override File		download	(PodFile podFile)		{ file }
	override Void		delete		(PodFile podFile)		{ file.delete }
	override PodFile[]	resolveAll	()						{ [podFile] }
	override PodFile[]	resolve		(Depend d, Str:Obj? o)	{ podFile.fits(d) ? podFile : PodFile#.emptyList }
	override Void 		cleanUp		()						{ }
		
	private Str:Str readMetaProps(File file) {
		if (file.exists.not)
			throw IOErr("File not found: ${file.normalize.osPath}")
		return FileUtils.readMetaProps(file)
	}
}
