
internal class TestSkysparkBug : Test {
	
	StubRepository? 	repository
	Satisfied?			satisfied
	Depend[]?			results

	override Void setup() {
		repository = StubRepository()
	}
	
	Void testFile() {
		FpmEnv#.pod.log.level = LogLevel.debug

// Trace dependency file for afMarsDomain 2.0.0 - 8-Jun-2021 Tue 14:06:09 GMT/BST

addDep("afAudit 0.0.4", "sys 1.0.74-1.0, concurrent 1.0.74-1.0, afBeanUtils 1.0.10-1.0, afConcurrent 1.0.24-1.0, afIoc 3.0.8-3.0, afIocConfig 1.1.0-1.1")
addDep("afBeanUtils 1.0.12", "sys 1.0.68-1.0")
addDep("afBson 1.1.2", "sys 1.0.69-1.0, inet 1.0.69-1.0, concurrent 1.0.69-1.0")
addDep("afConcurrent 1.0.26", "sys 1.0.69-1.0, concurrent 1.0.69-1.0")
addDep("afFandoc 0.0.6", "sys 1.0.69-1.0, fandoc 1.0.69-1.0, syntax 1.0.69-1.0")
addDep("afFom 0.1.18", "sys 1.0.71-1.0, concurrent 1.0.71-1.0, haystack 3.0.18-3.0, folio 3.0.18-3.0, afBeanUtils 1.0.10-1.0, afConcurrent 1.0.22-1.0")
addDep("afFormBean 1.2.6", "sys 1.0.69-1.0, concurrent 1.0.69-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.12-1.0, afIoc 3.0.0-3.0")
addDep("afIoc 3.0.8", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, afBeanUtils 1.0.8-1.0")
addDep("afIocConfig 1.1.2", "sys 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afIoc 3.0.0-3.0")
addDep("afIocEnv 1.1.0", "sys 1.0.68-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1")
addDep("afMongo 1.1.12", "sys 1.0.69-1.0, inet 1.0.69-1.0, util 1.0.69-1.0, concurrent 1.0.69-1.0, afConcurrent 1.0.18-1.0, afBson 1.1.0-1.1")
addDep("afMorphia 1.2.6", "sys 1.0.69-1.0, concurrent 1.0.69-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.18-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afBson 1.1.0-1.1, afMongo 1.1.8-1.1")
addDep("axon 3.0.29", "sys 1.0, concurrent 1.0, haystack 3.0.29")
addDep("concurrent 1.0.74", "sys 1.0")
addDep("dict 3.0.21", "sys 1.0, haystack 3.0.21")
addDep("dict 3.0.23", "sys 1.0, haystack 3.0.23")
addDep("dict 3.0.28", "sys 1.0, haystack 3.0.28")
addDep("fandoc 1.0.74", "sys 1.0")
addDep("folio 3.0.21", "sys 1.0, concurrent 1.0, haystack 3.0.21, dict 3.0.21")
addDep("folio 3.0.23", "sys 1.0, concurrent 1.0, haystack 3.0.23, dict 3.0.23")
addDep("folio 3.0.28", "sys 1.0, concurrent 1.0, haystack 3.0.28, dict 3.0.28")
addDep("folio 3.0.29", "sys 1.0, concurrent 1.0, haystack 3.0.29")					// this is the problem - where 3.0.29 no longer requires "dict"
addDep("haystack 3.0.29", "sys 1.0, concurrent 1.0, util 1.0, web 1.0")
addDep("inet 1.0.74", "sys 1.0, concurrent 1.0")
addDep("syntax 1.0.74", "sys 1.0")
addDep("sys 1.0.74", "")
addDep("util 1.0.74", "sys 1.0, concurrent 1.0")
addDep("web 1.0.74", "sys 1.0, concurrent 1.0, inet 1.0")
		
addDep("afMarsDomain 2.0.0", "sys 1.0.74-1.0, concurrent 1.0.74-1.0, fandoc 1.0.74-1.0, util 1.0.74-1.0, afBeanUtils 1.0.12-1.0, afConcurrent 1.0.24-1.0, afIoc 3.0.8-3.0, afIocConfig 1.1.2-1.1, afIocEnv 1.1.0-1.1, afFormBean 1.2.6-1.2, afAudit 0.0.4-1.0, afBson 1.1.2-1.1, afMongo 1.1.12-1.1, afMorphia 1.2.6-1.2, afFandoc 0.0.6-1.0, afFom 0.1.10-1.0, axon 3.0.29-3.0, haystack 3.0.29-3.0")
satisfyDependencies("afMarsDomain 2.0.0")



		FpmEnv.dumpEnv(satisfied.targetPod, satisfied.resolvedPods.vals, null) { echo(it) }
		

		
		actual 	 := satisfied.resolvedPods.vals.map { Depend("$it.name $it.version") }
		verifyPod("afMarsDomain 2.0.0")
		verifyPod("haystack     3.0.29")
	}

	private Void addDep(Str dependency, Str? dependents := null) {
		repository.add(dependency, dependents)
	}
	
	private Void satisfyDependencies(Str pod) { 
		satisfied = Resolver(Repository[repository]) {
			it.resolveTimeout1 = 5sec
			it.resolveTimeout2 = 10sec
		}.satisfyPod(Depend(pod))
		results = satisfied.resolvedPods.vals.map { Depend("$it.name $it.version") }
	}
	
	private Void verifyPod(Str pod) {
		verify(results.contains(Depend(pod)), "Result does not contain: $pod")
	}
}