
class PodMeta {
	const 	Str			name
	const 	Version		version
	const 	File		file
	const	Depend[]	depends
	
			Bool		inRepo
			Bool		versionFixed
	
	new make(|This|in) { in(this) }

	new makeFromProps(File file, Str:Str metaProps) {
		this.file 		= file
		this.name		= metaProps["pod.name"]
		this.version	= Version(metaProps["pod.version"], true)
		this.depends	= metaProps["pod.depends"].split(';').map { Depend(it, false) }.exclude { it == null }
	}
	
	PodFile toPodFile() {
		PodFile {
			it.name 	= this.name
			it.version	= this.version
			it.file		= this.file
		}
	}
	
	override Str toStr() {
		"$name $version - $file.normalize.osPath"
	}
}
