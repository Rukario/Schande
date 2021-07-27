@echo off && goto loaded

import os, sys, time, inspect
from datetime import datetime
from threading import Thread



# Local variables
if len(sys.argv) > 3:
    filelist = list(filter(None, sys.argv[1].split("//")))
    pythondir = sys.argv[2].replace("\\\\", "\\")
    # batchdir = sys.argv[3].replace("\\\\", "\\") # grabs "start in" argument
else:
    filelist = []
    pythondir = ""
batchdir = os.path.dirname(os.path.realpath(__file__))
if "/" in batchdir and not batchdir.endswith("/"): batchdir += "/"
elif not batchdir.endswith("\\"): batchdir += "\\"
batchdirx = batchdir.replace("\\", "\\\\")
batchfile = os.path.basename(__file__)
batchname = os.path.splitext(batchfile)[0]
os.chdir(batchdir)

date = datetime.now().strftime('%Y') + "-" + datetime.now().strftime('%m') + "-XX"
mainfolder = f"Import {date}/"
cdfolder = f"Import {date} cd/"
htmlfile = batchname + ".html"
rulefile = batchname + ".cd"
savrfile = batchname + ".sav"
savrhtml = batchname + ".savx"
textfile = batchname + ".txt"



def title(echo, ss=False):
    if ss:
        echo = f"""[{newfilen[0]} new{f" after {retries[0]} retries" if retries[0] else ""}] {echo}"""
    sys.stdout.write("\033]0;" + echo + "\007")



cls = "\033[H\033[2J"
if sys.platform == "win32":
    tcolor = "\033[40;93m"
    tcolorr = "\033[40;91m"
    tcolorg = "\033[40;92m"
    tcolorb = "\033[40;94m"
    tcoloro = "\033[40;38;2;255;144;48m"
    tcolorx = "\033[48;2;0;90;128;96m"
    os.system("")
else:
    tcolor = "\033[40m"
    tcolorr = "\033[40;91m"
    tcolorg = "\033[40;92m"
    tcolorb = "\033[40;36m"
    tcoloro = "\033[40;38;2;255;144;48m"
    tcolorx = "\033[0m"
title(batchfile)
sys.stdout.write("Non-ANSI-compliant Command Prompt/Terminal (expect lot of visual glitches): Upgrade to Windows 10 if you're on Windows.")
sys.stdout.write(tcolorx + cls)



eps = 30
echofriction = [int(time.time()*eps)]
stdout = ["", ""]
def echolistener():
    while True:
        if stdout[0] or stdout[1]:
            sys.stdout.write(f"{stdout[1]}{stdout[0]}")
            stdout[0] = ""
            stdout[1] = ""
        time.sleep(1/eps)
t = Thread(target=echolistener)
t.daemon = True
t.start()



def echo(threadn, b=0, f=0, end="\r", friction=False):
    if not str(threadn).isdigit():
        stdout[0] = ""
        stdout[1] = ""
        sys.stdout.write("\033[A"*b + (f"{threadn:<113}" if end else threadn) + "\n"*f + end)
        if not end:
            sys.stdout.flush()
    elif not echothreadn or threadn == echothreadn[0]:
        if friction:
            stdout[0] = f"{b:<113}\r"
        else:
            stdout[0] = ""
            stdout[1] = ""
            sys.stdout.write(f"{b:<113}\r")
    else:
        return



Bs = [0]
Bstime = [int(time.time())]
fp = "▹"
MBs = [0]
for n in range(256):
    h = f"{n:02x}"
    h0 = int(h[0],16)
    h1 = int(h[1],16)
    fp += chr(10240+h1+int(h0/2)*16+int(h1/8)*64+int(h0/8)*64+(h0%2)*8-int(h1/8)*8)
def echoMBs(threadn, Bytes, ff):
    if not threadn or (x := echothreadn.index(threadn)) < len(fx[0]):
        fx[0][x if threadn else 0] = fp[ff]
    if echofriction[0] < int(time.time()*eps):
        echofriction[0] = int(time.time()*eps)
        stdout[1] = "\n\033]0;" + f"""[{newfilen[0]} new{f" after {retries[0]} retries" if retries[0] else ""}] {FAVORITE} {''.join(fx[0][:len(echothreadn) if threadn else 1])} {MBs[0]} MB/s""" + "\007\033[A"
    else:
        echofriction[0] = int(time.time()*eps)
    if Bstime[0] < int(time.time()):
        Bstime[0] = int(time.time())
        MBs[0] = f"{(Bs[0]+Bytes)/1048576:.2f}"
        Bs[0] = Bytes
    else:
        Bs[0] += Bytes
fx = [[fp[0]]*8]



def kill(threadn, echo=None, r=None, view=None):
    if not echo:
        print(threadn)
    elif r:
        print(f"""
 {echo}
 Please update or remove cookie from "{r}" setting in {rulefile} then restart CLI.""")
    else:
        print(f"""Thread {threadn} was killed {"by" if "(" in echo else "because"} {echo} {"(V)iew" if view else ""}""")
    if view and choice("v") == 1:
        print(view)
    sys.exit()



def met(p, n):
    if n[1] and p.endswith(n[1]) or n[2] and not p.endswith(n[2]) or n[3] and p.startswith(n[3]) or n[4] and not p.startswith(n[4]) or n[5] and not n[5][0] <= len(p) <= n[5][1]:
        return
    return True



def debug(e, b=0, f=1):
    echo(f"{inspect.getframeinfo(inspect.stack()[1][0]).lineno} {e}", b, f)



def golden_carrot(array, z, delayed_array, new, n, preserve, reverse):
    debug(f"""{tcolor}              Array: {array}{tcolorx}""")
    preservation_move = False # prevents loop hell
    p = "" # chosen string
    a = "" # pre-asterisk string
    aa = "" # accumulating string disposed by asterisk for fallback and/or preservation
    reverse_a = ""
    new_array = [array[0], array[1]]
    ii = False # First run, pre-asterisk string
    cc = False # First caret
    carrot_saver = []
    z = [0, z]
    pc = False # pre-caret, whether was there an asterisk before caret
    while True:
        ac = False
        z = z[1].rsplit("*", 1) if reverse else z[1].split("*", 1)
        if reverse:
            z.reverse()
        debug(f"""{tcolorb}Next: {z[0]} from {z} {"(rev)" if reverse else ""}{tcolorx}""")
        if z[0].startswith("^"):
            carrot_saver += [z[0].split("^", 1)[1]]
            if len(z) == 2:
                debug(f"""{tcoloro}^NEXT!{tcolorx}""")
                continue
            z[0] = ""
            cc = True
        if len(z) == 2 and not z[0] and not z[1]:
            debug(f"{tcolorr}  Witnessed greed pick all{tcolorx}")
            if met(new_array[0], n):
                if reverse:
                    array[1] = array[0]
                    if not preserve:
                        array[0] = ""
                    new += [["", ""]]
                else:
                    array[0] = ""
                    new += [[new_array[0] if preserve else "", new_array[0]]]
            return
        elif len(z) == 2 and not reverse and not z[0]:
            debug(f"{tcolorr}  First Z is empty{tcolorx}")
            y = ["", new_array[0]]
            preservation_move = True
        elif len(z) == 2 and reverse and not z[0]:
            debug(f"{tcolorr}  First Z is empty SPECIAL{tcolorx}")
            if not len(y := new_array[0].rsplit(z[1], 1) if reverse else new_array[0].split(z[1], 1)) == 2:
                debug(f"{tcolorg}  Can't divide, exited SPECIAL loop{tcolorx}")
                return
            array[0] = y[0] + z[1] if preserve else y[0]
            array[1] = y[1]
            new += [[y[1] if preserve else "", ""]]
            return
        elif not len(z) == 2 and reverse and not z[0]:
            debug(f"{tcolorr}  Just one Z and is empty (reversed){tcolorx}")
            y = ["", new_array[0]]
            preservation_move = True
        elif not z[0]:
            debug(f"{tcolorr}  Just one Z and is empty{tcolorx}")
            y = [new_array[0], ""]
        elif not len(y := new_array[0].rsplit(z[0], 1) if reverse else new_array[0].split(z[0], 1)) == 2:
            if reverse:
                delayed_array[0] = array[0]
                debug(f"{tcolorg}  Can't divide, updating delayed_array {delayed_array} then exited loop{tcolorx}")
            else:
                debug(f"{tcolorg}  Can't divide, exited loop{tcolorx}")
            return
        else:
            debug(f"{tcolorg}  Divided: {y}{tcolorx}")
        if len(z) == 2 and not reverse and not z[1]:
            debug(f"{tcolorr}  Second Z is empty SPECIAL{tcolorx}")
            if met(y[0], n):
                array[0] = y[1] if preserve else ""
                new += [[y[0] + z[0] if preserve else y[0], y[1]]]
            return
        if reverse:
            y.reverse()
        if carrot_saver:
            carrot_saver.reverse()
            debug(f"""{tcoloro}Carrot ready to split: {carrot_saver}{tcolorx}""")
            c = [y[0], y[1]]
            carrot_aa = ""
            for cs in carrot_saver:
                if not len(c := c[0].split(cs, 1) if reverse else c[0].rsplit(cs, 1)) == 2:
                    debug(f"{tcolorg}  Can't divide, exited CARET loop{tcolorx}")
                    if reverse:
                        debug(f"""{tcolorb}  Deleted delayed_array{tcolorx}""")
                        delayed_array[0] = ""
                    return
                debug(f"{tcolorg}  CARET divided: {c}{tcolorx}")
                if cc:
                    if reverse:
                        y[0] = c[0]
                    else:
                        y[1] = c[1]
                        c[1] = ""
                    cc = False
                carrot_aa = carrot_aa + c[0] + cs if reverse else cs + c[1] + carrot_aa
                if reverse:
                    c.reverse()
            if reverse:
                c.reverse()
            aa = carrot_aa + c[1] + aa if reverse else aa + c[0] + carrot_aa
            if not ii:
                ii = True, c[0]
            if reverse:
                y[0] = c[1] if pc else c[0]
            else:
                y[0] = c[0] if pc else c[1]
            ac = True
            debug(f"""{tcoloro}  Carrot pick "{y[0]}"{tcolorx}""")
            carrot_saver = []
            preservation_move = True
        if len(z) == 2:
            new_array[0] = y[1]
            aa = z[0] + y[0] + aa if reverse else aa + y[0] + z[0]
            if not ii:
                ii = True, y[0]
            pc = True
            debug(f"""{tcolor}       More - Array: {new_array}{tcolorx}""")
        else:
            p = y[0]
            if ac:
                y[0] = ""
            if not met(p, n):
                p = ""
                new_array[0] = y[1]
                if reverse:
                    reverse_a = aa + y[0] + z[0]
                else:
                    a = aa + y[0] + z[0]
                debug(f"{tcolorg}      Fallback: {aa}{tcolorx}")
            elif preserve:
                new_array[0] = y[1] if preservation_move else y[1] + z[0] if reverse else z[0] + y[1]
                if reverse:
                    reverse_a = y[0] + z[0] if preservation_move else y[0]
                    a = aa
                else:
                    a = aa + y[0] + z[0] if preservation_move else aa + y[0]
                debug(f"{tcolorg}      Fallback: {aa}{tcolorx}")
                if preservation_move:
                    debug(f"""{tcolorr}"{z[0]}" was moved{tcolorx}""")
            else:
                new_array[0] = y[1]
                a = ii[1] if ii else y[0]
                if reverse:
                    reverse_a = "" if ii else y[0]
            if n[0]:
                debug(f"{tcolorg}Customized: {tcoloro}{n[0][0]}{tcolor}{p}{tcoloro}{n[0][1]}{tcolorx}")
                p = n[0][0] + p + n[0][1]
            if reverse:
                new_array[0] += reverse_a
                new_array[1] = p
                debug(f"""{tcolorb}  Picking from delayed_array: {delayed_array} then exited loop{tcolorx}""")
                new += [[a, delayed_array[0]]]
                delayed_array[0] = p
                debug(f"""{tcolorb}  Updated in delayed_array: {delayed_array} then exited loop{tcolorx}""")
            else:
                debug(f"""{tcolorb}  Standard pick "{p}" then exited loop{tcolorx}""")
                new += [[a, p]]
            return True, new_array



def golden_carrots(data, x, any=True, cw=[], preserve=False, reverse=False):
    data = [[data[0][0], ""]]
    new_array = []
    n = [cw] + [""]*5
    if len(x := x.rsplit(" not ends with ", 1)) == 2:
        n[1] = x[1]
    x = x[0]
    if len(x := x.rsplit(" ends with ", 1)) == 2:
        n[2] = x[1]
    x = x[0]
    if len(x := x.rsplit(" not starts with ", 1)) == 2:
        n[3] = x[1]
    x = x[0]
    if len(x := x.rsplit(" starts with ", 1)) == 2:
        n[4] = x[1]
    x = x[0]
    if len(y := x.rsplit(" letters", 1)) == 2:
        y = y[0].rsplit(" ", 1)
        if len(z := y[1].split("-", 1)) == 2:
            if z[0].isdigit() and z[1].isdigit():
                n[5] = [int(z[0]), int(z[1])]
                x = y[0]
        else:
            if z[0].isdigit():
                n[5] = [int(z[0]), int(z[0])]
                x = y[0]
    new = []
    for array in data:
        delayed_array = [""]
        while True:
            new_array = golden_carrot(array, x, delayed_array, new, n, preserve, reverse)
            if not new_array:
                break
            array = new_array[1]
            if not any:
                break
        if reverse and delayed_array[0]:
            array[0] = delayed_array[0]
        new += [array]
    data = new
    if reverse:
        debug(f"{tcoloro}Reversed array: {data}{tcolorx}")
        data.reverse()
    debug(f"""{tcoloro}Return array: {data}{tcolorx}\n RECEIVING {", ".join([x[1] for x in data[:-1]])}""")
    if preserve:
        print(f""" PRESERVED {"".join([x[0] for x in data])}\n""")
    else:
        print()
    return data



def carrot(array, z, new, n):
    debug(f"""{tcolor}              Array: {array}{tcolorx}""")
    p = ""
    a = ""
    aa = ""
    new_array = [array[0], array[1]]
    ii = False
    cc = False
    carrot_saver = []
    z = [0, z]
    pc = False
    while True:
        ac = False
        z = z[1].split("*", 1)
        debug(f"""{tcolorb}Next: {z[0]} from {z}{tcolorx}""")
        if z[0].startswith("^"):
            carrot_saver += [z[0].split("^", 1)[1]]
            if len(z) == 2:
                debug(f"""{tcoloro}^NEXT!{tcolorx}""")
                continue
            z[0] = ""
            cc = True
        if len(z) == 2 and not z[0] and not z[1]:
            debug(f"{tcolorr}  Witnessed greed pick all{tcolorx}")
            if met(new_array[0], n):
                array[0] = ""
                new += [["", new_array[0]]]
            return
        elif len(z) == 2 and not z[0]:
            debug(f"{tcolorr}  First Z is empty{tcolorx}")
            y = ["", new_array[0]]
        elif not z[0]:
            debug(f"{tcolorr}  Just one Z and is empty{tcolorx}")
            y = [new_array[0], ""]
        elif not len(y := new_array[0].split(z[0], 1)) == 2:
            debug(f"{tcolorg}  Can't divide, exited loop{tcolorx}")
            return
        else:
            debug(f"{tcolorg}  Divided: {y}{tcolorx}")
        if len(z) == 2 and not z[1]:
            debug(f"{tcolorr}  Second Z is empty SPECIAL{tcolorx}")
            if met(y[0], n):
                array[0] = ""
                new += [[y[0], y[1]]]
            return
        if carrot_saver:
            carrot_saver.reverse()
            debug(f"""{tcoloro}Carrot ready to split: {carrot_saver}{tcolorx}""")
            c = [y[0], y[1]]
            carrot_aa = ""
            for cs in carrot_saver:
                if not len(c := c[0].rsplit(cs, 1)) == 2:
                    debug(f"{tcolorg}  Can't divide, exited CARET loop{tcolorx}")
                    return
                debug(f"{tcolorg}  CARET divided: {c}{tcolorx}")
                if cc:
                    y[1] = c[1]
                    c[1] = ""
                    cc = False
                carrot_aa = cs + c[1] + carrot_aa
            aa += c[0] + carrot_aa
            if not ii:
                ii = True, c[0]
            y[0] = c[0] if pc else c[1]
            ac = True
            debug(f"""{tcoloro}  Carrot pick "{y[0]}"{tcolorx}""")
            carrot_saver = []
        if len(z) == 2:
            new_array[0] = y[1]
            aa += y[0] + z[0]
            if not ii:
                ii = True, y[0]
            pc = True
            debug(f"""{tcolor}       More - Array: {new_array}{tcolorx}""")
        else:
            p = y[0]
            if ac:
                y[0] = ""
            if not met(p, n):
                p = ""
                new_array[0] = y[1]
                a = aa + y[0] + z[0]
                debug(f"{tcolorg}      Fallback: {aa}{tcolorx}")
            else:
                new_array[0] = y[1]
                a = ii[1] if ii else y[0]
            if n[0]:
                debug(f"{tcolorg}Customized: {tcoloro}{n[0][0]}{tcolor}{p}{tcoloro}{n[0][1]}{tcolorx}")
                p = n[0][0] + p + n[0][1]
            debug(f"""{tcolorb}  Standard pick "{p}" then exited loop{tcolorx}""")
            new += [[a, p]]
            return True, new_array



def carrots(data, x, any=True, cw=[]):
    new_array = []
    n = [cw] + [""]*5
    if len(x := x.rsplit(" not ends with ", 1)) == 2:
        n[1] = x[1]
    x = x[0]
    if len(x := x.rsplit(" ends with ", 1)) == 2:
        n[2] = x[1]
    x = x[0]
    if len(x := x.rsplit(" not starts with ", 1)) == 2:
        n[3] = x[1]
    x = x[0]
    if len(x := x.rsplit(" starts with ", 1)) == 2:
        n[4] = x[1]
    x = x[0]
    if len(y := x.rsplit(" letters", 1)) == 2:
        y = y[0].rsplit(" ", 1)
        if len(z := y[1].split("-", 1)) == 2:
            if z[0].isdigit() and z[1].isdigit():
                n[5] = [int(z[0]), int(z[1])]
                x = y[0]
        else:
            if z[0].isdigit():
                n[5] = [int(z[0]), int(z[0])]
                x = y[0]
    new = []
    for array in data:
        while True:
            new_array = carrot(array, x, new, n)
            if not new_array:
                break
            array = new_array[1]
            if not any:
                break
        new += [array]
    data = new
    debug(f"""{tcoloro}Return array: {data}{tcolorx}\n RECEIVING {", ".join([x[1] for x in data[:-1]])}\n""")
    return data



def golden(body, x):
    golden_carrots(body, x, True, [], False, False)
    golden_carrots(body, x, True, [], False, True)
    golden_carrots(body, x, True, [], True, False)
    golden_carrots(body, x, True, [], True, True)
    print("\n")



print("\n")
c = [["abcdefghijkl", ""]]
echo(f"golden_carrots(): EXPECTING B", 0, 1)
golden(c, "a*c")
echo(f"golden_carrots(): EXPECTING GREED PICK BEFORE B", 0, 1)
golden(c, "*b")
echo(f"golden_carrots(): EXPECTING GREED PICK AFTER B", 0, 1)
golden(c, "b*")
echo(f"golden_carrots(): EXPECTING GREED ALL", 0, 1)
golden(c, "*")



c = [["https:/b/gallery.com/e/f/image.png", ""]]
print(f"""golden_carrots(): EXPECTING b/gallery and e/f/image""")
print(f"""golden_carrots(): EXPECTING gallery and image (reverse)""")
golden(c, "/*.")

print("""golden_carrots(): EXPECTING gallery and image""")
print("""golden_carrots(): EXPECTING b/gallery.com/e/f/image (reverse)""")
golden(c, "^/*.")

print(f"""golden_carrots(): EXPECTING B and F""")
print(f"""golden_carrots(): EXPECTING gallery.com/e/f/image (reverse)""")
golden(c, "^/*^/*.")

print(f"""golden_carrots(): EXPECTING F""")
print(f"""golden_carrots(): EXPECTING gallery (reverse)""")
golden(c, "^/*^/*^.")

print(f"""golden_carrots(): EXPECTING b/gallery.com/e/f""")
print(f"""golden_carrots(): EXPECTING nothing (reverse)""")
golden(c, "/*^/*^.")

print("""Golden_carrots()'s preservation and right-to-left seem useless right now but they're there for completeness sake.\nAlternative: use caret for right-to-left match. There's no use-case for preservation yet.\ncarrots() is golden_carrots() minified to have useful functions only.\n""")

c = [["abcdefghijkl", ""]]
print("carrots(): EXPECTING B THEN H with leftover: defgijkl")
d = [["".join(x[0] for x in carrots(c, "a*c")), ""]]
print("LEFTOVER: " + "".join(x[0] for x in carrots(d, "g*i")) + "\n")
print(f"To demonstrate uselessness of golden_carrots()'s preservation, I just fetch from older variable: {c[0][0]}\n")

c = [["https:/b/gallery.com/e/f/image.png", ""]]
print("""carrots(): EXPECTING b/gallery and e/f/image" """)
carrots(c, "/*.")

print("""carrots(): EXPECTING gallery and image""")
carrots(c, "^/*.")

print("""carrots(): EXPECTING B and F""")
carrots(c, "^/*^/*.")

print("""carrots(): EXPECTING F""")
carrots(c, "^/*^/*^.", False)



while True:
    input(f"{tcolorr}S{tcoloro}U{tcolor}C{tcolorg}K{tcolorb}-{tcolorr}E{tcoloro}S{tcolor}S{tcolorg}!{tcolorx}")



"""
::MacOS - Install Python 3 then open Terminal and enter:
open /Applications/Python\ 3.9/Install\ Certificates.command
sudo python3 -m pip install --upgrade pip
sudo python3 -m pip install PySocks
sudo python3 -m pip install opencv-python
sudo python3 -m pip install numpy
sudo python3 -m pip install Pillow
python3 -x /drag/n/drop/the/batchfile

:loaded
set color=0e && set stopcolor=05
color %color%
set batchfile=%~0
if %cd:~-1%==\ (set batchdir=%cd%) else (set batchdir=%cd%\)
set txtfile=%~n0.txt
set txtfilex=%~dpn0.txt
::if "%cd:~0,3%" == "%cd%" (echo I shouldn't work at drive level&&pause>nul&&exit)

setlocal enabledelayedexpansion
set batchdir=!batchdir:\=\\!
set filelist=
if [%1]==[] goto skip
:loop
set file=%1
set file=!file:"=!
set filelist=!filelist!//!file!
shift
if not [%1]==[] goto loop
:skip

set pythondir=%userprofile%\AppData\Local\Programs\Python\
chcp 65001>nul
if exist "!txtfilex!" for /f "delims=" %%i in ('findstr /b /i "Python = " "!txtfilex!"') do set string=%%i&& set pythondir=!string:~9!&&goto check
:check
chcp 437>nul
set x=Python 3.9
set pythondirx=!pythondir!!x: 3.=3!
if exist "!pythondirx!\python.exe" (cd /d "!pythondirx!" && color %color%) else (if exist "!pythondirx!-32\python.exe" (cd /d "!pythondirx!-32\" && color %color%) else (color %stopcolor%
echo.
if "!string!"=="" (echo  I can't seem to find \!x: 3.=3!\python.exe^^! Install !x! in default location please, or edit this batch file.&&echo.&&echo  Download the latest !x!.x from https://www.python.org/downloads/&&echo  ^> 64-bit: Scroll down and choose !x!.x from list, look for a "x86-64 executable installer".) else (echo  Please fix path to \!x: 3.=3!\python.exe in "Python =" setting in !txtfile!)
echo.
echo  I must exit^^!
pause%>nul
exit))
set pythondir=!pythondir:\=\\!

if exist Lib\site-packages\socks.py (echo.) else (goto install)
if exist Lib\site-packages\cv2 (echo.) else (goto install)
if exist Lib\site-packages\numpy\ (echo.) else (goto install)
if exist Lib\site-packages\PIL (goto start) else (echo.)

:install
echo  Hold on . . . I need to install the missing packages.
if exist "Scripts\pip.exe" (echo.) else (color %stopcolor% && echo  PIP.exe doesn't seem to exist . . . Please install Python properly^^! I must exit^^! && pause>nul && exit)
python -m pip install --upgrade pip
Scripts\pip.exe install PySocks
Scripts\pip.exe install opencv-python
Scripts\pip.exe install numpy
Scripts\pip.exe install Pillow
echo.
pause

:start
cls
color %color%
python.exe -x "!batchfile!" "!filelist!" "!pythondir!" "!batchdir!"
set filelist=
color %stopcolor%
echo.
echo Restart CLI? Press any key to continue . . .
pause >nul
goto start
"""
