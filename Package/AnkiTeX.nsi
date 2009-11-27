RequestExecutionLevel User
!include "LogicLib.nsh"
!include "nsDialogs.nsh"
!include "Sections.nsh"
!include "WinMessages.nsh"

Name "Anki & TeX" ; The name of the installer
OutFile "AnkiTeX.exe" ; The file to write
InstallDir $PROGRAMFILES\W32TeX ; The default installation directory
SetCompress off

ShowInstDetails show
XPStyle on


Page custom nsDialogsPage nsDialogsPageLeave
Page directory
Page instfiles

Var Elevate
Var Dialog
Var Id
Var Password
Var UserName

Function nsDialogsPage
        
        StrCpy $Elevate "False"
         StrCpy $UserName "None\\.."
        ClearErrors
	UserInfo::GetName
	IfErrors done ; Win9x
	Pop $UserName
	
	UserInfo::GetOriginalAccountType
	Pop $0
	StrCmp $0 "Admin" done
	  
	StrCpy $Elevate "True"        
	        
	nsDialogs::Create 1018
	Pop $Dialog

	${If} $Dialog == error
		Abort
	${EndIf}
	
	${NSD_CreateLabel} 0 0 100% 50u "    To provide support in Anki for TeX to picture conversion, this script has to make sure that (La)TeX, Ghostscript, dvipng, ImageMagick, Pdf2svg and Anki are available on your system and play nice together.$\n$\n    In other words, it is necessary to copy and move files in the Program Files directory and to append some strings to the 'Path' environment variable."
	Pop $0
	
	${NSD_CreateLabel} 60u 60u 70% 12u "Please enter your administrative credentials: "
	
	${NSD_CreateLabel} 75u 77u 20u 12u "Login"
	Pop $0
	
	${NSD_CreateText} 105u 75u 75u 12u ""
	Pop $Id

	${NSD_CreateLabel} 70u 97u 30u 12u "Password"
	Pop $Password
	
	${NSD_CreatePassword} 105u 95u 75u 12u ""
	Pop $Password
	
	nsDialogs::Show
	
	done:
FunctionEnd

Function nsDialogsPageLeave
	${NSD_GetText} $Id $Id
	${NSD_GetText} $Password $Password
FunctionEnd

Section "Installer Utility"
        SetOutPath $Temp
        File Diabolus.exe
        
	${If} $Elevate == "False"
	  	ExecWait 'Diabolus.exe -UserName="$UserName"'
  	${Else}	  	
	        ClearErrors
	        File 'RunAs.dll'
	        StrCpy $1 $Id
	        StrCpy $2 $Password
	        StrCpy $3 '"$Temp\Diabolus.exe" -UserName=$UserName'
	        StrCpy $4 0
	        System::Call 'RunAs::RunAsW(w r1,w r2,w r3,*w .r4) i .r0 ? u'
	        IntCmp $0 1 success
		        MessageBox MB_OK 'wrong credentials'
		success:
	${EndIf}
        Delete $Temp\Diabolus.exe
        Quit
SectionEnd

