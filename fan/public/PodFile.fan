
** Represents a pod version with a backing file.
const class PodFile {
	** The name of this pod.
	const Str		name
	
	** The version of this pod.
	const Version	version
	
	** Where the pod is located.
	** May have a local 'file:' or a remote 'http:' scheme.
	const Uri		url
	
	internal new make(|This|in) { in(this) }
	
	internal static new makeFromFile(File file) {
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
	
	** The backing file for this pod.
	** Convenience for 'podFile.url.toFile'.
	File file() {
		url.toFile
	}
	
	** This pod version expressed as a dependency.
	** Convenience for:
	** 
	**   syntax: fantom
	**   Depend("$name $version")
	Depend asDepend() {
		Depend("$name $version")
	}

	@NoDoc
	override Str toStr() 			{ "$name $version" }
	
	@NoDoc
	override Int hash() 			{ file.hash }
	
	@NoDoc
	override Bool equals(Obj? that)	{ file == (that as PodFile)?.file }
}
