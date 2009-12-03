!addplugindir Plugins
!include LogicLib.nsh
!include nsDialogs.nsh
!include Sections.nsh
!include WinMessages.nsh
!include TextReplace.nsh
!include Plugins\EnvVarUpdate.nsh
!include FileFunc.nsh
!insertmacro GetParameters
!insertmacro GetOptions

Name "Anki & TeX" ; The name of the installer
OutFile "AnkiTeX.net.exe" ; The file to write
InstallDir $PROGRAMFILES\W32TeX ; The default installation directory
SetCompressor lzma

ShowInstDetails show
XPStyle on


Page custom nsDialogsPage nsDialogsPageLeave
;Page directory
Page instfiles



Var Cmd
Var Ghostscript
Var ImageMagick
Var ImageMagickPath
Var XeTeX

Var Elevate
Var UserName
Var Id
Var Password

Var Dialog
Var Output

;ReadEnvStr $R0 COMSPEC
;nsExec::Exec "$R0 /C net ..."

Function Test 
  StrCpy $Elevate "False"
  SetDetailsPrint none
  SetOutpath "$TEMP"
  File Helpers\Find.bat
      
  StrCpy $Ghostscript "working"
  nsexec::Exec '"$Cmd" /c "$Temp\Find.bat gswin32c.exe>$Temp\Output.txt"'
  Pop $R0
  StrCmp $R0 "0" +4
    StrCpy $Elevate "True"
    StrCpy $Ghostscript "missing"
    Goto FindGhostscript
    
    ${textreplace::FindInFile} "$Temp\Output.txt" "gswin32c.exe"  "/S=1" $Output
    IntCmp $Output 0 +1 +1 FindGhostscript
      StrCpy $Elevate "True"
      StrCpy $Ghostscript "missing"
      
  FindGhostscript:  
  StrCpy $ImageMagick "working"
  nsexec::Exec '"$Cmd" /c  "$Temp\Find.bat imconvert.exe>$Temp\Output.txt"'
  Pop $R0
  StrCmp $R0 "0" +4
    StrCpy $Elevate "True"
    StrCpy $ImageMagick "probably not working"
    Goto FindXeTeX
     
    ${textreplace::FindInFile} "$Temp\Output.txt" "imconvert.exe"  "/S=1" $Output
    IntCmp $Output 0 +1 +1 FindXeTeX
      StrCpy $Elevate "True"
      StrCpy $ImageMagick "missing"
      nsexec::Exec '"$Cmd" /c "$Temp\Find.bat identify.exe>$Temp\Output.txt"'
      ${textreplace::ReplaceInFile} "$Temp\Output.txt" "$Temp\Output.txt" "\identify.exe" "" "/S=1" $Output
      IntCmp $Output 0 FindXeTeX FindXeTeX +1
        Push 1 ;line number to read from
        Push "$Temp\Output.txt" ;text file to read
        Call ReadFileLine
        Pop $ImageMagickPath ;output string (read from file.txt)
        	StrCpy $ImageMagickPath "$ImageMagickPath" -2  	;Have to remove the \r\n at the end
        	IfFileExists "$ImageMagickPath\convert.exe" +1 FindXeTeX
          StrCpy $ImageMagick "missing the right name"
          
  FindXeTeX: 
  StrCpy $XeTeX "working"
  nsexec::Exec '"$Cmd" /c  "$Temp\Find.bat xetex.exe>$Temp\Output.txt"'          
  Pop $R0
  StrCmp $R0 "0" +4
    StrCpy $Elevate "True"
    StrCpy $XeTeX "missing"
    Goto CleanUp
    
    ${textreplace::FindInFile} "$Temp\Output.txt" "xetex.exe"  "/S=1" $Output
    IntCmp $Output 0 +1 +1 +4
      StrCpy $Elevate "True"
      StrCpy $XeTeX "missing"
      Goto CleanUp
      
      nsexec::Exec '"$Cmd" /c  "$Temp\Find.bat xelatex.exe>$Temp\Output.txt"'          
      Pop $R0
      StrCmp $R0 "0" +4
        StrCpy $Elevate "True"
        StrCpy $XeTeX "missing"
        Goto CleanUp
    
        ${textreplace::FindInFile} "$Temp\Output.txt" "xelatex.exe"  "/S=1" $Output
        IntCmp $Output 0 +1 +1 CleanUp
          StrCpy $Elevate "True"
          StrCpy $XeTeX "missing"
  CleanUp:   
  Delete Helpers\Find.bat
  SetDetailsPrint both
FunctionEnd        

Function .onInit
   ReadEnvStr $Cmd COMSPEC

   Call Test

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
    Pop $0
    
    ${NSD_CreatePassword} 105u 95u 75u 12u ""
    Pop $Password
    
    nsDialogs::Show
	
  done:
FunctionEnd

Function nsDialogsPageLeave
	${NSD_GetText} $Id $Id
	${NSD_GetText} $Password $Password
FunctionEnd


Function ReadFileLine
        Exch $0 ;file
        Exch
        Exch $1 ;line number
        Push $2
        Push $3
         
          FileOpen $2 $0 r
         StrCpy $3 0
         
        Loop:
         IntOp $3 $3 + 1
          ClearErrors
          FileRead $2 $0
          IfErrors +2
         StrCmp $3 $1 0 loop
          FileClose $2
         
        Pop $3
        Pop $2
        Pop $1
        Exch $0
FunctionEnd



!macro Setup Name Command
  Push `${Command}`
  Push '${Name}'
  Call Setup
!macroend

Var Message
Function Setup
  StrCpy $Message "$0 setup failed:"
  Exch $0  ; $0 is the name of the software we setup
  Exch
  Exch $1 ; $1 is the command we execute to setup the software
  StrCmp $Elevate "True" elevate
    nsexec::Exec $0
    Pop $0
    StrCmp $0 "0" +3
      MessageBox MB_OK "$Message $0"
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
      MessageBox MB_OK 'Wrong credentials or $Message $0'
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
    DetailPrint "Ghostscript is $Ghostscript"
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
    !insertmacro Setup "ghostscript" '"$Cmd" /c start /wait /d "$TEMP\gs\" "Ghostscript setup" "setupgs.exe" "$PROGRAMFILES\ghostscript"'
    ${EnvVarUpdate} $0 "PATH" "P" "HKCU" "$PROGRAMFILES\ghostscript\gs8.64\bin"
  GhostscriptWorking: 
    DetailPrint "Ghostscript is working"
SectionEnd

Section "ImageMagick" SEC02
  StrCmp $ImageMagick "working" ImageMagickWorking
    DetailPrint "imagemagick is $ImageMagick"
    StrCmp $ImageMagick "missing the right name" ImageMagickCopy
    DetailPrint "Setting up imagemagick"
    SetOutpath "$TEMP"
    metadl::download  http://www.imagemagick.org/download/binaries/ImageMagick-i686-pc-windows.exe "$TEMP\ImageMagick.exe" ;
    ;File Pictures\ImageMagick-6.5.7-10-Q16-windows-dll.exe
    StrCpy $ImageMagickPath "$PROGRAMFILES\ImageMagick"
    ;ExecWait '"im.exe" /SP- /DIR="$ImageMagickPath" /SILENT /NOCANCEL /NOICONS /SUPPRESSMSGBOXES'
    !insertmacro Setup "ImageMagick Setup" '"$Cmd" /c start /wait /d "$TEMP\" ImageMagick.exe /SP- /DIR="$ImageMagickPath" /SILENT /NOCANCEL /NOICONS /SUPPRESSMSGBOXES'
    ;Delete "$TEMP\ImageMagick-6.5.7-10-Q16-windows-dll.exe"
    ImageMagickCopy:
      DetailPrint "Copying convert.exe to imconvert.exe"
      !insertmacro Setup "ImageMagick Copy" '"$Cmd" /c copy "$ImageMagickPath\convert.exe" "$ImageMagickPath\imconvert.exe"'
  ImageMagickWorking:  
      DetailPrint "ImageMagick is working"
SectionEnd   

Function StrSlash
  Exch $R3 ; $R3 = needle ("\" or "/")
  Exch
  Exch $R1 ; $R1 = String to replacement in (haystack)
  Push $R2 ; Replaced haystack
  Push $R4 ; $R4 = not $R3 ("/" or "\")
  Push $R6
  Push $R7 ; Scratch reg
  StrCpy $R2 ""
  StrLen $R6 $R1
  StrCpy $R4 "\"
  StrCmp $R3 "/" loop
  StrCpy $R4 "/"  
loop:
  StrCpy $R7 $R1 1
  StrCpy $R1 $R1 $R6 1
  StrCmp $R7 $R3 found
  StrCpy $R2 "$R2$R7"
  StrCmp $R1 "" done loop
found:
  StrCpy $R2 "$R2$R4"
  StrCmp $R1 "" done loop
done:
  StrCpy $R3 $R2
  Pop $R7
  Pop $R6
  Pop $R4
  Pop $R2
  Pop $R1
  Exch $R3
FunctionEnd

Section "Xe(La)TeX and pdf2svg" SEC03
  StrCmp $XeTeX "working" XeTeXWorking
    DetailPrint "XeTeX is $XeTeX"
    SetOutpath "$TEMP"
    metadl::download  http://w32tex.org/current/latex.tar.bz2 "$Temp\latex.tar.bz2"
    metadl::download  http://w32tex.org/current/mftools.tar.bz2 "$Temp\mftools.tar.bz2"
    metadl::download  http://w32tex.org/current/web2c-2009-lib.tar.bz2 "$Temp\web2c-2009-lib.tar.bz2" 
    metadl::download  http://w32tex.org/current/web2c-2009-w32.tar.bz2 "$Temp\web2c-2009-w32.tar.bz2"

  ;!insertmacro Download "$Temp" "ltxpkgs.tar.bz2" "http://w32tex.org/current/ltxpkgs.tar.bz2"
    metadl::download  http://w32tex.org/current/t1fonts.tar.bz2 "$Temp\t1fonts.tar.bz2" 
    metadl::download  http://w32tex.org/current/xetex-w32.tar.bz2 "$Temp\xetex-w32.tar.bz2"


;  File W32TeX\platex.tar.bz2                   ; optional  TeX engines
;  File W32TeX\ptex-3.1.11-w32.tar.bz2
;  File W32TeX\pdftex-w32.tar.bz2  
;  File W32TeX\luatex-w32.tar.bz2
;  File W32TeX\dvitools-w32.tar.bz2                       ; dvipng for (La)TeX

  ;File W32TeX\pgf2.0.tar.bz2  ; macros
  
  ;File Pictures\pdf2svg.tar.bz2       ; optional for svg pictures  
  SetOutpath "$TEMP"

  File Helpers\bzip2.exe ; utilities
  File Helpers\tar.exe    
  CreateDirectory "$PROGRAMFILES\W32TeX"               ; untar files into $InstDir =W32TeX/bin & share
  FindFirst $0 $1 "$TEMP\*.tar.bz2"
  loop:
    StrCmp $1 "" done
    SetDetailsPrint both
    DetailPrint "untaring $1"
    SetDetailsPrint none
    !insertmacro Setup "untaring $1" '"$Cmd" /c start /wait /d "$PROGRAMFILES\W32TeX\" "untaring $1" "$Temp\tar.exe" -jxvf "$TEMP\$1"'
    ;ExecWait '"$WINDIR\system32\cmd" /c start /wait /d "$InstDir\" "untaring $1" "$Temp\tar.exe" -jxf "$TEMP\$1"'
    ;ExecWait 'tar.exe -C "$InstDir" -jxvf "$TEMP\$1"'
    ;untgz::extract "-d" "$PROGRAMFILES\W32TeX" "$TEMP\$1"
    FindNext $0 $1
  Goto loop
  done:
  FindClose $0
  SetDetailsPrint both

    
  metadl::download  http://sourceforge.net/projects/pgf/files/pgf/version%202.00/pgf-2.00.tar.gz/download "$Temp\pgf.tar.bz2"
  !insertmacro Setup "untaring Pgf/Tikz" '"$Cmd" /c start /wait /d "$Temp\" "untaring Pgf/Tikz" "$Temp\tar.exe" -jxf "$TEMP\pgf"'
  ;untgz::extract "-d" "$TEMP" "$TEMP\pgf"
  !insertmacro Setup "copying generic" '"$Cmd" /c start /wait /d "$Temp\" "copying generic" xcopy generic "$PROGRAMFILES\W32TeX\share\texmf\tex\" /T /E'
  ;CopyFiles /SILENT "$TEMP\generic" "$PROGRAMFILES\W32TeX\share\texmf\tex\"
  !insertmacro Setup "copying \latex" '"$Cmd" /c start /wait /d "$Temp\" "copying \latex" xcopy latex "$PROGRAMFILES\W32TeX\share\texmf\tex\" /T /E'
 ; CopyFiles /SILENT "$TEMP\latex" "$PROGRAMFILES\W32TeX\share\texmf\tex\"
  !insertmacro Setup "copying plain" '"$Cmd" /c start /wait /d "$Temp\" "copying plain" xcopy plain "$PROGRAMFILES\W32TeX\share\texmf\tex\" /T /E'
  ;CopyFiles /SILENT "$TEMP\plain" "$PROGRAMFILES\W32TeX\share\texmf\tex\"
  !insertmacro Setup "copying context" '"$Cmd" /c start /wait /d "$Temp\" "copying context" xcopy context "$PROGRAMFILES\W32TeX\share\texmf\tex\" /T /E'
  ;CopyFiles /SILENT "$TEMP\context" "$PROGRAMFILES\W32TeX\share\texmf\tex\"
  !insertmacro Setup "copying doc" '"$Cmd" /c start /wait /d "$Temp\" "copying doc" xcopy doc "$PROGRAMFILES\W32TeX\share\texmf\" /T /E'
  ;CopyFiles /SILENT "$TEMP\doc" "$PROGRAMFILES\W32TeX\share\texmf\"
  Delete "$TEMP\pgf"  

  Push "<dir>$WINDIR/fonts</dir>$\n<dir>$InstDir\share\texmf\fonts\opentype\public\lm</dir>"           ; turns \ into /
  Push "\"                                               
  Call StrSlash
  Pop $R0                                                   ;Now $R0 contains 'c:/this/and/that/filename.htm'
  ${textreplace::ReplaceInFile} "$PROGRAMFILES\W32TeX\share\texmf\fonts\conf\fonts.conf" "$Temp\fonts.conf" "<dir>c:/windows/fonts</dir>" "$R0" "/S=1 /C=0 /AO=1" $0
  !insertmacro Setup "copying fonts.conf" '"$Cmd" /c copy "$Temp\fonts.conf" "$PROGRAMFILES\W32TeX\share\texmf\fonts\conf\fonts.conf"' 

  ${EnvVarUpdate} $0 "PATH" "P" "HKCU" "$PROGRAMFILES\W32TeX\bin"

  CreateDirectory "$APPDATA\.anki\plugins\TeX"
  Push "$APPDATA\.anki\plugins\TeX\\"           ; turns \ into /
  Push "\"                          
  Call StrSlash
  Pop $R0            ;Now $R0 contains 'c:/this/and/that/filename.htm'
  ${textreplace::ReplaceInFile} "$PROGRAMFILES\W32TeX\share\texmf\web2c\texmf.cnf" "$Temp\texmf.cnf" "$$srcinp" "$R0;$$srcinp" "/S=1 /C=0 /AO=1" $0
  !insertmacro Setup "copying texmf.cnf" '"$Cmd" /c copy "$Temp\texmf.cnf" "$PROGRAMFILES\W32TeX\share\texmf\web2c\texmf.cnf"'  
  
  Delete bzip2.exe
  Delete tar.exe
  XeTeXWorking:	
  DetailPrint "XeTeX is working"
  DetailPrint "Updating the XeTeX font cache"
  SetDetailsPrint none
  ExecWait 'fc-cache -v'
  ;Exec '"$Cmd" /c start /wait /d "$Temp\" "Updating the XeTeX Font Cache" fc-cache -v'
  SetDetailsPrint both
  
SectionEnd

Section Finish SEC04
        
   Call Test
   StrCmp $Elevate "True" Failed
     Delete "$TEMP\*.tar.bz2"
     MessageBox MB_OK "Setup succeeded: $\n$\n Ghostscript is $Ghostscript$\n ImageMagick is $ImageMagick$\n XeTeX is $XeTeX"     
     Quit
   Failed:
     MessageBox MB_OK "Setup failed : $\n$\n Ghostscript is still $Ghostscript$\n ImageMagick is still $ImageMagick$\n XeTeX is still $XeTeX"     
     Quit
SectionEnd
