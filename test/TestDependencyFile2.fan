
internal class TestDependencyFile2 : Test {
	
	StubRepository? 	repository
	Satisfied?			satisfied
	Depend[]?			results

	override Void setup() {
		repository = StubRepository()
	}
	
	Void testFile() {
		FpmEnv#.pod.log.level = LogLevel.debug

// Trace dependency file for shStackHub 0+ - 14-Jun-2018 Thu 16:04:49 GMT/BST

addDep("afAmazonS3 0.1.0", "sys 1.0.70-1.0, xml 1.0.70-1.0, afButter 1.2.8-1.2, afIoc 3.0.6-3.0, afIocConfig 1.1.0-1.1")
addDep("afBeanUtils 1.0.8", "sys 1.0")
addDep("afBedSheet 1.5.2", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, web 1.0.68-1.0, wisp 1.0.66-1.0, util 1.0.68-1.0, inet 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.12-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1")
addDep("afBedSheet 1.5.3", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, web 1.0.68-1.0, wisp 1.0.66-1.0, util 1.0.68-1.0, inet 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.12-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1, webmod 1.0, xml 1.0")
addDep("afBedSheet 1.5.4", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, web 1.0.68-1.0, wisp 1.0.66-1.0, util 1.0.68-1.0, inet 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.12-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1")
addDep("afBedSheet 1.5.5", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, web 1.0.68-1.0, wisp 1.0.66-1.0, util 1.0.68-1.0, inet 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.12-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1, webmod 1.0, xml 1.0")
addDep("afBedSheet 1.5.6", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, web 1.0.68-1.0, wisp 1.0.66-1.0, util 1.0.68-1.0, inet 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.12-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1")
addDep("afBedSheet 1.5.7", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, web 1.0.68-1.0, wisp 1.0.66-1.0, util 1.0.68-1.0, inet 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1, webmod 1.0, xml 1.0")
addDep("afBedSheet 1.5.8", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, web 1.0.68-1.0, wisp 1.0.66-1.0, util 1.0.68-1.0, inet 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1")
addDep("afBedSheet 1.5.9", "sys 1.0.69-1.0, concurrent 1.0.69-1.0, web 1.0.69-1.0, wisp 1.0.69-1.0, util 1.0.69-1.0, inet 1.0.69-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.4-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1, webmod 1.0, xml 1.0")
addDep("afBedSheet 1.5.10", "sys 1.0.69-1.0, concurrent 1.0.69-1.0, web 1.0.69-1.0, wisp 1.0.69-1.0, util 1.0.69-1.0, inet 1.0.69-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.4-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1")
addDep("afBedSheet 1.5.11", "sys 1.0.69-1.0, concurrent 1.0.69-1.0, web 1.0.69-1.0, wisp 1.0.69-1.0, util 1.0.69-1.0, inet 1.0.69-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.4-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1, webmod 1.0, xml 1.0")
addDep("afBounce 1.1.2", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, wisp 1.0.68-1.0, web 1.0.68-1.0, inet 1.0.68-1.0, xml 1.0.68-1.0, afConcurrent 1.0.12-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.2-1.5, afButter 1.2.2-1.2, afSizzle 1.0.2-1.0, afHtmlParser 0.1.0-0.1")
addDep("afBounce 1.1.3", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, wisp 1.0.68-1.0, web 1.0.68-1.0, inet 1.0.68-1.0, xml 1.0.68-1.0, afConcurrent 1.0.12-1.0, afIoc 3.0.4-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.2-1.5, afButter 1.2.2-1.2, afSizzle 1.0.2-1.0, afHtmlParser 0.1.0-0.1")
addDep("afBounce 1.1.4", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, wisp 1.0.68-1.0, web 1.0.68-1.0, inet 1.0.68-1.0, xml 1.0.68-1.0, afConcurrent 1.0.12-1.0, afIoc 3.0.4-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.2-1.5, afButter 1.2.2-1.2, afSizzle 1.0.2-1.0, afHtmlParser 0.1.0-0.1")
addDep("afBounce 1.1.5", "sys 1.0.69-1.0, concurrent 1.0.69-1.0, wisp 1.0.69-1.0, web 1.0.69-1.0, inet 1.0.69-1.0, xml 1.0.69-1.0, afConcurrent 1.0.18-1.0, afIoc 3.0.4-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.6-1.5, afButter 1.2.6-1.2, afSizzle 1.0.2-1.0, afHtmlParser 0.1.2-0.1")
addDep("afBounce 1.1.6", "sys 1.0.69-1.0, concurrent 1.0.69-1.0, wisp 1.0.69-1.0, web 1.0.69-1.0, inet 1.0.69-1.0, xml 1.0.69-1.0, afConcurrent 1.0.18-1.0, afIoc 3.0.4-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.6-1.5, afButter 1.2.6-1.2, afSizzle 1.0.2-1.0, afHtmlParser 0.1.2-0.1")
addDep("afBounce 1.1.7", "sys 1.0.70-1.0, concurrent 1.0.70-1.0, wisp 1.0.70-1.0, web 1.0.70-1.0, inet 1.0.70-1.0, xml 1.0.70-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.4-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.10-1.5, afButter 1.2.8-1.2, afSizzle 1.0.2-1.0, afHtmlParser 0.1.2-0.1")
addDep("afBounce 1.1.8", "sys 1.0.70-1.0, concurrent 1.0.70-1.0, wisp 1.0.70-1.0, web 1.0.70-1.0, inet 1.0.70-1.0, xml 1.0.70-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.4-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.10-1.5, afButter 1.2.8-1.2, afSizzle 1.0.2-1.0, afHtmlParser 0.1.2-0.1")
addDep("afBounce 1.1.9", "sys 1.0.70-1.0, concurrent 1.0.70-1.0, wisp 1.0.70-1.0, web 1.0.70-1.0, inet 1.0.70-1.0, xml 1.0.70-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.4-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.10-1.5, afButter 1.2.9-1.2, afSizzle 1.0.2-1.0, afHtmlParser 0.1.2-0.1")
addDep("afBson 1.1.0", "sys 1.0.69-1.0, inet 1.0.69-1.0, concurrent 1.0.69-1.0")
addDep("afButter 1.2.2", "sys 1.0.68-1.0, inet 1.0.68-1.0, web 1.0.68-1.0, util 1.0.68-1.0")
addDep("afButter 1.2.3", "sys 1.0.68-1.0, inet 1.0.68-1.0, web 1.0.68-1.0, util 1.0.68-1.0")
addDep("afButter 1.2.4", "sys 1.0.68-1.0, inet 1.0.68-1.0, web 1.0.68-1.0, util 1.0.68-1.0")
addDep("afButter 1.2.5", "sys 1.0.68-1.0, inet 1.0.68-1.0, web 1.0.68-1.0, util 1.0.68-1.0")
addDep("afButter 1.2.6", "sys 1.0.69-1.0, inet 1.0.69-1.0, web 1.0.69-1.0, util 1.0.69-1.0")
addDep("afButter 1.2.7", "sys 1.0.69-1.0, inet 1.0.69-1.0, web 1.0.69-1.0, util 1.0.69-1.0")
addDep("afButter 1.2.8", "sys 1.0.69-1.0, inet 1.0.69-1.0, web 1.0.69-1.0, util 1.0.69-1.0")
addDep("afButter 1.2.9", "sys 1.0.69-1.0, inet 1.0.69-1.0, web 1.0.69-1.0, util 1.0.69-1.0")
addDep("afColdFeet 1.4.0", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, afConcurrent 1.0.12-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1, afBedSheet 1.5.0-1.5")
addDep("afConcurrent 1.0.12", "sys 1.0, concurrent 1.0")
addDep("afConcurrent 1.0.14", "sys 1.0, concurrent 1.0")
addDep("afConcurrent 1.0.16", "sys 1.0.67-1.0, concurrent 1.0.67-1.0")
addDep("afConcurrent 1.0.17", "sys 1.0.67-1.0, concurrent 1.0.67-1.0")
addDep("afConcurrent 1.0.18", "sys 1.0.67-1.0, concurrent 1.0.67-1.0")
addDep("afConcurrent 1.0.19", "sys 1.0.67-1.0, concurrent 1.0.67-1.0")
addDep("afConcurrent 1.0.20", "sys 1.0.69-1.0, concurrent 1.0.69-1.0")
addDep("afConcurrent 1.0.21", "sys 1.0.69-1.0, concurrent 1.0.69-1.0")
addDep("afDuvet 1.1.2", "sys 1.0.68-1.0, util 1.0.68-1.0, web 1.0.68-1.0, afConcurrent 1.0.12-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.0-1.5")
addDep("afDuvet 1.1.3", "sys 1.0.68-1.0, util 1.0.68-1.0, web 1.0.68-1.0, afConcurrent 1.0.12-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.0-1.5, afBounce 1.1.0-1.1, afButter 1.2.0-1.2")
addDep("afDuvet 1.1.4", "sys 1.0.68-1.0, util 1.0.68-1.0, web 1.0.68-1.0, afConcurrent 1.0.12-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.0-1.5")
addDep("afDuvet 1.1.5", "sys 1.0.68-1.0, util 1.0.68-1.0, web 1.0.68-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.0-1.5, afBounce 1.1.0-1.1, afButter 1.2.0-1.2")
addDep("afDuvet 1.1.6", "sys 1.0.68-1.0, util 1.0.68-1.0, web 1.0.68-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.0-1.5")
addDep("afDuvet 1.1.7", "sys 1.0.68-1.0, util 1.0.68-1.0, web 1.0.68-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.9-1.5")
addDep("afDuvet 1.1.8", "sys 1.0.69-1.0, util 1.0.69-1.0, web 1.0.69-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.4-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.10-1.5, afBounce 1.1.4-1.1, afButter 1.2.8-1.2")
addDep("afEfan 1.5.2", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, afPlastic 1.1.0-1.1")
addDep("afEfanXtra 1.2.0", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, fandoc 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.12-1.0, afPlastic 1.1.0-1.1, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1, afEfan 1.5.0-1.5")
addDep("afFancordion 1.1.2", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, compiler 1.0.68-1.0, fandoc 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afPlastic 1.1.0-1.1")
addDep("afFancordion 1.1.3", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, compiler 1.0.68-1.0, fandoc 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afPlastic 1.1.0-1.1, afBounce 1.1.0-1.1, afSizzle 1.0.2-1.0")
addDep("afFancordion 1.1.4", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, compiler 1.0.68-1.0, fandoc 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afPlastic 1.1.0-1.1")
addDep("afFancordion 1.1.5", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, compiler 1.0.68-1.0, fandoc 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afPlastic 1.1.0-1.1, afBounce 1.1.0-1.1, afSizzle 1.0.2-1.0")
addDep("afFancordionBootstrap 1.0.2", "sys 1.0.68-1.0, afFancordion 1.1.0-1.1, afBeanUtils 1.0.4-1.0")
addDep("afFandoc 0.0.1", "sys 1.0.69-1.0, fandoc 1.0.69-1.0, syntax 1.0.69-1.0")
addDep("afFormBean 1.2.2", "sys 1.0.69-1.0, concurrent 1.0.69-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.12-1.0, afIoc 3.0.0-3.0")
addDep("afFormBean 1.2.3", "sys 1.0.69-1.0, concurrent 1.0.69-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.12-1.0, afIoc 3.0.0-3.0")
addDep("afGoogleAnalytics 0.1.8", "sys 1.0.68-1.0, util 1.0.68-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.0-1.5, afDuvet 1.1.0-1.1")
addDep("afGoogleAnalytics 0.1.9", "sys 1.0.70-1.0, util 1.0.70-1.0, afIoc 3.0.6-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.10-1.5, afDuvet 1.1.0-1.1")
addDep("afHaystackOps 0.1.2", "sys 1.0.70-1.0, web 1.0.70-1.0, inet 1.0.70-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.6-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.10-1.5, afJson 1.0.0-1.0, haystack 3.0.13-3.0, concurrent 1.0.70-1.0, afBounce 1.1.8-1.1, afButter 1.2.8-1.2")
addDep("afHtmlParser 0.1.0", "sys 1.0, xml 1.0, afPegger 0.1.0-0.1")
addDep("afHtmlParser 0.1.1", "sys 1.0, xml 1.0, afPegger 0.1.0-0.1")
addDep("afHtmlParser 0.1.2", "sys 1.0, xml 1.0, afPegger 0.1.0-0.1")
addDep("afIoc 3.0.0", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, afBeanUtils 1.0.8-1.0")
addDep("afIoc 3.0.2", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, afBeanUtils 1.0.8-1.0")
addDep("afIoc 3.0.4", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, afBeanUtils 1.0.8-1.0")
addDep("afIoc 3.0.5", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.14-1.0")
addDep("afIoc 3.0.7", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.20-1.0")
addDep("afIocConfig 1.1.1", "sys 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afIoc 3.0.0-3.0")
addDep("afIocEnv 1.1.0", "sys 1.0.68-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1")
addDep("afJson 1.0.0", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.12-1.0")
addDep("afJson 1.0.1", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.12-1.0")
addDep("afMarkdownParser 0.0.6", "sys 1.0.68-1.0, fandoc 1.0.68-1.0, afPegger 0.1.0-0.1")
addDep("afMongo 1.1.6", "sys 1.0.69-1.0, inet 1.0.69-1.0, util 1.0.69-1.0, concurrent 1.0.69-1.0, afConcurrent 1.0.18-1.0, afBson 1.1.0-1.1")
addDep("afMongo 1.1.7", "sys 1.0.69-1.0, inet 1.0.69-1.0, util 1.0.69-1.0, concurrent 1.0.69-1.0, afConcurrent 1.0.18-1.0, afBson 1.1.0-1.1")
addDep("afMorphia 1.2.2", "sys 1.0.69-1.0, concurrent 1.0.69-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.18-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afBson 1.1.0-1.1, afMongo 1.1.6-1.1")
addDep("afMorphia 1.2.3", "sys 1.0.69-1.0, concurrent 1.0.69-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.18-1.0, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afBson 1.1.0-1.1, afMongo 1.1.6-1.1")
addDep("afPegger 0.1.0", "sys 1.0, afBeanUtils 1.0.8-1.0, xml 1.0, concurrent 1.0")
addDep("afPillow 1.1.2", "sys 1.0, concurrent 1.0, web 1.0, afBeanUtils 1.0.6-1.0, afConcurrent 1.0.12-1.0, afPlastic 1.1.0-1.1, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1, afBedSheet 1.5.0-1.5, afEfanXtra 1.2.0-1.2")
addDep("afPillow 1.1.3", "sys 1.0, concurrent 1.0, web 1.0, afBeanUtils 1.0.6-1.0, afConcurrent 1.0.12-1.0, afPlastic 1.1.0-1.1, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1, afBedSheet 1.5.0-1.5, afEfanXtra 1.2.0-1.2, afBounce 1.1.0-1.1, afButter 1.2.0-1.2")
addDep("afPillow 1.1.4", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, web 1.0.68-1.0, afBeanUtils 1.0.6-1.0, afConcurrent 1.0.12-1.0, afPlastic 1.1.0-1.1, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1, afBedSheet 1.5.6-1.5, afEfanXtra 1.2.0-1.2")
addDep("afPillow 1.1.5", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, web 1.0.68-1.0, afBeanUtils 1.0.6-1.0, afConcurrent 1.0.12-1.0, afPlastic 1.1.0-1.1, afIoc 3.0.0-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1, afBedSheet 1.5.6-1.5, afEfanXtra 1.2.0-1.2, afBounce 1.1.0-1.1, afButter 1.2.0-1.2")
addDep("afPlastic 1.1.2", "sys 1.0.68-1.0, concurrent 1.0.68-1.0, compiler 1.0.68-1.0, compilerJava 1.0.68-1.0, afBeanUtils 1.0.8-1.0")
addDep("afSitemap 1.1.0", "sys 1.0.68-1.0, xml 1.0.68-1.0, afIoc 3.0.0-3.0, afBedSheet 1.5.0-1.5, afEfanXtra 1.2.0-1.2, afPillow 1.1.0-1.1")
addDep("afSizzle 1.0.2", "sys 1.0, xml 1.0")
addDep("afSizzle 1.0.4", "sys 1.0, xml 1.0")
addDep("afSizzle 1.0.5", "sys 1.0, xml 1.0")
addDep("afSlim 1.2.0", "sys 1.0.68-1.0, afEfan 1.5.0-1.5, afPlastic 1.1.0-1.1, afPegger 0.1.0-0.1")
addDep("afStripe 0.1.2", "sys 1.0.70-1.0, concurrent 1.0.70-1.0, afButter 1.2.8-1.2, afConcurrent 1.0.20-1.0, afIoc 3.0.6-3.0, afIocConfig 1.1.0-1.1, afJson 1.0.0-1.0")
addDep("asn1 3.0.13", "sys 1.0")
addDep("compiler 1.0.71", "sys 1.0")
addDep("compilerJava 1.0.71", "sys 1.0, compiler 1.0")
addDep("concurrent 1.0.71", "sys 1.0")
addDep("crypto 3.0.13", "sys 1.0, concurrent 1.0, util 1.0, asn1 3.0.13")
addDep("email 1.0.71", "sys 1.0, inet 1.0")
addDep("fandoc 1.0.71", "sys 1.0")
addDep("haystack 3.0.13", "sys 1.0, concurrent 1.0, util 1.0, web 1.0")
addDep("haystack 3.0.15", "sys 1.0, concurrent 1.0, util 1.0, web 1.0")
addDep("inet 1.0.71", "sys 1.0, concurrent 1.0")
addDep("shDomain 2.3.0", "sys 1.0.71-1.0, concurrent 1.0.70-1.0, xml 1.0.70-1.0, email 1.0.70-1.0, fandoc 1.0.70-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.6-3.0, afIocConfig 1.1.1-1.1, afIocEnv 1.1.0-1.1, afFormBean 1.2.2-1.2, afJson 1.0.1-1.0, afBson 1.1.0-1.1, afMongo 1.1.6-1.1, afMorphia 1.2.2-1.2, haystack 3.0.13, crypto 3.0.13, afStripe 0.1.2-0.1, afMarkdownParser 0.0.6-0.0, afFancordion 1.1.4-1.1, afFancordionBootstrap 1.0.2-1.0")
addDep("shEmails 2.3.0", "sys 1.0.70-1.0, concurrent 1.0.70-1.0, xml 1.0.70-1.0, email 1.0.70-1.0, fandoc 1.0.70-1.0, afBeanUtils 1.0.8-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.6-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1, shDomain 2.3.0-2.3, afEfanXtra 1.2.0-1.2, afSlim 1.2.0-1.2, afHtmlParser 0.1.2-0.1, afSizzle 1.0.4-1.0, afFancordion 1.1.4-1.1, afFancordionBootstrap 1.0.2-1.0")
addDep("shJobs 2.3.0", "sys 1.0.70-1.0, concurrent 1.0.70-1.0, fandoc 1.0.70-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.6-3.0, afIocEnv 1.1.0-1.1, afIocConfig 1.1.0-1.1, afBedSheet 1.5.10-1.5, shDomain 2.3.0-2.3, afMorphia 1.2.2-1.2, afStripe 0.1.2-1.1, afFancordion 1.1.4-1.1, afFancordionBootstrap 1.0.2-1.0")
addDep("shOps 2.3.0", "sys 1.0.70-1.0, concurrent 1.0.70-1.0, afConcurrent 1.0.20-1.0, afIoc 3.0.6-3.0, afIocConfig 1.1.0-1.1, afIocEnv 1.1.0-1.1, haystack 3.0.13-3.0, afJson 1.0.1-1.0, afMorphia 1.2.2-1.2, afBedSheet 1.5.10-1.5, shDomain 2.3.0-2.3, afHaystackOps 0.1.2-0.1, afFancordion 1.1.4-1.1, afFancordionBootstrap 1.0.2-1.0, afBounce 1.1.8-1.1, afButter 1.2.8-1.2, shStackHubClient 0.1")
addDep("shS3 2.3.0", "sys 1.0.70-1.0, afIoc 3.0.6-3.0, afIocConfig 1.1.0-1.1, afBedSheet 1.5.10-1.5, shDomain 2.3.0-2.3, afAmazonS3 0.1.0-0.1, afFancordion 1.1.4-1.1, afFancordionBootstrap 1.0.2-1.0")
addDep("shStackHub 2.3.3.0", "sys 1.0.71-1.0, concurrent 1.0.71-1.0, web 1.0.71-1.0, util 1.0.71-1.0, fandoc 1.0.71-1.0, wisp 1.0.71-1.0, shDomain 2.3.0-2.3, shEmails 2.3.0-2.3, shJobs 2.3.0-2.3, shOps 2.3.0-2.3, shS3 2.3.0-2.3, shStripe 2.3.0-2.3, afConcurrent 1.0.20-1.0, afIoc 3.0.7-3.0, afIocConfig 1.1.1-1.1, afIocEnv 1.1.0-1.1, afFandoc 0.0.1-1.0, afJson 1.0.1-1.0, afMorphia 1.2.2-1.2, afMongo 1.1.6-1.1, afHaystackOps 0.1.2-0.1, afStripe 0.1.2-0.1, afBounce 1.1.8-1.1, afSizzle 1.0.4-1.0, xml 1.0.70-1.0, afBedSheet 1.5.11-1.5, afPillow 1.1.4-1.1, afEfanXtra 1.2.0-1.2, afEfan 1.5.2-1.5, afGoogleAnalytics 0.1.8-0.1, afSitemap 1.1.0-1.1, afColdFeet 1.4.0-1.4, afDuvet 1.1.8-1.1, afSlim 1.2.0-1.2, afFormBean 1.2.2-1.2, afButter 1.2.9-1.2, afFancordion 1.1.4-1.1, afFancordionBootstrap 1.0.2-1.0")
addDep("shStackHubClient 0.1.0", "sys 1.0.70-1.0, afButter 1.2.8-1.2, afJson 1.0.0-1.0")
addDep("shStripe 2.3.0", "sys 1.0.70-1.0, afIoc 3.0.6-3.0, afIocEnv 1.1.0-1.1, afIocConfig 1.1.0-1.1, haystack 3.0.13, shDomain 2.3.0-2.3, afStripe 0.1.2-0.1, afBounce 1.1.8-1.1, afFancordion 1.1.4-1.1, afFancordionBootstrap 1.0.2-1.0")
addDep("syntax 1.0.71", "sys 1.0")
addDep("sys 1.0.71", "")
addDep("util 1.0.71", "sys 1.0, concurrent 1.0")
addDep("web 1.0.71", "sys 1.0, concurrent 1.0, inet 1.0")
addDep("webmod 1.0.71", "sys 1.0, inet 1.0, web 1.0, util 1.0")
addDep("wisp 1.0.71", "sys 1.0, util 1.0, concurrent 1.0, inet 1.0, web 1.0")
addDep("xml 1.0.71", "sys 1.0")
satisfyDependencies("shStackHub 0+")


		FpmEnv.dumpEnv(satisfied.targetPod, satisfied.resolvedPods.vals, null) { echo(it) }
		
		// TODO check logs for these test numbers:

		// [afFpm] Resolving pods for cwApp 0.2.0.225
		// [afFpm] Found 104 versions of 49 different pods
		// [afFpm] Calculated 550,502,400 dependency pod permutations
		// [afFpm] Collapsed to    69,120 dependency group permutations
		// [afFpm] Stated problem space in 806ms
		// [afFpm] Solving...
		// [afFpm]           ...Done
		// [afFpm] Cached 1218 bad dependency groups
		// [afFpm] Found 8 solutions in 3sec
		
		actual 	 := satisfied.resolvedPods.vals.map { Depend("$it.name $it.version") }
		verifyPod("shStackHub 2.3.3.0")
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
