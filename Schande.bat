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
if %cd:~-1%==\ (set batchdi=%cd:~0,-1%&&set batchdir=%cd%) else (set batchdi=%cd%&&set batchdir=%cd%\)
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

if exist Lib\site-packages\ (echo.) else (goto install)
if exist Lib\site-packages\ (goto start) else (echo.)

:install
echo  Hold on . . . I need to install the missing packages.
if exist "Scripts\pip.exe" (echo.) else (color %stopcolor% && echo  PIP.exe doesn't seem to exist . . . Please install Python properly^^! I must exit^^! && pause>nul && exit)
python -m pip install --upgrade pip
::Scripts\pip.exe install name_of_the_missing_package
::Scripts\pip.exe install what_else
echo.
pause

:start
cls
color %color%
python.exe -x "!batchfile!" "!filelist!" "!pythondir!" "!batchdi!" "!batchdir!"
set filelist=
color %stopcolor%
echo.
echo Restart CLI? Press any key to continue . . .
pause >nul
goto start
"""



import os, sys, io, ssl, socket, time, json, zlib, inspect, smtplib, hashlib, subprocess, mimetypes
from datetime import datetime, timedelta, UTC
from fnmatch import fnmatch
from http import cookiejar
from http.server import BaseHTTPRequestHandler
from queue import Queue
from socketserver import ThreadingMixIn, TCPServer
from threading import Thread, Event
from urllib import parse, request
from urllib.error import HTTPError, URLError
from random import random

class Queue(Queue):
    def clear(self):
        while not self.empty():
            self.get()

batchfile = os.path.basename(__file__)
batchname = os.path.splitext(batchfile)[0]
batchdi = batchdir = os.path.dirname(os.path.realpath(__file__)).replace("\\", "/")
filelist = []
schande_filelist = [[], []]
pythondir = ""

if len(sys.argv) > 4:
    filelist = list(filter(None, sys.argv[1].replace("\\", "/").split("//")))
    pythondir = sys.argv[2].replace("\\\\", "\\").replace("\\", "/")
    # batchdi = batchdir = sys.argv[3].replace("\\\\", "\\").replace("\\", "/") # grabs "start in" argument
if "/" in batchdir and not batchdir.endswith("/"):
    batchdir += "/"
else:
    batchdi = batchdir[:-1]
os.chdir(batchdir)

cd = batchname + " cd/"
tcd = "\\" + batchname + " cd\\"
htmlfile = batchname + ".html"
rulefile = batchname + ".cd"
sav = batchname + ".sav"
savs = batchname + ".savs"
savx = batchname + ".savx"
textfile = batchname + ".txt"

archivefile = [".7z", ".rar", ".zip"]
imagefile = [".gif", ".jpe", ".jpeg", ".jpg", ".png", ".heic"]
videofile = [".mkv", ".mp4", ".webm"]
utf8file = ['txt', 'bat', 'json', 'js', 'css', 'html']
notstray = ["mediocre.txt", "autosave.txt", "gallery.html", "keywords.json", "partition.json", ".URL"] # icon.png and icon #.png are handled in different way
mute404 = [
  "favicon.ico",
  "apple-touch-icon-precomposed.png",
  "apple-touch-icon.png",
  "apple-touch-icon-152x152-precomposed.png",
  "apple-touch-icon-152x152.png",
  "apple-touch-icon-120x120-precomposed.png",
  "apple-touch-icon-120x120.png"
]

alerted = [False]
busy = [False]*27
dlslot = [8]
echothreadn = []
error = [[]]*4
echoname = [batchfile]
newfilen = [0]
Keypress_prompt = [False]
Keypress_buffer = [""]
Keypress_time = [0, 0, 0]
Fast_presser = 0.5
Keypress = {"Key" + letter: False for letter in map(chr, range(65, 91))}

task = {
  "httpserver": [],
  "transmission": False,
  "run": Queue(),
  "makedirs": set(),
  "nodirs": set()
}

retries = [0]
sf = [0]



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
if not sys.platform == "darwin":
    os.system("")
title(batchfile)

cls = "\033[H\033[2J"
class tcolor:
    r = ansi_color("0", "1")
    g = ansi_color("0", "2")
    b = ansi_color("0", "3B78FF")
    o = ansi_color("0", "FF9030")
    if sys.platform == "darwin":
        x = ansi_color()
    else:
        x = ansi_color("005A80", "6")
        # x = ansi_color("2A211C", "BDAE9D")
    def __call__(self):
        return ansi_color("0")
    def z(c):
        if not len(c) == 6:
            kill("Bad color code")
        return f"\033[40;38;2;{int(c[:2],16)};{int(c[2:4],16)};{int(c[4:6],16)}m"



def mainmenu():
    return f"""
 - - - - {batchname} HTML - - - -
 + Press J twice to start or stop HTTP server. Server's dead, (J)im.
 | Press B to launch HTML in your favorite browser.
 | Press G to re/compile HTML from Geistauge's database (your browser will be used as comparison GUI).
 + Press D to open delete mode.

 - - - - Drag'n'drop / Input - - - -
 + Drag'n'drop and enter folder to add to Geistauge's database.
 + Drag'n'drop and enter image file to compare with another image, while scanning new folder, or find in database.

 - - - - Input - - - -
 + Enter partition.json to rebuild HTML.
 | Enter http(s):// to download file. Press V for page source viewing.
 + Enter valid site to start a scraper.
"""
def ready_input():
    echo(f"Your key: ", flush=True)
def skull():
    return r"""                                    
              ______                
           .-"      "-.             
          /            \            
         |'  .-.  .-.  '|           
    /\   | )(__/  \__)( |           
  _ \/   |/     /\     \|           
 \_\/    (_ \   ^^   / _)   .-==/~\ 
---,---,---|-|HHHHHH|-|---,\'-' {{~} 
           \          /     '-==\}/ 
            '--------'              
                                    """
def help():
    return f"""
 {rulefile} is {batchname}'s only setting file and only place to follow your rules how files are downloaded and sorted.


 - - - - Geistauge - - - -
  Wildcard: None, non-anchored start/end.

 > Arbitrary rule (unless # commented out) in {rulefile} will become Geistauge's pattern exemption.
 > No exemption if at least one similar image doesn't have a pattern.
 > Once scan is completed, {batchname} HTML will be used to view similar images,
   including tools to see the differences not seen by naked eyes.
   Geistauge (German translate: ghost eye)


 - - - - Sorter - - - -
  Wildcard: UNIX-style wildcard, ? matches 1 character, * matches everything, start/end is anchored until wildcarded.
 + Wildcard for file names only. Sorting from \\{batchname}\\:
 |  "\\...\\"                   use this directory for future matching. Multiple backslashes for nesting folders.
 |  "!\\...\\"                  use this directory for future non-matching.
 |  "\\...\\..." or "!\\...\\..." one-liner and future matching/non-matching.
 | From now on the arbitrary rule is a file sorting pattern, no longer part of Geistauge pattern exemptions.
 |
 | First rule will take its turn to sort the file, then resort to {tcd} for non-existent directories.
 | {tcd} can help ensure that no other rule can sort them any more (first rule = first to sort).
 + {tcd} is used for manual operation to a different directory where the folder actually exists.


 - - - - Torrent directory - - - -
 Wildcard: None, non-anchored
 +  "Transmission\\* for |all other| torrents" to download all torrents to \\Transmission\\, revise example to customize.
 |                      |(pattern)|
 + First rule will take its turn to designate a directory for torrent added.


 - - - - Download directory - - - -
  Wildcard: Single asterisk only, capture for prepend/append before file extension, non-anchored http ending.
 +  "...\\* for http..."       custom dir for downloads, \\{batchname}\\ if no custom dir specified.
 |  "...*date\\* for http..."  custom dir for downloads, "*date" will become "{fdate}".
 |  "...\\...*... for http..." and the file are also renamed (prepend/append).
 +  "...*... for http..."     and they go to \\{batchname}\\ while renamed.


 - - - - Spoofer - - - -
  Wildcard: None, non-anchored http ending.
 +  "Mozilla/5.0... for http..." visit page with user-agent.
 |  "key value for .site"     cookie for a site that requires login.
 +  "http... for http..."     visit page with referer.


 - - - - Scraper - - - -
  Wildcard: asterisks choose last, carets for right-to-left, hybrid greed median, non-anchored http ending.

 You need to:
  > know how to view page source or API.
  > know how to create pattern with asterisks or keys. Pages will be provided without newlines ("\\n") for convenience.
  > keep testing! Pages are full of variables. Develop solid asterisks/keys and flag scraper "ready" to stop previews.

 + Available pickers:
 |  "http..."         validates a site to start a scraper, attribute all pickers to this.
 |
 | Networking
 |  "defuse"          declare this url as having antibot detectors in place, defuse tools will be used on first visit.
 |  "visit"           visit especially for cookies before redirection.
 |  "urlfix ..*.. with ..*.." permanent redirector.
 |    Alternatively "X with Y".
 |  "url ..*.. with ..*.. redirector. Original url will be used for statement and scraper loop.
 |    Alternatively "X with Y".
 |  "POST X Y"        POST data (X) to url (Y) or to current page url (no Y) before accessing page.
 |
 | Alert
 |  "expect ...*..."  put scraper into loop, alarm when a pattern is found in page. "unexpect" for opposition.
 |    API: "un/expect .. > .. = X", "X > X" for multiple possibilities. Without equal sign to un/expect key only.
 |  "expect"          alert when the pages became accessible previously 404.
 |  "message ..."     customize alert message. Leave blank to exit loop without alerting.
 |
 | Get files
 |  "title ...*..."   pick and use as folder from first scraped page.
 |  "folder ...*..."  from url.
 |  "choose .. > .. = X" choose file by a match in another key. "X > X" for multiple possibilities in preference order.
 |  "file(s) ...*..." pick first or all files to download, "relfile(s)" for relative urls.
 |  "time ...*..."    pick time stamp for each file downloading.
 |  "name ...*..."    pick name for each file downloading. There's no file on disk without a filename!
 |  "meta ...*..."    from url.
 |  "extfix ...*..."  fix name without extension from url (detected by ending mismatch).
 |
 | Partition
 |  "part ...*..."    partitioning the page.
 |  "key ...*..."     pick identifier, defining each partition their ID, for HTML builder and/or *id name customization.
 |    key# for title (key1), timestamp (key2) then keywords (key3 each). Without key2+ to go stampless.
 |
 | HTML builder
 |  "reluctant"       do not update existing partition for HTML builder.
 |  "html ...*..."    pick article from page/partition for HTML builder.
 |    API: pick content for HTML-based pickers.
 |    HTML-based file and name pickers will look through for inline files and clean up articles.
 |    html# for insert mode: newline (+1), hyperlink (+2).
 |  "icon ...*..."    pick an icon. Incremental "icon#" to pick more icons up to #th.
 |
 | Miscellaneous
 |  "replace ..*.. with ..*.." find'n'replace before start picking in page/partition.
 |    Alternatively "X with Y".
 |  "newline ...*..." highlight areas to preserve newlines ("\\n").
 |  "pages ...*..."   pick more pages to scrape in parallel, "relpages" for relative urls.
 |    Page picker will make sure all pages are unique to visit, but older pages can cause loophole.
 |    Mostly FIFO aware (for HTML builder), using too many of it can cause FIFO (esp. arrangement) issue, it depends.
 |  "paginate *. * .* with X(Y)Z" split url into three parts then update/restore X and Z, paginate Y with +/- or key.
 |    Repeat this picker with different pattern to pick another location of this url to change.
 |    paginate# for extra pagination.
 +  "savelink"        save first scraped page link as URL file in same directory where files are downloading.

 + Manipulating picker:
 |  > Repeat a picker with different pattern for multiple possibilities/actions.
 |  > folder#, title#, name#, meta# to assemble assets together sequentially.
 |
 |  "...*..."         HTML-based picker.
 |  "... > ..."       API-based picker. "api > ..." to enforce.
 |  " > 0 > " (or asterisk) to iterate a list or dictionary values, " >> " to load dictionary from QS (Query String).
 |  "key Y << X"      X prefers master key Y.
 |
 | API supported pickers: key, html, expect, files, name, pages.
 | During API each file picker must be accompanied by name picker and all HTML-based name/meta pickers must descend.
 |
 | Customize the chosen one with prepend and append using "X customize with ...*..." after any picker.
 | Customize along with "*id" (extra asterisk) to insert key as name, only usable during using key picker, else "0".
 + Folder and title pickers will be auto-assigned with \\ to work as folder unless customized.

 + Manipulating asterisk/position:
 |  > Multiple asterisks to pick the last asterisk better and/or to discard others.
 |  > Arrange name and file pickers if needed to follow their position in page. file before -> name -> file after.
 |  > Arrange html and file pickers whether to download inline file or filelist on conflict of the same file name.
 |  > First with match will be chosen first. This doesn't apply to html and plural pickers such as files, pages.
 |  > Name match closest to the file will be chosen. file before -> name to before -> name to after -> file after.
 + Note: HTML-based name picker (esp. if repeated) will not respect file position made by a different file picker.

 + Right-to-left:
 |  > Use caret ^... to get the right match. Do ^..*^.. or ..*^.. (greedy), don't put caret before asterisk ^*
 |  > The final asterisk of the non-caret will be greedy and chosen. First asterisk if every asterisk has caret.
 +  > Using caret will finish with one chosen match.

 + For difficult asterisks:
 |  "X # letters" (# or #-#) after any picker (before "customize with") so the match is expected to be that amount.
 |  "X greater" after any picker (before "customize with") so the match is expected to be greater than asked number.
 |  "X ends/starts with X" after any picker (before "customize with"). "not" for opposition.
 + Use replace picker to discard what you don't need before complicating pickers with many asterisks or carets.


 - - - - Filter - - - -
  Wildcard: None, non-anchored start/end.

 + Possible operators: .filetype, !.filetype, !pattern, !!pattern.
 |  > .filetype    to whitelist file types.
 |  > !.filetype   to blacklist file types.
 |  > !pattern     to blacklist files by pattern match in their file names.
 |  > !!pattern    to whitelist, "!!" irony operator used to distinguish from Geistauge/Sorter rules.
 |
 | Filters are case insensitive.
 + Anchored ending if there's a period at the beginning, to avoid matching pattern of an extension name in file names.

 + Filters can be mainstreamed with scraper pickers as way to filter per-site.
 | Filters before any site picker will be your "general" filters. Filters under a site will be for this site.
 | Filters under a site picker will override whitelist.
 |
 | Extra pickers:
 |  "inherit"      to make whitelist incorporate again, your "exempt from blacklist" mode for this site.
 +  "reload"       to scrape and download files that was rejected in the past.
"""



eps = 30
stdtime = [int(time.time()*eps)]*2
stdout = Queue()
stdin = ["", ""]
def echofriction():
    while True:
        sys.stdout.write("".join(stdout.get()))
        stdin[0] = ""
        stdin[1] = ""
        time.sleep(1/eps)
Thread(target=echofriction, daemon=True).start()

def echo(t, b=0, f=0, clamp='', friction=False, flush=False):
    c = os.get_terminal_size().columns
    if not isinstance(t, int):
        stdout.clear()
        if clamp:
            t = f"{t[:c-1]}{(t[c-1:] and clamp)}"
        if flush:
            sys.stdout.write("\033[A"*b + t)
            sys.stdout.flush()
        else:
            sys.stdout.write("\033[A"*b + f"{t:<{c}}" + "\n"*f + "\r")
    elif not echothreadn or t == echothreadn[0]:
        if clamp:
            b = f"{b[:c-1]}{(b[c-1:] and clamp)}"
        if friction:
            s = time.time()
            if stdtime[1] < int(s*eps):
                stdtime[1] = int(s*eps)
                stdin[1] = f"{b:<{c}}\r"
                stdout.put((stdin))
            else:
                stdtime[1] = int(s*eps)
        else:
            stdout.clear()
            sys.stdout.write(f"{b:<{c}}\r")



def send(s, m, d):
    message = f"""Subject: {s}

{m}"""
    if not d and Mail:
        try:
            server = smtplib.SMTP_SSL("smtp.gmail.com")
            server.ehlo()
            server.login(Mail[0], Mail[2])
            server.sendmail(Mail[0], Mail[1], message)
            server.close()
        except:
            echo("Sending failed!\n > Create & use app password from 'App Passwords' under 'Signing in to Google' in https://myaccount.google.com/security.\n   Turn on the 2-Step Verification to see 'App Passwords' option under 'Signing in to Google'.\n > Make sure user and password is correct.", 0, 1)
    elif not d:
        echo("You should consider using Mail if you want alert over Mail.", 0, 1)
    else:
        echo("Dismissing", 0, 1)
    echo(" | " + "\n | ".join(message.splitlines()), 0, 2)



def alert(m, s, d=False):
    title("! " + monitor())
    send(s, m, d)
    if not d:
        choice(bg=["2e"])



def kill(threadn, e=None, r=None):
    if not e:
        echo(f"{tcolor.r}{threadn}{tcolor.x}", 0, 1)
    elif r:
        echo(f"""
 {e}
 Please update or remove {r} from {rulefile} then restart CLI.""", 0, 1)
    else:
        echo(f"""{tcolor.r}Thread {threadn} was killed {"by" if "(" in e else "because"} {e}{tcolor.x}""", 0, 1)
    sys.exit()



def whereami(e="echoed", b=0, f=1, kill=False, pause=False):
    dep = []
    for x in inspect.stack()[1:3]:
        c = inspect.getframeinfo(x[0])
        dep = [f"line {c.lineno} in {c.function}()"] + dep
    echo(f"""{" > ".join(dep)}: {tcolor.r if kill else tcolor.z("CCCCCC")}{e}{tcolor.x}""", b, f)
    if kill:
        while True:
            input("")
    elif pause:
        input("(C)ontinue?", "c")
        echo("", 1)



def echo_pip():
    if sys.platform == "win32":
        return rf"{sys.exec_prefix}\Scripts\pip.exe"
    elif sys.platform == "darwin":
        return "sudo python3 -m pip"
    elif sys.platform == "linux":
        return "pip3"



lostfocus = [False]
def choice(keys="", bg=[], double=False):
    if sys.platform == "win32":
        if bg:
            lostfocus[0] = True
            if bg == True:
                bg = ["%stopcolor%", "%color%"]
            for b in bg:
                os.system(f"color {b}")
            echo(tcolor.x)
        if keys:
            lostfocus[0] = False
            el = os.system(f"choice /c:{keys} /n")
            while lostfocus[0]:
                lostfocus[0] = False
                echo("Sorry, lost focus, what was your choice, again?\n")
                el = os.system(f"choice /c:{keys} /n")
    else:
        if keys:
            el = os.system("""while true; do
read -s -n 1 el || break
read -s -n 400 -t 0.01
case $el in
""" + "\n".join([f"{k} ) exit {e+1};;" for e, k in enumerate(keys)]) + """
esac
done""")
            if el >= 256:
                el /= 256
            el = int(el)
            echo(f"{keys[el-1].upper()}\n", flush=True)
    if not keys:
        return
    if el == 0:
        echo("", 0, 1)
    if el < 0 or el > 100:
        whereami(f"Obscene return code {el}", kill=True)
    if double and keys[el-1].lower() in double.lower():
        Keypress_time[0] = time.time()
        if Keypress_time[0] > Keypress_time[1]:
            el = -el
        Keypress_time[1] = Keypress_time[0] + Fast_presser
    return el



def input(i="Your Input: ", choices=False, double=False):
    echo(str(i), flush=True)
    if choices:
        keys = ""
        for c in choices:
            keys += c[0].lower()
        while True:
            el = choice(keys, double=double)
            if el > 0 and (c := choices[el-1])[1:]:
                echo("", 1, 0)
                nter = input("Type and enter to confirm, else to return: " + c + f"\033[{len(c)-1}D")
                echo("", 1, 0)
                echo(str(i), flush=True)
                if nter.lower() == choices[el-1][1:].lower():
                    echo(c, 0, 0)
                    return el
            else:
                return el
    else:
        return sys.stdin.readline().replace("\n", "")



def new_rules():
    return """

- - - - Spoofer - - - -
Mozilla/5.0 for http
4-8 seconds rarity 75% 00:00
# 12-24 seconds rarity 23% 00:00
# 64-128 seconds rarity 2% 00:00
"""



sys.stdout.write(tcolor.x + cls)

if not os.path.exists(rulefile):
    open(rulefile, 'w').close()
if os.path.getsize(rulefile) < 1:
    rules = new_rules().splitlines()
else:
    with open(rulefile, 'r', encoding="utf-8") as f:
        rules = f.read().splitlines()

new_setting = False
pos = 0
settings = ["Launch HTTP server = ", "Browser = ", "Mail = ", "Geistauge = No", "Python = " + pythondir, f"UTC offset = {datetime.now().astimezone().strftime('%z')[:-2]}", "Proxy = socks5://"]
for setting in settings:
    if not rules[pos].replace(" ", "").startswith(setting.replace(" ", "").split("=")[0]):
        if pos == 0:
            while True:
                i = input("Launch HTTP server? (Y)es/(N)o: ", "yn")
                if i == 1:
                    echo("", 1)
                    i = input("Quick password for sensitive files serving, enter nothing to return to last prompt: ")
                    if not i:
                        echo("", 1)
                        continue
                    setting += i
                else:
                    setting += "No"
                break
            echo("", 1)
            echo("", 0, 1)
        rules.insert(pos, setting)
        print(f"""Added new setting "{setting}" to {rulefile}!""")
        new_setting = True
    pos += 1
if new_setting:
    with open(rulefile, 'wb') as f:
        f.write(bytes("\n".join(rules), 'utf-8'))



def status():
    return f"""🗎×{newfilen[0]}{f" ↺×{retries[0]}" if retries[0] else ""} {echoname[0]}"""



Bs = [0]
Bstime = [int(time.time())]
Ba = "▹"
Barray = [[Ba[0]]*8]
MBs = [0]
for n in range(256):
    h = f"{n:02x}"
    h0 = int(h[0],16)
    h1 = int(h[1],16)
    Ba += chr(10240+h1+int(h0/2)*16+int(h1/8)*64+int(h0/8)*64+(h0%2)*8-int(h1/8)*8)
def echoMBs(threadn, Bytes, total):
    if not threadn or (x := echothreadn.index(threadn)) < len(Barray[0]):
        Barray[0][x if threadn else 0] = Ba[total%257]
    s = time.time()
    if stdtime[0] < int(s*eps):
        stdtime[0] = int(s*eps)
        stdin[0] = "\n\033]0;" + f"""{status()} {''.join(Barray[0][:len(echothreadn) if threadn else 1])} {MBs[0]} MB/s""" + "\007\033[A"
        stdout.put((stdin))
    else:
        stdtime[0] = int(s*eps)
    if Bstime[0] < int(s):
        Bstime[0] = int(s)
        MBs[0] = f"{(Bs[0]+Bytes)/1048576:.2f}"
        Bs[0] = Bytes
    else:
        Bs[0] += Bytes



pg = [0]
tp = " ․⁚⋮⁴⁵⁶⁷⁸⁹abcdef⍿"
pr = len(tp)-1
pgtime = [int(time.time()/5)]
tm = [x.copy() for _ in range(10) for x in [[tp[0]]*12]]
def monitor():
    s = time.time()
    min = int(s / 60 % 60 % 10)
    sec = int(s % 60 / 5)
    tm[min][sec] = tp[pg[0]] if pg[0] < pr else tp[pr]
    ts = [x.copy() for x in tm]
    ts[min][sec] = "|"
    return f"""{status()} ꊱ {" ꊱ ".join(["".join(x) for x in ts])} ꊱ"""



def http2ondisk(url, directory):
    subdir = filter(None, parse.unquote(url.split('?',1)[0].split('#',1)[0]).split('/'))
    path = directory
    for folder in subdir:
        path = os.path.join(path, folder)
    return path

from datetime import timezone
day = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

def httpdate(ut):
    dt = datetime.fromtimestamp(ut, timezone.utc).timetuple()
    return f'{day[dt[6]]}, {dt[2]:02} {month[dt[1]-1]} {dt[0]} {dt[3]:02}:{dt[4]:02}:{dt[5]:02} GMT'

# delete if BaseHTTPRequestHandler is due
from socketserver import StreamRequestHandler
from email.feedparser import FeedParser as dumbass
from email.message import Message as thinkingprocess

class RangeHTTPRequestHandler(StreamRequestHandler):
    def __init__(self, *args, directory=None):
        self.directory = os.fspath(directory)
        super().__init__(*args)

    # delete if BaseHTTPRequestHandler is due
    def parse_request(self):
        self.command = None
        self.close_connection = True
        requestline = str(self.raw_requestline, 'iso-8859-1')
        requestline = requestline.rstrip('\r\n')
        self.requestline = requestline
        words = requestline.split()
        if len(words) == 0:
            return

        if len(words) >= 3:
            try:
                version_number = words[-1].split('/', 1)[1].split(".")
                version_number = int(version_number[0]), int(version_number[1])
            except:
                self.send_error(400, "Bad request version ({words[-1]})")
                return
            if version_number >= (2, 0):
                self.send_error(505, f"Invalid HTTP version")
                return

        if not 2 <= len(words) <= 3:
            self.send_error(400, f"Bad request syntax ({requestline})")
            return
        command, path = words[:2]

        if len(words) == 2:
            self.close_connection = True
            if command != 'GET':
                self.send_error(400, f"Bad HTTP/0.9 request type ({command})")
                return

        self.command = command
        self.path = '/' + path.lstrip('/') if path.startswith('//') else path

        try:
            headers = []
            while True:
                line = self.rfile.readline(4096+11 + 1)
                if len(line) > 4096+11:
                    self.send_error(431, 'One of the headers is too long')
                headers.append(line)
                if len(headers) > 24:
                    self.send_error(431, "Too many headers")
                if line in (b'\r\n', b'\n', b''):
                    break
            hstring = b''.join(headers).decode('iso-8859-1')
            dum = dumbass(thinkingprocess)
            dum.feed(hstring)
            self.headers = dum.close()
        except:
            self.send_error(431, "Obscene headers")

        conntype = self.headers.get('Connection', "")
        if conntype.lower() == 'close':
            self.close_connection = True
        return True

    # delete if BaseHTTPRequestHandler is due
    def handle_one_request(self):
        self.raw_requestline = self.rfile.readline(65537)
        if len(self.raw_requestline) > 65536:
            self.requestline = ''
            self.command = ''
            self.send_error(414)
            return
        if not self.raw_requestline:
            self.close_connection = True
            return
        if not self.parse_request():
            return
        mname = 'do_' + self.command
        if not hasattr(self, mname):
            self.send_error(501, f"Unsupported method ({self.command})")
            return
        method = getattr(self, mname)
        method()
        self.wfile.flush()

    def handle(self):
        self.close_connection = True
        try:
            self.handle_one_request()
        except:
            whereami("DISCONNECTED", 0, 1)
            self.close_connection = True
            raise
        while not self.close_connection:
            self.handle_one_request()

    def AUTH(self, ondisk):
        for q in self.qs.split('&'):
            if q == HTTPserver:
                return True
        buffer = ondisk.replace("/", "\\")
        echo(f"""{(datetime.now(UTC) + timedelta(hours=int(offset))).strftime('%Y-%m-%d %H:%M:%S')} [{self.command} stalled] {tcolor.g}{self.client_address[0]} {tcolor.r}<- {tcolor.z("CCCCCC")}{buffer}{tcolor.x} use {tcolor.g}?{HTTPserver}{tcolor.o}{'&' + tcolor.b + self.qs if self.qs else ''}{tcolor.x} query string to authorize this connection.""", 0, 1)
        self.close_connection = False

    def do_GET(self):
        self.qs = ""
        if '?' in self.path:
            self.path, self.qs = self.path.split('?', 1)
        f = self.send_head()
        if f:
            try:
                self.copyfile(f, self.wfile)
            finally:
                f.close()

    def do_POST(self):
        Bytes = int(self.headers['Content-Length'])
        self.qs = ""
        if '?' in self.path:
            self.path, self.qs = self.path.split('?', 1)
        dir = batchdir.rstrip("/") + saint(self.path).replace("\\", "/").rsplit("/", 1)[0] + "/"
        for q in self.qs.split('&'):
            if q.endswith(".json"):
                cd = saint(q.split('=', 1)[-1].rsplit('/', 1)[0] + '/').replace("\\", "/")
                dir += cd[1:] if cd.startswith('/') else cd
                break
        if Bytes < 2000:
            data = self.rfile.read(Bytes).decode('utf-8')
            self.send_response(200, size=Bytes)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self.end_headers()
            api = {"kind":"","ondisk":"","body":""}
            try:
                api.update(json.loads(data))
            except:
                pass
            ondisk = saint(api["ondisk"]).replace("\\", "/")
            if api["kind"] == "Save":
                echo(f"Save {dir}{ondisk}", 0, 1)
                schande_filelist[0][0] += [f"{dir}{ondisk}"]
                self.wfile.write(bytes(f"Save list updated", 'utf-8'))
            elif api["kind"] == "Schande!":
                echo(f"Schande! {dir}{ondisk}", 0, 1)
                schande_filelist[0][1] += [f"{dir}{ondisk}"]
                self.wfile.write(bytes(f"Schande list updated", 'utf-8'))
            elif api["kind"] == "keywords":
                echo(f""" File updated: {dir}{ondisk}""", 0, 1)
                if os.path.exists(f"{dir}{ondisk}"):
                    with open(f"{dir}{ondisk}", 'r') as f:
                        body = json.loads(f.read())
                        k = next(iter(api["body"]))
                        if api["body"][k]:
                            body.update(api["body"])
                        elif k in body:
                            del body[k]
                else:
                    body = api["body"]
                with open(f"{dir}{ondisk}", 'w') as f:
                    f.write(json.dumps(body))
            else:
                echo(f"Stray POST data: {data}", 0, 1)
                self.wfile.write(bytes(f"Stray POST data sent", 'utf-8'))
        else:
            self.send_response(200, size=Bytes)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self.end_headers()
            echo(f"Large POST data: {Bytes} in length exceeding 2000 allowance", 0, 1)
            self.wfile.write(bytes(f"Large POST data sent", 'utf-8'))

    def list_directory(self, ondisk, ntime=False):
        parent = parse.unquote(self.path)
        parent += "" if parent.endswith("/") else "/ (please fix missing slash in url)"

        load_from_qs = False
        for q in self.qs.split('&'):
            if q.endswith(".json"):
                load_from_qs = "Gallery"

        if parent == "/" and not load_from_qs and not self.AUTH(ondisk):
            return
        enc = sys.getfilesystemencoding()

        if load_from_qs == "Gallery":
            if os.path.exists(s := f"{ondisk}/savelink.URL"):
                with open(s, 'r') as f:
                    page = f.read().splitlines()[1].replace("URL=", "")
                get_pick = [x for x in navigator["pickers"].keys() if page.startswith(x)]
                if not get_pick:
                    kill(f"\n  {page}\n\nCouldn't recognize this url, I must exit!")
                pattern = navigator["pickers"][get_pick[0]]["pattern"]
            else:
                pattern = [[], []]
            htmldata = new_gallery_html(pattern).encode(enc, 'surrogateescape')
        else:
            try:
                list = sorted(os.listdir(ondisk), key=lambda a: a.lower())
            except OSError:
                self.send_error(404, "No permission to list directory")
                return
            if not ondisk.endswith("/"):
                ondisk += "/"
            dirs = []
            files = []
            for name in list:
                fullname = f"{ondisk}{name}"
                ut = f"{os.path.getmtime(fullname):.7f}" if ntime else None
                if os.path.isdir(fullname):
                    parts = []
                    for partfn in ["partition.json", "partition A.json", "partition B.json", "partition C.json", "partition D.json", "partition E.json", "partition F.json"]:
                        if os.path.exists(fullname + "/" + partfn):
                            parts += [partfn]
                    dirs.append([ut, name, parts])
                elif os.path.isfile(fullname):
                    alt_view = False
                    if fullname.endswith(tuple(utf8file + ['.savx'])):
                        alt_view = True
                    files.append([ut, name, alt_view])
            htmldata = new_list_html(parent, dirs, files).encode(enc, 'surrogateescape')

        f = io.BytesIO()
        f.write(htmldata)
        f.seek(0)
        size = str(len(htmldata))
        self.send_response(200, size=size)
        self.send_header('Content-Type', f"text/html; charset={enc}")
        self.send_header('Content-Length', size)
        self.end_headers()
        return f

    extensions_map = {'.gz': 'application/gzip', '.z': 'application/octet-stream', '.bz2': 'application/x-bzip2', '.xz': 'application/x-xz',}

    def guess_type(self, ondisk):
        ext = os.path.splitext(ondisk)[1].lower()
        if ext in self.extensions_map:
            return self.extensions_map[ext]
        guess, _ = mimetypes.guess_type(ondisk)
        return guess if guess else 'application/octet-stream'

    def send_head(self):
        ntime = True
        self.range = (0, 0)
        self.total = 0
        ondisk = http2ondisk(self.path, self.directory)
        if os.path.isdir(ondisk):
            return self.list_directory(ondisk, ntime)
        if ondisk.endswith("/"):
            self.send_error(404, "File not found")
            return
        if ondisk.endswith(".cd") and not self.AUTH(ondisk):
            return

        try:
            f = open(ondisk, 'rb')
        except OSError:
            self.send_error(404, "File not found")
            return
        fs = os.fstat(f.fileno())
        size = fs[6]
        self.total = size

        # Range support
        start, end = 0, size-1
        if 'Range' in self.headers:
            start, end = self.headers.get('Range').strip().strip('bytes=').split('-')
        if start == "":
            try:
                end = int(end)
            except ValueError as e:
                self.send_error(400, 'invalid range')
            start = size-end
        else:
            try:
                start = int(start)
            except ValueError as e:
                self.send_error(400, 'invalid range')
            if start and start >= size:
                self.send_error(416, 'Requested Range Not Satisfiable')
            if end == "":
                end = size-1
            else:
                try:
                    end = int(end)
                except ValueError as e:
                    self.send_error(400, 'invalid range')

        start = max(start, 0)
        end = min(end, size-1)
        self.range = (start, end)

        try:
            Bytes = str(end-start+1)
            if 'Range' in self.headers:
                self.send_response(206, size=Bytes)
            else:
                self.send_response(200, size=Bytes)
            self.send_header('Accept-Ranges', 'bytes')
            self.send_header('Content-Range', f'bytes {start}-{end}/{size}')
            self.send_header('Content-Type', self.guess_type(ondisk))
            self.send_header('Content-Length', Bytes)
            self.send_header('Last-Modified', httpdate(fs.st_mtime))

            # Developer note: use this if BaseHTTPRequestHandler is due?
            # self.send_header('Last-Modified', self.date_time_string(fs.st_mtime))

            self.end_headers()
            return f
        except:
            whereami("DISCONNECTED", 0, 1)

    def send_response(self, code, message=None, size=0, dead=False):
        buffer = '' if dead else f' {size} bytes'
        ondisk = http2ondisk(self.path, self.directory).replace("/", "\\")
        if not ondisk.rsplit("\\", 1)[-1] in mute404:
            echo(f"{(datetime.now(UTC) + timedelta(hours=int(offset))).strftime('%Y-%m-%d %H:%M:%S')} [{self.command} {code}] {tcolor.g}{self.client_address[0]} {tcolor.r}<- {tcolor.r if dead else tcolor.b}{ondisk}{tcolor.x}{buffer}", 0, 1)

        if not hasattr(self, '_headers_buffer'):
            self._headers_buffer = []
        self._headers_buffer.append(f"""HTTP/1.0 {code} {message}
""".encode('latin-1', 'strict'))
        # Developer note: use this if BaseHTTPRequestHandler is due?
        # self.send_response_only(code, message)

        self.send_header('Server', batchname)

        self.send_header('Date', httpdate(time.time()))
        # Developer note: use this if BaseHTTPRequestHandler is due?
        # self.send_header('Date', self.date_time_string())

    # Developer note: delete if BaseHTTPRequestHandler is due?
    def send_header(self, keyword, value):
        if not hasattr(self, '_headers_buffer'):
            self._headers_buffer = []
        self._headers_buffer.append(f"""{keyword}: {value}
""".encode('latin-1', 'strict'))
        if keyword.lower() == 'connection':
            if value.lower() == 'close':
                self.close_connection = True
            elif value.lower() == 'keep-alive':
                self.close_connection = False

    # Developer note: delete if BaseHTTPRequestHandler is due?
    def end_headers(self):
        self._headers_buffer.append(b"\r\n")
        if hasattr(self, '_headers_buffer'):
            self.wfile.write(b"".join(self._headers_buffer))
            self._headers_buffer = []

    def send_error(self, code, message=None):
        body = "<html><title>404</title><style>html,body{white-space:pre; background-color:#0c0c0c; color:#fff; font-family:courier; font-size:14px;}</style><body> .          .      .      . .          .       <p>      .              .         .             <p>         .     🦦 -( 404 )       .  <p>   .      .           .       .       . <p>     .         .           .       .     </body></html>"
        size = str(len(body))
        try:
            self.send_response(code, message, size, True)
            self.send_header('Connection', 'close')
            self.send_header('Content-Type', "text/html;charset=utf-8")
            self.send_header('Content-Length', size)
            self.end_headers()
            self.wfile.write(bytes(body, 'utf-8'))
        except:
            whereami("DISCONNECTED", 0, 1)

    def copyfile(self, source, outputfile):
        dl = self.range[0]
        source.seek(dl)
        sf[0] += 1
        thread = sf[0]
        echothreadn.append(-thread)
        try:
            while buf := source.read(262144):
                Bytes = len(buf)
                dl += Bytes
                echoMBs(-thread, -Bytes, -int(dl/self.total*256) if self.total else 0)
                outputfile.write(buf)
            if len(echothreadn) == 1:
                echo("DONE", 0, 1)
        except:
            whereami("DISCONNECTED", 0, 1)
        echothreadn.remove(-thread)



class httpserver(TCPServer, ThreadingMixIn):
    allow_reuse_address = True

    # Developer note: Delete below they don't provide anything useful?
    def server_bind(self):
        TCPServer.server_bind(self)
        host, port = self.server_address[:2]
        self.server_name = socket.getfqdn(host)
        self.server_port = port
    def process_request_thread(self, request, client_address):
        self.finish_request(request, client_address)
    def process_request(self, request, client_address):
        Thread(target=self.process_request_thread, args=(request, client_address), daemon=True).start()
def startserver(port, directory):
    d = directory.rsplit("/", 2)[1]
    d = f"\\{d}\\" if d else f"""DRIVE {directory.replace("/", "")}\\"""
    print(f""" HTTP SERVER: Serving {d} at port {port}""")
    def inj(self, *args):
        return RangeHTTPRequestHandler.__init__(self, *args, directory=self.directory)
    s = httpserver(("", port), type(f'RangeHTTPRequestHandler<{directory}>', (RangeHTTPRequestHandler,), {'__init__': inj, 'directory': directory}))
    task["httpserver"].append(s)
    s.serve_forever()
    echo(f" HTTP SERVER: Stopped serving {d} freeing port {port}", 0, 1)

try:
    import certifi
    context = ssl.create_default_context(cafile=certifi.where())
except:
    context = None
# context = ssl.create_default_context(purpose=ssl.Purpose.SERVER_AUTH)
def stopserver():
    if sys.platform == "linux" and not busy[0] and not task["transmission"]:
        os.system("killall -9 cat")
    for s in task["httpserver"]:
        s.shutdown()
    task["httpserver"] = []
def restartserver():
    if sys.platform == "linux" and not busy[0] and not task["transmission"]:
        os.system("cat /dev/location > /dev/null &")
    port = 8885
    directories = [batchdir]
    for directory in directories:
        port += 1
        Thread(target=startserver, args=(port,directory,), daemon=True).start()
def portkilled(port=8886):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(1)
    r = s.connect_ex(("127.0.0.1", port))
    s.close()
    if r:
        echo(f" HTTP SERVER: Port {port} is dead, Jim.", 1, 1)
        stopserver()
        echo("", 0, 1)
    return True if r else False



cookies = cookiejar.MozillaCookieJar(batchname + "/cookies.txt")
# if os.path.exists(batchname + "/cookies.txt"):
#     cookies.load()
def new_cookie():
    return {'port_specified':False, 'domain_specified':False, 'domain_initial_dot':False, 'path_specified':True, 'version':0, 'port':None, 'path':'/', 'secure':False, 'expires':None, 'comment':None, 'comment_url':None, 'rest':{"HttpOnly": None}, 'rfc2109':False, 'discard':True, 'domain':None, 'name':None, 'value':None}



def ast(rule, key="0", key1="0"):
    return rule.replace("*date", fdate).replace("*id", key).replace("*title", key1).replace("/", "\\")

def saint(name=False, url=False, scheme=True):
    if url:
        url = list(parse.urlsplit(url))
        scheme = f"{url[0]}://{url[1]}" if scheme else f"""{url[1].split("www.", 1)[-1]}"""
        new_url = f"""{scheme}{parse.quote(url[2], safe="%/")}"""
        if url[3]:
            new_url += "?" + url[3]
        if url[4]:
            new_url += "#" + url[4]
        return new_url
    else:
        return "".join(i for i in parse.unquote(name).replace("/", "\\") if i not in "\":*?<>|")[:200]



def met(p, m):
    if not m:
        return True
    p = f"{p}"
    if m[0] and p.endswith(m[0]) or m[1] and not p.endswith(m[1]) or m[2] and p.startswith(m[2]) or m[3] and not p.startswith(m[3]) or m[4] and not m[4][0] <= len(p) <= m[4][1]:
        return
    return True

def peanutshell(z="0", c=[], g=False, m=[], cw=[]):
    return [[z, c, g, m, cw, "", ""]]

def peanut(z, cw, f, a):
    if len(z := z.rsplit(" customize with ", 1)) == 2:
        cw = z[1].rsplit("*", 1)
        if not len(cw) == 2:
            cw += [""]
    z = z[0]
    c = []
    if len(z := z.rsplit(" = ", 1)) == 2:
        c = z[1].split(" > ")
    z = z[0]
    g = False
    if len(z := z.rsplit(" greater", 1)) == 2:
        g = z[1] if z[1] else True
    z = z[0]
    m = [""]*5
    if len(z := z.rsplit(" not ends with ", 1)) == 2:
        m[0] = z[1]
    z = z[0]
    if len(z := z.rsplit(" ends with ", 1)) == 2:
        m[1] = z[1]
    z = z[0]
    if len(z := z.rsplit(" not starts with ", 1)) == 2:
        m[2] = z[1]
    z = z[0]
    if len(z := z.rsplit(" starts with ", 1)) == 2:
        m[3] = z[1]
    z = z[0]
    if len(y := z.rsplit(" letters", 1)) == 2:
        y = y[0].rsplit(" ", 1)
        if len(z := y[1].split("-", 1)) == 2:
            if z[0].isdigit() and z[1].isdigit():
                m[4] = [int(z[0]), int(z[1])]
                z = y[0]
        else:
            if z[0].isdigit():
                m[4] = [int(z[0]), int(z[0])]
                z = y[0]
    z = [[z, c, g, m, cw, [], " ꍯ " if f else ""]]
    if " > " in z[0][0] or a:
        if z[0][0].startswith("0"):
            z[0][0] = " > 0" + z[0][0].split("0", 1)[1]
        if " > 0" in z[0][0]:
            x = z[0][0].rsplit(" > 0", 1)
            z[0][0] = x[1]
            z = [x[0] + ' > 0', z]
        else:
            z = ['', z]
        if z[0].startswith(" > 0"):
            z[0] = "0" + z[0].split(" > 0", 1)[1]
        if z[1][0][0].startswith("api > "):
            z[1][0][0] = z[1][0][0].split("api", 1)[1]
        a = True
    else:
        z = ['', z]
    return [z, a]

def at(s, r, cw=[], alt=0, key=False, name=False, folder=False, meta=False):
    n, r = r.split(" ", 1) if " " in r else [r, ""]
    n = int(n) if n else 0
    if key:
        if len(d := r.split(" << ", 1)) == 2:
            r = [peanut(d[0], [], False, True)[0]] + peanut(d[1], [], folder, False)
        else:
            r = [[0, 0]] + peanut(r, [], False, False)
    else:
        r = peanut(r, cw, folder, False)
    if not s:
        s += [[]]
    if n:
        s += [[] for _ in range(n-len(s)+1)]
    if not s[n]:
        s[n] += [{"alt":alt}]
    s[n] += [r]
    if name and r[0] and not r[1]:
        file_pos[0] = "file_after"
    if name or meta:
        if len(s) > site["seqN"]:
            site["seqN"] = len(s)

def declare(rule, boolean=False):
    rule = rule.split("=", 1)
    rule[1] = rule[1].strip()
    if boolean and not rule[1] == "Yes" and not rule[1] == "No":
        return
    return rule[1]

offset = declare(rules[5])
date = datetime.now(UTC) + timedelta(hours=int(offset))
fdate = date.strftime('%Y') + "-" + date.strftime('%m') + "-XX"



def new_picker():
    return {
        "POST": [],
        "DELETE": [],

        "replace": [],
        "defuse": False,
        "visit": False,
        "reluctant": False,
        "part": [],
        "dict": [],
        "html": [],
        "icon": [],
        "links": [],
        "inlinefirst": True,
        "expect": [],
        "dismiss": False,
        "break": False,
        "pattern": [[], [], False, False],
        "message": [],
        "key": [],
        "folder": [],
        "choose": [],
        "file": [],
        "file_after": [],
        "files": False,
        "name": [],
        "time": [],
        "extfix": "",
        "urlfix": [],
        "url": [],
        "pages": [],
        "paginate": [],
        "checkpoint": False,
        "savelink": False,
        "ready":False
    }



file_pos = ["file"]
def add_picker(s, rule):
    if rule.startswith("POST "):
        rule = rule.split(" ", 2)
        s["POST"] += [[rule[1], rule[2]] if len(rule) == 2 else [rule[1], []]]
    elif rule.startswith("DELETE "):
        rule = rule.split(" ", 2)
        s["DELETE"] += [[rule[1], rule[2]] if len(rule) == 2 else [rule[1], []]]
    elif rule.startswith("defuse"):
        s["defuse"] = [True, rule.split(" ", 1)[1]] if " " in rule else [True, False]
    elif rule.startswith("visit"):
        s["visit"] = True
    elif rule.startswith("reluctant"):
        s["reluctant"] = True
    elif rule.startswith("part "):
        s["part"] += [rule.split("part ", 1)[1]]
    elif rule.startswith("replace "):
        rule = rule.split(" ", 1)[1].rsplit(" with ", 1)
        s["replace"] += [[rule[0], rule[1]]]
    elif rule.startswith("dict "):
        s["dict"] += [rule.split("dict ", 1)[1]]
    elif rule.startswith("html"):
        at(s["html"], rule.split("html", 1)[1])
        if s["file"] or s["file_after"]:
            s["inlinefirst"] = False
    elif rule.startswith("icon"):
        at(s["icon"], rule.split("icon", 1)[1])
    elif rule.startswith("inherit"):
        s["pattern"][2] = True
    elif rule.startswith("reload"):
        s["pattern"][3] = True
    elif rule.startswith("links"):
        at(s["links"], rule.split("links", 1)[1])
    elif rule.startswith("key"):
        at(s["key"], rule.split("key", 1)[1], key=True)
    elif rule.startswith("folder"):
        at(s["folder"], rule.split("folder", 1)[1], ["", "\\"])
    elif rule.startswith("title"):
        at(s["folder"], rule.split("title", 1)[1], ["", "\\"], 1)
    elif rule.startswith("expect"):
        at(s["expect"], rule.split("expect", 1)[1], [], 1)
    elif rule.startswith("unexpect"):
        at(s["expect"], rule.split("unexpect", 1)[1])
    elif rule.startswith("dismiss"):
        s["dismiss"] = True
    elif rule.startswith("break"):
        s["break"] = True
    elif rule.startswith("message "):
        s["message"] += [rule.split("message ", 1)[1]]
    elif rule.startswith("choose "):
        s["choose"] += [peanut(rule.split("choose ", 1)[1], [], False, False)[0]]
    elif rule.startswith("file "):
        at(s[file_pos[0]], rule.split("file", 1)[1], [], 1)
    elif rule.startswith("relfile "):
        at(s[file_pos[0]], rule.split("relfile", 1)[1])
    elif rule.startswith("files "):
        at(s[file_pos[0]], rule.split("files", 1)[1], [], 1)
        s["files"] = True
    elif rule.startswith("relfiles "):
        at(s[file_pos[0]], rule.split("relfiles", 1)[1])
        s["files"] = True
    elif rule.startswith("time"):
        s["time"] = rule.split("time ", 1)[1]
    elif rule.startswith("name"):
        at(s["name"], rule.split("name", 1)[1], ["", ""], 1, name=True)
    elif rule.startswith("meta"):
        at(s["name"], rule.split("meta", 1)[1], ["", ""], meta=True)
    elif rule.startswith("extfix "):
        s["extfix"] = rule.split("extfix ", 1)[1]
    elif rule.startswith("urlfix"):
        if rule == "urlfix":
            s["urlfix"] += [[]]
        elif not " with " in rule:
            kill("""urlfix picker is broken, there need to be "with"!""")
        else:
            rule = rule.split("urlfix ", 1)[1].rsplit(" with ", 1)
            x = rule[1].split("*", 1)
            s["urlfix"] += [[x[0], rule[0], x[1] if len(x) > 1 else ""]]
    elif rule.startswith("url "):
        if not " with " in rule:
            kill("""url picker is broken, there need to be "with"!""")
        rule = rule.split("url ", 1)[1].rsplit(" with ", 1)
        x = rule[1].split("*", 1)
        s["url"] += [[x[0], rule[0], x[1] if len(x) > 1 else ""]]
    elif rule.startswith("pages "):
        at(s["pages"], rule.split("pages", 1)[1], [], 1)
    elif rule.startswith("relpages "):
        at(s["pages"], rule.split("relpages", 1)[1])
    elif rule.startswith("paginate"):
        r = rule.split("paginate", 1)[1]
        n, r = r.split(" ", 1) if " " in r else [r, ""]
        n = int(n) if n else 0
        if not s["paginate"]:
            s["paginate"] += [[]]
        if n:
            s["paginate"] += [[] for _ in range(n-len(s["paginate"])+1)]
        if not " with " in r:
            kill("""paginate picker is broken, there need to be "with"!""")
        x = r.rsplit(" with ", 1)
        y = x[1].replace("(", ")")
        if len(z := y.split(")")) == 3:
            pass
        elif len(z := y.split("*")) == 2:
            z.insert(1, "")
        else:
            kill("""paginate picker is broken, there need to be a pair of parentheses or an asterisk!""")
        if not s["paginate"][n]:
            s["paginate"][n] += [{"alt":0}]
        s["paginate"][n] += [[x[0].split(" "), z]]
    elif rule.startswith("checkpoint"):
        s["checkpoint"] = True
    elif rule.startswith("ready"):
        s["ready"] = True
    elif rule.startswith("savelink"):
        s["savelink"] = "savelink" if rule == "savelink" else rule.split("savelink ", 1)[1]
    else:
        return
    return True



def getrule(rule):
    if not rule or rule.startswith("#"):
        return



    rr = rule.split(" for ")
    if len(rr) == 2 and rr[0].startswith("md5"):
        sorter["md5"] += [rr[1]]
    elif len(rr) == 2 and rr[0].startswith("Mozilla/5.0"):
        navigator["agent"].update({rr[1]: rr[0]})
    elif len(rr) == 2 and rr[1].endswith("torrents"):
        d = rr[0].replace("\\", "/")
        r = rr[1].rsplit(" torrents", 1)
        if len(r) == 2 and d.endswith("/*"):
            d = d.rsplit("/*", 1)[0]
            if r[0] == "all other":
                sorter["torrentdirs"].update({"": d})
            else:
                sorter["torrentdirs"].update({r[0]: d})
        else:
            kill("\n There is at least one of the bad torrent dir rules (folder didn't end with /* or name had a spacing issue).")
    elif len(rr) == 2 and rr[1].startswith("http"):
        if rr[0].startswith("http"):
            navigator["referers"].update({rr[1]: rr[0]})
        elif len(r := ast(rr[0]).split("*")) == 2:
            sorter["customdirs"].update({rr[1]: r})
        elif len(r := rr[0].split(" ")) == 2:
            navigator["headers"].update({rr[1]: r})
        else:
            kill("\n There is at least one of the bad custom dir rules (no asterisk or too many).")
    elif len(rr) == 2 and rr[1].startswith('.') or len(rr) == 2 and rr[1].startswith('www.'):
        c = new_cookie()
        c.update({'domain': rr[1], 'name': rr[0].split(" ")[0], 'value': rr[0].split(" ")[1]})
        cookies.set_cookie(cookiejar.Cookie(**c))
        if not cli["dismiss"] == 2:
            cli["dismiss"] = False



    elif len(sr := rule.split(" seconds rarity ")) == 2:
        x = sr[0].split("-", 1)
        if x[0] == "paused":
            y = [[86400]*2]
        elif len(x) == 2:
            y = [[int(z) for z in x]]
        else:
            y = [[int(x[0])]*2]
        y = y*int(sr[1].split("%")[0])
        if len(src := sr[1].split(" ", 1)) == 2: 
            time_at = int(src[1].replace(":", ""))
        else:
            time_at = 0
        if time_at in navigator["timeout"]:
            navigator["timeout"][time_at] += y
        else:
            navigator["timeout"].update({time_at:y})
    elif rule == "collisionisreal":
        sorter["collisionisreal"] = True
    elif rule == "editisreal":
        sorter["editisreal"] = True
    elif rule == "buildthumbnail":
        sorter["buildthumbnail"] = True
    elif rule == "verifyondisk":
        sorter["verifyondisk"] = True
    elif rule == "theyfuckedup":
        ssl._create_default_https_context = ssl._create_unverified_context
    elif rule.startswith('bgcolor '):
        cli["bgcolor"] = rule.replace("bgcolor ", "")
    elif rule.startswith('fgcolor '):
        cli["fgcolor"] = rule.replace("fgcolor ", "")
    elif rule == "shuddup":
        cli["dismiss"] = 2
    elif rule == "showpreview":
        cli["showpreview"] = True
    elif rule.startswith('!'):
        navigator["pickers"][site["http"]]["pattern"][1 if rule.startswith("!!") else 0] += [rule.lstrip("!")]
    elif rule.startswith('.'):
        navigator["pickers"][site["http"]]["pattern"][1] += [rule]
    elif rule.startswith("\\"):
        site["dir"] = rule.split("\\", 1)[1]
        if site["dir"].endswith("\\"):
            if site["dir"] in sorter["dirs"]:
                print(f"""{tcolor.o} SORTER: \\{site["dir"]} must be announced only once.{tcolor.x}""")
            sorter["dirs"].update({site["dir"]: [False]})
        else:
            dir = site["dir"].rsplit("\\", 1)
            dir[0] += "\\"
            site["dir"] = dir[0]
            if dir[0] in sorter["dirs"]:
                print(f"""{tcolor.o} SORTER: \\{dir[0]} must be announced only once.{tcolor.x}""")
            sorter["dirs"].update({dir[0]: [False, dir[1]]})
    elif rule.startswith("!\\"):
        site["dir"] = rule.split("!\\", 1)[1]
        if site["dir"].endswith("\\"):
            if site["dir"] in sorter["dirs"]:
                print(f"""{tcolor.o} SORTER: \\{site["dir"]} must be announced only once.{tcolor.x}""")
            sorter["dirs"].update({site["dir"]: [True]})
        else:
            dir = site[1].rsplit("\\", 1)
            dir[0] += "\\"
            site["dir"] = dir[0]
            if dir[0] in sorter["dirs"]:
                print(f"{tcolor.o} SORTER: \\{dir[0]} must be announced only once.{tcolor.x}")
            sorter["dirs"].update({dir[0]: [True, dir[1]]})
    elif rule.startswith("http"):
        for n in range(site["seqN"]):
            if not navigator["pickers"][site["http"]]["name"][n]:
                kill(f"\n One of the name pickers for sequential name assemblement was skipped.")
        site["seqN"] = 0
        site["http"] = rule
        if not site["http"] in navigator["pickers"]:
            navigator["pickers"].update({site["http"]:new_picker()})
        file_pos[0] = "file"
    elif add_picker(navigator["pickers"][site["http"]], rule):
        pass
    elif site["dir"]:
        sorter["dirs"][site["dir"]] += [rule]
    else:
        sorter["exempts"] += [rule]



def loadrule():
    navigator["pickers"] = {site["http"]:new_picker()}
    sorter["torrentdirs"] = {}

    for rule in rules:
        getrule(rule)

    for n in range(site["seqN"]):
        if not navigator["pickers"][site["http"]]["name"][n]:
            kill(f"\n One of the name pickers for sequential name assemblement was skipped.")



cli = {"bgcolor":False, "fgcolor":"3", "dismiss":0, "showpreview":False}
navigator = {"referers":{}, "headers":{}, "agent":{"http":"Mozilla/5.0"}, "timeout":{}, "pickers":{}}
sorter = {"md5":[], "customdirs":{}, "torrentdirs":{}, "dirs":{}, "exempts":[], "buildthumbnail":False, "verifyondisk":False, "collisionisreal":False, "editisreal":False}
site = {"http":"inline", "dir":"", "seqN":0}

# Loading referer, sort, and custom dir rules, pickers, and inline file rejection by file types from rulefile
loadrule()
if cli["bgcolor"]:
    tcolor.x = ansi_color(cli["bgcolor"], cli["fgcolor"])
    sys.stdout.write(tcolor.x + cls)



HTTPserver = declare(rules[0])
if HTTPserver == "No":
    HTTPserver = False
Browser = declare(rules[1])
Mail = declare(rules[2])
Geistauge = declare(rules[3], True)
proxy = declare(rules[6])
if HTTPserver:
    restartserver()
else:
    print(" HTTP SERVER: OFF")
if Browser:
    print(" BROWSER: " + Browser.replace("\\", "/").rsplit("/", 1)[-1])
else:
    print(" BROWSER: NONE")
if Mail:
    Mail = Mail.split(" ", 2)
    if len(Mail) > 1:
        if Mail[0].endswith("@gmail.com"):
            print(" MAIL: " + Mail[0] + " -> " + Mail[1] + " *")
        else:
            print(" MAIL: Non-Gmail as sender is unimplemented for now.\n\n Please try again . . .")
    else:
        print(" MAIL: Please add your two email addresses (sender/receiver)\n\n Corrupted rule encountered, please read above and then try again.")
        sys.exit()
    if len(Mail) < 3:
        import getpass
        Mail += [getpass.getpass(prompt=f" {Mail[0]}'s password (automatic if saved as third address): ")]
        echo("", 1)
    if not cli["dismiss"] == 2:
        cli["dismiss"] = False
else:
    print(" MAIL: NONE")
if Geistauge == None:
    kill(' GEISTAUGE: I am neither "Yes" nor "No" (case sensitive)\n\n Corrupted rule encountered, please read above and then try again.')
Geistauge = True if Geistauge == "Yes" else False
if Geistauge:
    try:
        import numpy, cv2
        from PIL import Image
        Image.MAX_IMAGE_PIXELS = 400000000
        print(" GEISTAUGE: ON")
    except:
        kill(f" GEISTAUGE: Additional prerequisites required - please execute in another command prompt with:\n\n{echo_pip()} install pillow\n{echo_pip()} install numpy\n{echo_pip()} install opencv-python")
elif sorter["verifyondisk"]:
    kill(f""" GEISTAUGE: I must be enabled for "verifyondisk" declared in {rulefile}.""")
elif sorter["buildthumbnail"]:
    kill(f""" GEISTAUGE: I must be enabled for "buildthumbnail" declared in {rulefile}.""")
else:
    print(" GEISTAUGE: OFF")
if "socks5://" in proxy and proxy[10:]:
    if not ":" in proxy[10:]:
        kill(" PROXY: Invalid socks5:// address, it must be socks5://X.X.X.X:port OR socks5://user:pass@X.X.X.X:port\n\n Corrupted rule encountered, please read above and then try again.")
    try:
        import socks
    except:
        kill(f" PROXY: Additional prerequisites required - please execute in another command prompt with:\n\n{echo_pip()} install PySocks")
    if "@" in proxy[10:]:
        usr, pw, address, port = proxy.replace("socks5:","").replace("/","").replace("@",":").split(":")
        socks.setdefaultproxy(socks.PROXY_TYPE_SOCKS5, address, int(port), username=usr, password=pw)
    else:
        address, port = proxy.replace("socks5:","").replace("/","").split(":")
        socks.setdefaultproxy(socks.PROXY_TYPE_SOCKS5, address, int(port))
    socket.socket = socks.socksocket
    # The following line prevents DNS leaks. https://stackoverflow.com/questions/13184205/dns-over-proxy
    socket.getaddrinfo = lambda *args: [(socket.AF_INET, socket.SOCK_STREAM, 6, '', (args[0], args[1]))]
print(f""" PROXY: {proxy if proxy[10:] else "OFF"}""")



if not cli["dismiss"]:
    choice(bg=["4c", "%color%"])
    buffer = f"\n{tcolor.o} TO YOURSELF: {rulefile} contains personal information\n like mail, password, cookies. Edit {rulefile} before sharing!"
    if HTTPserver:
        buffer += f"\n{skull()}\n HTTP SERVER: Anyone accessing your server can open {rulefile} reading personal information\n like mail, password, cookies."
    echo(f"""{buffer}\n\nAdd "shuddup" to {rulefile} to dismiss this message.{tcolor.x}""", 0, 1)



ticking = [Event(), False, Event()]
ticking[0].set()
ticking[2].set()
def timer(e="", listen=[], antalisten=[], clock=navigator["timeout"]):
    if not ticking[1]:
        ticking[1] = True
        if not clock:
            clock.update({0:[4, 8]})
            echo(f"""\n"#-# seconds rarity 100% 00:00" in {rulefile} to customize timer, add another timer to manipulate rarity/schedule.\n""", 1, 1)

        now = int((datetime.now(UTC) + timedelta(hours=int(offset))).strftime('%H%M'))
        time_at = None
        next_clock = 0
        big_clock = 0
        for key in clock.keys():
            if now <= key:
                if next_clock >= key:
                    next_clock = key
            if now >= key:
                if not time_at or time_at < key:
                    time_at = key
            if big_clock < key:
                big_clock = key
        if time_at == None:
            time_at = big_clock

        randindex = int(len(clock[time_at])*random())
        r = clock[time_at][randindex]
        s = r[0]+int((r[1]-r[0]+1)*random())
        if next_clock:
            next_clock = int((datetime.now(UTC) + timedelta(hours=int(offset))).strftime('%Y%m%d') + f'{next_clock:04}')
            end = int((datetime.now(UTC) + timedelta(hours=int(offset), seconds=s)).strftime('%Y%m%d%H%M'))
            if end > next_clock:
                s = int(datetime.strptime(str(next_clock), '%Y%m%d%H%M').timestamp()) - int(time.time())
        end = int(time.time()) + s
        endclock = (datetime.now(UTC) + timedelta(hours=int(offset), seconds=s)).strftime('%H:%M')
        while True:
            ticking[0].clear()
            now = int(time.time())
            s = end - now
            if s < 61:
                echo(f"{e} {s} . . .")
                ticking[0].wait(timeout=1)
            else:
                h = int(s / 60 / 60)
                h = f"{h} hour and " if h == 1 else f"{h} hours and " if h else ""
                m = int(s / 60 % 60)
                m = f"{m} minute" if m == 1 else f"{m} minutes"
                sec = int(s % 60)
                echo(f"{e} {h}{m} until {endclock}")
                ticking[0].wait(timeout=sec)
            if pgtime[0] < int(time.time()/5):
                pgtime[0] = int(time.time()/5)
                pg[0] = 0
                title(monitor())
            if Keypress["KeyZ"]:
                Keypress["KeyZ"] = False
                break
            if now > end-2 or any(Keypress[n] for n in listen) or any(not Keypress[n] for n in antalisten):
                break
        ticking[1] = False
    else:
        while ticking[1]:
            time.sleep(0.5)



Keypress_err = ["Some error happened. (R)etry un(P)ause (S)kip once (X)auto defuse antibot with (F)irefox: "]
def retry(stderr):
    # Developer note: urllib has slight memory leak
    Keypress["KeyR"] = False
    while True:
        if not Keypress_prompt[0]:
            Keypress_prompt[0] = True
            if stderr:
                if Keypress["KeyP"]:
                    e = f"{retries[0]} retries (R)etry now (P)ause (S)kip once (X)auto"
                    if Keypress["KeyT"]:
                        timer(f"{e} (T)imer off, reloading in", listen=["KeyR", "KeyS"], antalisten=[16, 20, 24])
                    else:
                        echo(f"{e} (T)imer on")
                    Keypress["KeyR"] = True if Keypress["KeyP"] else False
                if not Keypress["KeyR"]:
                    title(monitor())
                    Keypress_err[0] = f"{stderr} (R)etry un(P)ause (S)kip once (X)auto defuse antibot with (F)irefox"
                    while True:
                        echo(Keypress_err[0])
                        ticking[0].clear()
                        if Keypress["KeyR"] or Keypress["KeyP"]:
                            break
                        if Keypress["KeyS"]:
                            Keypress["KeyS"] = False
                            Keypress_prompt[0] = False
                            return
                        if Keypress["KeyF"]:
                            Keypress["KeyF"] = False
                            return 2
                        ticking[0].wait()
                    ticking[0].set()
            else:
                echo(f"{retries[0]} retries (S)kip one, wait it out, or press X to quit trying . . . ")
            time.sleep(0.1)
            retries[0] += 1
            title(monitor())
            Keypress_prompt[0] = False
            return 1
        elif Keypress["KeyR"]:
            time.sleep(0.1) # so I don't return too soon to turn off another Keypress["KeyR"] used to turn off Keypress_prompt.
            return True
        time.sleep(0.1)



def overwrite(ondisk, todisk):
    if os.path.basename(todisk) == "desktop.ini":
        os.system(f"attrib -s -h \"{todisk}\"")
    try:
        with open(ondisk, 'rb') as fsrc:
            with open(todisk, 'wb') as fdst:
                while True:
                    buffer = fsrc.read(16*1024)
                    if not buffer:
                        break
                    fdst.write(buffer)
        os.utime(todisk, (os.path.getatime(ondisk), os.path.getmtime(ondisk)))
    except:
        # raise
        kill("Write protected or in use (by COM surrogate probably).\n\nTry again!")
    if os.path.basename(todisk) == "desktop.ini":
        os.system(f"attrib +s +h \"{todisk}\"")



def fetch(url, stderr="", dl=0, threadn=0, data=None, method=None, hydra=None):
    referer = x[0] if (x := [v for k, v in navigator["referers"].items() if url.startswith(k)]) else ""
    ua = x[0] if (x := [v for k, v in navigator["agent"].items() if url.startswith(k)]) else 'Mozilla/5.0'
    headers = {x[0][0]:x[0][1]} if (x := [v for k, v in navigator["headers"].items() if url.startswith(k)]) else {}
    headers.update({'User-Agent':ua, 'Referer':referer, 'Origin':referer})
    if hydra:
        headers.update(hydra)
    while True:
        # accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        accept = "application/json"
        ct = "application/json"
        headers.update({'Range':f'bytes={dl}-', 'Accept':accept, 'Content-Type':ct})
        try:
            resp = request.urlopen(request.Request(saint(url=url), headers=headers, data=data, method=method if method else "POST" if data else "GET"))
            break
        except HTTPError as e:
            if stderr or Keypress["KeyX"] and not Keypress["KeyS"]:
                el = retry(f"{stderr} ({e.code} {e.reason})")
                if el == 2:
                    driver(saint(url=url))
                    Keypress_prompt[0] = False
                    Keypress["KeyR"] = True
                elif not el:
                    return 0, str(e.code)
            else:
                Keypress["KeyS"] = False
                return 0, str(e.code)
        except URLError as e:
            if "CERTIFICATE_VERIFY_FAILED" in str(e.reason):
                echo("", 0, 1)
                if context:
                    kill(f""" {e.reason}\n\n They fucked up deploying their certificates (probably).\n Add "theyfuckedup" to {rulefile} to bypass this kind of error if you're willing to take risks.""")
                else:
                    kill(f""" {e.reason}\n\n Either they fucked up deploying their certificates or this Python is just having shitty certificate validator.\n Try execute optional prerequisites in another command prompt with:\n\n{echo_pip()} install certifi""")
            if stderr or Keypress["KeyX"] and not Keypress["KeyS"]:
                if not retry(f"{stderr} ({e.reason})"):
                    return 0, e.reason
            else:
                Keypress["KeyS"] = False
                return 0, e.reason
        except:
            if stderr or Keypress["KeyX"] and not Keypress["KeyS"]:
                el = retry(f"{stderr} (closed by host)")
                if el == 2:
                    echo(" BROWSER: Maybe not.", 0, 1)
                    Keypress_prompt[0] = False
                    Keypress["KeyR"] = True
                elif not el:
                    return 0, "closed by host"
            else:
                Keypress["KeyS"] = False
                return 0, "closed by host"
    return resp, 0



# cookies.save()
request.install_opener(request.build_opener(request.HTTPSHandler(context=context), request.HTTPCookieProcessor(cookies)))

def get(url, todisk="", utf8=False, conflict=[[], []], headonly=False, stderr="", sleep=0, threadn=0):
    if sleep:
        time.sleep(sleep)
    dl = 0
    if todisk:
        echo(threadn, f"{threadn:>3} Downloading 0 / 0 MB {url}", clamp='█')
        if os.path.exists(todisk + ".part"):
            dl = os.path.getsize(todisk + ".part")
    else:
        echo(threadn, "0 MB")
    Keypress["KeyZ"] = False
    while echothreadn and echothreadn.index(threadn) >= dlslot[0]:
        time.sleep(0.1)
    resp, err = fetch(url, stderr, dl, threadn)
    if not resp:
        return 0, err
    total = resp.headers['Content-length']
    if total:
        total = dl + int(total)
        GB = True if total > 1073741824 else False
        MB = f"{total/1073741824:.2f} GB" if GB else f"{int(total/1048576)} MB"
    else:
        GB = False
        MB = "0 MB"
    if todisk and total and dl == total:
        echo(f"{threadn:>3} Download completed: {url}", 0, 1)
        os.rename(todisk + ".part", todisk)
        return 1, 0
    if headonly and not stderr:
        return total, 0
    if todisk:
        if conflict[0]:
            if not total in conflict[1]:
                for file in conflict[0]:
                    if os.path.exists(file):
                        conflict[1] += [os.path.getsize(file)]
            if total in conflict[1]:
                echo("Filename collision + same filesize, safe to ignore", 0, 1)
                return 2, 0
        conflict[1] += [total]
        echo(threadn, f"""{threadn:>3} Downloading {f"{dl/1073741824:.2f}" if GB else int(dl/1048576)} / {MB} {url}""", clamp='█')
        with open(todisk + ".part", 'ab') as f:
            while True:
                try:
                    block = resp.read(262144)
                    if not block:
                        if not total or dl == total:
                            break
                        if not retry(stderr):
                            return 0, err
                        resp, err = fetch(url, stderr, dl, threadn)
                        if not resp:
                            return 0, err
                        if resp.status == 200 and dl > 0:
                            kill(threadn, "server doesn't allow resuming download. Delete the .part file to start again.")
                        continue
                except KeyboardInterrupt:
                    resp, err = fetch(url, stderr, dl, threadn)
                    if not resp:
                        return 0, err
                    if resp.status == 200 and dl > 0:
                        kill(threadn, "server doesn't allow resuming download. Delete the .part file to start again.")
                    continue
                except:
                    if not retry(stderr):
                        return 0, err
                    resp, err = fetch(url, stderr, dl, threadn)
                    if not resp:
                        return 0, err
                    if resp.status == 200 and dl > 0:
                        kill(threadn, "server doesn't allow resuming download. Delete the .part file to start again.")
                    continue
                f.write(block)
                Bytes = len(block)
                dl += Bytes
                echoMBs(threadn, Bytes, int(dl/total*256) if total else 0)
                echo(threadn, f"""{threadn:>3} Downloading {f"{dl/1073741824:.2f}" if GB else int(dl/1048576)} / {MB} {url}""", clamp='█', friction=True)
                if Keypress["KeyZ"]:
                    resp, err = fetch(url, stderr, dl, threadn)
                    if not resp:
                        return 0, err
                    if resp.status == 200 and dl > 0:
                        kill(threadn, "server doesn't allow resuming download. Delete the .part file to start again.")
                    Keypress["KeyZ"] = False
        echo(f"{threadn:>3} Download completed: {url}", 0, 1)
        os.rename(todisk + ".part", todisk)
        if Keypress_prompt[0]:
            echo(Keypress_err[0], flush=True)
        stdout.clear()
        return 1, 0
    else:
        data = bytearray()
        while True:
            try:
                block = resp.read(262144)
                if not block:
                    if not total or dl == total:
                        stdout.clear()
                        if utf8:
                            try:
                                return data.decode("utf-8"), 0
                            except:
                                try:
                                    return zlib.decompress(data, 16+zlib.MAX_WBITS).decode("utf-8"), 0
                                except:
                                    todisk = saint(parse.unquote(url.split("/")[-1]))
                                    echo(f" Not an UTF-8 file! Save on disk as {todisk} to open it in another program? (S)ave or discard and (C)ontinue: ", flush=True)
                                    Keypress["KeyC"] = False
                                    Keypress["KeyS"] = False
                                    while not Keypress["KeyC"] and not Keypress["KeyS"]:
                                        time.sleep(0.1)
                                    Keypress["KeyC"] = False
                                    if Keypress["KeyS"]:
                                        Keypress["KeyS"] = False
                                        with open(todisk, 'wb') as f:
                                            f.write(data);
                                        echo(f"{threadn:>3} Download completed: {url}", 0, 1)
                                    if Keypress_prompt[0]:
                                        echo(Keypress_err[0], flush=True)
                                    return 1, 0
                        else:
                            return data, 0
                    if not retry(stderr):
                        return 0, err
                    resp, err = fetch(url, stderr, dl, threadn)
                    if not resp:
                        return 0, err
                    if resp.status == 200:
                        data = bytearray()
                        dl = 0
                    continue
            except KeyboardInterrupt:
                resp, err = fetch(url, stderr, dl, threadn)
                if not resp:
                    return 0, err
                if resp.status == 200:
                    data = bytearray()
                    dl = 0
                continue
            except:
                if not retry(stderr):
                    return 0, err
                resp, err = fetch(url, stderr, dl, threadn)
                if not resp:
                    return 0, err
                if resp.status == 200:
                    data = bytearray()
                    dl = 0
                continue
            data += block
            Bytes = len(block)
            dl += Bytes
            echoMBs(threadn, Bytes, int(dl/total*256) if total else 0)
            echo(threadn, f"{int(dl/1048576)} MB", friction=True)
            if Keypress["KeyZ"]:
                resp, err = fetch(url, stderr, dl, threadn)
                if not resp:
                    return 0, err
                if resp.status == 200:
                    data = bytearray()
                    dl = 0
                Keypress["KeyZ"] = False



def echolinks():
    while True:
        threadn, todisk, onserver, sleep = task["download"].get()
        conflict = [[], []]
        for n in range(len(onserver)):
            if n and not sorter["collisionisreal"]:
                continue
            url = onserver[n]
            if n:
                if not conflict[0]:
                    conflict[0] += [todisk]
                todisk = f" ({n+1}).".join(todisk.rsplit(".", 1))
                conflict[0] += [todisk]
            if os.path.exists(todisk):
                echo(f"{threadn:>3} Already downloaded: {todisk}", 0, 1)
            elif not (err := get(url, todisk=todisk, conflict=conflict, threadn=threadn, sleep=sleep)[1]):
                newfilen[0] += 1
                error[0] += ["<a href=\"" + todisk.replace("#", "%23") + "\"><img src=\"" + todisk.replace("#", "%23") + "\" height=200px></a>"]
            else:
                error[1] += [todisk]
                error[2] += [f"&gt; Error downloading ({err}): {url}"]
                echo(f"{threadn:>3} Error downloading ({err}): {url}", 0, 1)
        echothreadn.remove(threadn)
        task["download"].task_done()



def check(string, patterns, whitelist=False):
    found = False
    for pattern in patterns:
        if not pattern:
            continue
        if pattern.startswith('.'):
            if string.lower().endswith(pattern.lower()):
                found = True
                break
        elif pattern.lower() in string.lower():
            found = True
            break
    if found and not whitelist or not found and whitelist:
        return pattern.lower()
    else:
        return ""



def isrej(filename, pattern):
    inline = navigator["pickers"]["inline"]["pattern"]
    rejected = ""
    origin = ""
    if "/" in filename:
        dir, filename = filename.rsplit("/", 1)
        dir = f"{batchname}/{echoname[0]}/{dir}/"
    else:
        dir = f"{batchname}/{echoname[0]}/"
    if pattern[0]:
        origin = "mediocre.txt"
        rejected = check(filename, pattern[0])
    if not rejected and pattern[2]:
        rejected = check(filename, pattern[1], whitelist=True)
        if rejected and inline[1]:
            rejected = check(filename, inline[1], whitelist=True)
        elif rejected and inline[0]:
            origin = rulefile
            rejected = check(filename, inline[0])
        else:
            rejected = ""
    elif not rejected and pattern[1]:
        rejected = check(filename, pattern[1], whitelist=True)
    elif not rejected and inline[1]:
        rejected = check(filename, inline[1], whitelist=True)
    elif not rejected and inline[0]:
        origin = rulefile
        rejected = check(filename, inline[0])
    if rejected and cli["showpreview"]:
        if rejected in filename.lower():
            print(f"{tcolor}{origin:>18}: {dir}{filename.lower().replace(rejected, tcolor.r + rejected + tcolor)}{tcolor.x}")
        else:
            print(f"{tcolor}  Not in whitelist: {dir}{tcolor.b}{filename}{tcolor.x}")
    return rejected



def get_cd(subdir, file, pattern, makedirs=False, preview=False):
    link = file["link"]
    todisk = batchname + "/" + file["name"].replace("\\", "/")
    if rule := [v for k, v in sorter["customdirs"].items() if k in link]:
        name, ext = os.path.splitext(file["name"])
        name = name.rsplit("/", 1)
        if len(name) == 2:
            folder = name[0] + "/"
            name = name[1]
        else:
            folder = ""
            name = name[0]
        prepend, append = rule[0]
        todisk = f"{folder}{prepend}{name}{append}{ext}".replace("\\", "/") # "\\" in file["name"] can work like folder after prepend
        dir = subdir + x[0] + "/" if len(x := todisk.rsplit("/", 1)) == 2 else subdir
        if isrej(todisk, pattern):
            link = ""
        elif not preview:
            if makedirs or [ast(x) for x in sorter["exempts"] if ast(x) == dir.replace("/", "\\")]:
                if not dir in task["makedirs"] and not task["makedirs"].add(dir) and not os.path.exists(dir):
                    if makedirs == 2:
                        echo(f"(C)ontinue or (S)kip making a new directory: {dir}", 0, 1)
                        Keypress["KeyS"] = False
                        Keypress["KeyC"] = False
                        while not Keypress["KeyS"] and not Keypress["KeyC"]:
                            time.sleep(0.1)
                        Keypress["KeyC"] = False
                        if Keypress["KeyS"]:
                            Keypress["KeyS"] = False
                            task["nodirs"].add(dir)
                    if not dir in task["nodirs"]:
                        try:
                            os.makedirs(dir)
                        except:
                            buffer = "\\" + dir.replace("/", "\\")
                            kill(f"Can't make folder {buffer} because there's a file using that name, I must exit!")
            elif not dir in task["makedirs"] and not task["makedirs"].add(dir) and not os.path.exists(dir):
                task["nodirs"].add(dir)
            if dir in task["nodirs"]:
                error[1] += [todisk]
                error[2] += [f"&gt; Error downloading (dir): {link}"]
                print(f" Error downloading (dir): {link}")
                link = ""
    elif not preview:
        dir = subdir + x[0] + "/" if len(x := todisk.rsplit("/", 1)) == 2 else subdir
        if isrej(todisk, pattern):
            link = ""
        elif not dir in task["makedirs"] and not task["makedirs"].add(dir) and not os.path.exists(batchname + "/"):
            try:
                os.makedirs(batchname + "/")
            except:
                buffer = "\\" + batchname.replace("/", "\\")
                kill(f"Can't make folder {buffer} because there's a file using that name, I must exit!")
    if not preview:
        if makedirs and not dir in task["makedirs"] and not task["makedirs"].add(dir) and not os.path.exists(dir):
            if makedirs == 2:
                echo(f"(C)ontinue or (S)kip making a new directory: {dir}", 0, 1)
                Keypress["KeyS"] = False
                Keypress["KeyC"] = False
                while not Keypress["KeyS"] and not Keypress["KeyC"]:
                    time.sleep(0.1)
                Keypress["KeyC"] = False
                if Keypress["KeyS"]:
                    Keypress["KeyS"] = False
                    task["nodirs"].add(dir)
            if not dir in task["nodirs"]:
                try:
                    os.makedirs(dir)
                except:
                    buffer = "\\" + dir.replace("/", "\\")
                    kill(f"Can't make folder {buffer} because there's a file using that name, I must exit!")
        file.update({"name":todisk, "edited":file["edited"]})
    return [link, todisk, file["edited"]]



def downloadtodisk(fromhtml, oncomplete, makedirs=False):
    if not "download" in task:
        task.update({"download":Queue()})
        for i in range(8):
            Thread(target=echolinks, daemon=True).start()
    if not fromhtml:
        threadn = 0
        while True:
            threadn += 1
            echothreadn.append(threadn)
            task["download"].put((threadn, "Key listener test", ["Key listener test"], random()*0.5))
            if threadn == 200:
                break
        try:
            task["download"].join()
        except KeyboardInterrupt:
            pass
        return
    error[0] = []
    error[1] = []
    error[2] = []
    htmlpart = fromhtml["partition"]
    pattern = fromhtml["pattern"]
    subdir = ""
    lastfilen = newfilen[0]



    # Partition and rebuild HTML
    filelist = [[], []]
    # whereami("Getting filelist")
    for key in htmlpart.keys():
        files = []
        duplicates = set()
        for file in htmlpart[key]["files"]:
            if not file["name"]:
                print(f""" Couldn't download to disk without a name for {file["link"]}""")
            else:
                if (x := get_cd(subdir, file, pattern, makedirs) + [key])[0]:
                    filelist[0] += [x]
            if not file["name"] in duplicates and not duplicates.add(file["name"]):
                files += [file["name"].rsplit("/", 1)[-1]]
        htmlpart[key]["files"] = files
        for h in htmlpart[key]["html"]:
            if len(h) == 2 and h[1]:
                if not h[1]["name"]:
                    print(f""" Couldn't download to disk without a name for {h[1]["link"]}""")
                else:
                    if (x := get_cd(subdir, h[1], pattern, makedirs) + [key])[0]:
                        filelist[1] += [x]
                h[1] = h[1]["name"].rsplit("/", 1)[-1]
    if fromhtml["inlinefirst"]:
        filelist = filelist[1] + filelist[0]
    else:
        filelist = filelist[0] + filelist[1]

    if error[1]:
        buffer = " There is at least one of the bad custom dir rules (non-existent dir).\n"
        echoed = []
        for e in error[1]:
            if not (e := os.path.split(e)[0].replace("/", "\\") + "\\") in echoed:
                echoed += [e]
                buffer += f"  {e}\n"
        echo("", 0, 1)
        echo(f"{buffer} Add following dirs as new rules (preferably only for those intentional) to allow auto-create dirs.", 0, 2)



    if not filelist:
        if fromhtml["makehtml"]:
            subdir = get_cd("", new_link(fromhtml["page"], fromhtml["folder"], 0), pattern, makedirs)[1]
            if os.path.exists(p := f"{subdir}partition.json"):
                with open(p, 'r') as f:
                    p = json.loads(f.read())
            else:
                p = {}
            if (part := updatepart(f"{subdir}partition.json", p, htmlpart, filelist, pattern, fromhtml["reluctant"])):
                new_relics = {}
                for key in part.keys():
                    part[key].update({"visible": False if part[key]["keywords"] and isrej(part[key]["keywords"][0], pattern) else True})
                    new_relics.update({key: part[key]})
                parttohtml(subdir, fromhtml["name"], new_relics, filelist, pattern)
        else:
            echo("Filelist is empty!", 0, 1)
        return
    # if len(filelist) == 1:
    #     echothreadn.append(0)
    #     task["download"].put((0, filelist[0][1], [filelist[0][0]], 0))
    #     try:
    #         task["download"].join()
    #     except KeyboardInterrupt:
    #         pass
    #     return



    # Autosave (1/3)
    new_files = {}
    dirs = set()
    htmldirs = {}
    # whereami("Assessing files")
    for onserver, ondisk, edited, key in filelist:



        # Autosave (2/3) and load partition.json
        dir = ondisk.rsplit("/", 1)[0] + "/"
        if not dir in dirs and not dirs.add(dir):
            if os.path.exists(p := f"{dir}partition.json"):
                with open(p, 'r') as f:
                    htmldirs.update({dir:json.loads(f.read())})
            else:
                htmldirs.update({dir:{}})
        if dir in htmldirs and key in htmldirs[dir] and not pattern[3]:
            if len(htmldirs[dir][key]["keywords"]) < 2:
                continue
            timestamp = htmldirs[dir][key]["keywords"][1]
            if not edited == "0" and not edited == timestamp:
                if os.path.exists(ondisk):
                    if sorter["editisreal"]:
                        old = ".old_file_" + timestamp
                        os.rename(ondisk, ren(ondisk, old))
                        thumbnail = ren(ondisk, '_small')
                        if os.path.exists(thumbnail):
                            os.rename(thumbnail, ren(thumbnail, old))
                    else:
                        print(f"  Edited on server: {ondisk}")
                        continue
            else:
                continue

        key = ondisk.lower()
        if key in new_files:
            new_files[key] = [onserver] + new_files[key]
        else:
            new_files.update({key: [onserver, ondisk]})



    for dir in htmldirs.keys():
        if not os.path.exists(dir):
            continue
        # whereami("Compiling parts")
        for icon in fromhtml["icons"]:
            if not os.path.exists(dir + icon["name"]):
                if icon["premade"]:
                    if not icon["premade"] == 2:
                        overwrite(icon["premade"], dir + icon["name"])
                elif err := get(icon["link"], dir + icon["name"])[1]:
                    echo(f""" Error downloading ({err}): {icon["link"]}""", 0, 1)
                    icon["premade"] = 2
                else:
                    icon["premade"] = dir + icon["name"]
            elif not icon["premade"]:
                icon["premade"] = dir + icon["name"]

        if page := fromhtml["page"]:
            file = dir + page["name"] + ".URL"
            if not os.path.exists(file):
                with open(file, 'w') as f:
                    f.write(f"""[InternetShortcut]
URL={page["link"]}""")
                buffer = file.replace("/", "\\")
                echo(f" File created: \\{buffer}", 0, 1)

        if not os.path.exists(dir):
            os.makedirs(dir)



        if fromhtml["premade"]:
            overwrite(f"{dir}gallery.html", fromhtml["premade"])
        else:
            if (part := updatepart(f"{dir}partition.json", htmldirs[dir], htmlpart, filelist, pattern, fromhtml["reluctant"])) or sorter["verifyondisk"]:
                new_relics = {}
                for key in part.keys():
                    part[key].update({"visible": False if part[key]["keywords"] and isrej(part[key]["keywords"][0], pattern) else True})
                    new_relics.update({key: part[key]})
                parttohtml(dir, fromhtml["name"], new_relics, filelist, pattern)
                # fromhtml["premade"] = f"{dir}gallery.html"
                # Developer note: Need to handle editisreal in Autosave (2/3), unimplemented for now.



    threadn = 0
    for key in new_files.keys():
        threadn += 1
        echothreadn.append(threadn)
        task["download"].put((threadn, new_files[key][-1], new_files[key][:-1], 0))
    try:
        task["download"].join()
    except KeyboardInterrupt:
        pass



    # Autosave (3/3), build thumbnails and errorHTML
    if sorter["buildthumbnail"]:
        echo("Building thumbnails . . .")
        for dir in htmldirs.keys():
            for file in next(os.walk(dir))[2]:
                thumbnail = f"{dir}{ren(file, '_small')}"
                if not os.path.exists(thumbnail):
                    try:
                        img = Image.open(f"{dir}{file}")
                        w, h = img.size
                        if h > 200:
                            img.resize((int(w*(200/h)), 200), Image.ANTIALIAS).save(thumbnail, subsampling=0, quality=100)
                        else:
                            img.save(thumbnail)
                    except:
                        pass
    newfile = False if lastfilen == newfilen[0] else True
    if error[1]:
        for x in error[1]:
            # Legacy code for ender! Need a new way to find part IDs of failed downloads.
            htmlpart.pop(os.path.basename(x).split(".", 1)[0], None)
    if not newfile:
        sys.stdout.write(" Nothing new to download.")
    if error[1]:
        sys.stdout.write(" There are failed downloads I will try again later.\n")
    elif not newfile:
        sys.stdout.write("\n")
    title(status())



driver_running = [False]
def new_driver():
    while True:
        try:
            from selenium import webdriver
            break
        except:
            echo("", 0, 1)
            echo(f" SELENIUM: Additional prerequisites required - please execute in another command prompt with:\n\n{echo_pip()} install selenium", 0, 2)
            echo("(C)ontinue when finished installing required prerequisites.")
            Keypress["KeyC"] = False
            while not Keypress["KeyC"]:
                time.sleep(0.1)
            Keypress["KeyC"] = False
    if os.path.isfile(batchdir + "chromedriver.exe"):
        if not os.path.exists(batchdir + "chromedriver"):
            os.makedirs(batchdir + "chromedriver")
        # import undetected_chromedriver as uc
        # return uc.Chrome()
        options = webdriver.ChromeOptions()
        options.arguments.extend([f'user-data-dir={batchdir}chromedriver', '--disable-blink-features=AutomationControlled', "--no-default-browser-check", "--no-first-run"])
        if "http" in navigator["agent"]:
            options.add_argument(f"user-agent={navigator['agent']['http']}")
        driver = webdriver.Chrome(options=options)
        driver.execute_cdp_cmd(
            "Page.addScriptToEvaluateOnNewDocument",
            {
                "source": """
                    let objectToInspect = window;
                    let result = [];

                    while (objectToInspect !== null) {
                      result = result.concat(Object.getOwnPropertyNames(objectToInspect));
                      objectToInspect = Object.getPrototypeOf(objectToInspect);
                    }

                    for (const p of result) {
                      p.match(/.+_.+_(Array|Promise|Symbol)/ig);
                      delete window[p];
                    }
                    """
            },
        )
        return driver
    elif os.path.isfile(batchdir + "geckodriver.exe"):
        if not os.path.exists(batchdir + "geckodriver"):
            os.makedirs(batchdir + "geckodriver")
        options = webdriver.FirefoxOptions()
        options.arguments.extend(['--profile', batchdir + "geckodriver"])
        options.set_preference('general.useragent.override', navigator['agent']['http'])
        driver = webdriver.Firefox(options=options)
        # driver.execute_script("")
        return driver
    else:
        subdir = batchdir.replace("/", "\\")
        echo(f""" The defuse picker (or you) suggested there are antibot detectors in place in this url
 and I will need a browser to defeat them.

 CHROME: Download and extract the latest stable release from https://chromedriver.chromium.org/home
 FIREFOX: Download and extract the latest win64 package from https://github.com/mozilla/geckodriver/releases

 to {subdir} and then try again.

 > Couldn't recommend Firefox because one dumbass Firefox developer has something to say
   https://github.com/mozilla/geckodriver/issues/1680#issuecomment-581466864
   https://github.com/mozilla/geckodriver/issues/1878#issuecomment-856673443
 > Context: They're not going to give their Gecko driver an option to turn off 'navigator.webdriver'
   used to defeat more antibot traps, claiming it's not the solution.

 Either will expect Chrome or Firefox being already installed, then {batchname} will create own user profile respectively:
  > {subdir}chromedriver\\ (Chrome)
  > {subdir}geckodriver\\ (Firefox)
 Once launched, personalize it sometime. Default settings is trait of bots not saving!""", 0, 2)
def ff_login(url):
    dom = parse.urlparse(url).netloc.replace("www", "")
    revisit = False
    for c in cookies:
        if dom == c.domain:
            revisit = True
            driver_running[0].add_cookie({"name":c.name, "value":c.value, "domain":c.domain})
    if revisit:
        driver_running[0].get(url)
def driver(url):
    if not driver_running[0]:
        if f := new_driver():
            driver_running[0] = f
        else:
            return
    # url = "https://www.whatsmyua.info/"
    driver_running[0].get(url)
    if not 'http' in navigator["agent"]:
        echo(f" BROWSER: Update your user-agent spoofer with:\n\n {driver_running[0].execute_script('return navigator.userAgent')}\n", 0, 1)
    elif not driver_running[0].execute_script('return navigator.userAgent') == navigator['agent']['http']:
        echo(f" BROWSER: My user-agent didn't match to an user-agent spoofer.", 0, 1)
    # ff_login(url)
    echo("(C)ontinue when finished defusing.")
    Keypress["KeyC"] = False
    while not Keypress["KeyC"]:
        time.sleep(0.1)
    Keypress["KeyC"] = False
    try:
        for bc in driver_running[0].get_cookies():
            if "httpOnly" in bc:
                del bc["httpOnly"]
            if "expiry" in bc:
                del bc["expiry"]
            if "sameSite" in bc:
                del bc["sameSite"]
            c = new_cookie()
            c.update(bc)
            cookies.set_cookie(cookiejar.Cookie(**c))
        echo("", 0, 1)
        echo(f" BROWSER: Gave cookie(s) to {batchname}", 0, 1)
        return True
    except:
        echo("", 0, 1)
        echo(" Couldn't communicate with browser! Has it been closed by accident? Maybe another time . . .", 0, 1)
        driver_running[0] = False
        return



def carrot(array, z, m, cw, saint, new):
    a = ""
    aa = ""
    p = ""
    update_array = [array[0], array[1]]
    ii = False
    cc = False
    carrot_saver = []
    if not "*" in z:
        if z in update_array[0]:
            if met(update_array[0], m):
                array[0] = ""
                new += [["", cw[0] + cw[1] if cw else ""]]
        return
    z = [0, z]
    pc = False
    while True:
        ac = False
        z = z[1].split("*", 1)
        if z[0].startswith("^"):
            carrot_saver += [z[0].split("^", 1)[1]]
            if len(z) == 2:
                continue
            z[0] = ""
            cc = True
        if len(z) == 2 and not z[0] and not z[1]:
            if met(update_array[0], m):
                array[0] = ""
                new += [["", cw[0] + update_array[0] + cw[1] if cw else update_array[0]]]
            return
        elif len(z) == 2 and not z[0]:
            y = ["", update_array[0]]
        elif not z[0]:
            y = [update_array[0], ""]
        elif not len(y := update_array[0].split(z[0], 1)) == 2:
            return
        if len(z) == 2 and not z[1]:
            if met(y[1], m):
                array[0] = ""
                new += [[y[0], cw[0] + y[1] + cw[1] if cw else y[1]]]
            return
        if carrot_saver:
            carrot_saver.reverse()
            c = [y[0], y[1]]
            carrot_aa = ""
            for cs in carrot_saver:
                if not len(c := c[0].rsplit(cs, 1)) == 2:
                    return
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
            carrot_saver = []
        if len(z) == 2:
            update_array[0] = y[1]
            aa += y[0] + z[0]
            if not ii:
                ii = True, y[0]
            pc = True
        else:
            p = y[0]
            if ac:
                y[0] = ""
            if not met(p, m):
                p = ""
                update_array[0] = y[1]
                a = aa + y[0] + z[0]
            else:
                if saint:
                    p = saint.join(s.strip() for s in p.replace("\\", "/").split("/"))
                update_array[0] = y[1]
                a = ii[1] if ii else y[0]
                if cw:
                    p = cw[0] + p + cw[1]
            new += [[a, p]]
            return True, update_array



def carrots(arrays, z, cw=[], any=True):
    update_array = []
    new = []
    for array in arrays:
        while True:
            update_array = carrot(array, z[1][0][0], z[1][0][3], cw if cw else z[1][0][4], z[1][0][6], new)
            if not update_array:
                break
            array = update_array[1]
            if not any:
                break
        new += [array]
    arrays = new
    return arrays



def linear(d, z, v):
    dt = []
    for x in z:
        dc = d
        if not x[0]:
            if v:
                dt += [d]
            continue
        elif x[0] == "0" or isinstance(x[0], int):
            dt += [x[0]]
            continue
        for y in x[0].split(" > "):
            y = y.split(" >> ")
            if not y[0]:
                continue
            if dc and isinstance(dc, dict) and y[0] in dc:
                dc = dc[y[0]]
                if len(y) == 2:
                    dc = json.loads(dc)
                    if dc and y[1] in dc:
                        dc = dc[y[1]]
            elif x[5]:
                kill(0, x[5])
            else:
                if v and dc and isinstance(dc, str):
                    try:
                        dj = json.loads(dc)
                        if y[0] in dj:
                            echo(f"{tcolor.o} > {y[0]}{tcolor.x} appears to be the first dict-in-dict key, please use {tcolor.o} >> {y[0]}{tcolor.x} instead.", 0, 1)
                    except:
                        pass
                return
        if not dc:
            return
        # dc = str(dc)
        if x[6]:
            dc = x[6].join(s.strip() for s in dc.replace("\\", "/").split("/"))
        if x[2] == True or x[2] and Keypress_buffer[0]:
            busy[1] = True
            ticking[2].clear()
            echo(f"Is {dc} greater than your expected number? Enter (N)umber", 0, 1)
            Keypress_err[0] = f"{dc} > "
            ticking[2].wait()
            busy[1] = False
            x[2] = Keypress_buffer[0]
            Keypress_buffer[0] = ""
        if x[2] and not isinstance(x[2], int) and x[2] > dc:
            return
        if x[1] and not any(c for c in x[1] if c == str(dc)) or x[3] and not met(dc, x[3]):
            if x[5]:
                kill(0, x[5])
            else:
                return
        if x[4]:
            dt += [f"{x[4][0]}{dc}{x[4][1]}"]
        else:
            dt += [dc]
    return dt



def branch(d, z, v):
    ds = []
    t = type(d).__name__
    pos = 0
    for x in z[0]:
        pos += 1
        x = x.split(" >> ")
        if not x[0]:
            if t == "list":
                for x in d:
                    ds += branch(x, [z[0][pos:]] + z[1:], v)
            elif t == "dict":
                for x in d.values():
                    ds += branch(x, [z[0][pos:]] + z[1:], v)
            return ds
        elif t == "dict" and x[0] in d:
            d = d[x[0]]
            if len(x) == 2:
                d = json.loads(d)
                if x[1] in d:
                    d = d[x[1]]
                else:
                    return ds
            t = type(d).__name__
        else:
            return ds
    else:
        if v and t in ["str", "int"]:
            ds += [[f"{tcolor.o}VIEWER: > 0 was used to access {tcolor.z('ffffff')}{d}"]]
            return ds
        elif not t in ["list", "dict"]:
            return ds
        elif dt := linear(d, z[1], v):
            if len(z) > 2:
                return [dt + b for b in branch(d, z[2:], v)]
            else:
                return [dt]
    return ds

def tree(d, z, v=False):
    # tree(dictionary, [branching keys, [[linear keys, choose, conditions, customize with, stderr and kill, replace slashes], [linear keys, 0 accept any, 0 no conditions, 0 no customization, 0 continue without, 0 no slash replacement]]], return anything for viewsource)
    pos = 0
    while pos < len(z):
        if isinstance(z[pos], list):
            pos += 2
            continue
        z[pos] = ['' if x == "0" else x for x in z[pos].split(" > ")] if z[pos] else []
        pos += 2
    return branch(d, z, v)



def opendb(data):
    try:
        return json.loads(data)
    except:
        try:
            data_qsl = {}
            for k, v in parse.parse_qsl(data):
                data_qsl.update({k: v})
            return data_qsl
        except:
            kill("Data received is not API or QS. Please check the data and determine if API-based picker is appropriate for it.")



def carrot_files(html, htmlpart, key, pick, abs_page, folder, file_after=False):
    update_html = []
    url = ""
    new_name = ""
    new_name_err = True
    for array in html:
        update_array = [array[0], array[1]]
        if file_after:
            update_html += [[array[0], '']]
            url = array[1]
        if url and not isinstance(url, dict):
            url = abs_page + url
            new_time = 0
            new_name = ""
            for x in pick["name"]:
                new_name_err = True
                for z, a in x[1:]:
                    cw = z[1][0][4]
                    if a:
                        continue
                    cw = ast(f"{cw[0]}*{cw[1]}", key, htmlpart[key]["keywords"][0] if key in htmlpart and len(htmlpart[key]["keywords"]) > 0 else "0").rsplit("*", 1)
                    if not z:
                        new_name_err = False
                    elif x[0]["alt"]:
                        # name
                        if len(n := carrots([[update_array[0], ""]], z, cw)) >= 2:
                            new_name += n[-2 if file_after else 0][1]
                            new_name_err = False
                            if file_after:
                                update_html[-1][0] = n[0][0] + n[1][0]
                            else:
                                update_array[0] = n[0][0] + n[1][0]
                            break
                    else:
                        # meta
                        if len(n := carrots([[url, ""]], z, cw, False)) == 2:
                            new_name += n[-2][1]
                            new_name_err = False
                            break
                if new_name_err:
                    kill(0, "there's no name asset found in HTML for this file.")
            for x in pick["time"]:
                new_time_err = True
                for z, a in x[1:]:
                    cw = z[1][0][4]
                    if a:
                        continue
                    cw = ast(f"{cw[0]}*{cw[1]}", key, htmlpart[key]["keywords"][0] if key in htmlpart and len(htmlpart[key]["keywords"]) > 0 else "0").rsplit("*", 1)
                    if not z:
                        new_time_err = False
                    elif len(n := carrots([[update_array[0], ""]], z, cw)) >= 2:
                        new_time += n[-2 if file_after else 0][1]
                        new_time_err = False
                        if file_after:
                            update_html[-1][0] = n[0][0] + n[1][0]
                        else:
                            update_array[0] = n[0][0] + n[1][0]
                        break
                if new_time_err:
                    kill(0, "there's no time stamp asset found in HTML for this file.")
            if e := pick["extfix"]:
                if len(ext := carrots([[url, ""]], e, [".", ""], False)) == 2 and not new_name.endswith(ext := ext[-2][1]):
                    new_name += ext
            if file_after:
                url = array[1]
            if not new_time and key in htmlpart and len(htmlpart[key]["keywords"]) > 1:
                new_time = htmlpart[key]["keywords"][1]
            update_html[-1][1] = new_link(url, folder + parse.unquote(new_name), new_time)
            if not file_after:
                update_html += [[update_array[0], '']]
        elif not file_after:
            update_html += [[array[0], '']]
        url = array[1]
    return update_html, new_name_err



def tree_files(db, k, f, pick, htmlpart, folder, filelist, pos):
    master_key = ["", peanutshell()]
    file = f[0]
    if k:
        key = k[1][1]
        if k[0][0]:
            if len(z := k[1][0].split(k[0][0] if k[0][0].startswith("0") else k[0][0] + " > 0", 1)) == 2:
                file = z[1]
                master_key = [k[0][0], peanutshell(k[0][1])]
        elif k[0][1]:
            master_key = ["", peanutshell(k[0][1])]
    else:
        key = peanutshell()



    if pick["choose"]:
        choose = pick["choose"][pos-1]
    else:
        choose = [0, []]
    if pick["time"]:
        whereami()
    meta = []
    linear_name = []
    off_branch_name = []
    stderr = "there's no name asset found in dictionary for this file."
    for z in pick["name"]:
        if not z[0]["alt"]:
            meta += [[]]
            for m, a in z[1:]:
                cwf = m[1][0][4]
                if off_branch_name:
                    cwf = ["".join(off_branch_name) + cwf[0], cwf[1]]
                meta[-1] += [[m, cwf]]
            off_branch_name = []
            linear_name += [[1]]
            continue
        z, a = z[pos]
        cwf = z[1][0][4]
        if not z:
            continue
        if f[0] == z[0]:
            if off_branch_name:
                cwf = [cwf[0] + "".join(off_branch_name), cwf[1]]
                off_branch_name = []
            linear_name += [z[1][0][:4] + [cwf, stderr, 0]]
        elif x := tree(db, [z[0], [z[1][0][:4] + [cwf, stderr, 0]]]):
            off_branch_name += [x[0][0]]
    files = tree(db, master_key + [file, key + choose[1] + f[1] + linear_name])
    if choose[1]:
        cf = []
        for cc in choose[1][0][1]:
            if [cx := x[:2] + x[3:] for x in files if str(x[2]) == cc]:
                cf = cx
                break
        files = [cf]
    if not files or not files[0]:
        return
    for file in files:
        f_key = file[1 if file[0] == "0" else 0]
        fp = []
        for x in meta:
            for y, cwf in x:
                cwf = ast(f"{cwf[0]}*{cwf[1]}", f"{f_key}", htmlpart[f_key]["keywords"][0] if f_key in htmlpart and len(htmlpart[f_key]["keywords"]) > 0 else "0").rsplit("*", 1)
                if len(ret := carrots([[file[2], ""]], y, cwf, False)) == 2 and ret[-2][1]:
                    fp += [ret[-2][1]]
                    break
                elif not y:
                    fp += [""]
                    break
        name = "".join([x if not x == 1 else fp.pop(0) if fp else "" for x in file[3:]] + off_branch_name)
        if e := pick["extfix"]:
            if len(ext := carrots([[file[2], ""]], e, [".", ""], False)) == 2 and not name.endswith(ext := ext[-2][1]):
                name += ext
        filelist += [[f_key, new_link(file[2], folder + name, htmlpart[f_key]["keywords"][1] if f_key in htmlpart and len(htmlpart[f_key]["keywords"]) > 1 else 0)]]



def pick_files(threadn, page, data, db, part, htmlpart, pick, pickf, folder, filelist, pos, file_after):
    for y in pickf:
        name_err = True
        for z, a in y[1:]:
            if pick["key"] and pick["key"][0]:
                keys = pick["key"][0]
            else:
                keys = [0, 0]
            if a:
                pos += 1
                if not db:
                    db = opendb(data)
                for k in keys[1:]:
                    if k and not z[0] == k[1][0]:
                        continue
                    tree_files(db, k, z, pick, htmlpart, folder, filelist, pos)
            elif not db:
                for p in part:
                    key = "0"
                    for k in keys[1:]:
                        if not k:
                            continue
                        if len(d := carrots([p], k[1], any=False)) == 2:
                            key = d[0][1]
                            break
                    html, name_err = carrot_files(carrots([p], z, any=pick["files"]), htmlpart, key, pick, "" if y[0]["alt"] else page, folder, file_after)
                    for h in html:
                        if not h[1]:
                            continue
                        filelist += [[key, h[1]]]
            if not pick["files"] and not name_err:
                break
    return pos



def rp(x, p):        
    for r in p:
        if "*" in r[0]:
            x = "".join(y[0] + y[1] for y in carrots([[x, ""]], ["", peanutshell(r[0], cw=r[1].split("*", 1))]))
        else:
            x = x.replace(r[0], r[1])
    return x



def get_data(threadn, page, url, pick):
    data = ""
    if not pick["ready"]:
        echo(f""" {"into" if url else "Visiting"} {page}""", 0, 1)
    if pick["defuse"]:
        if x := pick["defuse"][1]:
            cookie_err = f"I'll need a cookie named {x}."
            while cookie_err:
                for c in cookies:
                    if pick["defuse"][1] == c.name:
                        cookie_err = False
                if cookie_err:
                    echo(cookie_err, 0, 1)
                    cookie_err = f"Hmm, I haven't gotten the cookie named {x} yet. Try again?"
                    driver(page)
        else:
            driver(page)
    if pick["visit"]:
        fetch(page, stderr="Error visiting the page to visit")
    if pick["POST"]:
        for x in pick["POST"]:
            post = x[1] if x[1] else url
            data, err = fetch(post, stderr="Error sending data", data=str(x[0]).encode('utf-8'))
            if err:
                print(f" Error visiting ({err}): {page}")
                return 0, 0
        data = data.read()
    if pick["DELETE"]:
        for x in pick["DELETE"]:
            post = x[1] if x[1] else url
            data, err = fetch(post, stderr="Error sending data", data=str(x[0]).encode('utf-8'), method="DELETE")
            if err:
                print(f" Error visiting ({err}): {page}")
                return 0, 0
        data = data.read()
    if not data:
        data, err = get(url if url else page, utf8=True, stderr="Update cookie or referer if these are required to view", threadn=threadn)
        if err:
            print(f" Error visiting ({err}): {url if url else page}")
            return 0, 0
        elif isinstance(data, int) or len(data) < 4:
            return 0, 0
    title(monitor())
    data = ''.join([x.strip() for x in data.splitlines()])
    if pick["part"]:
        part = []
        for z in pick["part"]:
            part += [[x[1], ""] for x in carrots([[data, ""]], ["", peanutshell(z)])]
    else:
        part = [[data, ""]]
    for p in part:
        p[0] = rp(p[0], pick["replace"])
    return data, part



def pick_in_page():
    while True:
        data = 0
        url = 0
        threadn, pick, start, page, pagen, more_pages, alerted_pages, fromhtml = task["scraper"].get()
        htmlpart = fromhtml["partition"][threadn]
        folder = fromhtml["folder"]
        proceed = True
        pg[0] += 1
        redir = False
        if x := pick["urlfix"]:
            for y in x:
                if not y:
                    redir = True
                    break
                if "*" in y[1]:
                    if len(c := carrots([[page, ""]], ['', peanutshell(y[1])], any=False)) == 2:
                        page = y[0] + c[-2][1] + y[2]
                        redir = True
                else:
                    page = page.replace(y[1], y[0])
                    redir = True
            if redir and not pick["ready"]:
                echo(f" Updated url with a permanent redirection", 0, 1)
        if x := pick["url"]:
            url = page
            for y in x:
                if "*" in y[1]:
                    if len(c := carrots([[url, ""]], ['', peanutshell(y[1])], any=False)) == 2:
                        url = y[0] + c[-2][1] + y[2]
                        redir = True
                else:
                    url = url.replace(y[1], y[0])
                    redir = True
            if redir and not pick["ready"]:
                echo(f" Visiting {url}", 0, 1)
        db = ""
        if proceed and pick["expect"]:
            proceed = False
            pos = 0
            found_all = []
            for y in pick["expect"]:
                found = False
                for z, a in y[1:]:
                    if not z:
                        if not pick["ready"]:
                            echo(f""" {"into" if url else "Visiting"} {page}""", 0, 1)
                        found = True if fetch(page)[0] else False
                        title(monitor())
                    else:
                        if not data:
                            data, part = get_data(threadn, page, url, pick)
                            if not data:
                                break
                        if a:
                            if not db:
                                db = opendb(data)
                            pos += 1
                            found = tree(db, z)
                            if y[0]["alt"] and found or not y[0]["alt"] and not found:
                                break
                        else:
                            found = True if [x[1] for x in carrots(part, z, any=False)][0] else False
                            if y[0]["alt"] and found or not y[0]["alt"] and not found:
                                break
                if y[0]["alt"] and found or not y[0]["alt"] and not found:
                    found_all += [True]
                else:
                    found_all += [False]
                    break
            if all(found_all):
                if pick["break"]:
                    proceed = False
                else:
                    proceed = True
                    if not pick["dismiss"]:
                        if Browser:
                            os.system(f"""start "" "{Browser}" "{page}" """)
                        alerted_pages += [[start, page, pagen]]
                        alerted[0] = f"(C)ontinue (S)kip {len(alerted_pages)} alerted pages"
                    if pick["message"] and len(pick["message"]) >= pos:
                        buffer = pick["message"][pos-1]
                    else:
                        buffer = "As expected" if y[0]["alt"] and found else "Not any longer"
                    alert(page, buffer, pick["dismiss"])
            else:
                if pick["break"]:
                    proceed = True
                else:
                    timer(f"{alerted[0]}, resuming unalerted pages in" if alerted[0] else "Not quite as expected! Reloading in", listen=["KeyC", "KeyS"])
                    if not Keypress["KeyS"]:
                        more_pages += [[start, page, pagen]]
                        proceed = False
        if proceed and any(pick[x] for x in ["folder", "pages", "html", "icon", "dict", "file", "file_after"]) and not data:
            data, part = get_data(threadn, page, url, pick)
            if not data:
                proceed = False
        if proceed and pick["dict"]:
            for y in pick["dict"]:
                if len(c := carrots(part, ['', peanutshell(y)])) == 2:
                    data = c[0][1]
        if proceed and not folder:
            if proceed and pick["folder"]:
                for y in pick["folder"]:
                    name_err = True
                    for z, a in y[1:]:
                        if a:
                            if not db:
                                db = opendb(data)
                            for d in tree(db, z):
                                folder += d[0]
                                name_err = False
                        elif y[0]["alt"]:
                            if x := [x[1] for x in carrots([[data, ""]], z, any=False) if x[1]]:
                                folder += x[0]
                                name_err = False
                                break
                        else:
                            if len(x := carrots([[page, ""]], z, any=False)) == 2:
                                folder += x[0][1]
                                name_err = False
                                break
                    if name_err:
                        kill(0, "there's no suitable name asset for folder creation. Check folder pickers and try again.")
                if name_err:
                    break
                fromhtml["folder"] = folder
                fromhtml["name"] = folder
                echo("", 0, 1)
                echo(f"Folder assets assembled! From now on the downloaded files will go to this directory: {tcolor.g}\\{folder}{tcolor.x}*\nAdditional folders are made by custom dir rules in {rulefile}.", 0, 2)
            elif proceed and (x := pick["savelink"]):
                fromhtml["page"] = new_link(page, x, 0)
        if proceed and pick["pages"]:
            for y in pick["pages"]:
                for z, a in y[1:]:
                    if a:
                        if not db:
                            db = opendb(data)
                        pages = tree(db, z)
                        if pages and not pages[0][0] == "None":
                            for p in pages:
                                if not p[0] == page and not page + p[0] == page:
                                    px = p[0] if y[0]["alt"] else page.rsplit("/", 1)[0] + "/" + p[0]
                                    more_pages += [[start, px, pagen]]
                                    if pick["checkpoint"]:
                                        print(f"Checkpoint: {px}\n")
                    else:
                        if not "*" in (p:= z[1][0][0]):
                            if not p == page and not page + p == page:
                                px = p if y[0]["alt"] else page.rsplit("/", 1)[0] + "/" + p
                                more_pages += [[start, px, pagen]]
                                if pick["checkpoint"]:
                                    print(f"Checkpoint: {px}\n")
                        for p in [x[1] for x in carrots([[data, ""]], z) if x[1]]:
                            if not p == page and not page + p == page:
                                px = p if y[0]["alt"] else page.rsplit("/", 1)[0] + "/" + p
                                more_pages += [[start, px, pagen]]
                                if pick["checkpoint"]:
                                    print(f"Checkpoint: {px}\n")
        if proceed and pick["paginate"]:
            for y in pick["paginate"]:
                new = page
                for z in y[1:]:
                    l = carrots([[new, ""]], ['', peanutshell(z[0][0])])[0][1] if len(z[0]) > 1 else ""
                    l_fix = z[1][0]
                    x = carrots([[new, ""]], ['', peanutshell(z[0][1 if len(z[0]) > 1 else 0])])[0][1]
                    if (p := z[1][1]).isdigit() or p[1:].isdigit():
                        if x.isdigit():
                            x = int(x) + int(p)
                        else:
                            kill(f""" String captured: {x}
 Calculate with (+): {p}

Paginate picker is broken, captured string must be digit for calculator +/- mode!""")
                    elif z[1][1]:
                        p, a = peanut(z[1][1], [], False)
                        if a:
                            if not data:
                                data, part = get_data(threadn, page, url, pick)
                                if not data:
                                    break
                            if not db:
                                db = opendb(data)
                            x = tree(db, p)[-1][0]
                    r_fix = z[1][2]
                    r = carrots([[new, ""]], ['', peanutshell(z[0][2])])[0][1] if len(z[0]) == 3 else ""
                    new = f"{l}{l_fix}{x}{r_fix}{r}"
                more_pages += [[start, new, pagen]]
        if proceed and pick["html"]:
            fromhtml["makehtml"] = True
            k_html = []
            if pick["key"] and pick["key"][0]:
                part_keys = pick["key"][0]
            else:
                part_keys = [0, 0]
            pos = 0
            for y in pick["html"]:
                for z, a in y[1:]:
                    if a:
                        if not db:
                            db = opendb(data)
                        for p_k in part_keys[1:]:
                            master_key = ["", peanutshell()]
                            z0 =  z[0]
                            if not p_k:
                                key = peanutshell()
                            else:
                                if z0 == p_k[1][0]:
                                    key = p_k[1][1]
                                else:
                                    continue
                                if p_k[0][0]:
                                    if len(x := p_k[1][0].split(p_k[0][0], 1)) == 2:
                                        z0 = x[1]
                                        master_key = [p_k[0][0], peanutshell(p_k[0][1])]
                                elif p_k[0][1]:
                                    master_key = ["", peanutshell(p_k[0][1])]
                            for html in tree(db, master_key + [z0, key + z[1]]):
                                if pos == 1 or pos == 5:
                                    html[2] = html[2] + "\n"
                                if pos > 3:
                                    html[2] = hyperlink(html[2])
                                html[2] = rp(html[2], pick["replace"])
                                k_html += [[html[1 if html[0] == "0" else 0], [[html[2], ""]]]]
                    else:
                        new = []
                        for p in part:
                            key = "0"
                            for p_k in part_keys[1:]:
                                if len(d := carrots([[p[0], ""]], p_k[1], any=False)) == 2:
                                    key = d[0][1]
                                    break
                            c = carrots([[p[0], ""]], z, any=False)
                            k_html += [[key, [[rp(c[0][1], pick["replace"]), ""]]]]
                            new += [["".join(x[0] for x in c), ""]]
                        part = new
                pos += 1
            for k, html in k_html:
                if not k in htmlpart:
                    htmlpart.update(new_p(k))
                file_after = False
                for x in [pick["file"], pick["file_after"]]:
                    for y in x:
                        for z, a in y[1:]:
                            if a:
                                continue
                            html = carrot_files(carrots(html, z, any=pick["files"]), htmlpart, k, pick, "" if y[0]["alt"] else page, folder, file_after)[0]
                    file_after = True
                htmlpart[k]["html"] += html
            keywords = {}
            pos = 0
            for y in pick["key"][1:]:
                for z in y[1:]:
                    z, a = z[1:]
                    if a:
                        if not db:
                            db = opendb(data)
                        for p_k in part_keys[1:]:
                            if not p_k:
                                key = peanutshell()
                            else:
                                if z[0] == p_k[1][0]:
                                    key = p_k[1][1]
                                else:
                                    continue
                            for d in tree(db, [z[0], z[1] + key]):
                                if not d[1] in keywords:
                                    keywords.update({d[1]: [""]})
                                if pos == 0:
                                    keywords[d[1]][0] = d[0]
                                else:
                                    if len(ks := keywords[d[1]]) == 1 and not pos == 1:
                                        ks += [""]
                                    ks += [d[0]]
                    else:
                        for p in part:
                            key = "0"
                            for p_k in part_keys[1:]:
                                if len(d := carrots([[p[0], ""]], p_k[1], any=False)) == 2:
                                    key = d[0][1]
                                    break
                            if not key in keywords:
                                keywords.update({key: ["", ""]})
                            if pos < 2:
                                if not keywords[key][pos] and len(x := carrots([p], z, any=False)) == 2:
                                    keywords[key][pos] = x[0][1]
                            else:
                                for x in carrots([p], z)[:-1]:
                                    keywords[key] += [x[1]]
                pos += 1
            for z in keywords.keys():
                if not z in htmlpart:
                    htmlpart.update(new_p(z))
                htmlpart[z]["keywords"] += [rp(y, pick["replace"]) for y in keywords[z]]
        if proceed and pick["icon"]:
            pos = 0
            for y in pick["icon"]:
                if len(fromhtml["icons"]) < pos + 1:
                    for z, a in y[1:]:
                        if a:
                            if not db:
                                db = opendb(data)
                            url = tree(db, z)[0][0]
                            ext = ""
                            for x in imagefile:
                                if x in url:
                                    ext = x
                            icon = new_link(url, f"""icon{" " + str(pos) if pos else ""}{ext}""", 0)
                            icon.update({"premade":False})
                            fromhtml["icons"] += [icon]
                        else:
                            if len(c := carrots(part, z, any=False)) == 2:
                                url = c[0][1]
                                ext = ""
                                for x in imagefile:
                                    if x in url:
                                        ext = x
                                icon = new_link(url, f"""icon{" " + str(pos) if pos else ""}{ext}""", 0)
                                icon.update({"premade":False})
                                fromhtml["icons"] += [icon]
                pos += 1
        if proceed and (pick["file"] or pick["file_after"]):
            pos = 0
            filelist = []
            if pick["file"]:
                pos = pick_files(threadn, page, data, db, part, htmlpart, pick, pick["file"], folder, filelist, pos, False)
            if pick["file_after"]:
                pos = pick_files(threadn, page, data, db, part, htmlpart, pick, pick["file_after"], folder, filelist, pos, True)
            for file in filelist:
                k = file[0]
                if not k in htmlpart:
                    htmlpart.update(new_p(k))
                htmlpart[k].update({"files":[file[1]] + htmlpart[k]["files"]})
            if not pick["ready"]:
                stdout = ""
                x = ""
                pattern = fromhtml["pattern"]
                for k in htmlpart.keys():
                    for file in htmlpart[k]["files"]:
                        x = get_cd("", file, pattern, preview=True)
                        buffer = x[1].replace("/", "\\")
                        stdout += f"{tcolor.b}{x[0]}{tcolor.r} -> {tcolor.g}\\{buffer}\n"
                    for h in htmlpart[k]["html"]:
                        if h[1]:
                            x = get_cd("", h[1], pattern, preview=True)
                            buffer = x[1].replace("/", "\\")
                            stdout += f"{tcolor.b}{x[0]}{tcolor.r} -> {tcolor.g}\\{buffer}\n"
                if not x:
                    stdout += f"{tcolor.r} No files found in this page (?) Check pattern, add more file pickers, using cookies can make a difference." + "\n"
                echo(stdout + tcolor.x)
        if proceed and not pick["ready"]:
            fromhtml["ready"] = False
        echothreadn.remove(threadn)
        task["scraper"].task_done()



def new_p(z):
    return {z:{"html":[], "keywords":[], "files":[]}}

def new_part(threadn=0):
    new = {threadn:new_p("0")} if threadn else new_p("0")
    return {
      "ready": True,
      "page": "",
      "name": "",
      "folder": "",
      "makehtml": False,
      "pattern": [[], [], False, False],
      "icons": [],
      "inlinefirst": True,
      "reluctant": False,
      "partition": new,
      "premade": False
    }

def new_link(l, n, e):
    return {"link":l, "name":saint(n), "edited":e}



def nextshelf(fromhtml):
    sort_part = {}
    threadn = list(fromhtml["partition"].keys())
    threadn.sort()
    for t in threadn:
        sort_part.update(fromhtml["partition"][t])
    fromhtml["partition"] = sort_part

    if not fromhtml["ready"]:
        htmlpart = fromhtml["partition"]
        stdout = ""
        if fromhtml["makehtml"]:
            stdout += f"\n Then create " + tcolor.g + fromhtml["folder"] + "gallery.html" + tcolor.x + " with\n"
            if x := fromhtml["icons"]:
                stdout += f"""{tcolor.g}█{"█ █".join([i["name"] for i in x])}█\n"""
            if x := fromhtml["page"]:
                stdout += f"""{tcolor.o}<h2><a href="{x["link"]}">{x["name"]}</a></h2>\n"""
            for k in htmlpart.keys():
                if htmlpart[k]["keywords"] or htmlpart[k]["html"] or htmlpart[k]["files"]:
                    keywords = htmlpart[k]["keywords"]
                    title = keywords[0] if keywords and keywords[0] else f"ꍯ Part {k} ꍯ"
                    timestamp = keywords[1] if len(keywords) > 1 and keywords[1] else "No timestamp"
                    afterwords = ", ".join(f"{kw}" for kw in keywords[2:]) if len(keywords) > 2 else "None"
                    stdout += f"{tcolor.x}{k} :: {tcolor}{tcolor.b}{title} [{tcolor}{timestamp}{tcolor.r} Keywords: {afterwords}{tcolor.b}]\n"
                    for file in htmlpart[k]["files"]:
                        stdout += tcolor.g + file["name"].rsplit("\\")[-1] + "\n"
                    if html := htmlpart[k]["html"]:
                        for h in html:
                            if h[0]:
                                stdout += tcolor.o + h[0]
                            if h[1]:
                                stdout += tcolor.g + "█" + h[1]["name"].rsplit("\\")[-1] + "█"
                        stdout += "\n"
        echo(f"""{stdout}{tcolor.x} ({tcolor.b}Download file {tcolor.r}-> {tcolor.g}to disk{tcolor.x}) - Add scraper instruction "ready" in {rulefile} to stop previews for this site (C)ontinue or return to (M)ain menu: """, flush=True)
        Keypress["KeyM"] = False
        Keypress["KeyC"] = False
        while not Keypress["KeyM"] and not Keypress["KeyC"]:
            time.sleep(0.1)
        Keypress["KeyC"] = False
        if Keypress["KeyM"]:
            Keypress["KeyM"] = False
            return
    downloadtodisk(fromhtml, "Autosave declared completion.", makedirs=2)



pgs = [8]
def scrape(startpages):
    if not "scraper" in task:
        task.update({"scraper":Queue()})
        for i in range(8):
            Thread(target=pick_in_page, daemon=True).start()
    shelf = {}
    threadn = 0
    pages = startpages
    visited = set()
    alerted_pages = []
    while True:
        more_pages = []
        for start, page, pagen in pages:
            pgs[0] -= 1
            threadn += 1
            echothreadn.append(threadn)
            get_pick = [x for x in navigator["pickers"].keys() if page.startswith(x)]
            if not get_pick:
                print(f"I don't have a scraper for {page}")
                break
            pick = navigator["pickers"][get_pick[0]]
            if not start:
                start = page
                shelf.update({start: new_part(threadn)})
                fromhtml = shelf[start]
                fromhtml["pattern"] = navigator["pickers"][get_pick[0]]["pattern"]
                fromhtml["inlinefirst"] = pick["inlinefirst"]
                fromhtml["reluctant"] = pick["reluctant"]
            else:
                fromhtml = shelf[start]
                fromhtml["partition"].update({threadn:new_p("0")})
            task["scraper"].put((threadn, pick, start, page, pagen, more_pages, alerted_pages, fromhtml))
        try:
            task["scraper"].join()
        except KeyboardInterrupt:
            pass # Ctrl + C
        pgs[0] = 8
        seen = set()
        more_pages = [x for x in more_pages if not x[1] in seen and not seen.add(x[1])]
        for _, page, _ in more_pages:
            if page in visited and not visited.add(page):
                print(f"{tcolor.r}Already visited {page} loophole warning{tcolor.x}")
                # more_pages.remove(page)
        if not more_pages and not alerted_pages:
            break
        pages = more_pages
        if alerted[0]:
            if not more_pages:
                echo(alerted[0])
                time.sleep(1)
            if Keypress["KeyC"]:
                Keypress["KeyC"] = False
                pages += alerted_pages
                alerted_pages = []
                alerted[0] = False
                choice(bg=["2e", "%color%"])
            elif Keypress["KeyS"]:
                Keypress["KeyS"] = False
                alerted_pages = []
                alerted[0] = False
                choice(bg=["2e", "%color%"])
    title(status())

    for p in shelf.keys():
        if shelf[p]["partition"]:
            nextshelf(shelf[p])



def whsm(file):
    f = Image.open(file)
    # Developer note: checksum of image data, not whole file! hashlib.sha256() if you want SHA256
    try:
        w, h = f.size
        s = os.path.getsize(file)
        m = hashlib.md5(f.tobytes()).hexdigest()
    except:
        return 0, 0, 0, "X"
    return w, h, s, m



def ph(file):
    dctii = cv2.dct(numpy.float32(Image.open(file).convert("L").resize((64, 64), Image.Resampling.LANCZOS)))[:12,:12]
    return format(int(''.join(str(b) for b in 1*(dctii > numpy.median(dctii)).flatten()), 2), 'x')



def phthread():
    while True:
        threadn, total, file, filevs, accu = task["verify"].get()
        try:
            hash = ph(file)
            f = file.rsplit("/", 1)
            if f[0].endswith(" Trash"):
                f[0] = f[0].rsplit(" Trash", 1)[0]
            accu.append(f"{hash} {f[0]}/{f[1]}")
            if filevs and filevs == hash:
                print(f"{file}\nSame file found! (C)ontinue")
                choice("c", ["2e"])
        except:
            error[0] += [file]
        if threadn%16 == 0:
            echo(str(int((threadn / total) * 100)) + "%")
        task["verify"].task_done()



def scanthread(filelist, filevs, savwrite):
    if not "verify" in task:
        task.update({"verify":Queue()})
        for i in range(8):
            Thread(target=phthread, daemon=True).start()
    accu = []
    threadn = 0
    total = len(filelist)
    for file in filelist:
        threadn += 1
        task["verify"].put((threadn, total, file, filevs, accu))
    task["verify"].join()
    if accu:
        savwrite.write(bytes('\n'.join(accu) + "\n", 'utf-8'))
        savwrite.flush()
    print("100%")



def tosav(fp, filevs=""):
    fp = fp.replace("\\", "/").split(batchdir)[1]
    savread = opensav(sav)
    if len(savread) == 0:
        savwrite = open(sav, 'ab')
        savwrite.write(bytes(f'{batchdir}\n', 'utf-8'))
    else:
        savwrite = open(sav, 'ab')
        firstline = savread.splitlines()[0]
        if not batchdir == firstline:
            echo(f"{batchdir} {firstline} Wrong SAV", 0, 1)
            return
    filelist = []
    error[0] = []
    title("Top directory")
    print("\n - - - - Top - - - -")
    for file in next(os.walk(fp))[2]:
        if not file.lower().endswith(tuple(imagefile)):
            continue
        if (file := f"{fp}/{file}") in savread:
            continue
        else:
            filelist += [file]
    scanthread(filelist, filevs, savwrite)



    for subfolder in next(os.walk(fp))[1]:
        if subfolder.endswith(" Trash 2"):
            continue
        filelist = []
        title(subfolder)
        print("\n - - - - \\" + subfolder + "\\ - - - -")
        for dir, folders, files in os.walk(f"{fp}/{subfolder}"):
            dir = fp + "/" + os.path.relpath(dir, fp).replace("\\", "/") + "/"
            for file in files:
                if not file.lower().endswith(tuple(imagefile)):
                    continue
                if (file := f"{dir}{file}") in savread:
                    continue
                else:
                    filelist += [file]
        scanthread(filelist, filevs, savwrite)
    savwrite.close()



    if error[0]:
        print(f"\n There are {len(error[0])} corrupted image file(s):")
        print("\n".join(error[0]))
    else:
        print("\n No corrupted image files!")



def opensav(file):
    if os.path.exists(file):
        with open(file, 'r', encoding='utf-8') as f:
            return f.read()
    else:
        open(file, 'w').close()
        return ""



def ren(filename, append):
    return append.join(filename.rsplit(".", 1) if filename.count(".") > 1 else [filename, ""])



def container(ondisk, label=''):
    link = ondisk.replace("#", "%23")
    if ondisk.lower().endswith(tuple(videofile)):
        return f"""<div class="frame"><video height="200" autoplay><source src="{link}"></video>{label}</div>"""
    elif ondisk.lower().endswith(tuple(imagefile)):
        if sorter["buildthumbnail"]:
            thumbnail = f"{subdir}" + ren(link.rsplit("/", 1), "_small")
        else:
            thumbnail = link
        return f"""<div class="frame"><a class="fileThumb" href="{link}"><img class="lazy" data-src="{thumbnail}"></a>{label}</div>"""
    else:
        label = f"""<div class="aqua" style="height:174px; width:126px;">{ondisk}</div>"""
        buffer = f"""<a href="{link}">{label}</a>"""
        buffer += f"""<a href="{ondisk.rsplit(".", 1)[0].replace("#", "%23")}"><div class="aqua" style="height:174px;"><i class="aqua" style="border-width:0 3px 3px 0; padding:3px; -webkit-transform: rotate(-45deg); margin-top:82px;"></i></div></a>"""
        return buffer



def new_list_html(parent, dirs, files):
    if parent == "/":
        title = "Top directory"
    else:
        title = parent.replace(">", "&gt;").replace("<", "&lt;").replace("&", "&amp;").replace("/", "\\")

    buffer = []
    for ut, name, parts in dirs:
        link = parse.quote(name)
        label = name.replace(">", "&gt;").replace("<", "&lt;").replace("&", "&amp;")
        as_qs = ''
        for part in parts:
            as_qs += f' - <a href="/View.html?partition={parent}{name}/{part}" class="viewer">{part}</a>'
        buffer += [f' {ut if ut else "&gt;"} <a href="{link}/">\\{label}\\</a>{as_qs}']

    for ut, name, alt_view in files:
        link = parse.quote(name)
        label = name.replace(">", "&gt;").replace("<", "&lt;").replace("&", "&amp;")
        as_qs = ''
        if alt_view:
            if name.endswith(tuple([".savx"])):
                as_qs = f' - <a href="/View.html?{name}" class="viewer">open</a>'
            else:
                as_qs = f' - <a href="/New Text.html?open={parent}{name}" class="viewer">view source</a>'
        buffer += [f' {ut if ut else "&gt;"}  <a href="{link}">{label}</a>{as_qs}']

    style = """
h1, h2, h3, h4, h5, h6 {
  margin: 4px;
}

[contenteditable], input {
  &:focus {
    outline: none;
  }
}

body {
  font-family: courier;
  font-size: 14px;
  line-height: 16px;
  -webkit-text-size-adjust: none;

  white-space: pre;
  background-color: #10100c;
  color: #088;
}

a {
  color: #cb7;
  text-decoration: none;

  &:visited {
    color: #efdfa8;
  }

  &.viewer {
    color: #6cb;

    &:visited {
      color: #bfe;
    }
  }
}
"""

    body = f"<h2>{title}</h2>{'\n'.join(buffer)}"

    return f"""<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="white">
<meta name="format-detection" content="telephone=no">
<meta name="viewport" content="user-scalable=0">
<title>{title}</title>
<style>{style}</style>
</head>
<body class="exitmenu">{body}</body>
</html>"""



def hyperlink(html):
    links = html.replace("http://", "https://").split("https://")
    new_html = links[0]
    for link in links[1:]:
        link = [link, ""]
        for x in "<\"'\n":
            if len(y := link[0].split(x, 1)) == 2:
                link[0] = y[0]
                link[1] = x + y[1] + link[1]
        url = "https://" + link[0]
        new_html += f"""<a href="{url}">{url}</a>{link[1]}"""
    return new_html



def updatepart(partfile, relics, htmlpart, filelist, pattern, reluctant):
    if "0" in htmlpart and not htmlpart["0"]["html"] and not htmlpart["0"]["files"]:
        del htmlpart["0"]

    new_relics = htmlpart.copy()
    part_is = False
    if not os.path.exists(partfile):
        with open(partfile, 'w') as f:
            f.write(json.dumps(new_relics))
        part_is = "created"
        part = new_relics
    else:
        stray_keys = iter(relics.keys())
        part = {}
        for key in new_relics.keys():
            if not key in relics:
                part.update({key:new_relics[key]})
                part_is = "updated"
                continue
            for stray_key in stray_keys:
                if not key == stray_key:
                    part.update({stray_key:relics[stray_key]})
                    for file in relics[stray_key]["files"]:
                        filelist += [[0, file, 0, stray_key]]
                else:
                    break
            if reluctant:
                part.update({key:relics[key]})
            elif not relics[key]["html"] == new_relics[key]["html"] or not relics[key]["keywords"] == new_relics[key]["keywords"]:
                new_stray_files = list(set(relics[key]["files"]).difference(new_relics[key]["files"]))
                if "stray_files" in relics[key]:
                    new_stray_files += relics[key]["stray_files"]
                if new_stray_files:
                    new_relics[key].update({"stray_files": new_stray_files})
                # if not relics[key]["html"] == new_relics[key]["html"]:
                #     stray_links = []
                #     for z in ["href=\"*\"", "href='*'", "http*"]:
                #         stray_links += carrots(relics[key]["html"], ["", peanutshell(z)])
                part.update({key:new_relics[key]})
                part_is = "updated"
            else:
                part.update({key:relics[key]})
        for stray_key in stray_keys:
            if not stray_key in part:
                part.update({stray_key:relics[stray_key]})
                for file in relics[stray_key]["files"]:
                    filelist += [[0, file, 0, stray_key]]
    if part_is:
        with open(partfile, 'w') as f:
            f.write(json.dumps(part))
        buffer = partfile.replace("/", "\\")
        echo(f" File {part_is}: \\{buffer}", 0, 1)
        return part
    elif pattern[3]:
        buffer = partfile.replace("/", "\\")
        echo(f" File loaded (filter reload): \\{buffer}", 0, 1)
        return part



def gethread():
    while True:
        threadn, htmlname, total, file = task["geistauge"].get()
        ondisk = f"{batchname}/{htmlname}/{file}"
        if file.endswith(tuple(imagefile)):
            try:
                image = Image.open(ondisk)
                image.verify()
            except:
                print(f" Corrupted on disk: {ondisk}")
                error[2] += [f"&gt; Corrupted on disk: {ondisk}"]
        elif False and file.endswith(tuple(archivefile)):
            if subprocess.call(f'"{sevenz}" t -pBadPassword "{ondisk}"', stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL):
                print(f" Corrupted on disk: {ondisk}")
                error[2] += [f"&gt; Corrupted on disk: {ondisk}"]
        if threadn%8 == 0:
            echo(" GEISTAUGE: " + str(int((threadn / total) * 100)) + "%")
        task["geistauge"].task_done()



def parttohtml(subdir, htmlname, part, filelist, pattern):
    files = []
    for file in next(os.walk(subdir))[2]:
        if not file.endswith(tuple(notstray)) and not file.startswith("icon"):
            files += [file]

    if sorter["verifyondisk"]:
        if not "geistauge" in task:
            task.update({"geistauge":Queue()})
            for i in range(8):
                Thread(target=gethread, daemon=True).start()
        threadn = 0
        for file in files:
            threadn += 1
            task["geistauge"].put((threadn, htmlname, len(files), file))
        task["geistauge"].join()
        echo(" GEISTAUGE: 100%", 0, 1)

    unsorted_stray_files = sorted(set(files).difference(x[1].rsplit("/", 1)[-1] for x in filelist))
    if unsorted_stray_files:
        if not "0" in part:
            part.update(new_p("0"))
            part["0"].update({"visible": True, "stray_files": unsorted_stray_files})
        else:
            part["0"].update({"stray_files": unsorted_stray_files})

    for file in unsorted_stray_files:
        if not file.endswith(tuple(notstray)) and isrej(file, pattern):
            ondisk = f"{subdir}{file}".replace("/", "\\")
            echo(f"Blacklisted file saved on disk: {ondisk}", 0, 1)
            error[2] += [f"&gt; Blacklisted file saved on disk: {ondisk}"]

    if sorter["buildthumbnail"]:
        echo("Building thumbnails . . .")



def tosavx(delete=False):
    start = time.time()
    echo(f"\n Now compiling duplicates to SAVX . . . kill this CLI to cancel.", 0, 2)
    newsavx = False
    savread = opensav(sav).splitlines()
    savxread = opensav(savx).splitlines()
    if not batchdir == savread[0]:
        echo(f"{batchdir} {savread[0]} Wrong SAV", 0, 1)
        return
    if len(savxread) == 0:
        savxread += [batchdir]
    elif not batchdir == savxread[0]:
        echo(f"{batchdir} {savxread[0]} Wrong SAVX", 0, 1)
        return
    savsread = opensav(savs).splitlines()
    ordered_sav = sorted(savread[1:], key=lambda s: s.split(" ", 1)[1])
    datagroup = {}
    for line in ordered_sav:
        phash, file = line.split(" ", 1)
        datagroup.setdefault(phash, [])
        datagroup[phash].append(file)
    for phash in datagroup.keys():
        philist = datagroup[phash]
        if phash in savsread and delete:
            for ondisk in philist:
                if os.path.exists(ondisk):
                    dir, filename = ondisk.rsplit("/", 1)
                    trashdir = f"{dir} Trash 2/"
                    if not os.path.exists(trashdir):
                        os.makedirs(trashdir)
                    os.rename(ondisk, trashdir + filename)
                    # os.remove(ondisk)
            continue
        if len(philist := [ondisk for ondisk in philist if os.path.exists(ondisk)]) < 2:
            continue
        Perfectexemption = True
        for ondisk in philist:
            if not any(word in ondisk for word in sorter["exempts"]):
                Perfectexemption = False
        if Perfectexemption:
            continue
        whsm_m = [0, 0, 0, 0]

        philist = iter(philist)
        file = next(philist)
        file2 = next(philist)
        while True:
            whsm_s = [0, 0, 0, 0]
            for line in savxread[1:]:
                x = line.split(" ", 4)
                if x[4] == file2:
                    whsm_s = [int(x[0]), int(x[1]), int(x[2]), x[3]]
                    break
            if not whsm_s[3]:
                whsm_s = whsm(file2)
                savxread += [" ".join([str(x) for x in whsm_s]) + f" {file2}"]
            if not whsm_m[3]:
                for line in savxread[1:]:
                    x = line.split(" ", 4)
                    if x[4] == file:
                        whsm_m = [int(x[0]), int(x[1]), int(x[2]), x[3]]
                        break
                if not whsm_m[3]:
                    whsm_m = whsm(file)
                    savxread == [" ".join([str(x) for x in whsm_m]) + f" {file}"]
            if whsm_m[3] == whsm_s[3] and delete:
                if not any(word in file2 for word in sorter["exempts"]):
                    if os.path.exists(file2):
                        os.remove(file2)
                elif not any(word in file for word in sorter["exempts"]):
                    if os.path.exists(file):
                        os.remove(file)
                    file = file2
                if file2 := next(philist, None):
                    continue
                else:
                    break
            newsavx = True
            if not (file2 := next(philist, None)):
                break
    if newsavx:
        with open(savx, 'wb') as f:
            f.write(bytes("\n".join(savxread), 'utf-8'))
    echo(f'total runtime: {time.time()-start}', 0, 1)



def savenow(trashdir=False):
    if os.path.exists(sav):
        savread = opensav(sav).splitlines()
    else:
        return
    if os.path.exists(savx):
        savxread = opensav(savx).splitlines()
    else:
        return
    new_savs = []

    if trashdir:
        dir = trashdir.rsplit(" Trash", 1)[0] + "/"
        for file in next(os.walk(trashdir))[2]:
            new = [[], []]
            ondisk = dir + file
            for line in savread:
                if ondisk in line:
                    new[0] = line
                    break
            for ondisk in savxread:
                if ondisk in line:
                    new[1] = line
                    break
            if new[0]:
                savread.remove(new[0])
                new_savs += [new[0].split(" ", 1)[0]]
            if new[1]:
                savxread.remove(new[1])
        with open(savs, 'ab') as f:
            f.write(bytes("\n".join(new_savs) + "\n", 'utf-8'))
        # with open(sav, 'wb') as f:
        #     f.write(bytes("\n".join(savread) + "\n", 'utf-8'))
        # with open(savx, 'wb') as f:
        #     f.write(bytes("\n".join(savxread) + "\n", 'utf-8'))
    elif schande_filelist[0][0]:
        buffer = ""
        for ondisk in schande_filelist[0][0]:
            next_new = [[], []]
            for line in savread:
                if ondisk in line:
                    next_new[0] = line
                    break
            for line in savxread:
                if ondisk in line:
                    next_new[1] = line
                    break
            if all(next_new):
                new_savs += [next_new[0].split(" ", 1)[0] + " " + " ".join(next_new[1].split(" ", 4)[:4])]
                buffer += f" Save: {tcolor.g}{ondisk}{tcolor.x}\n"
            else:
                buffer += f" Unscanned: {tcolor.b}{ondisk}{tcolor.x}\n"
        echo(buffer, 0, 1)
        if not new_savs:
            echo("No files to save!", 0, 1)
            return
        if input(" Press S again to confirm or return to (M)ain menu: ", "sm") == 1:
            with open(savs, 'ab') as f:
                f.write(bytes("\n".join(new_savs) + "\n", 'utf-8'))
    else:
        echo("No files to save!", 0, 1)



def delnow():
    stdout = ""
    trashlist = {}
    for ondisk in schande_filelist[0][1]:
        if os.path.exists(ondisk):
            dir, file = ondisk.rsplit("/", 1)
            if not dir in trashlist:
                trashlist.update({dir:[]})
            trashlist[dir] += [file]
            buffer = dir.replace("/", "\\")
            stdout += f"{tcolor.b}{buffer}\\{file}{tcolor.r} -> {tcolor.g}{buffer} Trash\\{file}{tcolor.x}\n"
    if not trashlist:
        echo("No schande'd files!", 0, 1)
        return
    echo(stdout, 0, 1)
    if input(" Press D again to confirm or return to (M)ain menu: ", "dm") == 1:
        for dir in trashlist.keys():
            trashdir = dir + " Trash/"
            if not os.path.exists(trashdir):
                os.makedirs(trashdir)
            for file in trashlist[dir]:
                if os.path.exists(file):
                    os.rename(f"{dir}/{file}", f"{trashdir}{file}")
        echo(skull(), 0, 1)
        choice(bg=["4c", "%color%"])
        schande_filelist[0][1] = []
    return True



def delmode():
    print("""
 Press D again to view files to be taken to \\.. Trash\\

 (G)eistauge auto - delete non-exempted duplicate images immediately with a confirmation.
   > One first non-exempt in path alphabetically will be kept if no other duplication are exempted.
   > Rebuild Geistauge HTML without/less identical images.

 (S)ave - "seen" files in best quality and there must not be inferior similarities again.
   > Use this only if what you think is unique and best quality available.
   > Use the Save button in browser to select files you want to save.
   > Developer note: Useless feature for now!

 (T)rash - "seen" trash files, input an trash folder to start.
   > Useful for files you don't like but kept coming back to haunt you.
   > Delete/move files from \\.. Trash\\ beforehand if you think you might change your mind later.
   > Then for the next time they will be moved to \\.. Trash 2\\ during (G)eistauge auto.
""")
    while True:
        el = input("Return to (M)ain menu: ", "dgstm")
        if not el:
            whereami("Bad choice", kill=True)
        elif el == 1:
            if delnow():
                return
        elif el == 2:
            if not Geistauge:
                choice(bg=True)
                print(" GEISTAUGE: Maybe not.")
                return
            choice(bg=["4c", "%color%"])
            if input("Drag'n'drop and enter my SAV file: ").rstrip().replace("\"", "").replace("\\", "/") == f"{batchdir}{sav}":
                echo(skull(), 0, 1)
                choice(bg=["4c", "%color%"])
                tosavx(True)
            return
        elif el == 3:
            savenow()
            return
        elif el == 4:
            echo("", 1, 0)
            trashdir = input("Trash dir: ").rstrip().replace("\"", "").replace("\\", "/")
            if os.path.isdir(trashdir) and trashdir.endswith(" Trash"):
                echo(skull(), 0, 1)
                choice(bg=["4c", "%color%"])
                savenow(trashdir)
            return
        elif el == 5:
            echo("", 1, 0)
            return



# Inherit the remove function
def delmode_old(m):
    print("\n This is my shortcut to delete the file alongside browser.\n Enter another file:/// local url then/or (V)iew/(R)emove/(D)elete/E(X)it\n Nothing is really deleted until you enter D twice.\n")
    while True:
        file = parse.unquote(input("Add file to delete list: ").rstrip().replace("file:///", "").replace("http://127.0.0.1:8886/", batchdir))
        if file.lower() == "x":
            return
        if file.lower() == "v":
            for x in schande_filelist[0][1]:
                echo(x, 0, 1)
        elif file.lower() == "r":
            file = parse.unquote(input("Remove file from delete list: ").rstrip().replace("file:///", "").replace("http://127.0.0.1:8886/", batchdir))
            while True:
                try:
                    schande_filelist[0][1].remove(file)
                    choice(bg=["2a", "%color%"])
                except:
                    choice(bg=["08", "%color%"])
                    break
        elif file.lower() == "d" and schande_filelist[0][1]:
            delnow()
        elif os.path.exists(file):
            choice(bg=["4c", "%color%"])
            schande_filelist[0][1] += [file]
        else:
            choice(bg=["08", "%color%"])



def compare(fp):
    try:
        hash = ph(fp)
    except:
        print(" Featuring image is corrupted.")
        return
    s = input("Enter reference (compare) / more folder to scan / nothing (find in database): ").rstrip().strip('\"')
    start = time.time()
    if not s:
        db = opensav(sav).splitlines()
        found = False
        indb = False
        print()
        for line in db:
            hash2, s = line.split(" ", 1)
            if hash == hash2:
                if fp != s:
                    if os.path.exists(s):
                        print(f"{hash2} {s} (still exists)")
                    else:
                        print(f"{hash2} {s} (non-existent)")
                    found = True
                else:
                    indb = True
        if not found and indb:
            print(f" {tcolor.g}Featuring image is unique!{tcolor.x} But come on, let's compile HTML from database so you can find duplication faster.")
        elif not found:
            print(f" {tcolor.g}Featuring image is unique! Nothing like it in database!{tcolor.x}")
        else:
            print(f"{hash} {fp} (featuring image)\nSame file found! (C)ontinue")
            choice("c", ["2e"])
    elif os.path.isdir(s):
        fp = s
        tosav(fp, hash)
    else:
        try:
            hash2 = ph(s)
        except:
            print(f"\n {tcolor.r}Reference image is corrupted.{tcolor.x}")
            return
        if hash == hash2:
            fp = whsm(fp)
            print(f"\n Featuring: {fp[0]} x {fp[1]}\n Reference: {label(m, whsm(s))}")
        else:
            print(f"\n {tcolor.g}Use your eyes, they're different{tcolor.x}")
    print(f"total runtime: {time.time()-start}")



def finish_sort():
    if not os.path.exists(batchname + "/"):
        choice(bg=True)
        print(f" \\{batchname}\\ doesn't exist! Nothing to sort.")
        return
    mover = {}
    for file in next(os.walk(batchname + "/"))[2]:
        for hash in sorter["md5"]:
            if len(c := carrots([[file,""]], ['', peanutshell(hash)], any=False)) == 2 and not c[0][0] and not c[-1][0]:
                ondisk = batchname + "/" + file
                with open(ondisk, 'rb') as f:
                    s = f.read()
                ext = os.path.splitext(ondisk)[1].lower()
                fp = hashlib.md5(s).hexdigest()
                file = fp + ext
                if not os.path.exists(fp + ext):
                    os.rename(ondisk, batchname + "/" + file)
                else:
                    print(f"I want to (D)elete {ondisk} because {file} already exists.")
                    if choice("d") == 1:
                        os.remove(ondisk)
                break
        for dir in sorter["dirs"].keys():
            if sorter["dirs"][dir][0]:
                found = False
                for n in sorter["dirs"][dir][1:]:
                    if fnmatch(file, n):
                        found = True
                        break
                if not found:
                    print(f"{tcolor.b}{batchname}\\ {tcolor.r}-> {tcolor.g}{dir}{tcolor}{file}{tcolor.x}")
                    mover.update({file:dir})
                    break
            else:
                for n in sorter["dirs"][dir][1:]:
                    if fnmatch(file, n):
                        print(f"{tcolor.b}{batchname}\\ {tcolor.r}-> {tcolor.g}{dir}{tcolor}{file}{tcolor.x}")
                        mover.update({file:dir})
                        break
    if not mover:
        choice(bg=True)
        print(f" Nothing to sort! Check and add or update pattern if there are files in \\{batchname}\\ needed to be sorted.")
        return
    echo(f" ({tcolor.b}From directory {tcolor.r}-> {tcolor.g}to a more deserving directory{tcolor.x}) {tcd} for non-existent directories - (C)ontinue ", flush=True)
    if not choice("c") == 1:
        whereami("Bad choice", kill=True)
    for file, dir in mover.items():
        if os.path.exists(dir + file):
            print(f"""I want to (D)elete source file because destination file already exists:
     source:      {batchname + "/"}{file}
     destination: {dir}{file}""")
            if not choice("d") == 1:
                whereami("Bad choice", kill=True)
            os.remove(batchname + "/" + file)
        elif os.path.exists(dir):
            os.rename(batchname + "/" + file, dir + file)
        else:
            if not os.path.exists(cd):
                os.makedirs(cd)
            if not os.path.exists(cd + file):
                os.rename(batchname + "/" + file, cd + file)
            else:
                print(f"""I want to (D)elete source file because destination file already exists:
     source:      {batchname}/{file}
     destination: {cd}{file}""")
                if not choice("d") == 1:
                    whereami("Bad choice", kill=True)
                os.remove(batchname + "/" + file)



def syntax(html, api=False):
    if api:
        x = html.split("{")
        html = [tcolor.z("ffffff") + x[0]]
        c = 0xffffff
        for y in x[1:]:
            c -= 0x224400
            y = y.split("}")
            html += ["{" + tcolor.z(str(hex(c if c > 0 else 0x111111)[2:])) + y[0]]
            for z in y[1:]:
                c += 0x224400
                html += [tcolor.z(str(hex(c if c > 0 else 0x111111)[2:])) + "}" + z]
        return ''.join(html + [tcolor.x])
    a = [[html,""]]
    for z in ["http://", "https://", "/"]:
        m = ['', '', '>', '', '', '']
        a = carrots(a, ['', peanutshell(f"'{z}*'", m=m)], ["'" + z, "'"])
        a = carrots(a, ['', peanutshell(f"\"{z}*\"", m=m)], ["\"" + z, "\""])
    z = []
    for x in a:
        y = tcolor
        if x[1][-4:-1] == ".js":
            y = tcolor.o
        elif ".json" in x[1] or "/api/" in x[1]:
            y = tcolor.b
        elif x[1][1:5] == "http":
            y = tcolor.g
        z += [x[0] + y + x[1] + tcolor.x]
    return "".join(z)



savepage = [{}]
def view_in_page(data, z, a):
    if a:
        if x := tree(data, z, True):
            for y in x:
                echo(syntax(f"{y[0]}", True), 0, 1)
                savepage[0]["part"] += [y[0]]
            if not z[1][0][0]:
                echo(f"{tcolor.o} Last key > 0 is view only. You must establish a next key for use in picker rules.{tcolor.x}", 0, 1)
        else:
            echo(f"{tcolor.o}Last few keys doesn't exist, try again.{tcolor.x}", 0, 1)
    else:
        if len(z[1][0][0].split("*")) > 1:
            if len(c := carrots([[data, ""]], z)) > 1:
                for x in c[:-1]:
                    echo(f"{tcolor.z('ffffff')}{x[1]}{tcolor.x}" if x[1] else f"{tcolor.o}zero-width{tcolor.x}", 0, 1)
                    savepage[0]["part"] += [x[1]]
            else:
                echo(f"{tcolor.o}No match found in page, try again.{tcolor.x}", 0, 1)
        else:
            echo(f"Please use asterisk {tcolor.o}*{tcolor.x} or right arrow key {tcolor.o} > {tcolor.x} (single-key use {tcolor.o}api > ...{tcolor.x}) to start finding in page.", 0, 1)

def source_view():
    while True:
        i = input("Enter URL to view source, append URL with key > s > to read it as dictionary, enter nothing to exit: ").rstrip()
        if i.startswith("http"):
            page, key = i.split(" ", 1) if " " in i else [i, False]
            if not page in savepage[0]:
                data, err = get(page, utf8=True)
                if err:
                    echo(f" Error visiting ({err}): {page}", 0, 1)
                    continue
                savepage[0] = {page:data, "part":[]}
            else:
                data = savepage[0][page]
            if not data.isdigit():
                if key:
                    z, a = peanut(key, [], False, False)
                    if a:
                        data = opendb(data)
                    view_in_page(data, z, a)
                else:
                    data = ''.join([s.strip() if s.strip() else "" for s in data.splitlines()])
                    echo(syntax(data), 0, 2)
            else:
                echo(f"Error or dead (update cookie or referer if these are required to view: {data})", 0, 2)
        elif not i:
            echo("", 1)
            echo("", 1)
            break
        else:
            z, a = peanut(i, [], False, False)
            part = savepage[0]["part"]
            savepage[0]["part"] = []
            for data in part:
                view_in_page(data, z, a)



def remote_echo(remote, nolist):
    echo(f" - - {(datetime.now(UTC) + timedelta(hours=int(offset))).strftime('%Y-%m-%d %H:%M:%S')} - - ", 0, 1)
    with subprocess.Popen([remote, "-l"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, bufsize=1, universal_newlines=True) as p:
        listed = False
        for line in p.stdout:
            if not any(x for x in ["Sum:    ", "ID    Done", "ID   Done"] if x in line):
                listed = True
                line = line.rstrip()
                id = line[:6].strip()
                percent = line[6:13].strip()
                status = line[59:71].strip() 
                name = line[72:].strip()
                echo(f"{id:>3} {status} {percent} {name}", 0, 1, clamp='█')
        if not listed:
            echo(nolist, 0, 1)
        echo("", 0, 1)

def remote_echo_files(remote, torrent_id):
    echo(f" - - {(datetime.now(UTC) + timedelta(hours=int(offset))).strftime('%Y-%m-%d %H:%M:%S')} - - ", 0, 1)
    with subprocess.Popen([remote, "-t", str(torrent_id), "-f"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL) as p:
        listed = False
        buffer = p.communicate()[0].decode().splitlines()
        for line in buffer:
            line = line.rstrip()
            if line and not any(x for x in [" files):", "  Done"] if x in line):
                listed = True
                id = line[:3].strip()
                percent = line[5:10].strip()
                status = line[19:23].strip()
                size = line[24:33].strip() 
                name = line[34:].strip()
                echo(f"{int(id)+1:>3} {'Include' if status == 'Yes' else 'Ignore '} {percent} {size:>9}  {name}", 0, 1, clamp='█')
        if not listed:
            echo("No files to list!", 0, 1)
        echo("", 0, 1)



def killdaemon(el):
    if el == "SlowK":
        echo(f"Press K twice in fast sequence to kill transmission-daemon and return to main menu.", 1, 1)
        return
    if sys.platform == "linux":
        os.system("killall -9 transmission-daemon")
    else:
        os.system("taskkill -f /im transmission-daemon.exe")
    task["transmission"] = False
    return True

def uninstdaemon(el):
    if sys.platform == "linux":
        if el == "SlowU":
            echo(f"Press U twice in fast sequence to uninstall Transmission and return to main menu.", 1, 1)
        else:
            os.system("apk del transmission-daemon")
            os.system("apk del transmission-cli")
    else:
        echo("Keypress U makes use of 'apk del' command which is only understood by Linux computers,\nother computers should uninstall Daemon through their app management.", 1, 3)
    return True


def start_remote(remote):
    shuddup = {"stdout":subprocess.DEVNULL, "stderr":subprocess.DEVNULL}
    pos = 0
    last_el = "KeyS"
    remove = []
    switch = "STOP"
    if not task["transmission"]:
        echo(""" Key listener (torrent/file viewer):
  > Press D, F to decrease or increase number by 10.
  > Press S, G to (S)top/start (G)etting selected item.
   > Finished torrent will stop automatically, start a finished torrent to seed indefinitely.
  > Press L, M to re/(L)ist all items or return to torrent (M)anager/(M)ain menu.
   > Press K to kill transmission-daemon and return to main menu.
   > Press U to uninstall Transmission and return to main menu.

 Key listener (torrent management):
  > Press R, E, I to (R)emove torrent, view fil(E)s of selected torrent, or (I)nput new torrent.""", 0, 2)
    while True:
        if task["transmission"]:
            index = input(f"Select TORRENT by number to {switch}: {f'{pos/10:g}' if pos else ''}", ["All", *"defgiklmrsu0123456789"], double="klu")
            if index < 0:
                el = "Slow" + "?ADEFGIKLMRSU0123456789"[-index]
            else:
                el = "Key" + "?ADEFGIKLMRSU0123456789"[index]
            num = index - len("?ADEFGIKLMRSU")
        else:
            index = input("(I)nput new torrent, (L)ist or return to (M)ain menu: ", [*"ilm"])
            el = "Key" + "?ILM"[index]
            task["transmission"] = True
        if el == "KeyD":
            pos -= 10 if pos > 0 else 0
            echo("", 1)
        elif el == "KeyF":
            pos += 10
            echo("", 1)
        elif el in ["KeyL", "SlowL"]:
            if last_el == "KeyR" and remove:
                if el == "SlowL":
                    echo(f"Press L twice in fast sequence to remove: {' '.join(x for x in remove)}", 1, 1)
                    continue
                for r in remove:
                    subprocess.Popen([remote, "-t", r, "-r"], **shuddup)
                remove = []
                pos = 0
                last_el = "KeyS"
                switch = "STOP"
                time.sleep(0.5)
                echo("", 1)
                remote_echo(remote, "All torrents removed!")
            else:
                echo("", 1)
                remote_echo(remote, "No torrents to list!")
        elif el == "KeyM":
            return
        elif el in ["KeyK", "SlowK"]:
            if killdaemon(el):
                return
            continue
        elif el in ["KeyU", "SlowU"]:
            if uninstdaemon(el):
                return
            continue
        elif el == "KeyI":
            echo("", 1)
            buffer = "cancel"
            while True:
                i = input(f"Magnet/torrent link, enter nothing to {buffer}: ").replace("\"", "")
                if i.startswith("magnet:") or i.startswith("http") or i.endswith(".torrent"):
                    dir = ""
                    if m := parse.parse_qs(i):
                        m = m["dn"][0]
                    else:
                        m = i
                    if d := [v for k, v in sorter["torrentdirs"].items() if k in m]:
                        dir = d[0]
                    else:
                        dir = "Transmission"
                    subprocess.Popen([remote, "-w", batchdir + dir, "--start-paused", "-a", i, "-sr", "0"], **shuddup)
                    buffer = "finish"
                    pos = 0
                    last_el = "KeyG"
                    switch = "START"
                elif not i:
                    echo("", 1)
                    if buffer == "finish":
                        remote_echo(remote, "Daemon's dead, Jim.")
                    break
                else:
                    choice(bg=True)
                    echo("Invalid input", 0, 2)
        elif not el[-1].isdigit() and not el == "KeyA":
            last_el = el
            pos = 0
            remove = []
            if el == "KeyS":
                switch = "STOP"
            elif el == "KeyG":
                switch = "START"
            elif el == "KeyR":
                switch = "REMOVE, (A)ll"
            elif el == "KeyE":
                switch = "VIEW file list"
            echo("", 1)
        else:
            if last_el == "KeyS":
                if el == "KeyA":
                    echo("", 1)
                else:
                    subprocess.Popen([remote, "-t", str(num+pos), "-S"], **shuddup)
            elif last_el == "KeyG":
                if el == "KeyA":
                    echo("", 1)
                else:
                    subprocess.Popen([remote, "-t", str(num+pos), "-s"], **shuddup)
            elif last_el == "KeyR":
                if el == "KeyA":
                    subprocess.Popen([remote, "-t", "all", "-r"], **shuddup)
                    remove = []
                    last_el = "KeyS"
                    time.sleep(0.5)
                    echo("", 1)
                    remote_echo(remote, "All torrents removed!")
                else:
                    remove += [str(num+pos)]
                    switch = "REMOVE, (A)ll, press L twice to confirm above, press R to clear"
            elif last_el == "KeyE":
                if el == "KeyA":
                    echo("", 1)
                    continue
                pos2 = 0
                last_i = "KeyS"
                switch2 = "STOP getting"
                i = "KeyE"
                while True:
                    if i == "KeyD":
                        pos2 -= 10 if pos2 > 0 else 0
                        echo("", 1)
                    elif i == "KeyF":
                        pos2 += 10
                        echo("", 1)
                    elif i == "KeyE":
                        remote_echo_files(remote, num+pos)
                    elif i == "KeyM":
                        echo("", 1)
                        break
                    elif i in ["KeyK", "SlowK"]:
                        if killdaemon(i):
                            return
                    elif not i[-1].isdigit() and not i == "KeyA":
                        last_i = i
                        pos2 = 0
                        if i == "KeyS":
                            switch2 = "STOP getting"
                        elif i == "KeyG":
                            switch2 = "GET"
                        echo("", 1)
                    elif last_i == "KeyS" or last_i == "KeyG":
                        KeyGet = "-G" if last_i == "KeyS" else "-g"
                        KeyAll = "all" if i == "KeyA" else str(num2-1+pos2)
                        subprocess.Popen([remote, "-t", str(num+pos), KeyGet, KeyAll], **shuddup)
                    index = input(f"Select FILE by number to {switch2}, (A)ll: {f'{pos2/10:g}' if pos2 else ''}", ["All", *"defgkms0123456789"], double="k")
                    if index < 0:
                        i = "Slow" + "?ADEFGKMS0123456789"[-index]
                    else:
                        i = "Key" + "?ADEFGKMS0123456789"[index]
                    num2 = index - len("?ADEFGKMS")



strayrun = [False]
def torrent_get(fp=""):
    if sys.platform == "win32":
        daemon = "C:/Program Files/Transmission/transmission-daemon.exe"
        remote = "C:/Program Files/Transmission/transmission-remote.exe"
        # daemon = f"{batchdir}bin/transmission-daemon.exe"
        # remote = f"{batchdir}bin/transmission-remote.exe"
        if not os.path.exists(daemon) or not os.path.exists(remote):
            echo(" Download and install Transmission x64 for Windows in default location from https://github.com/transmission/transmission/releases and then try again.", 0, 1)
            return
    elif sys.platform == "linux":
        if not os.path.exists("/usr/bin/transmission-daemon") or not os.path.exists("/usr/bin/transmission-remote"):
            el = input("Install Transmission (E)dge (C)urrent e(X)it", "ecx")
            if el == 1:
                getdae = "apk add transmission-daemon --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community"
                getcli = "apk add transmission-cli --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community"
            elif el == 2:
                getdae = "apk add transmission-daemon"
                getcli = "apk add transmission-cli"
            else:
                return
            echo(f"{tcolor.b}{getdae}{tcolor.x}", 0, 1)
            os.system(getdae)
            echo(f"{tcolor.b}{getcli}{tcolor.x}", 0, 1)
            os.system(getcli)
        daemon = "transmission-daemon"
        remote = "transmission-remote"
        if not task["httpserver"]:
            os.system("cat /dev/location > /dev/null &")
    else:
        echo("Unimplemented for this system!")
        return
    shuddup = {"stdout":subprocess.DEVNULL, "stderr":subprocess.DEVNULL}
    if not task["transmission"]:
        strayrun[0] = subprocess.Popen([daemon, "-f"], **shuddup, shell=True)
        # Developer note: needs a way to echo tutorial when transmission-daemon ran as Windows service (a stray process; since subprocess with shell=True should still spawn that process as child). It's to do with installer setting it to automatic startup. Ctrl + Shift + Esc > Services > Open Services > Right-click on "Transmission Daemon" > Properties > set Startup type to Manual
    if fp:
        dir = ""
        if m := parse.parse_qs(fp):
            m = m["dn"][0]
        else:
            m = fp
        if d := [v for k, v in sorter["torrentdirs"].items() if k in m]:
            dir = d[0]
        else:
            dir = "Transmission"
        subprocess.Popen([remote, "-w", batchdir + dir, "--start-paused", "-a", fp, "-sr", "0"], **shuddup)
    start_remote(remote)
    if sys.platform == "linux" and not task["httpserver"]:
        os.system("killall -9 cat")



def read_input(fp):
    if any(word for word in navigator["pickers"].keys() if fp.startswith(word)):
        task["run"].put((0, fp))
    elif fp.startswith("http") and not fp.startswith("http://127.0.0.1"):
        if fp.endswith("/"):
            choice(bg=True)
            echo(" I don't have a scraper for that!", 0, 2)
        else:
            task["run"].put((1, fp))
    elif fp.startswith("magnet") or fp.endswith(".torrent"):
        torrent_get(fp)
    elif os.path.exists(fp):
        if fp.endswith("partition.json"):
            subdir = fp.rsplit("/", 1)[0] + "/"
            htmlname = fp.rsplit("/", 2)[-2]
            if os.path.exists(p := f"{subdir}savelink.URL"):
                with open(p, 'r') as f:
                    page = f.read().splitlines()[1].replace("URL=", "")
            else:
                page = input("URL file not found, please guess original url to provide pattern for this partition: ")
            get_pick = [x for x in navigator["pickers"].keys() if page.startswith(x)]
            if not get_pick:
                kill("Couldn't recognize this url, I must exit!")
            pattern = navigator["pickers"][get_pick[0]]["pattern"]
            # pattern = [[], [], False]
            with open(fp, 'r') as f:
                htmlpart = json.loads(f.read())

            filelist = []
            new_relics = {}
            for key in htmlpart.keys():
                htmlpart[key].update({"visible": False if htmlpart[key]["keywords"] and isrej(htmlpart[key]["keywords"][0], pattern) else True})
                new_relics.update({key: htmlpart[key]})
                for file in htmlpart[key]["files"]:
                    if not isrej(file, pattern):
                        filelist += [["", file]]
                for array in htmlpart[key]["html"]:
                    if len(array) == 2 and array[1]:
                        if not isrej(array[1], pattern):
                            filelist += [["", array[1]]]
            parttohtml(subdir, htmlname, new_relics, filelist, pattern)
        elif not Geistauge:
            choice(bg=True)
            echo(" GEISTAUGE: Maybe not.", 0, 2)
        elif os.path.isdir(fp):
            print(f"""\nLoading featuring {"folder" if os.path.isdir(fp) else "image"} successful: "{fp}" """)
            tosav(fp)
        else:
            print(f"""\nLoading featuring {"folder" if os.path.isdir(fp) else "image"} successful: "{fp}" """)
            compare(fp)
    else:
        choice(bg=True)
        echo("Invalid input or not on disk", 0, 2)
    return True



def read_file(textread):
    startpages = []
    nextpages = []
    fromhtml = new_part()
    for line in textread:
        if not line or line.startswith("#"):
            continue
        elif line == "then":
            nextpages += [startpages]
            startpages = []
            continue
        elif line == "end":
            break
        elif not line.startswith("http"):
            continue
        if any(word for word in navigator["pickers"].keys() if line.startswith(word)):
            startpages += [["", line, [0]]]
        else:
            name = parse.unquote(line.split("/")[-1])
            fromhtml["partition"]["0"]["files"] += [new_link(line, name, 0)]
    nextpages += [startpages]
    if fromhtml["partition"]["0"]["files"]:
        downloadtodisk(fromhtml, "Autosave declared completion.")
    elif nextpages:
        resume = False
        for startpages in nextpages:
            if resume:
                print(f"\n Resuming next lines from {textfile}")
            else:
                resume = True
            scrape(startpages)
    else:
        print(f" No urls in {textfile}!")



demo = [0]
if filelist:
    busy[0] = True
    if sys.platform == "linux" and not task["httpserver"]:
        os.system("cat /dev/location > /dev/null &")
    if len(filelist) > 1:
        kill(f"""
 Only one input at a time is allowed! It's a good indication that you should reorganize better
 if there are too many folders to input and you don't want to use input's parent.{'''

 Geistauge is also disabled which can be a reminder that this is not the setup to run Geistauge.
 May I suggest having another copy of this script with Geistauge enabled in different directory?''' if not Geistauge else ""}""")
    read_input(filelist[0])
    busy[0] = False
    if sys.platform == "linux" and not task["httpserver"]:
        os.system("killall -9 cat")



def unrecognized(k):
    echo("", 1)
    echo(f"Keypress {k} unrecognized", 0, 1)
    if not busy[0]:
        ready_input()

def pressed(k, s=True):
    echo("", 1)
    Keypress[k] = s
    if not busy[0]:
        ready_input()
    if ticking[0]:
        ticking[0].set()

def has(i, x):
    if not x:
        return
    x = saint(url=x, scheme=False)
    for z in i:
        if z in x:
            x = x.split(z, 1)[-1]
        else:
            return
    return True

def keylistener():
    while True:
        index = input("", ["All", *"bcdefghijklmnopqrstuvwxyz0123456789"], double="jp")
        if index < 0:
            code = "Slow" + "?ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"[-index]
        else:
            code = "Key" + "?ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"[index]

        if code == "KeyA":
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo(f"Reading {textfile} . . .", 0, 1)
            task["run"].put((2, opensav(textfile).splitlines()))
        elif code == "KeyB":
            if sys.platform == "win32":
                if not Browser:
                    choice(bg=True)
                    echo(f""" No browser selected! Please check the "Browser =" setting in {rulefile}""", 0, 1)
                elif HTTPserver:
                    os.system(f"""start "" "{Browser}" "http://127.0.0.1:8886/" """)
                else:
                    echo(" HTTP SERVER: Maybe not.", 0, 1)
            else:
                echo(" BROWSER: Maybe not.", 0, 1)
            if not busy[0]:
                ready_input()
        elif code == "KeyC":
            pressed(code)
        elif code == "KeyD":
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            delmode()
            ready_input()
        elif code == "KeyE":
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo(help(), 0, 1)
            ready_input()
        elif code == "KeyF":
            pressed(code)
        elif code == "KeyG":
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            if not Geistauge:
                choice(bg=True)
                echo(" GEISTAUGE: Maybe not.", 0, 1)
            else:
                tosavx()
            ready_input()
        elif code == "KeyH":
            unrecognized(code)
        elif code == "KeyI":
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            if fp := input("Your input, enter nothing to cancel: ").rstrip().replace("\"", "").replace("\\", "/"):
                read_input(fp)
            else:
                echo("", 1)
                echo("", 1)
        elif code == "KeyJ":
            echo("", 1)
            if Keypress_time[0] < Keypress_time[2]:
                echo(" HTTP SERVER: 10-second demo", 0, 1)
                time.sleep(10)
                stopserver()
            elif task["httpserver"]:
                stopserver()
            else:
                restartserver()
            Keypress_time[2] = Keypress_time[0] + Fast_presser*4
            if not busy[0]:
                ready_input()
        elif code == "SlowJ":
            if not task["httpserver"] or portkilled():
                echo("Press J twice in fast sequence to start server.", 1, 1)
            else:
                echo("Press J twice in fast sequence to stop server.", 1, 1)
            if not busy[0]:
                ready_input()
        elif code == "KeyK":
            c = False
            for c in cookies:
                echo(str(c), 1, 2)
            if not c:
                echo("No cookies!", 1, 1)
            if not busy[0]:
                ready_input()
        elif code == "KeyL":
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            textread = opensav(textfile).splitlines()
            textread = filter(None, [x.lstrip("# ") for x in textread])
            echo(f"Reading {textfile} . . .", 0, 1)
            d = input(f"Enter domain name starting with, enter nothing to cancel: ").lower()
            echo("", 1)
            if not d:
                ready_input()
                continue
            textread = [x for x in textread if saint(url=x, scheme=False).lower().startswith(d)]
            for line in textread:
                line = line.replace(d, f"{tcolor.g}{d}{tcolor.o}", 1)
                echo(f" > {tcolor.b}{line}{tcolor.x}", 0, 1)
            urls = textread
            while True:
                i = input(f"Enter url containing, (C)ontinue or enter nothing to cancel: ").lower()
                if i.lower() == "c":
                    if urls:
                        echo("", 1, 1)
                        task["run"].put((2, urls))
                    else:
                        echo("Canceled", 1, 2)
                        ready_input()
                    break
                elif i:
                    urls = [x for x in textread if i in saint(url=x, scheme=False).lower()]
                    echo(f"{len(urls)} result(s)", 1, 1)
                    for line in urls:
                        line = line.replace(d, f"{tcolor}{d}{tcolor.o}", 1).replace(i, f"{tcolor.g}{i}{tcolor.o}", 1)
                        echo(f" > {tcolor.b}{line}{tcolor.x}", 0, 1)
                else:
                    echo("Canceled", 1, 2)
                    ready_input()
                    break
        elif code == "KeyM":
            if busy[0]:
                pressed(code)
                continue
            echo("", 1)
            torrent_get()
            echo("", 1)
            ready_input()
        elif code == "KeyN":
            if busy[1]:
                echo("", 1)
                Keypress_buffer[0] = input(Keypress_err[0])
                ticking[2].set()
            else:
                echo("", 1)
                echo("Number cleared", 0, 1)
                Keypress_buffer[0] = True
            if not busy[0]:
                ready_input()
        elif code == "KeyO":
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            finish_sort()
            ready_input()
        elif code == "KeyP":
            echo("Unpaused", 1, 2)
            pressed(code)
            Keypress["KeyX"] = True
        elif code == "SlowP":
            echo("Paused (press P twice in fast sequence to unpause)", 1, 2)
            pressed(code, False)
        elif code == "KeyQ":
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            task["run"].put((3, True))
        elif code == "KeyR":
            pressed(code)
        elif code == "KeyS":
            pressed(code)
        elif code == "KeyT":
            if navigator["timeout"]:
                echo(f"""COOLDOWN {"DISABLED" if Keypress["KeyT"] else "ENABLED"}""", 1, 2)
            else:
                echo(f"""Timer not enabled, please add "#-# seconds rarity 100% 00:00" in {rulefile}, add another timer to manipulate rarity.""", 1, 2)
            pressed(code, False if Keypress["KeyT"] else True)
        elif code == "KeyU":
            unrecognized(code)
        elif code == "KeyV":
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            source_view()
            ready_input()
        elif code == "KeyW":
            unrecognized(code)
        elif code == "KeyX":
            echo(f"""SET ALL ERROR DOWNLOAD REQUESTS TO: {"SKIP" if Keypress["KeyX"] else "RETRY"}""", 1, 2)
            pressed(code, False if Keypress["KeyX"] else True)
            Keypress["KeyP"] = True
        elif code == "KeyY":
            if sys.platform == "linux":
                # Developer note: Update to use htop if iSH app adds support to use it.
                os.system("top")
            else:
                if os.path.exists("ntop.exe"):
                    os.system("ntop.exe")
                else:
                    subdir = batchdir.replace("/", "\\")
                    echo(f"Save ntop.exe from https://github.com/gsass1/NTop/releases to {subdir} and then try again.", 0, 1)
            if not busy[0]:
                ready_input()
        elif code == "KeyZ":
            pressed(code)
        elif code[-1].isdigit():
            dlslot[0] = int(code[-1])
            echo(f"""MAX PARALLEL DOWNLOAD SLOT: {dlslot[0]} {"(pause)" if not dlslot[0] else ""}""", 1, 1)
            if not busy[0]:
                ready_input()
        else:
            echo("", 1)
            pressed("KeyZ")



Thread(target=keylistener, daemon=True).start()
print(f"""
 Key listener:
  > Press X to enable or disable indefinite retry on error downloading files (for this session).
  > Press S to skip next error once during downloading files.
  > Press T to enable or disable cooldown during errors (reduce server strain).
  > Press K to view cookies.
  > Press 1 to 8 to set max parallel download of 8 available slots, 0 to pause.
  > Press Z or CtrlC to break and reconnect of the ongoing downloads or to end timer instantly.

 Key listener (main menu):
  > Press I, L, A to enter (I)nput or (L)oad select/(A)ll list from {textfile}.
  > Press O to s(O)rt files.
  > Press M, E to open torrent (M)anager or h(E)lp document.""")



echo(mainmenu(), 0, 1)
ready_input()
while True:
    i, m = task["run"].get()
    busy[0] = True
    if sys.platform == "linux" and not task["httpserver"] and not task["transmission"]:
        os.system("cat /dev/location > /dev/null &")
    if i == 0:
        scrape([["", m, [0]]])
    elif i == 1:
        x = new_part()
        x["partition"]["0"]["files"] = [new_link(m, parse.unquote(m.split("/")[-1]), 0)]
        downloadtodisk(x, "Autosave declared completion.")
    elif i == 2:
        read_file(m)
    elif i == 3:
        downloadtodisk(False, "Key listener test")
    busy[0] = False
    if sys.platform == "linux" and not task["httpserver"] and not task["transmission"]:
        os.system("killall -9 cat")
    echo("", 0, 1)
    ready_input()
