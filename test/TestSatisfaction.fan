
internal class TestSatisfaction : Test {
	
	StubRepository? 	repository
	Satisfier?			satisfier

	override Void setup() {
		repository = StubRepository()
	}
	
	Void testEasyHappyPath() {
		// everyone depends on the same versions
		addDep("afBed 2.0", "afPlastic 1.2")
		addDep("afIoc 2.0", "afPlastic 1.2")
		addDep("afPlastic 1.2")
		
		satisfyDependencies("afBed 2.0, afIoc 2.0")
		
		verifyPodFiles("afIoc 2.0, afBed 2.0, afPlastic 1.2")
	}

	Void testPaths2() {
		addDep("afIoc 2.0", "afPlastic 1.0 - 2.0")
		addDep("afBed 2.0", "afPlastic 1.2")
		addDep("afPlastic 2.0")
		addDep("afPlastic 1.2")

		addDep("afPlastic 3.0")
		addDep("afPlastic 1.4")
		
		satisfyDependencies("afBed 2.0, afIoc 2.0")
		
		verifyPodFiles("afIoc 2.0, afBed 2.0, afPlastic 1.2")
	}
	
	Void testPaths3() {
		addDep("afIoc 2.0", "afPlastic 1.2")
		
		satisfyDependencies("afIoc 2.0")
		verify(satisfier.resolvedPods.isEmpty)
	}

	Void testPaths4() {
		addDep("afBed 2.0", "afPlastic 1.2")
		addDep("afIoc 2.0", "afPlastic 1.4 - 2.0")
		addDep("afPlastic 1.4")
		addDep("afPlastic 1.2")
		
		satisfyDependencies("afBed 2.0, afIoc 2.0")
		verify(satisfier.resolvedPods.isEmpty)
	}

	Void testPaths5() {
		addDep("afBed 2.0", "afIoc 3.0, afPlastic 1.4 - 2.0")
		addDep("afIoc 3.0", "afPlastic 3.0")
		addDep("afPlastic 2.0")
		addDep("afPlastic 3.0")
		
		satisfyDependencies("afBed 2.0, afIoc 3.0")
		verify(satisfier.resolvedPods.isEmpty)
	}

	Void testPaths6() {
		addDep("afBed 2.0", "afIoc 2.0 - 3.0, afPlastic 1.4")
		addDep("afIoc 2.0", "afPlastic 1.4")
		addDep("afIoc 3.0", "afPlastic 2.0")
		addDep("afPlastic 1.4")
		addDep("afPlastic 2.0")
		
		satisfyDependencies("afBed 2.0")

		verifyPodFiles("afBed 2.0, afIoc 2.0, afPlastic 1.4")
	}

	Void testPaths7() {
		// test filter out pods that can't be reached with current selection
		addDep("afBed 2.0", "afIoc 2.0-3.0")
		addDep("afIoc 2.0")
		addDep("afIoc 3.0", "afPlastic 2.0")
		
		satisfyDependencies("afBed 2.0")

		verifyPodFiles("afBed 2.0, afIoc 2.0")
	}

	Void testPaths8() {
		// same as above but with more potential for NPEs
		addDep("afBed 2.0", "afIoc 2.0-3.0")
		addDep("afIoc 3.0")
		addDep("afIoc 2.0", "afPlastic 2.0")
		
		satisfyDependencies("afBed 2.0")

		verifyPodFiles("afBed 2.0, afIoc 3.0")
	}

	Void testPaths9() {
		// ensure we don't just return the first solution found, as it may not contain the latest versions 
		addDep("afEgg 5.0", "afBed 0+")

		addDep("afBed 2.0", "afIoc 1.8, afPlastic 1.4")
		addDep("afBed 2.1", "afIoc 1.7, afPlastic 1.3")
		addDep("afBed 2.2", "afIoc 1.6, afPlastic 1.2")
		addDep("afBed 2.3", "afIoc 1.5, afPlastic 1.1")

		addDep("afIoc 1.5")
		addDep("afIoc 1.6")
		addDep("afIoc 1.7")
		addDep("afIoc 1.8")
		addDep("afPlastic 1.1")
		addDep("afPlastic 1.2")
		addDep("afPlastic 1.3")
		addDep("afPlastic 1.4")
		
		satisfyDependencies("afEgg 5.0")

		// I admit there's a bit of luck to the ordering of internal map, as to which solution would get picked first
		verifyPodFiles("afEgg 5.0, afBed 2.0, afIoc 1.8, afPlastic 1.4")
	}

	Void testBuggy() {
		addDep("afEggbox@0.0.5", "afBounce 1.0.22-1.0, afFancordion 1.0.4-1.0, afFancordionBootstrap 1.0.0-1.0")
		addDep("afFancordion@1.1.0", "afBounce 1.1.0-1.1")
		addDep("afFancordion@1.0.4", "afBounce 1.0.18-1.0")
		addDep("afFancordionBootstrap@1.0.2", "afFancordion 1.1.0-1.1")
		addDep("afFancordionBootstrap@1.0.0", "afFancordion 1.0.4-1.0")

		addDep("afBounce@1.1.0")
		addDep("afBounce@1.0.24")
		addDep("afBounce@1.0.22")
		
		satisfyDependencies("afEggbox 0.0.5")
		
		// hmm - I swear this wasn't resolving  on the desktop!? 
		// sys::Err: Could not resolve afBounce (1.1.0, 1.0.24, 1.0.22)
		//   afEggbox@0.0.5 -> afBounce 1.0.20-1.0
		//   afFancordion@1.1.0 -> afBounce 1.1.0-1.1
		verifyPodFiles("afEggbox 0.0.5, afFancordionBootstrap 1.0.0, afFancordion 1.0.4, afBounce 1.0.24")		
	}

	private Void addDep(Str dependency, Str? dependents := null) {
		repository.add(dependency, dependents)
	}
	
	private Void satisfyDependencies(Str pods) {
		dependsOn := pods.split(',').map { Depend(it) }
		satisfier = Satisfier(TargetPod(Depend("TestPod 1.0"), dependsOn), Repositories([repository]))
		satisfier.satisfyDependencies
	}

	private Void verifyPodFiles(Str pods) {
		expected := pods.split(',').map { Depend(it) }
		actual 	 := satisfier.resolvedPods.vals.map { Depend("$it.name $it.version") }
		common	 := expected.intersection(actual)
		all		 := expected.union(actual)
		diff	 := all.removeAll(common)
		if (diff.isEmpty.not) {
			expected = expected.removeAll(common).insertAll(0, common)
			actual   = actual  .removeAll(common).insertAll(0, common)
			verifyEq(expected, actual)
		}
	}
}
