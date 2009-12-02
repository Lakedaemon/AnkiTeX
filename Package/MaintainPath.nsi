!addplugindir Plugins
!include LogicLib.nsh
!include Plugins\EnvVarUpdate.nsh
!include FileFunc.nsh
!insertmacro GetParameters
!insertmacro GetOptions

Name "MaintainPath" ; The name of the installer
OutFile "MaintainPath.exe" ; The file to write
InstallDir $Temp ; The default installation directory

ShowInstDetails show
SetCompressor lzma


Page instfiles

Var myDir

Function .onInit
  ${GetParameters} $R0
  ClearErrors
  ${GetOptions} $R0 -myDir= $myDir
FunctionEnd

Section "Preppend path"
  ${EnvVarUpdate} $0 "PATH" "P" "HKLM" "$myDir"  ; preppend to path
  Quit
SectionEnd


