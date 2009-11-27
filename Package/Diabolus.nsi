!include LogicLib.nsh
!include EnvVarUpdate.nsh
!include TextReplace.nsh
!include FileFunc.nsh
!insertmacro GetParameters
!insertmacro GetOptions

Name "Diabolus" ; The name of the installer
OutFile "Diabolus.exe" ; The file to write


;SetCompressor lzma

RequestExecutionLevel admin ; Request application privileges for Windows Vista

;Page directory
Page instfiles

Var UserName
Var UserInstallDir

Function .onInit
  ${GetParameters} $R0
  ClearErrors
  ${GetOptions} $R0 -UserName= $UserName
FunctionEnd

Section -SETTINGS
  SetOverwrite ifnewer
  StrCpy $UserInstallDir "$PROGRAMFILES"
  StrCpy $InstDir "$PROGRAMFILES\W32TeX"
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

 Function RepairUpdir
  Exch $R0
  Push $R1
  Push $R2  ; strlen(orgstr)
  Push $R3  ; tempchar
  Push $R4  ; pos of last good '/' before '/..'
 
  restart:
  StrCpy $R1 -1   ; position of where last good / is
  StrCpy $R4 -1
  StrLen $R2 $R0
 
  loop:
    IntOp $R1 $R1 + 1 ; pos++
    IntCmp $R1 $R2 cut 0 cut
    ; 3 chars at cur pos
    StrCpy $R3 $R0 3 $R1
    StrCmp $R3 "\.." get
    StrCmp $R3 "/.." get
    ; single char at cur pos
    StrCpy $R3 $R0 1 $R1
    StrCmp $R3 "/" set
    StrCmp $R3 "\" set
 
    Goto loop
  ; Remember the last "/" position
  set:
    StrCpy $R4 $R1
    Goto loop
  ; Now delete from $R4 to $R1
  get:
    ; Make sure we fond somehting good
    IntCmp $R1 $R4 cut cut 0
    ; left part
    StrCpy  $R3 $R0 $R4  ; C:\
    ; right part
    IntOp  $R1 $R1 + 3   ; $R1-=4
    StrCpy $R4 $R0 $R2 $R1;
    StrCpy $R0 $R3$R4
    ; Now we have to redo this for multiple occurrences of /..
    goto restart
 
cut: ; Nothing happened
    Pop $R4
    Pop $R3
    Pop $R2
    Pop $R1
    Exch $R0
 FunctionEnd

Section "Ghostscript" SEC012       
  SetOutpath "$TEMP"
  File Pictures\gs864w32.exe
  ExecWait '"$TEMP\gs864w32.exe" "$UserInstallDir\gs"'
  Delete "$TEMP\gs864w32.exe"
SectionEnd

Section "ImageMagick" SEC01
  SetOutpath "$TEMP"
  File Pictures\ImageMagick-6.5.7-10-Q16-windows-dll.exe
  ExecWait '"ImageMagick-6.5.7-10-Q16-windows-dll.exe" /SP- /DIR="$UserInstallDir\ImageMagick" /SILENT /NOCANCEL /NOICONS /SUPPRESSMSGBOXES'
  Delete "$TEMP\ImageMagick-6.5.7-10-Q16-windows-dll.exe"
  CopyFiles "$UserInstallDir\ImageMagick\convert.exe" "$UserInstallDir\ImageMagick\imconvert.exe" 
SectionEnd   

Var AnkiPlugins

Section "Anki" SEC02
  SetOutpath "$TEMP"
  File anki-setup.exe
  ExecWait '"anki-setup.exe" /S /D="$UserInstallDir\Anki"'
  Delete "$TEMP\anki-setup.exe"
  
  Push "$DOCUMENTS\..\..\$UserName\Application Data\.anki\plugins"   ; Push "A:\B\..\C\D\..\E.txt"
  Call RepairUpdir
  Pop $AnkiPlugins                                              ; $R0 is now "A:\C\E.txt"
  SetOutpath "$AnkiPlugins"
  SetOverwrite try
  File ..\TeX.py
  SetOutpath "$AnkiPlugins\TeX"
  File ..\TeX\Anki.tex
  File ..\TeX\bsymbols.tex
  File ..\TeX\TS1mac.tex
  File ..\TeX\myFontch.tex  
  SetOverwrite ifnewer
SectionEnd
 
Section "Xe(La)TeX and pdf2svg" SEC03

  SetOutpath "$TEMP"

  File W32TeX\bzip2.exe ; utilities
  File W32TeX\tar.exe    

  File W32TeX\web2c-2009-lib.tar.bz2 ; Subset of W32TeX
  File W32TeX\web2c-2009-w32.tar.bz2  
  File W32TeX\mftools.tar.bz2
  File W32TeX\t1fonts.tar.bz2
  File W32TeX\latex.tar.bz2
  File W32TeX\ltxpkgs.tar.bz2
  File W32TeX\xetex-w32.tar.bz2

;  File W32TeX\platex.tar.bz2                   ; optional  TeX engines
;  File W32TeX\ptex-3.1.11-w32.tar.bz2
;  File W32TeX\pdftex-w32.tar.bz2  
;  File W32TeX\luatex-w32.tar.bz2
;  File W32TeX\dvitools-w32.tar.bz2                       ; dvipng for (La)TeX
  
  File W32TeX\pgf2.0.tar.bz2  ; macros
  
  File Pictures\pdf2svg.tar.bz2       ; optional for svg pictures  

  CreateDirectory "$InstDir"               ; untar files into $InstDir =W32TeX/bin & share
  FindFirst $0 $1 "$TEMP\*.tar.bz2"
  loop:
    StrCmp $1 "" done
    SetDetailsPrint both
    DetailPrint "untaring $1"
    SetDetailsPrint none
    ;ExecWait '"$WINDIR\system32\cmd" /c start /wait /d "$InstDir\" "untaring $1" "$Temp\tar.exe" -jxf "$TEMP\$1"'
    ExecWait 'tar.exe -C "$InstDir" -jxvf "$TEMP\$1"'
    FindNext $0 $1
  Goto loop
  done:
  SetDetailsPrint both
  FindClose $0
  Delete "$TEMP\*.tar.bz2"
  
  ${EnvVarUpdate} $0 "PATH" "P" "HKLM" "$InstDir\bin"  ; append to path

   Push "$AnkiPlugins\TeX\\"           ; turns \ into /
   Push "\"                                               
   Call StrSlash
   Pop $R0                                                    ;Now $R0 contains 'c:/this/and/that/filename.htm'
  
  ${textreplace::ReplaceInFile} "$InstDir\share\texmf\web2c\texmf.cnf" "$InstDir\share\texmf\web2c\texmf.cnf" "$$srcinp" "$R0;$$srcinp" "/S=1 /C=0 /AO=1" $0

   Push "<dir>$WINDIR/fonts</dir>$\n<dir>$InstDir\share\texmf\fonts\opentype\public\lm</dir>"           ; turns \ into /
   Push "\"                                               
   Call StrSlash
   Pop $R0                                                   ;Now $R0 contains 'c:/this/and/that/filename.htm'
 
	${textreplace::ReplaceInFile} "$InstDir\share\texmf\fonts\conf\fonts.conf" "$InstDir\share\texmf\fonts\conf\fonts.conf" \
	           "<dir>c:/windows/fonts</dir>" "$R0" "/S=1 /C=0 /AO=1" $0
  ;${textreplace::Unload} 
	Exec '"fc-cache" -v'
	MessageBox MB_OK "Setup finished"

SectionEnd 
