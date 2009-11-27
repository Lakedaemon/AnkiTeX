AnkiTeX brings support for cards with Tex or LaTeX markup inside [$][/$],  [$$][/$$] and [latex][/latex] cards.

The requirements for AnkiTeX are :

1) a working TeX distribution with XeTeX and XeLateX. 

 the string "path to Anki plugin folder\TeX" must be added in your TeX Input sources  

2) Ghosscript

It is needed by ImageMagick to work with pdf files

3) ImageMagick

on windows platform the executable "convert.exe" must be renamed/copied to a file called "imconvert.exe", in order not to conflict with another 
windows filesystem executable called convert.exe


How to make sure that all your components are working properly : 


1) type "xetex" in a console. If it doesn't find the executable, it means either that

a) you don't have xetex on your system
--> download and install xetex (go to section A)

b) you have xetex on your system but your path environment variable doesn't point to the directory where the xetex.exe executable is
--> append the path to the directory where xetex.exe is to the PATH environment variable


2) type "xelatex" in a console. The diagnosys and the remedies are the same with "xelatex" instead of xetex


3) type "gsview32" or "gsview64" in a console. If it doesn't find the executable, you need to install ghostscript.
(the GPL ghostscript installer makes sure that the PATH environment variable is rightly set)

4) In a console, type "imconvert" if you are on windows or type "convert" (in the other cases). 
If it doesn't find the executable, you need to install ImageMagick (the installer makes sure the PATH environment variable is rightly set)

if you are on windows, make sure that you make a copy named "imconvert.exe" of the file "convert.exe" that is in ImageMagick's directory.
 
 
                               Setup from scratch


A) Downloading and setingup a (La)TeX distribution including XeTeX and XeLateX on your system.

a) If you are on windows, you are lucky : I have created an installer that sets everything you need to run anki with TeX : 
it even updates Anki to it's latest snapshot (ask it nicely and I'll give a link).

If you don't want to use the installer : you can either use the W32TeX (simple, works great, has the best parts, easily customizable) 
or MikTeX (more features but more difficult to set up. I fled it a few years ago and never looked back).

b) If you are on Unix/linux, you are lucky too : unix/linux system usually ship with a working TeX/LaTeX distribution

c) If you are on a mac, well... you are on your own, I won't be able to help you as I don't own a mac (and i don't even want to touch one with a ten foot pole).
You'll have to set up it all yourself. The MacTeX distribution has been reported to work, see here http://www.tug.org/mactex/2009/



B) You'll find ghostscript there : http://pages.cs.wisc.edu/~ghost/doc/GPL/gpl864.htm (binaries are at the bottom)
C) You'll find imageMagick there : http://www.imagemagick.org/script/index.php

D) update your PATH environment variable so it finds the xetex, xelatex, gsview32, (im)convert executables 

E) Make sure xetex and xelatex know that they have to look for *.tex files in "The anki plugin folder"/TeX
This means updating the TeXInput strings in the TeX distributon based on web2c

good luck



