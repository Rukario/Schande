@echo off && goto loaded

r"""
::MacOS:           open /Applications/Python\ 3.10/Install\ Certificates.command
::Linux/MacOS:     python3 -x /drag/n/drop/the/batchfile

::if MacOS (pip=sudo python3 -m pip) else if Linux (pip=pip3)
::update pip:      %pip% install --upgrade pip
::install package: %pip% install name_of_the_missing_package

:loaded
set color=0e && set stopcolor=06
color %color%
set batchfile=%~0
if %cd:~-1%==\ (set batchdir=%cd%) else (set batchdir=%cd%\)
set pythondir=%userprofile%\AppData\Local\Programs\Python\
if exist "%~n0.cd" (set tcd=%~n0.cd&&set TXT=%~dpn0.cd) else if exist "%~n0.txt" (set tcd=%~n0.txt&&set TXT=%~dpn0.txt)

setlocal enabledelayedexpansion
chcp 65001>nul
if not "!TXT!"=="" for /f "delims=" %%i in ('findstr /b /i "Python = " "!TXT!"') do set string=%%i&& set string=!string:~9!&&chcp 437>nul&& goto check
chcp 437>nul
:check
if not "!string!"=="" (set pythondir=!string!)
set x=Python 3.13
set cute=!x:.=!
set cute=!cute: =!
set pythondirx=!pythondir!!cute!
if exist "!pythondirx!\python.exe" (cd /d "!pythondirx!" && color %color%) else (color %stopcolor%
echo.
if "!string!"=="" (echo  I can't seem to find \!cute!\python.exe^^! Install !x! in default location please, or edit this batch file.&&echo.&&echo  Download the latest !x!.x from https://www.python.org/downloads/) else (echo  Please fix path to \!cute!\python.exe in "Python =" setting in !tcd!)
echo.
echo  I must exit^^!
pause%>nul
exit)
set pythondir=!pythondir:\=\\!

set batchdir=!batchdir:\=\\!
set filelist=
if [%1]==[] goto skip
set n=!cmdcmdline:*%~f0=!
if ["!n:~2,8!"]==["magnet:?"] set filelist=!n:~2,-1!&&goto skip
:loop
set file=%1
set file=!file:"=!
set filelist=!filelist!//!file!
shift
if not [%1]==[] goto loop
:skip

if exist Lib\site-packages\cv2 (echo.) else (goto install)
if exist Lib\site-packages\numpy\ (echo.) else (goto install)
if exist Lib\site-packages\PIL (goto start) else (echo.)

:install
echo  Hold on . . . I need to install the missing packages.
if exist "Scripts\pip.exe" (echo.) else (color %stopcolor% && echo  PIP.exe doesn't seem to exist . . . Please install Python properly^^! I must exit^^! BYE pause>nul && exit)
python -m pip install --upgrade pip
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



import os, sys, cv2, numpy, time
from queue import Queue
from threading import Thread
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont
from urllib import parse

batchfile = os.path.basename(__file__)
batchname = os.path.splitext(batchfile)[0]
batchdir = os.path.dirname(os.path.realpath(__file__)).replace("\\", "/")
filelist = []
pythondir = ""

if len(sys.argv) > 3:
    filelist = list(filter(None, sys.argv[1].split("//")))
    pythondir = sys.argv[2].replace("\\\\", "\\") # unused
    # batchdir = sys.argv[3].replace("\\\\", "\\") # grabs "start in" argument
if "/" in batchdir and not batchdir.endswith("/"):
    batchdir += "/"
os.chdir(batchdir)


browser = "C:\\Program Files\\Mozilla Firefox\\firefox.exe"
imagefile = [".gif", ".jpe", ".jpeg", ".jpg", ".png"]
imagefile2 = [".heic"]
videofile = [".mkv", ".mp4", ".webm", ".ts"]



def ansi(c):
    if len(c) == 3:
        c = "".join(x*2 for x in c)
    return ";".join(str(int(x, 16)) for x in [c[0:2], c[2:4], c[4:6]])

def ansi_color(b=False, f="F9F1A5"):
    if not b:
        return "\033[0m"
    b = f"4{b}" if len(b) == 1 else "48;2;" + ansi(b)
    f = f"9{f}" if len(f) == 1 else "38;2;" + ansi(f)
    return f"\033[{b};{f}m"



def title(t):
    sys.stdout.write("\033]0;" + t + "\007")
cls = "\033[H\033[2J"
tcolor = ansi_color("0")
tcolorr = ansi_color("0", "1")
tcolorg = ansi_color("0", "2")
tcolorb = ansi_color("0", "3B78FF")
tcoloro = ansi_color("0", "FF9030")
if sys.platform == "darwin":
    tcolorx = ansi_color()
else:
    tcolorx = ansi_color("005A80", "6")
    # tcolorx = ansi_color("2A211C", "BDAE9D")
    os.system("")
title(batchfile)



sys.stdout.write(tcolorx + cls)

if not os.path.exists("ffmpeg.exe"):
    print("ffmpeg.exe is missing . . . I must exit!\n\n Download win64-lgpl.zip from https://github.com/BtbN/FFmpeg-Builds/releases")
    sys.exit()



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



def echo(threadn, b=0, f=0, friction=False):
    if not str(threadn).isdigit():
        stdout[0] = ""
        stdout[1] = ""
        sys.stdout.write("\033[A"*b + f"{threadn:<113}" + "\n"*f + "\r")
    elif not echothreadn or threadn == echothreadn[0]:
        if friction:
            stdout[0] = f"{b:<113}\r"
        else:
            stdout[0] = ""
            stdout[1] = ""
            sys.stdout.write(f"{b:<113}\r")
    else:
        return

def choice(keys="", bg=False, persist=False):
    if sys.platform == "win32":
        if bg: os.system(f"""color {"%stopcolor%" if bg == True else bg}""")
        if keys: el = os.system(f"choice /c:{keys} /n")
        if bg and not persist: os.system("color %color%")
    else:
        if keys: el = os.system("""while true; do
read -s -n 1 el || break
case $el in
""" + "\n".join([f"{k} ) exit {e+1};;" for e, k in enumerate(keys)]) + """
esac
done""")
    echo(tcolorx)
    if not keys: return
    if el >= 256:
        el /= 256
    return el

def kill(threadn, e=None):
    if not e:
        echo(f"{tcolorr}{threadn}{tcolorx}", 0, 1)
    else:
        echo(f"""{tcolorr}Thread {threadn} was killed {"by" if "(" in e else "because"} {e}{tcolorx}""", 0, 1)
    sys.exit()



def lazy():
    master = cv2.imread(f"{batchname} LIGHT.png")
    slave = cv2.imread(f"{batchname} DARK.png")
    witnessedsq = Image.open(f"{batchname}.png")
    witnessedsq = numpy.array(witnessedsq)
    witnessedsq = cv2.cvtColor(witnessedsq, cv2.COLOR_BGRA2BGR)
    witnessedsq_g = cv2.cvtColor(witnessedsq, cv2.COLOR_BGR2GRAY)



    kernel = numpy.ones((5,5),numpy.uint8)
    gapfix = cv2.copyMakeBorder(witnessedsq_g,10,10,10,10,cv2.BORDER_CONSTANT,value=000000)
    gapfix = cv2.morphologyEx(gapfix, cv2.MORPH_CLOSE, kernel)
    height, width = gapfix.shape
    gapfix = gapfix[10:height-10, 10:width-10]
    contours, _ = cv2.findContours(gapfix, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    for contour in contours:
        (x,y,w,h) = cv2.boundingRect(contour)
        if h > 2:
            wx = x
            # 'True' to enable width multiplier vs height to handle first character that is identical.
            if False:
                wx = x+w-int(h*12.25)
            if wx < 0:
                wx = 0
            # TOP
            cv2.line(gapfix, (x+w-1,y), (wx,y), (255,255,255), 1)
            # BOTTOM
            cv2.line(gapfix, (x+w-1,y+h-1), (wx,y+h-1), (255,255,255), 1)
            # added RIGHT side for better handle several certain character with apertures
            cv2.line(gapfix, (x+w-1,y), (x+w-1,y+h-1), (255,255,255), 1)
            # added LEFT side for better handle several certain character with apertures
            cv2.line(gapfix, (wx,y), (wx,y+h-1), (255,255,255), 1)

    # Rectangles so you can see for yourself.
    if False:
        cv2.imwrite(f"{batchname} SQ.png", gapfix)



    kernel = numpy.ones((7,7),numpy.uint8)
    gapfix = cv2.copyMakeBorder(gapfix,10,10,10,10,cv2.BORDER_CONSTANT,value=000000)
    im_floodfill = gapfix.copy()
    he, we = gapfix.shape[:2]
    mask = numpy.zeros((he+2, we+2), numpy.uint8)
    cv2.floodFill(im_floodfill, mask, (0,0), 255)
    im_floodfill_inv = cv2.bitwise_not(im_floodfill)
    gapfix = gapfix | im_floodfill_inv
    gapfix = gapfix[10:height-10, 10:width-10]
    gapfix = cv2.morphologyEx(gapfix, cv2.MORPH_OPEN, kernel)
    contours, _ = cv2.findContours(gapfix, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    for contour in contours:
        (x,y,w,h) = cv2.boundingRect(contour)
        if h > 2:
            points = numpy.array( [[[x,y-1],[x+w,y-1],[x+w,y+h],[x,y+h]]], dtype=numpy.int32 )
            cv2.fillPoly(witnessedsq_g, points, color=(255,255,255))
        else:
            print("IGNORED")

    # Green rectangles so you can see for yourself.
    if False:
        for contour in contours:
            (x,y,w,h) = cv2.boundingRect(contour)
            if h > 2:
                points = numpy.array( [[[x,y-1],[x+w,y-1],[x+w,y+h],[x,y+h]]], dtype=numpy.int32 )
                cv2.rectangle(witnessedsq,(x-1,y),(x+w,y+h),(0,255,0,255),1)
            else:
                print("IGNORED")
        cv2.imwrite(f"{batchname} SQG.png", witnessedsq)



    witnessed = cv2.morphologyEx(slave, cv2.MORPH_OPEN, kernel)
    witnessed = cv2.cvtColor(witnessed, cv2.COLOR_BGR2RGBA)
    witnessed = cv2.bitwise_and(witnessed, witnessed, mask = witnessedsq_g)
    slave = cv2.cvtColor(slave, cv2.COLOR_BGR2RGBA)
    witnessed = Image.fromarray(witnessed)
    slave = Image.fromarray(slave)
    mediocre = Image.alpha_composite(slave, witnessed) 
    mediocre.save(f"{batchname} DARK++.png")
    print(f"{batchname} DARK++.png created!")

    witnessed = cv2.morphologyEx(master, cv2.MORPH_CLOSE, kernel)
    witnessed = cv2.cvtColor(witnessed, cv2.COLOR_BGR2RGBA)
    witnessed = cv2.bitwise_and(witnessed, witnessed, mask = witnessedsq_g)
    master = cv2.cvtColor(master, cv2.COLOR_BGR2RGBA)
    witnessed = Image.fromarray(witnessed)
    master = Image.fromarray(master)
    mediocre = Image.alpha_composite(master, witnessed) 
    mediocre.save(f"{batchname} LIGHT++.png")
    print(f"{batchname} LIGHT++.png created!")



def apng():
    print("\n Working on animation . . .")
    if slave2:
        os.system(f"""ffmpeg.exe -r 2 -i "concat:{batchname} A.png|{batchname} A+B.png|{batchname} B.png|{batchname} B+C.png|{batchname} C.png|{batchname} A+C.png|{master}|{slave}|{slave2}|{master}|{slave}|{slave2}" -c copy -movflags faststart -pix_fmt yuva420p -c:v apng -plays 0 -crf 8 -f apng "{batchname} APNG.png" -y -loglevel error""")
    else:
        os.system(f"ffmpeg.exe -r 2 -i \"concat:{batchname} A.png|{batchname} A+B.png|{batchname} B.png|{master}|{slave}|{master}|{slave}\" -c copy -movflags faststart -pix_fmt yuva420p -c:v apng -plays 0 -crf 8 -f apng \"{batchname} APNG.png\" -y -loglevel error")
    print(f"{batchname} APNG.png created!")
    os.system(f"""choice /c:b /n /m:"Press B to view animated image file in your browser: " """)
    os.system(f"""start "" "{browser}" "{batchname} APNG.png" """)



def exposedall(datas, alpha):    
    newData = []
    if alpha:
        for item in datas:
            if item[0] == 0 and item[1] == 0 and item[2] == 0: newData.append((0, 0, 0, 0))
            elif item[0] > 0 or item[1] > 0 or item[2] > 0: newData.append((255, 255, 255, 255))
            else: newData.append(item)
        return(newData)
    for item in datas:
        if item[0] == 0 and item[1] == 0 and item[2] == 0: newData.append((0, 0, 0))
        elif item[0] > 12 or item[1] > 12 or item[2] > 12: newData.append((255, 255, 255))
        elif item[0] > 10 or item[1] > 10 or item[2] > 10: newData.append((208, 192, 240))
        elif item[0] > 8 or item[1] > 8 or item[2] > 8: newData.append((176, 128, 224))
        elif item[0] > 6 or item[1] > 6 or item[2] > 6: newData.append((144, 64, 192))
        elif item[0] > 4 or item[1] > 4 or item[2] > 4: newData.append((112, 32, 160))
        elif item[0] > 2 or item[1] > 2 or item[2] > 2: newData.append((64, 16, 128))
        elif item[0] > 0 or item[1] > 0 or item[2] > 0: newData.append((32, 8, 96))
        else: newData.append(item)
    return(newData)



def witnessed(witnessed, filename, alpha=False):
    datas = witnessed.getdata()
    newData = exposedall(datas, alpha)
    witnessed.putdata(newData)
    witnessed.save(filename)
    print(filename + " created!")



def sizecheck(master, slave, slave2=None):
    masterw, masterh = master.size
    slavew, slaveh = slave.size
    if slave2:
        slave2w, slave2h = slave2.size
        print(f"\n Featuring: {masterw} x {masterh}")
        if masterw > slavew:
            slavew = f"{tcolorr}{slavew}"
        elif masterw < slavew:
            slavew = f"{tcolorg}{slavew}"
        if masterh > slaveh:
            slaveh = f"{tcolorr}{slaveh}"
        elif masterh < slaveh:
            slaveh = f"{tcolorg}{slaveh}"
        print(f" Reference: {slavew}{tcolorx} x {slaveh}{tcolorx}")
        if masterw > slave2w:
            slave2w = f"{tcolorr}{slave2w}"
        elif masterw < slave2w:
            slave2w = f"{tcolorg}{slave2w}"
        if masterh > slave2h:
            slave2h = f"{tcolorr}{slave2h}"
        elif masterh < slave2h:
            slave2h = f"{tcolorg}{slave2h}"
        print(f" Reference: {slave2w}{tcolorx} x {slave2h}{tcolorx}")
    else:
        print(f"\n Featuring: {masterw} x {masterh}")
        if masterw > slavew:
            slavew = f"{tcolorr}{slavew}"
        elif masterw < slavew:
            slavew = f"{tcolorg}{slavew}"
        if masterh > slaveh:
            slaveh = f"{tcolorr}{slaveh}"
        elif masterh < slaveh:
            slaveh = f"{tcolorg}{slaveh}"
        print(f" Reference: {slavew}{tcolorx} x {slaveh}{tcolorx}")



def quicktutorial():
    print("""
 + Each line must be prepended with "file " then appended with filename and extension, use apostrophes to escape spaces.
 + Duplicate a line where still-image file as input for per-frame delay and duplicate multiple lines for gif-esque loop.
 + Duplicate a line where animated file as input will act gif-esque.
""")

def makeapng(resize):
    print(" - - - - Make APNG/MP4 - - - -")
    print(" + Video will be unstable if too much FPS and/or resolution.\n")
    print(f"I'll read {textfile} again later.")

    while True:
        framerate = input("    Framerate (23.976 max): ")
        if framerate.replace(".", "").isdigit() and float(framerate) < 24:
            break
        os.system("color %stopcolor%")
        os.system("color %color%")
        print(tcolorx, end="\r")
    while True:
        newsize = input("    Resolution (e.g. 4000x3000, enter nothing will keep original) must be EVEN NUMBER in both dimensions: ")
        if not newsize:
            break
        try:
            x, y = newsize.split("x")
            if x.isdigit() and y.isdigit():
                resize = newsize
                break
            os.system("color %stopcolor%")
            os.system("color %color%")
            print(tcolorx, end="\r")
        except:
            os.system("color %stopcolor%")
            os.system("color %color%")
            print(tcolorx, end="\r")
    errorlevel = os.system(f"""choice /c:av /n /m:"    Images to (A)PNG or (V)ideo: """)
    if errorlevel == 1:
        print(" Working . . .")
        ext = ".png"
        os.system(f"""ffmpeg.exe -r {framerate} -f concat -safe 0 -i "{masterdir + textfile}" -c copy -movflags faststart -pix_fmt yuva420p -vf "scale={resize}" -c:v apng -plays 0 -crf 8 -f apng "{masterdir + mastername}.png" -y -loglevel error""")
    elif errorlevel == 2:
        print(" Working . . .")
        ext = ".mp4"
        os.system(f"""ffmpeg.exe -r {framerate} -f concat -safe 0 -i "{masterdir + textfile}" -c copy -movflags faststart -pix_fmt yuv420p -vf "scale={resize}" -c:v libx264 -crf 8 "{masterdir + mastername}.mp4" -y -loglevel error""")
    print(f"""\n "{mastername + ext}" created!""")
    sys.exit()

def compilemp4():
    print(" - - - - Compile MP4 - - - -")
    os.system(f"choice /c:r /n /m:\"Press R to read {textfile} again and make {mastername}.mp4 video: \"")
    os.system(f"""ffmpeg.exe -f concat -safe 0 -i "{masterdir + textfile}" -c copy "{masterdir + mastername}.mp4" -y -loglevel error""")
    print(f"""\n "{mastername}.mp4" created!""")
    sys.exit()

def betterpng(masterdir, filelist):
    print("\n - - - - FFmpeg's PNG compression - - - -")
    errorlevel = os.system(f"choice /c:pa /n /m:\"Press P to resave PNG files (A to resave as APNG) from featuring/parent folder to \\{os.path.basename(masterdir)} (png)/(apng)\\: \"")
    if errorlevel == 1:
        destination = masterdir + " (png)\\"
    elif errorlevel == 2:
        destination = masterdir + " (apng)\\"
    masterdir = masterdir + "\\"
    if not os.path.exists(destination):
        os.makedirs(destination)
    for file in filelist:
        file = os.path.basename(file)
        if os.path.exists(destination + file):
            continue
        if file.lower().endswith(tuple(imagefile + imagefile2)):
            print("Copying . . .", end="\r")
            if errorlevel == 1:
                if file.lower().endswith(".png"):
                    os.system(f"""ffmpeg.exe -i "{masterdir + file}" "{destination + file}" -y -loglevel error""")
                elif file.lower().endswith(".heic"):
                    os.system(rf"""ffmpeg.exe -f hevc -i "{masterdir + file}" -vf "select=eq(n\,0)" "{destination + os.path.splitext(file)[0] + ".png"}" -y -loglevel error""")
            elif errorlevel == 2:
                os.system(f"""ffmpeg.exe -r 2 -i "concat:{masterdir + file}|{masterdir + file}" -c copy -movflags faststart -pix_fmt yuva420p -vf "scale={resize}" -c:v apng -plays 0 -crf 8 -f apng "{destination + file}" -y -loglevel error""")
            print("Copy completed: " + destination + file)
    sys.exit()

def compiletext(textfile, isnew):
    with open(masterdir + textfile, 'a') as f:
        f.write(ffmpegdata)
    print(f"{textfile} {isnew}!")
    quicktutorial()
    if master.lower().endswith(tuple(imagefile)):
        makeapng(resize)
    else:
        compilemp4()

def resave(resize):
    if master.lower().endswith(tuple(imagefile + imagefile2)):
        print("\n Note: MP4 will play properly only if the featuring image is in fact animated.\n GIF or PNG may not be animated but I won't be able to tell.\n")
        while True:
            print("(L)oop or (R)otate: ")
            el = choice("lr")
            if el == 1:
                loop = input("Number of loops (16 max) for MP4, enter nothing for resaving image files as PNGs with FFMPEG's PNG compression: ")
                if loop.isdigit():
                    loop = int(loop)-1
                    if 0 <= loop <= 15:
                        print(" Working . . .")
                        os.system(f"""ffmpeg.exe -stream_loop {loop} -i "{master}" -movflags faststart -pix_fmt yuv420p -vf "scale={resize}" -c:v libx264 -crf 8 "{masterdir + mastername}.mp4" -loglevel error""")
                        print(f"""\n "{mastername}.mp4" created!""")
                        sys.exit()
                elif not loop:
                    betterpng(os.path.dirname(os.path.realpath(master)), filelist)
                os.system("color %stopcolor%")
                os.system("color %color%")
                print(tcolorx, end="\r")
            elif el == 2:
                deg = -360
                image = Image.open(filelist[0])
                while deg:
                    print(deg)
                    if os.path.exists(os.path.splitext(os.path.basename(filelist[0]))[0] + " (" + str(deg) + "deg).png"):
                        deg += 10
                        continue
                    image.rotate(deg, resample=3).save(os.path.splitext(os.path.basename(filelist[0]))[0] + " (" + str(deg) + "deg).png")
                    deg += 10
            else:
                kill(0)
    elif master.lower().endswith(tuple(videofile)):
        while True:
            offset = input("Offset Length (e.g. 55:53.4 2.9 for 2.9 seconds video from 55:53.4 offset), enter nothing to convert without trimming, enter (M)anipulate mode: ").split(" ")
            if offset[0].lower() == "m":
                while True:
                    try:
                        W, H, X, Y, B, S, I = input("W H X Y Brightness Saturation Interpolation (separate with space, in_h/* in_w/* is supported): ").split(" ")
                        break
                    except:
                        choice(bg=True)
                        print("TRY AGAIN")
                os.system(f"""ffmpeg -i "{master}" -filter:v "crop={W}:{H}:{X}:{Y},eq=brightness={B}:saturation={S}{",minterpolate" if I else ""}"{" -r " + I if I else ""} "{masterdir + mastername} edit.mp4" -loglevel error""")
                print(f"""\n "{mastername} edit.mp4" created!""")
                sys.exit()
            elif len(offset) == 2:
                print(" Working . . .")
                os.system(f"""ffmpeg.exe -i "{master}" -ss {offset[0]} -t {offset[1]} -async 1 "{masterdir + mastername} (trimmed).mp4" -loglevel error""")
                print(f"""\n "{mastername} (trimmed).mp4" created!""")
            elif offset[0]:
                choice(bg=True)
                continue
            elif master.lower().endswith(".mp4"):
                print("Already MP4 . . . I must exit!")
            else:
                print(" Working . . .")
                os.system(f"""ffmpeg.exe -i "{master}" "{masterdir + mastername}.mp4" -loglevel error""")
                print(f"""\n "{mastername}.mp4" created!""")
            sys.exit()
    else:
        return



def witnessmepng(masterread, slaveread, slave2read=None):
    if slave2read:
        slave3 = ImageChops.lighter(slaveread, slave2read)
        witnessed1 = ImageChops.subtract(slave3, masterread)
        master3 = ImageChops.lighter(masterread, slave2read)
        witnessed2 = ImageChops.subtract(master3, slaveread)
        master2 = ImageChops.lighter(masterread, slaveread)
        witnessed3 = ImageChops.subtract(master2, slave2read)
        witnessednot1 = ImageChops.lighter(witnessed2, witnessed3)
        witnessednot2 = ImageChops.lighter(witnessed1, witnessed3)
        witnessednot3 = ImageChops.lighter(witnessed1, witnessed2)
        witnessed0 = ImageChops.lighter(witnessed1, witnessednot1)
    else:
        witnessed0 = ImageChops.difference(masterread, slaveread)
        witnessed1 = ImageChops.subtract(masterread, slaveread)
        witnessed2 = ImageChops.subtract(slaveread, masterread)

    witnessed(witnessed0.convert("RGBA"), f"{batchname}.png", alpha=True)
    if slave2read:
        witnessed(witnessed0.convert("RGB"), f"{batchname} A+B+C.png")
        witnessed(witnessednot3.convert("RGB"), f"{batchname} A+B.png")
        witnessed(witnessednot2.convert("RGB"), f"{batchname} A+C.png")
        witnessed(witnessednot1.convert("RGB"), f"{batchname} B+C.png")
        witnessed(witnessed3.convert("RGB"), f"{batchname} C.png")
    else:
        witnessed(witnessed0.convert("RGB"), f"{batchname} A+B.png")
    witnessed(witnessed1.convert("RGB"), f"{batchname} A.png")
    witnessed(witnessed2.convert("RGB"), f"{batchname} B.png")



def witnessmej(masterread, slaveread):
    masterread_ed = masterread.filter(ImageFilter.FIND_EDGES)
    font = ImageFont.truetype("arial.ttf", 16)
    ImageDraw.Draw(masterread_ed).text((10, 10), "1", fill=(255, 255, 255), font=font)
    masterread_ed.save(f"{batchname} D.png")
    print(f"{batchname} D.png created!")

    slaveread_ed = slaveread.filter(ImageFilter.FIND_EDGES)
    ImageDraw.Draw(slaveread_ed).text((10, 10), "2", fill=(255, 255, 255), font=font)
    slaveread_ed.save(f"{batchname} E.png")
    print(f"{batchname} E.png created!")

    os.system(f"ffmpeg.exe -r 2 -i \"concat:{batchname} D.png|{batchname} E.png\" -c copy -movflags faststart -pix_fmt yuva420p -c:v apng -plays 0 -crf 8 -f apng \"{batchname} EdgeDiff.png\" -y -loglevel error")
    print(f"{batchname} EdgeDiff.png created!")
    os.system(f"""choice /c:b /n /m:"Press B to view animated image file in your browser: " """)
    os.system(f"""start "" "{browser}" "{batchname} EdgeDiff.png" """)



def help():
    print(f"""
 ::MAIN
 | Drag'n'drop items to batch file (rather than this CLI) for speedy workflow!
 + Drag folder to duplicate folder with PNG files resave with FFmpeg's PNG compression.
 
 ::TXT
 | I'll do live example of dragged items before adding to TXT file with optional continuation from TXT.
 + Or drag featuring TXT file to start make APNG or MP4 from it.

 ::ANIMATED FILE
 + Convert featuring APNG/GIF to MP4 or featuring video to MP4 with optional trim.

 ::PNGs
 | When every input is PNG, I can create "{batchname} A" and "{batchname} B" and optional extra "{batchname} C".
 | "{batchname}.png" will be of great assistance finding an easily overlooked difference.
 |
 | Optional prompt for "{batchname} APNG" for animated differences in APNG.
 |
 | Optional prompt for "{batchname} LIGHT" preferring LIGHTER pixels and "{batchname} DARK" preferring DARKER pixels.
 | Each have their own disadvantages in eliminating differences. You can edit and merge both for a best picture.
 |
 + Enter nothing to create "{batchname} LIGHT++" and "{batchname} DARK++", aka lazy anti-piracy mark removal.

 ::JPGs
 | When one of the input is not PNG, hopefully mix of PNG and JPGs or just JPGs,
 | I'll create "{batchname} D", "{batchname} E", and "{batchname} EdgeDetect.png"
 + for comparing pictures by their JPEG artifacts. "{batchname} EdgeDetect.png" is animated PNG of D and E.
""")



isother = False
resize = "trunc(iw/2)*2:trunc(ih/2)*2"
if filelist:
    master = filelist[0]
    print("Loading featuring image successful: \"" + master + "\"")
else:
    while True:
        master = parse.unquote(input("Drag'n'drop the featuring image and hit Enter, (H)elp: ").replace("\"", "").replace("file:///", ""))
        if not master:
            if os.path.exists(f"{batchname} LIGHT.png") and os.path.exists(f"{batchname} DARK.png") and os.path.exists(f"{batchname}.png"):
                lazy()
                sys.exit()
            print(f"\nNO! I require \"{batchname} LIGHT.png\", \"{batchname} DARK.png\", and \"{batchname}.png\" before I proceed.")
            sys.exit()
        elif master.lower() == "h":
            help()
        elif not os.path.exists(master):
            os.system("color %stopcolor%")
            os.system("color %color%")
            print(tcolorx, end="\r")
        else:
            filelist.append(master)
            break
if os.path.isdir(master):
    betterpng(master, os.listdir(master))
else:
    masterdir = os.path.dirname(os.path.realpath(master)) + "\\"
    mastername, masterext = os.path.splitext(os.path.basename(master))
    textfile = mastername + ".txt"
    if masterext.lower() == ".txt":
        print(f"Reading {textfile} . . .")
        if os.path.getsize(masterdir + textfile) < 1:
            print(f"\n No filename list in {textfile}! . . . I must exit!")
            sys.exit()
        else:
            with open(masterdir + textfile, 'r') as f:
                textread = f.read().splitlines()
            quicktutorial()
            if textread[0].split("'")[1].lower().endswith(tuple(imagefile)):
                makeapng(resize)
            else:
                compilemp4()
    elif any(ext == masterext.lower() for ext in imagefile):
        masterread = Image.open(master)
        mastertype = masterread.format
        masterread = masterread.convert("RGB")
    else:
        isother = True



if len(filelist) > 1:
    slave = filelist[1]
    print("Loading reference image successful: \"" + slave + "\"")
else:
    while True:
        slave = parse.unquote(input("Drag'n'drop the reference image and hit Enter, or enter nothing to resave featuring image as MP4/PNG, save as (I)CO: ").replace("\"", "").replace("file:///", ""))
        if not slave:
            if not resave(resize):
                os.system("color %stopcolor%")
                os.system("color %color%")
                print(tcolorx, end="\r")
        elif slave == "i":
            masterread.save(f"{masterdir}{mastername}.ico")
            sys.exit()
        elif not os.path.exists(slave):
            os.system("color %stopcolor%")
            os.system("color %color%")
            print(tcolorx, end="\r")
        else:
            filelist.append(slave)
            break
if slave:
    if slave.lower().endswith(tuple(imagefile)):
        slaveread = Image.open(slave)
        slavetype = slaveread.format
        slaveread = slaveread.convert("RGB")
    else:
        isother = True



ispng = True
if not isother and mastertype == "PNG" and slavetype == "PNG":
    if len(filelist) > 2:
        slave2 = filelist[2]
        print("Loading reference image successful: \"" + slave2 + "\"")
    else:
        while True:
            slave2 = parse.unquote(input("Drag'n'drop second reference image (optional, PNG only) and hit Enter: ").replace("\"", "").replace("file:///", ""))
            if slave2 and not os.path.exists(slave2):
                os.system("color %stopcolor%")
                os.system("color %color%")
                print(tcolorx, end="\r")
            elif not slave2:
                break
            else:
                filelist.append(slave2)
                break
    if slave2:
        if slave2.lower().endswith(tuple(imagefile)):
            slave2read = Image.open(slave2)
            if slave2read.format != "PNG":
                ispng = False
            slave2read = slave2read.convert("RGB")
            sizecheck(masterread, slaveread, slave2read)
        else:
            isother = True
    else:
        sizecheck(masterread, slaveread)
else:
    ispng = False
    if not isother:
        sizecheck(masterread, slaveread)



sameext = ""
diffext = False
ffmpegdata = ""
for file in filelist:
    salveext = os.path.splitext(os.path.basename(file))[1].lower()
    ffmpegdata += f"file '{file}'\n"
    if not sameext:
        sameext = salveext
    elif salveext != sameext:
        diffext = True
if diffext:
    print("\n - - - - Dangerous example (all file extensions must be consistent!) - - - -")
else:
    print("\n - - - - Live example for TXT file - - - -")
print(ffmpegdata)



while True:
    if ispng:
        print(f"""(T)ype new/enter TXT file to append with above, enter nothing for differences with first {"three" if slave2 else "two"} loaded files... """)
        witnessme = input(f"""\"witness" for animated differences and/or "me" for LIGHT and DARK files again with first {"three" if slave2 else "two"} loaded files: """).strip("\"")
    elif not isother:
        witnessme = input("""(T)ype new/enter TXT file to append with above, enter nothing for animated differences with first two loaded files: """).strip("\"")
    else:
        witnessme = input("""(T)ype new/enter TXT file to append with above: """).strip("\"")
    if os.path.exists(os.path.splitext(witnessme)[0] + ".txt"):
        masterdir = os.path.dirname(os.path.realpath(witnessme)) + "\\"
        textfile = os.path.basename(witnessme)
        mastername = os.path.splitext(textfile)[0]
        compiletext(textfile, "updated")
    elif witnessme.lower() == "t":
        while True:
            mastername = input("Enter TXT filename: ")
            if os.path.exists(masterdir + mastername + ".png") or os.path.exists(masterdir + mastername + ".mp4"):
                os.system("color %stopcolor%")
                print(" Collision resistance failed . . . TRY AGAIN!")
                os.system("color %color%")
                print(tcolorx, end="\r")
            elif mastername:
                textfile = mastername + ".txt"
                compiletext(textfile, "created")
            else:
                os.system("color %stopcolor%")
                os.system("color %color%")
                print(tcolorx, end="\r")
    elif ispng and not witnessme or ispng and witnessme.lower() == "witness me" or ispng and witnessme.lower() == "witness" or ispng and witnessme.lower() == "me":
        if slave2:
            witnessmepng(masterread, slaveread, slave2read)
        else:
            witnessmepng(masterread, slaveread)
        if witnessme.lower().endswith("me"):
            DARK = ImageChops.darker(masterread, slaveread)
            LIGHT = ImageChops.lighter(masterread, slaveread)
            if slave2read:
                DARK = ImageChops.darker(DARK, slave2read)
                LIGHT = ImageChops.lighter(LIGHT, slave2read)
            DARK.save(f"{batchname} DARK.png")
            print(f"{batchname} DARK.png created!")
            LIGHT.save(f"{batchname} LIGHT.png")
            print(f"{batchname} LIGHT.png created!")
        if "witness" in witnessme.lower():
            apng()
        sys.exit()
    elif not isother and not witnessme:
        witnessmej(masterread, slaveread)
        sys.exit()
    else:
        os.system("color %stopcolor%")
        os.system("color %color%")
        print(tcolorx, end="\r")