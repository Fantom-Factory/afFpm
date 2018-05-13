
internal class SinglePodRepository : Repository {
	override Str		name
	override Uri		url
	override Bool		isLocal	:= true
	private	 File		file
	private	 PodFile[]	podFile
	private	 Depend[]?	dependsOn
	
	new make(File file) {
		this.name		= file.name
		this.url		= file.normalize.uri
		this.file		= file
		this.podFile	= [readFile(file)]
	}

	override Void		upload		(PodFile podFile)	{ throw UnsupportedErr() }
	override File		download	(PodFile podFile)	{ file }
	override Void		delete		(PodFile podFile)	{ file.delete }
	override PodFile[]	resolveAll	()					{ podFile }
	override PodFile[]	resolve		(Depend depend)		{ podFile.first.fits(depend) ? podFile : PodFile#.emptyList }
	override Depend[]	dependencies(PodFile podFile)	{ podFile == this.podFile.first ? dependsOn : throw UnknownPodErr(podFile.depend.toStr) }
	
	private PodFile readFile(File file) {
		if (file.exists.not)
			throw IOErr("File not found: ${file.normalize.osPath}")

		zip	:= Zip.read(file.in)
		try {
			File? 		entry
			[Str:Str]?	metaProps
			while (metaProps == null && (entry = zip.readNext) != null) {
				if (entry.uri == `/meta.props`)
					metaProps = entry.readProps
			}
			if (metaProps == null)
				throw IOErr("Could not find `/meta.props` in pod file: ${file.normalize.osPath}")

			this.dependsOn = metaProps["pod.depends"].split(';').map { Depend(it, true) }
			
			return PodFile(metaProps["pod.name"], Version(metaProps["pod.version"], true), file.normalize.uri, this)

		} finally {
			zip.close
		}	
	}
}
