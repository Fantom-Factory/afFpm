
internal class PodDependencies {

	PodResolvers	podResolvers
	FileCache		fileCache		:= FileCache()
	PodNode[]		initNodes		:= PodNode[,]
	Str:PodNode		podNodes		:= Str:PodNode[:]
	
	new make(FpmConfig config) {
		this.podResolvers	= PodResolvers(config, fileCache)
	}
	
	This addPod(Depend dependency) {
		podNode := resolveNode(dependency).pickLatestVersion
		if (podNode.podVersions.isEmpty)
			throw Err("Could not find pod file for '${dependency}'")
		initNodes.add(podNode)
		return this
	}
	
	This satisfyDependencies() {
		createProblemDomain
		reduceDomain
		pickLatestPods
		return this
	}
	
	Void createProblemDomain() {
		podNodes.vals.each { expandNode(it) }
	}
	
	Void reduceDomain() {
		
	}
	
	// in the event multiple pods satisfy the dependencies, pick the latest ones
	Void pickLatestPods() {
		podNodes.each { it.pickLatestVersion }
	}
	
	Void expandNode(PodNode node) {
		node.podVersions.each |podVersion| {
			podVersion.depends.each |depend| {
				innerNode := resolveNode(depend)
				expandNode(innerNode)
			}
		}
	}
	
	PodNode? resolveNode(Depend dependency) {
		podNodes.getOrAdd(dependency.name) {
			PodNode {
				it.name 		= dependency.name
				it.podVersions	= PodVersion[,]
			}
		}.addPodVersions(podResolvers.resolve(dependency))
	}	
	
	Str:PodFile getPodFiles() {
		podNodes.map { it.toPodFile }
	}
}


class PodNode {
	const 	Str		name
	PodVersion[]	podVersions
	Bool			expanded

	new make(|This|in) { in(this) }

	This pickLatestVersion() {
		podVersions = podVersions.sort |p1, p2| { p1.version <=> p2.version }
		podVersions = podVersions.isEmpty ? podVersions : [podVersions.last]
		return this
	}
	
	This addPodVersions(PodVersion[] pods) {
		podVersions = podVersions.addAll(pods).unique
		return this
	}
	
	PodFile toPodFile() {
		if (podVersions.isEmpty)
			throw Err("No pod version found for ${name}")
		if (podVersions.size > 1)
			throw Err("Too many versions for ${name}")

		return PodFile {
			it.name 	= this.name
			it.version	= this.podVersions.first.version
			it.file		= this.podVersions.first.file
		}
	}

	override Str toStr() 			{ name }
	override Int hash() 			{ name.hash }
	override Bool equals(Obj? that)	{ name == that?->name }
}

class PodVersion {
	const 	Str			name
	const 	Version		version
	const	Depend		depend
	const	File		file
	const	Depend[]	depends

	new make(|This|in) { in(this) }

	new makeFromProps(File file, Str:Str metaProps) {
		this.file 		= file
		this.name		= metaProps["pod.name"]
		this.version	= Version(metaProps["pod.version"], true)
		this.depends	= metaProps["pod.depends"].split(';').map { Depend(it, false) }.exclude { it == null }
		this.depend		= Depend("${name} ${version}")
	}

	override Str toStr() 			{ depend.toStr }
	override Int hash() 			{ depend.hash }
	override Bool equals(Obj? that)	{ depend == that?->depend }
}
