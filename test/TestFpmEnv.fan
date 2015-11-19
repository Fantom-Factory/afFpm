
internal class TestFpmEnv :Test {
	
	Void testSplitStr() {
		verifyEq(FpmEnv.splitStr(null), Str#.emptyList)
		verifyEq(FpmEnv.splitStr(""), Str#.emptyList)
		
		// standard split
		verifyEq(FpmEnv.splitStr("how are you"), Str["how", "are", "you"])

		// standard split - moar spaces
		verifyEq(FpmEnv.splitStr("   how   are   you   "), Str["how", "are", "you"])
		
		// standard quotes
		verifyEq(FpmEnv.splitStr("\"how are you\""), Str["how are you"])
		
		// mixed
		verifyEq(FpmEnv.splitStr("\"how are\" you"), Str["how are", "you"])
		
		// no closing quote
		verifyEq(FpmEnv.splitStr("how \"are you"), Str["how", "are you"])
		
		// quotes not prefixed with space
		verifyEq(FpmEnv.splitStr("how\"are\" you"), Str["how\"are\"", "you"])

		// quotes surrounded with space
		verifyEq(FpmEnv.splitStr("how \" are \" you"), Str["how", " are ", "you"])

		// quotes surrounded with space
		verifyEq(FpmEnv.splitStr("how \" are \"you"), Str["how", " are ", "you"])

		// quotes surrounded with space
		verifyEq(FpmEnv.splitStr("how \" are y\"ou"), Str["how", " are y", "ou"])
	}
}
