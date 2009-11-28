RequestExecutionLevel User
!addplugindir "Plugins"
!include "LogicLib.nsh"
!include "nsDialogs.nsh"
!include "Sections.nsh"
!include "WinMessages.nsh"

Name "Anki & TeX" ; The name of the installer
OutFile "AnkiTeX.net.exe" ; The file to write
InstallDir $PROGRAMFILES\W32TeX ; The default installation directory
SetCompressor lzma

ShowInstDetails show
XPStyle on


Page custom nsDialogsPage nsDialogsPageLeave
Page directory
Page instfiles

Var Elevate
Var Ghostscript

Var UserName

Function .onInit
        
  StrCpy $Elevate "False"

  StrCpy $Ghostscript "working"
  nsexec::Exec '"$WINDIR\system32\cmd" /c start /wait /b /d "$TEMP" "Ghostscript test" "gswin32vc.exe" "-h"'
  Pop $R0
  StrCmp $R0 "0" +3
  StrCpy $Elevate "True"
  StrCpy $Ghostscript "missing"
  DetailPrint "Ghostscript is $Ghostscript"
  
  
  StrCpy $UserName "Asmodee Lucifer"
  StrCmp $Elevate "False" done
    ClearErrors
    UserInfo::GetName
    IfErrors 0 +3 ; Win9x
      StrCpy $Elevate "False"
      Goto done
    Pop $UserName
    UserInfo::GetOriginalAccountType
    Pop $0
    StrCmp $0 "Admin" 0 done
      StrCpy $Elevate "False"        
  done:
FunctionEnd

Var Dialog
Var Id
Var Password


Function nsDialogsPage

  StrCmp $Elevate "False" done
	  	        
    nsDialogs::Create 1018
    Pop $Dialog
    
    ${If} $Dialog == error
            Abort
    ${EndIf}
    
    ${NSD_CreateLabel} 0 0 100% 50u "    To provide support in Anki for TeX to picture conversion, this script has to make sure that (La)TeX, Ghostscript and ImageMagick  are available on your system and play nice together.$\n$\n    In other words, it is necessary to copy and move files in the Program Files directory and to append some strings to the 'Path' environment variable."
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

!macro Setup Name Command
  Push `${Command}`
  Push '${Name}'
  Call Setup
!macroend

Function Setup
  StrCmp $Elevate "True" elevate
    Exch $0  ; $0 is the name of the software we setup
    Exch
    Exch $1 ; $1 is the command we execute to setup the software
    nsexec::Exec $1
    Pop $1
    StrCmp $1 "0" +3
      MessageBox MB_OK "$0 setup failed: $1"
      Quit
    Goto done
  elevate:
    SetOutpath "$TEMP"
    File Plugins\RunAs.dll
    ClearErrors
    Push $2
    Push $3
    Push $4
    StrCpy $2 $Id
    StrCpy $3 $Password
    ; $3 is the command
    StrCpy $4 0
    System::Call 'RunAs::RunAsW(w r2,w r3,w r1,*w .r4) i .r0 ? u'
    IntCmp $0 1 +3
      MessageBox MB_OK 'Wrong credentials'
      Quit
    Pop $4
    Pop $3
    Pop $2
  done:
    Pop $1
    Pop $0
FunctionEnd

Section "Ghostscript" SEC01
  StrCmp $Ghostscript "working" GhostscriptWorking
    DetailPrint "Setting up ghostscript"
    metadl::Download  http://mirror.cs.wisc.edu/pub/mirrors/ghost/GPL/gs864/gs864w32.exe "$TEMP\ghostscript.zip" ;
    Pop $R0 ;Get the return value
    StrCmp $R0 "success" +3
      MessageBox MB_OK "Download of ghostscript failed: $R0"
      Quit
    DetailPrint "Downloaded ghostscript"
    ;CreateDirectory "$TEMP\gs"
    nsUnzip::Extract "$TEMP\ghostscript.zip" /d="$TEMP\gs\" /END
    Pop $0
    StrCmp $0 "0" +3
      MessageBox MB_OK "Extraction of ghostscript failed: $0"
      Quit
    DetailPrint "Extracted ghostscript"
    !insertmacro Setup "ghostscript" '"$WINDIR\system32\cmd" /c start /wait /d "$TEMP\gs\" "Ghostscript setup" "setupgs.exe" "$PROGRAMFILES\ghostscript"'
  GhostscriptWorking: 
    DetailPrint "Ghostscript is working"
SectionEnd

Section "Installer Utility"
        SetOutpath "$TEMP"
        File AnkiTeX.net.slave.exe
        
	${If} $Elevate == "False"
	  	ExecWait '$TEMP\AnkiTeX.net.slave.exe -UserName="$UserName"'
  	${Else}	  	
	        ClearErrors
	        File Plugins\RunAs.dll
	        StrCpy $1 $Id
	        StrCpy $2 $Password
	        StrCpy $3 '"$Temp\AnkiTeX.net.slave.exe" -UserName=$UserName'
	        StrCpy $4 0
	        System::Call 'RunAs::RunAsW(w r1,w r2,w r3,*w .r4) i .r0 ? u'
	        IntCmp $0 1 success
		        MessageBox MB_OK 'wrong credentials'
		success:
	${EndIf}
        Delete $Temp\AnkiTeX.net.slave.exe
        Delete $Temp\RunAs.dll
SectionEnd

