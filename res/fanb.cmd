@setlocal

@set FPM_CMDLINE_ARGS=build.fan%*

@call fan-orig.cmd afBuild::Build %*

@endlocal