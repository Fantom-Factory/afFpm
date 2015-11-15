
internal class TestDependencySatisfaction : Test {
	
	PodDependencies podDepends := PodDependencies(FpmConfig())

	override Void setup() {
		
	}
	
	Void testEasyHappyPath() {
		// everyone depends on the same versions
		addPod("afIoc 2.0", "afPlastic 1.2")
		addPod("afBed 2.0", "afPlastic 1.2")
		addPod("afPlastic 1.2")
		
		podDepends.satisfyDependencies
		
		verifyPodFiles("afIoc 2.0, afBed 2.0, afPlastic 1.2")
	}

	Void testPaths2() {
		addPod("afIoc 2.0", "afPlastic 1.0 - 2.0")
		addPod("afBed 2.0", "afPlastic 1.2")
		addPod("afPlastic 1.2")
		addPod("afPlastic 1.0")
		
		podDepends.satisfyDependencies
		
		verifyPodFiles("afIoc 2.0, afBed 2.0, afPlastic 1.2")
	}
	
	Void testPaths3() {
		addPod("afIoc 2.0", "afPlastic 1.2")
		
		podDepends.satisfyDependencies
		fail
	}

	Void testPaths4() {
		addPod("afIoc 2.0", "afPlastic 1.4 - 2.0")
		addPod("afBed 2.0", "afPlastic 1.2")
		addPod("afPlastic 1.4")
		addPod("afPlastic 1.2")
		
		podDepends.satisfyDependencies
		fail
	}
	
//	Void testPaths5() {
//		addPod("afIoc 2.0", "afPlastic 1.4 - 2.0")
//		addPod("afBed 2.0", "afPlastic 1.2")
//		addPod("afPlastic 1.4")
//		addPod("afPlastic 1.2")
//		
//		podDepends.satisfyDependencies
//		fail
//	}
	
	private Void verifyPodFiles(Str pods) {
		expected := pods.split(',').map { Depend(it) }
		actual 	 := podDepends.getPodFiles.vals.map { Depend("$it.name $it.version") }
		common	 := expected.intersection(actual)
		all		 := expected.union(actual)
		diff	 := all.removeAll(common)
		if (diff.isEmpty.not) {
			expected = expected.removeAll(common).insertAll(0, common)
			actual   = actual  .removeAll(common).insertAll(0, common)
			verifyEq(expected, actual)
		}
	}
	
	private Void addPod(Str pod, Str? depends := null) {
		podDepends.podResolvers.depends[Depend(pod)] = PodMeta {
			it.name 	= Depend(pod).name
			it.version	= Depend(pod).version
			it.depends	= depends?.split(',')?.map { Depend(it) } ?: Depend#.emptyList
			it.file		= File(``)
		}
	}
}
