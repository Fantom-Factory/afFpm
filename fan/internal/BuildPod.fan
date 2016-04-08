
** Impersonates a build::BuildPod - can't be arsed with a dependency on build
internal class BuildPod {

			Str?	errMsg
	private Obj?	buildPod
	
	private new err(Str errMsg) {
		this.errMsg = errMsg
	}

	private new wrap(Obj buildPod) {
		this.buildPod = buildPod
	}
	
	Str		podName()	{ buildPod->podName		}
	Version	version()	{ buildPod->version		}
	Str[]	depends()	{ buildPod->depends		}
	Uri		outPodDir()	{ buildPod->outPodDir	}
	
	static new make(Str? filePath) {
		try {
			if (filePath == null)
				return null
			file := filePath.startsWith("file:") ? File(filePath.toUri, false) : File.os(filePath)
			if (file.isDir || file.exists.not || file.ext != "fan")
				return null
			
			// use Plastic because the default pod name when running a script (e.g. 'build_0') is already taken == Err
			buildPodType := Type.find("build::BuildPod")
			obj := PlasticCompiler().compileCode(file.readAllStr).types.find { it.fits(buildPodType) }?.make

			// if it's not a BuildPod instance, return null - e.g. it may just be a BuildScript instance!
			return BuildPod.wrap(obj)
		} catch (Err err)
			return BuildPod.err(err.msg)
	}

}
