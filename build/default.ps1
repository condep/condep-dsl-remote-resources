properties {
	$pwd = Split-Path $psake.build_script_file	
	$build_directory  = "$pwd\output\condep-dsl-remote-resources"
	$configuration = "Release"
	$preString = "beta"
	$releaseNotes = ""
}
 
include .\..\tools\psake_ext.ps1

function GetNugetAssemblyVersion($assemblyPath) {
	$versionInfo = Get-Item $assemblyPath | % versioninfo

	return "$($versionInfo.FileMajorPart).$($versionInfo.FileMinorPart).$($versionInfo.FileBuildPart)-$preString"
}

task default -depends Build-All, Pack-All
task ci -depends Build-All, Pack-All

task Build-All -depends Clean, Build, Create-BuildSpec-ConDep-Dsl-Remote-Resources
task Pack-All -depends Pack-ConDep-Dsl-Remote.Resources

task Build {
	Exec { msbuild "$pwd\..\src\condep-dsl-remote-resources.sln" /t:Build /p:Configuration=$configuration /p:OutDir=$build_directory /p:GenerateProjectSpecificOutputFolder=true}
}

task Clean {
	Write-Host "Cleaning Build output"  -ForegroundColor Green
	Remove-Item $build_directory -Force -Recurse -ErrorAction SilentlyContinue
}

task Create-BuildSpec-ConDep-Dsl-Remote-Resources {
	Generate-Nuspec-File `
		-file "$build_directory\condep.dsl.remote.resources.nuspec" `
		-version $(GetNugetAssemblyVersion $build_directory\ConDep.Dsl.Remote.Resources\ConDep.Dsl.Remote.Resources.dll) `
		-id "ConDep.Dsl.Remote.Resources" `
		-title "ConDep.Dsl.Remote.Resources" `
		-licenseUrl "http://www.con-dep.net/license/" `
		-projectUrl "http://www.con-dep.net/" `
		-description "Remote resources used by ConDep operations server side." `
		-iconUrl "https://raw.github.com/torresdal/ConDep/master/images/ConDepNugetLogo.png" `
		-releaseNotes "$releaseNotes" `
		-tags "Continuous Deployment Delivery Infrastructure WebDeploy Deploy msdeploy IIS automation powershell remote" `
		-files @(
			@{ Path="ConDep.Dsl.Remote.Resources\ConDep.Dsl.Remote.Resources.dll"; Target="lib/net40"}
		)
}

task Pack-ConDep-Dsl-Remote.Resources {
	Exec { nuget pack "$build_directory\condep.dsl.remote.resources.nuspec" -OutputDirectory "$build_directory" }
}