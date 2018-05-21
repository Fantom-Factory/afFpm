
** Updates dependencies for a Fantom project.
** 
** Update is an alias for the versatile Install command - sometimes it just  
** makes more sense to 'update'! 
** 
** To update dependencies for a given Fantom project to the latest versions
** 
** Examples:
** 
**   C:\> fpm update
**   C:\> fpm update -r default build.fan
**   C:\> fpm update -r release myPod 2.0.10
** 
@NoDoc	// Fandoc is only saved for public classes
class UpdateCmd : InstallCmd {

	new make(|This| f) : super(f) { }

}