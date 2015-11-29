
internal class TestFpmEnvDefault :Test {
	
	Void testSplitStr() {
		verifyEq(FpmEnvDefault.splitStr(null), Str#.emptyList)
		verifyEq(FpmEnvDefault.splitStr(""), Str#.emptyList)
		
		// standard split
		verifyEq(FpmEnvDefault.splitStr("how are you"), Str["how", "are", "you"])

		// standard split - moar spaces
		verifyEq(FpmEnvDefault.splitStr("   how   are   you   "), Str["how", "are", "you"])
		
		// standard quotes
		verifyEq(FpmEnvDefault.splitStr("\"how are you\""), Str["how are you"])
		
		// mixed
		verifyEq(FpmEnvDefault.splitStr("\"how are\" you"), Str["how are", "you"])
		
		// no closing quote
		verifyEq(FpmEnvDefault.splitStr("how \"are you"), Str["how", "are you"])
		
		// quotes not prefixed with space
		verifyEq(FpmEnvDefault.splitStr("how\"are\" you"), Str["how\"are\"", "you"])

		// quotes surrounded with space
		verifyEq(FpmEnvDefault.splitStr("how \" are \" you"), Str["how", " are ", "you"])

		// quotes surrounded with space
		verifyEq(FpmEnvDefault.splitStr("how \" are \"you"), Str["how", " are ", "you"])

		// quotes surrounded with space
		verifyEq(FpmEnvDefault.splitStr("how \" are y\"ou"), Str["how", " are y", "ou"])
	}
}
