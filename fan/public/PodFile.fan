
** Represents a pod file.
const class PodFile {
	** The name of this pod.
	const Str		name
	
	** The version of this pod.
	const Version	version
	
	** Where the pod is located.
	const Uri		url
	
	internal new make(|This|in) { in(this) }
	
	** The backing file of this pod.
	File file() {
		url.toFile
	}
	
	** This pod versions expressed as a dependency.
	** Convenience for:
	** 
	**   syntax: fantom
	**   Depend("$name $version")
	Depend asDepend() {
		Depend("$name $version")
	}

	static new makeFromFile(File file) {
		zip	:= Zip.read(file.in)
		try {
			File? 		entry
			[Str:Str]?	metaProps
			while (metaProps == null && (entry = zip.readNext) != null) {
				if (entry.uri == `/meta.props`)
					metaProps = entry.readProps
			}
			if (metaProps == null)
				throw Err("Pod file ${file.normalize.osPath} does not contain `/meta.props`")
			return PodVersion(file, metaProps).toPodFile

		} finally {
			zip.close
		}	
	}

	override Str toStr() 			{ "$name $version" }
	override Int hash() 			{ file.hash }
	override Bool equals(Obj? that)	{ file == (that as PodFile)?.file }
}
