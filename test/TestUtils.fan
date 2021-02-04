
internal class TestUtils :Test {

	Void testDependFits() {
		verifyDependsNot("afBedSheet 1.0", 		"afIoc 1.0")
		verifyDependsNot("afBedSheet 1.0",		"afBedSheet 2.0")
		verifyDepends	("afBedSheet 1.0.2",	"afBedSheet 1.0")
		verifyDependsNot("afBedSheet 1.1.2",	"afBedSheet 1.0")

		verifyDepends	("afBedSheet 1", 		"afBedSheet 1")
		verifyDependsNot("afBedSheet 1", 		"afBedSheet 1.0")	// Not - 'cos we're testing if the entire range is included, not an individual pod version
		verifyDependsNot("afBedSheet 1", 		"afBedSheet 1.0.0")
		verifyDependsNot("afBedSheet 1", 		"afBedSheet 1.0.0.0")
		verifyDepends	("afBedSheet 1.0", 		"afBedSheet 1")
		verifyDepends	("afBedSheet 1.0.0", 	"afBedSheet 1")
		verifyDepends	("afBedSheet 1.0.0.0", 	"afBedSheet 1")

		verifyDependsNot("afBedSheet 0.9", 		"afBedSheet 1.0.0 - 1.0")
		verifyDepends	("afBedSheet 1.0", 		"afBedSheet 1.0.0 - 1.0")
		verifyDepends	("afBedSheet 1.0.2",	"afBedSheet 1.0.0 - 1.0")
		verifyDependsNot("afBedSheet 1.1", 		"afBedSheet 1.0.0 - 1.0")
		verifyDependsNot("afBedSheet 2.0", 		"afBedSheet 1.0.0 - 1.0")

		verifyDependsNot("afBedSheet 1.1", 		"afBedSheet 1.2+")
		verifyDepends	("afBedSheet 1.2", 		"afBedSheet 1.2+")
		verifyDepends	("afBedSheet 1.2.1",	"afBedSheet 1.2+")
		verifyDepends	("afBedSheet 1.3", 		"afBedSheet 1.2+")

		verifyDependsNot("afBedSheet 1.2-1.4", 	"afBedSheet 1.6-1.8")
		verifyDependsNot("afBedSheet 1.2-1.7", 	"afBedSheet 1.6-1.8")
		verifyDependsNot("afBedSheet 1.2-1.4", 	"afBedSheet 1.3-1.8")
		verifyDependsNot("afBedSheet 1.6-1.8", 	"afBedSheet 1.2-1.4")

		verifyDependsNot("afBedSheet 1.6-1.8", 	"afBedSheet 1.7")
		verifyDepends	("afBedSheet 1.6-1.8", 	"afBedSheet 1")
		verifyDependsNot("afBedSheet 1.6-1.8", 	"afBedSheet 1.9+")
		verifyDepends	("afBedSheet 1.6-1.8", 	"afBedSheet 1.2+")
		
		verifyDepends	("afBedSheet 1.2+", 	"afBedSheet 1.1+")
		verifyDepends	("afBedSheet 1.2.2+", 	"afBedSheet 1.2+")
		verifyDependsNot("afBedSheet 1.1+", 	"afBedSheet 1.2+")
		verifyDependsNot("afBedSheet 1.2.2+", 	"afBedSheet 1.2.4+")
		
		// TODO multi-examples
	}
	
	Void verifyDepends(Str d1, Str d2) {
		verifyTrue(FpmUtils.dependFits(Depend(d1), Depend(d2)))
	}
	
	Void verifyDependsNot(Str d1, Str d2) {
		verifyFalse(FpmUtils.dependFits(Depend(d1), Depend(d2)))
	}
	
	Void testSplitQuotedStr() {
		verifyEq(FpmUtils.splitQuotedStr(null), null)
		verifyEq(FpmUtils.splitQuotedStr(""), null)
		
		// standard split
		verifyEq(FpmUtils.splitQuotedStr("how are you"), Str["how", "are", "you"])

		// standard split - moar spaces
		verifyEq(FpmUtils.splitQuotedStr("   how   are   you   "), Str["how", "are", "you"])
		
		// standard quotes
		verifyEq(FpmUtils.splitQuotedStr("\"how are you\""), Str["how are you"])
		
		// mixed
		verifyEq(FpmUtils.splitQuotedStr("\"how are\" you"), Str["how are", "you"])
		
		// no closing quote
		verifyEq(FpmUtils.splitQuotedStr("how \"are you"), Str["how", "are you"])
		
		// quotes not prefixed with space
		verifyEq(FpmUtils.splitQuotedStr("how\"are\" you"), Str["how\"are\"", "you"])

		// quotes surrounded with space
		verifyEq(FpmUtils.splitQuotedStr("how \" are \" you"), Str["how", " are ", "you"])

		// quotes surrounded with space
		verifyEq(FpmUtils.splitQuotedStr("how \" are \"you"), Str["how", " are ", "you"])

		// quotes surrounded with space
		verifyEq(FpmUtils.splitQuotedStr("how \" are y\"ou"), Str["how", " are y", "ou"])
	}
}
