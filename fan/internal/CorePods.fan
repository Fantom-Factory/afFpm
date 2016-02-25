
internal const class CorePods {
	private const Str[] corePodNames := "docIntro docLang docFanr docTools build compiler compilerDoc compilerJava compilerJs concurrent dom email fandoc fanr fansh flux fluxText fwt gfx icons inet obix sql syntax sys testCompiler testJava testNative testSys util web webfwt webmod wisp xml".split

	Bool isCorePod(Str podName) {
		corePodNames.any { it.equalsIgnoreCase(podName) }
	}
}

