
** Impersonates a build::BuildPod - can't be arsed with a dependency on build
internal class BuildPod {

			Str?	errMsg
			Str?	errCode
	private Obj?	buildPod
	
	private new err(Str errMsg, Str? errCode := null) {
		this.errMsg  = errMsg
		this.errCode = errCode
	}

	private new wrap(Obj buildPod) {
		this.buildPod = buildPod
	}
	
	Str		podName()	{ buildPod->podName		}
	Version	version()	{ buildPod->version		}
	Str[]	depends()	{ buildPod->depends		}
	Uri		outPodDir()	{ buildPod->outPodDir	}
	
	override Str toStr() { "${podName} ${version}" }		
	
	static new make(Str? filePath) {
		try {
			if (filePath == null)
				return BuildPod.err("File null")
			file := filePath.startsWith("file:") ? File(filePath.toUri, false) : File.os(filePath)
			if (file.isDir || file.exists.not || file.ext != "fan")
				return BuildPod.err("File not found: ${file.osPath}")
			
			// use Plastic because the default pod name when running a script (e.g. 'build_0') is already taken == Err
			buildPodType := Type.find("build::BuildPod")
			pod := PlasticCompiler().compileCode(file.readAllStr)
			obj := pod.types.find { it.fits(buildPodType) }?.make

			if (obj == null)
				return BuildPod.err(pod.types.join(",") { it.base.qname } + " does not extend build::BuildPod", "notBuildPod")
			
			// if it's not a BuildPod instance, return null - e.g. it may just be a BuildScript instance!
			return BuildPod.wrap(obj)
		} catch (Err err)
			return BuildPod.err(err.msg)
	}

}
