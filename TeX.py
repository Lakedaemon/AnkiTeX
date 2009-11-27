# -*- coding: utf-8 -*-
# Copyright: Olivier Binda <olivier.binda@wanadoo.fr>
# License: GNU GPL, version 3 or later; http://www.gnu.org/copyleft/gpl.html
# ---------------------------------------------------------------------------
# This file is a plugin for the "anki" flashcard application http://ichi2.net/anki/
# ---------------------------------------------------------------------------
# Version 1.0
import re,os, sys, subprocess, stat, time, shutil, tempfile

import anki
# hack for the fact editor Nothing changes...except that I have overloaded the mungeQA function
from ankiqt.ui.facteditor import *
from htmlentitydefs import entitydefs
latex = anki.latex




scale = 3

   
        
# for plain tex

pictureSuffix = ".svg"

latexDviPngCmd = ["F:\pdf2svg\pdf2svg.bat"]
  
regexps = {
"standard": (lambda x:x,re.compile(r"\[latex\](.+?)\[/latex\]", re.DOTALL | re.IGNORECASE)),
"expression": (lambda x:"$" + x + "$",re.compile(r"\[\$\](.+?)\[/\$\]", re.DOTALL | re.IGNORECASE)),
"math": (lambda x:"$$" + x + "$$",re.compile(r"\[\$\$\](.+?)\[/\$\$\]", re.DOTALL | re.IGNORECASE))
}

# for latex

pictureSuffix = ".png"

latexDviPngCmd = ["dvipng", "-D", "150", "-T", "tight","tmp.dvi","-o", "tmp.png"]

regexps = {
"standard": (lambda x:x,re.compile(r"\[latex\](.+?)\[/latex\]", re.DOTALL | re.IGNORECASE)),
"expression": (lambda x:"$" + x + "$",re.compile(r"\[\$\](.+?)\[/\$\]", re.DOTALL | re.IGNORECASE)),
"math": (lambda x:"\\begin{displaymath}" + x + "\\end{displaymath}",re.compile(r"\[\$\$\](.+?)\[/\$\$\]", re.DOTALL | re.IGNORECASE))
}     


# my Students

pictureSuffix = ".png"

# on windows, we had to change the name of the image magick convert utility from "convert.exe" to "imconvert.exe" to avoid conflict with a windows fylesystem exe called convert
if sys.platform == "win32" or sys.platform == "win64":
        latexDviPngCmd = ["imconvert", "-density","150", "tmp.pdf","-trim","+repage","tmp.png"]
else:
        latexDviPngCmd = ["convert", "-density","150", "tmp.pdf","-trim","+repage","tmp.png"]
        
regexps = {
"standard": (lambda x:x,re.compile(r"\[latex\](.+?)\[/latex\]", re.DOTALL | re.IGNORECASE)),
"expression": (lambda x:"$" + x + "$",re.compile(r"\[\$\](.+?)\[/\$\]", re.DOTALL | re.IGNORECASE)),
"math": (lambda x:"$$" + x + "$$",re.compile(r"\[\$\$\](.+?)\[/\$\$\]", re.DOTALL | re.IGNORECASE))
}

def latexWrap(latex):
        return """\\documentclass[12pt]{article}\n
                \\XeTeXdefaultencoding utf-8\n
                \\paperwidth=210truemm\\relax
                \\paperheight=297truemm\\relax
                \\pdfpagewidth=210truemm\\relax
                \\pdfpageheight=297truemm\\relax
                 \\pagestyle{empty}\n
                 \\begin{document}\n
                 %s\n
                 \\end{document}\n
                 """ % latex

def texWrap(latex):
        return """\\input Anki.tex\n
                %s\n
                \\bye\n
                """ % latex



latex.regexps= regexps
call = latex.call

tmpdir = "F:\\Temp\\TeX\\"
#tmpdir = tempfile.mkdtemp(prefix="anki")

from ankiqt import mw
from anki.sound import  stripSounds

def mungeQA(deck, txt):
    txt = renderLatex(deck, txt)
    txt = stripSounds(txt)
    return txt
    
def mungeQAB(deck, txt):
    txt = renderLatex(deck, txt)
    txt = stripSounds(txt)
    # hack to fix thai presentation issues
    if mw.bodyView.main.config['addZeroSpace']:
        txt = txt.replace("</span>", "&#8203;</span>")
    return txt
        
mw.bodyView.mungeQA = mungeQAB




def renderLatex(deck, text, build=True):
    "Convert TEXT with embedded latex tags to image links."
    for (func,reCompile) in regexps.values():
            for match in reCompile.finditer(text):
                    text = text.replace(match.group(), imgLink(deck, func(match.group(1)),
                                                   build))
    return text


def call(argv, wait=True, **kwargs):
    try:
        o = subprocess.Popen(argv, **kwargs)
    except OSError:
        # command not found
        return -1
    if wait:
        while 1:
            try:
                ret = o.wait()
            except OSError:
                # interrupted system call
                continue
            break
    else:
        ret = 0
    return ret

from anki.utils import checksum

def latexImgFile(deck, latexCode):
    key = checksum(latexCode)
    return ("latex-%s" % key) + pictureSuffix 
    
def mungeLatex(latex):
    "Convert entities, fix newlines, and convert to utf8."
    for match in re.compile("&([a-z]+);", re.IGNORECASE).finditer(latex):
        if match.group(1) in entitydefs:
            latex = latex.replace(match.group(), entitydefs[match.group(1)])
    latex = re.sub("<br( /)?>", "\n", latex)
    latex = latex.encode("utf-8")
    return latex    

def cacheAllLatexImages(deck):
    deck.startProgress()
    fields = deck.s.column0("select value from fields")
    for c, field in enumerate(fields):
        if c % 10 == 0:
            deck.updateProgress()
        renderLatex(deck, field)
    deck.finishProgress()

latex.cacheAllLatexImages = cacheAllLatexImages


def buildImg(deck, latex):    
    log = open(os.path.join(tmpdir, "latex_log.txt"), "w+")
    texpath = os.path.join(tmpdir, "tmp.tex")
    tempTexPath = texpath
    texpath = texpath.encode(sys.getfilesystemencoding())
    oldcwd = os.getcwd()
    if sys.platform == "win32":
        si = subprocess.STARTUPINFO()
        si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    else:
        si = None
    try:
        os.chdir(tmpdir)
        errmsg = _(
                "Error executing 'xetex' or 'dvipng'.\n"
            "A log file is available here:\n%s") % tmpdir
        texfile = file(tempTexPath, "w")
        texfile.write(texWrap(latex))
        texfile.close()
        # we shouldn't use texpath here because if you get a path with spaces 
        # or weird chars, like C:\document~\some thing\ it beaks (La)TeX. We could enclode the path in "", 
        # but why not use the filename, it's simpler
        if call(["xetex",  "-interaction=nonstopmode", #texpath
                 "tmp.tex"], stdout=log, stderr=log, startupinfo=si):
                texfile = file(tempTexPath, "w")
                texfile.write(latexWrap(latex))
                texfile.close()
                if call(["xelatex", "-interaction=nonstopmode", #texpath
                        "tmp.tex"], stdout=log, stderr=log, startupinfo=si):
                        return (False, errmsg)            
        if call(latexDviPngCmd,
                stdout=log, stderr=log, startupinfo=si):            
            return (False, errmsg)
        if pictureSuffix==".svg":        
                scale = 2
                txt = open("tmp.txt","r" ) 
                (width,height,xOffset,yOffset) = tuple(map(lambda x:int(x.strip('+-\n')),txt.read().split(',')))
                txt.close()
                replacment = 'width="%s" height="%s" viewBox="%s %s %s %s"' % (scale*(width+1),scale*(height+1),xOffset,yOffset,width+1,height+1) # some pictures are 1 pixel cropped
                src = open("tmp.svg","r")
                myList = []
                for Line in src:
                        if Line.find('viewBox'):
                                myList.append(re.sub(r'width="[^"]*" height="[^"]*" viewBox="[^"]*"',replacment,Line))
                        else:
                                myList.append(Line)
                src.close() 
                dst = open("tmp.svg","w" )  
                dst.write("".join(myList)) 
                dst.close()    
        # add to media
        target = latexImgFile(deck, latex)
        shutil.copy2("tmp"+pictureSuffix, os.path.join(deck.mediaDir(create=True),
                                             target))
        return (True, target)
    finally:
        os.chdir(oldcwd)
        
anki.latex.buildImg = buildImg     

def imageForLatex(deck, latex, build=True):
    "Return an image that represents 'latex', building if necessary."
    imageFile = latexImgFile(deck, latex)
    ok = True
    if build and (not imageFile or not os.path.exists(imageFile)):
        (ok, imageFile) = buildImg(deck, latex)
    if not ok:
        return (False, imageFile)
    return (True, imageFile)

def imgLink(deck, latex, build=True):
    "Parse LATEX and return a HTML image representing the output."
    latex = mungeLatex(latex)
    (ok, img) = imageForLatex(deck, latex, build)
    if ok:
        return '<img src="%s">' % img
    else:
        return img
# I need to override mungeQA in there
def updateCard(self):
        c = self.cards[self.currentCard]
        styles = (self.deck.css +
                  ("\nhtml { background: %s }" % c.cardModel.lastFontColour) +
                  "\ndiv { white-space: pre-wrap; }")
        styles = runFilter("addStyles", styles, c)
        self.dialog.webView.setHtml(
            ('<html><head>%s</head><body>' % getBase(self.deck)) +
            "<style>" + styles + "</style>" +
            runFilter("drawQuestion", mungeQA(self.deck, c.htmlQuestion()),
                      c) +
            "<br><br><hr><br><br>" +
            runFilter("drawAnswer", mungeQA(self.deck, c.htmlAnswer()),
                      c)
            + "</body></html>")
        playFromText(c.question)
        playFromText(c.answer)

ui.facteditor.PreviewDialog.updateCard=updateCard  

