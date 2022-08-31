@echo off && goto loaded

import os, sys, io, ssl, socket, time, json, zlib, inspect, smtplib, hashlib, subprocess, mimetypes
from datetime import datetime, timedelta
from fnmatch import fnmatch
from http import cookiejar
from http.server import BaseHTTPRequestHandler
from queue import Queue
from socketserver import ThreadingMixIn, TCPServer
from threading import Thread
from urllib import parse, request
from urllib.error import HTTPError, URLError
from random import random

batchfile = os.path.basename(__file__)
batchname = os.path.splitext(batchfile)[0]
batchdir = os.path.dirname(os.path.realpath(__file__)).replace("\\", "/")
filelist = []
savefiles = [[]]
delfiles = [[]]
pythondir = ""
thumbnail_dir = ""

if len(sys.argv) > 3:
    filelist = list(filter(None, sys.argv[1].replace("\\", "/").split("//")))
    pythondir = sys.argv[2].replace("\\\\", "\\").replace("\\", "/")
    # batchdir = sys.argv[3].replace("\\\\", "\\").replace("\\", "/") # grabs "start in" argument
if "/" in batchdir and not batchdir.endswith("/"):
    batchdir += "/"
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
imagefile = [".gif", ".jpe", ".jpeg", ".jpg", ".png"]
videofile = [".mkv", ".mp4", ".webm"]
specialfile = ["mediocre.txt", "autosave.txt", "gallery.html", "keywords.json", "partition.json", ".URL"] # icon.png and icon #.png are handled in different way

alerted = [False]
busy = [False]
dlslot = [8]
echothreadn = []
error = [[]]*4
echoname = [batchfile]
newfilen = [0]
run_input = [False]*4
Keypress_prompt = [False]
Keypress_time = [time.time()]
Keypress = [False]*27
torrent_menu = [False]
retries = [0]
sf = [0]

# Probably useless settings
collisionisreal = False
editisreal = False
buildthumbnail = False
shuddup = True
showpreview = False
verifyondisk = False



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



def title(echo):
    sys.stdout.write("\033]0;" + echo + "\007")
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
    os.system("")
if sys.platform == "linux":
    dlslot[0] = 1
    os.system("cat /dev/location > /dev/null &")
title(batchfile)



def mainmenu():
    return f"""
 - - - - {batchname} HTML - - - -
 + Press J to stop / restart HTTP server.
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
    sys.stdout.write(f"Ready input: ")
    sys.stdout.flush()
def skull():
    return """                                    
              ______                
           .-"      "-.             
          /            \\            
         |'  .-.  .-.  '|           
    /\   | )(__/  \__)( |           
  _ \/   |/     /\     \|           
 \_\/    (_ \   ^^   / _)   .-==/~\\ 
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
 |  "send X Y"        send data (X) to url (Y) or to current page url (no Y) before accessing page.
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
 |  "html ...*..."    pick article from page/partition for HTML builder.
 |    API: pick content for HTML-based pickers.
 |    HTML-based file and name pickers will look through for inline files and clean up articles.
 |    html# for insert mode: newline (html1), inline non-inline files from filelist (+2, unimplemented), hyperlink (+4).
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
 |  "... > ..."       API-based picker.
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

def columns():
    return os.get_terminal_size().columns

def echo(t, b=0, f=0, clamp='', friction=False):
    c = columns()
    if not isinstance(t, int):
        if clamp:
            t = f"{t[:c-1]}{(t[c-1:] and clamp)}"
        stdout[0] = ""
        stdout[1] = ""
        sys.stdout.write("\033[A"*b + f"{t:<{c}}" + "\n"*f + "\r")
    elif not echothreadn or t == echothreadn[0]:
        if clamp:
            b = f"{b[:c-1]}{(b[c-1:] and clamp)}"
        if friction:
            stdout[0] = f"{b:<{c}}\r"
        else:
            stdout[0] = ""
            stdout[1] = ""
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
        echo(f"{tcolorr}{threadn}{tcolorx}", 0, 1)
    elif r:
        echo(f"""
 {e}
 Please update or remove {r} from {rulefile} then restart CLI.""", 0, 1)
    else:
        echo(f"""{tcolorr}Thread {threadn} was killed {"by" if "(" in e else "because"} {e}{tcolorx}""", 0, 1)
    sys.exit()



def tcolorz(c):
    if not len(c) == 6:
        kill("Bad color code")
    return f"\033[40;38;2;{int(c[:2],16)};{int(c[2:4],16)};{int(c[4:6],16)}m"



def whereami(e="echoed", b=0, f=1, kill=False, pause=False):
    dep = []
    for x in inspect.stack()[1:3]:
        c = inspect.getframeinfo(x[0])
        dep = [f"line {c.lineno} in {c.function}()"] + dep
    echo(f"""{" > ".join(dep)}: {tcolorr if kill else tcolorz("CCCCCC")}{e}{tcolorx}""", b, f)
    if kill:
        while True:
            input("")
    elif pause:
        input("(C)ontinue?", "c")
        echo("", 1)



def echo_pip():
    if sys.platform == "win32":
        return f"{sys.exec_prefix}\Scripts\pip.exe"
    elif sys.platform == "darwin":
        return "sudo python3 -m pip"
    elif sys.platform == "linux":
        return "pip3"



lostfocus = [False]
def choice(keys="", bg=[]):
    if sys.platform == "win32":
        if bg:
            lostfocus[0] = True
            if bg == True:
                bg = ["%stopcolor%", "%color%"]
            for b in bg:
                os.system(f"color {b}")
            echo(tcolorx)
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
case $el in
""" + "\n".join([f"{k} ) exit {e+1};;" for e, k in enumerate(keys)]) + """
esac
done""")
            if el >= 256:
                el /= 256
            el = int(el)
            sys.stdout.write(f"{keys[el-1].upper()}\n")
            sys.stdout.flush()
    if not keys:
        return
    if el == 0:
        echo("", 0, 1)
    if el < 0 or el > 100:
        whereami(f"Obscene return code {el}", kill=True)
    return el



def input(i="Your Input: ", choices=False):
    sys.stdout.write(str(i))
    sys.stdout.flush()
    if choices:
        keys = ""
        for c in choices:
            keys += c[0].lower()
        while True:
            el = choice(keys)
            if (c := choices[el-1])[1:]:
                echo("", 1, 0)
                nter = input("Type and enter to confirm, else to return: " + c + f"\033[{len(c)-1}D")
                echo("", 1, 0)
                sys.stdout.write(str(i))
                sys.stdout.flush()
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
4-8 seconds rarity 75%
# 12-24 seconds rarity 23%
# 64-128 seconds rarity 2%
"""



sys.stdout.write(tcolorx + cls)

if not os.path.exists(rulefile):
    open(rulefile, 'w').close()
if os.path.getsize(rulefile) < 1:
    rules = new_rules().splitlines()
else:
    with open(rulefile, 'r', encoding="utf-8") as f:
        rules = f.read().splitlines()

new_setting = False
pos = 0
settings = ["Launch HTML server = ", "Browser = ", "Mail = ", "Geistauge = No", "Python = " + pythondir, f"UTC offset = {datetime.now().astimezone().strftime('%z')[:-2]}", "Proxy = socks5://"]
for setting in settings:
    if not rules[pos].replace(" ", "").startswith(setting.replace(" ", "").split("=")[0]):
        if pos == 0:
            setting += "Yes" if input("Launch HTML server? (Y)es/(N)o: ", "yn") == 1 else "No"
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
    # return f"""[{newfilen[0]} new{f" after {retries[0]} retries" if retries[0] else ""}] {echoname[0]}"""
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
    if echofriction[0] < int(s*eps):
        echofriction[0] = int(s*eps)
        stdout[1] = "\n\033]0;" + f"""{status()} {''.join(Barray[0][:len(echothreadn) if threadn else 1])} {MBs[0]} MB/s""" + "\007\033[A"
    else:
        echofriction[0] = int(s*eps)
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



class RangeHTTPRequestHandler(BaseHTTPRequestHandler):
    def __init__(self, *args, directory=None):
        self.directory = os.fspath(directory)
        super().__init__(*args)

    def do_GET(self):
        if '?' in self.path:
            self.path = self.path.split('?')[0]
        f = self.send_head()
        if f:
            try:
                self.copyfile(f, self.wfile)
            finally:
                f.close()

    def do_POST(self):
        Bytes = int(self.headers['Content-Length'])
        dir = batchdir.rstrip("/") + saint(self.path).replace("\\", "/").rsplit("/", 1)[0] + "/"
        if Bytes < 2000:
            data = self.rfile.read(Bytes).decode('utf-8')
            self.send_response(200, size=Bytes)
            self.send_header('Content-type', 'text/plain; charset=utf-8')
            self.end_headers()
            api = {"kind":"","ondisk":"","body":""}
            try:
                api.update(json.loads(data))
            except:
                pass
            ondisk = saint(api["ondisk"]).replace("\\", "/")
            if api["kind"] == "Save":
                echo(f"Save {dir}{ondisk}", 0, 1)
                savefiles[0] += [f"{dir}{ondisk}"]
                self.wfile.write(bytes(f"Save list updated", 'utf-8'))
            elif api["kind"] == "Schande!":
                echo(f"Schande! {dir}{ondisk}", 0, 1)
                delfiles[0] += [f"{dir}{ondisk}"]
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
            self.send_header('Content-type', 'text/plain; charset=utf-8')
            self.end_headers()
            echo(f"Large POST data: {Bytes} in length exceeding 2000 allowance", 0, 1)
            self.wfile.write(bytes(f"Large POST data sent", 'utf-8'))

    def list_directory(self, ondisk, ntime=False):
        try:
            list = os.listdir(ondisk)
        except OSError:
            self.send_error(404, "No permission to list directory")
            return None
        list.sort(key=lambda a: a.lower())

        parent = parse.unquote(self.path)
        if parent == "/":
            title = "Top directory"
        else:
            title = parent.replace(">", "&gt;").replace("<", "&lt;").replace("&", "&amp;").replace("/", "\\")
        enc = sys.getfilesystemencoding()

        dirs = []
        files = []
        for name in list:
            fullname = os.path.join(ondisk, name)
            displayname = name.replace(">", "&gt;").replace("<", "&lt;").replace("&", "&amp;")
            link = parse.quote(name)
            ut = f" {os.path.getmtime(fullname)}" if ntime else ""
            if os.path.isdir(fullname):
                displayname = "\\" + displayname + "\\"
                dirs.append(f' &gt; <a href="{link}/">{displayname}</a>{ut}')
            elif os.path.isfile(fullname):
                files.append(f' &gt;  <a href="{link}">{displayname}</a>{ut}')
        buffer = '\n'.join(dirs + files)

        style = """html,body{white-space:pre; background-color:#10100c; color:#088; font-family:courier; font-size:14px;}
a{color:#cb7; text-decoration:none;}
a:visited{color:#efdfa8;}
h2 {margin:4px;}"""
        htmldata = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8"/>
<meta name="format-detection" content="telephone=no">
<title>{title}</title>
<style>{style}</style>
</head>
<body><h2>{title}</h2>{buffer}</body>
</html>""".encode(enc, 'surrogateescape')
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
        self.range = (0, 0)
        self.total = 0
        ondisk = http2ondisk(self.path, self.directory)
        if os.path.isdir(ondisk):
            return self.list_directory(ondisk)

        if ondisk.endswith("/"):
            self.send_error(404, "File not found")
            return None
        try:
            f = open(ondisk, 'rb')
        except OSError:
            self.send_error(404, "File not found")
            return None
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
            self.send_header('Last-Modified', self.date_time_string(fs.st_mtime))
            self.end_headers()
            return f
        except:
            echo("DISCONNECTED", 0, 1)

    def send_response(self, code, message=None, size=0, dead=False):
        buffer = '' if dead else f' {size} bytes'
        ondisk = http2ondisk(self.path, self.directory).replace("/", "\\")
        if not ondisk.rsplit("\\", 1)[-1] in ["favicon.ico", "apple-touch-icon-precomposed.png", "apple-touch-icon.png"]:
            echo(f"{(datetime.utcnow() + timedelta(hours=int(offset))).strftime('%Y-%m-%d %H:%M:%S')} [{self.command} {code}] {tcolorg}{self.address_string()} {tcolorr}<- {tcolorr if dead else tcolorb}{ondisk}{tcolorx}{buffer}", 0, 1)
        self.send_response_only(code, message)
        self.send_header('Server', batchname)
        self.send_header('Date', self.date_time_string())

    def send_error(self, code, message=None):
        body = "<html><title>404</title><style>html,body{white-space:pre; background-color:#0c0c0c; color:#fff; font-family:courier; font-size:14px;}</style><body> .          .      .      . .          .       <p>      .              .         .             <p>         .     🦦 -( 404 )       .  <p>   .      .           .       .       . <p>     .         .           .       .     </body></html>"
        size = str(len(body))
        try:
            self.send_response(code, message, size, True)
            self.send_header('Connection', 'close')
            self.send_header("Content-Type", "text/html;charset=utf-8")
            self.send_header('Content-Length', size)
            self.end_headers()
            self.wfile.write(bytes(body, 'utf-8'))
        except:
            echo("DISCONNECTED", 0, 1)

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
            echo("DONE", 0, 1)
        except:
            echo("DISCONNECTED", 0, 1)
        echothreadn.remove(-thread)



class httpserver(TCPServer, ThreadingMixIn):
    allow_reuse_address = True
def startserver(port, directory):
    d = directory.rsplit("/", 2)[1]
    d = f"\\{d}\\" if d else f"""DRIVE {directory.replace("/", "")}\\"""
    print(f""" HTML SERVER: Serving {d} at port {port}""")
    def inj(self, *args):
        return RangeHTTPRequestHandler.__init__(self, *args, directory=self.directory)
    s = httpserver(("", port), type(f'RangeHTTPRequestHandler<{directory}>', (RangeHTTPRequestHandler,), {'__init__': inj, 'directory': directory}))
    servers[0].append(s)
    s.serve_forever()
    echo(f" HTTP SERVER: Stopped serving {d} freeing port {port}", 0, 1)

try:
    import certifi
    context = ssl.create_default_context(cafile=certifi.where())
except:
    context = None
# context = ssl.create_default_context(purpose=ssl.Purpose.SERVER_AUTH)
servers = [[]]
def stopserver():
    for s in servers[0]:
        s.shutdown()
    servers[0] = []
def restartserver():
    port = 8885
    directories = [batchdir]
    for directory in directories:
        port += 1
        t = Thread(target=startserver, args=(port,directory,))
        t.daemon = True
        t.start()
def portkilled(port=8886):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(1)
    r = s.connect_ex(("localhost", port))
    s.close()
    if servers[0] and r:
        echo(f" HTTP SERVER: Port {port} is dead, Jim.", 0, 1)
        stopserver()
    return True if r else False



cookies = cookiejar.MozillaCookieJar(batchname + "/cookies.txt")
if os.path.exists(batchname + "/cookies.txt"):
    cookies.load()
def new_cookie():
    return {'port_specified':False, 'domain_specified':False, 'domain_initial_dot':False, 'path_specified':True, 'version':0, 'port':None, 'path':'/', 'secure':False, 'expires':None, 'comment':None, 'comment_url':None, 'rest':{"HttpOnly": None}, 'rfc2109':False, 'discard':True, 'domain':None, 'name':None, 'value':None}



def ast(rule, key="0", key1="0"):
    return rule.replace("*date", fdate).replace("*id", key).replace("*title", key1).replace("/", "\\")

def saint(name=False, url=False):
    if url:
        url = list(parse.urlsplit(url))
        url[2] = parse.quote(url[2], safe="%/")
        return parse.urlunsplit(url)
    else:
        return "".join(i for i in parse.unquote(name).replace("/", "\\") if i not in "\":*?<>|")[:200]



def met(p, n):
    if n[0] and p.endswith(n[0]) or n[1] and not p.endswith(n[1]) or n[2] and p.startswith(n[2]) or n[3] and not p.startswith(n[3]) or n[4] and not n[4][0] <= len(p) <= n[4][1]:
        return
    return True

def conditions(x):
    n = [""]*5
    if len(x := x.rsplit(" not ends with ", 1)) == 2:
        n[0] = x[1]
    x = x[0]
    if len(x := x.rsplit(" ends with ", 1)) == 2:
        n[1] = x[1]
    x = x[0]
    if len(x := x.rsplit(" not starts with ", 1)) == 2:
        n[2] = x[1]
    x = x[0]
    if len(x := x.rsplit(" starts with ", 1)) == 2:
        n[3] = x[1]
    x = x[0]
    if len(y := x.rsplit(" letters", 1)) == 2:
        y = y[0].rsplit(" ", 1)
        if len(z := y[1].split("-", 1)) == 2:
            if z[0].isdigit() and z[1].isdigit():
                n[4] = [int(z[0]), int(z[1])]
                x = y[0]
        else:
            if z[0].isdigit():
                n[4] = [int(z[0]), int(z[0])]
                x = y[0]
    return [x, n]

def peanut(z, cw, a):
    if len(z := z.rsplit(" customize with ", 1)) == 2:
        cw = z[1].rsplit("*", 1)
        if not len(cw) == 2:
            cw += [""]
    z = z[0]
    if " > " in z or a:
        if z.startswith("0"):
            z = " > 0" + z.split("0", 1)[1]
        if " > 0" in z:
            z = z.rsplit(" > 0", 1)
            z = [z[0] + ' > 0'] + conditions(z[1])
        else:
            z = [''] + conditions(z)
        a = True
    return [z, cw, a]

def at(s, r, cw=[], alt=0, key=False, name=False, meta=False):
    n, r = r.split(" ", 1) if " " in r else [r, ""]
    n = int(n) if n else 0
    if key:
        if len(d := r.split(" << ", 1)) == 2:
            r = [peanut(d[0], [], True)[0]] + peanut(d[1], [], False)
        else:
            r = [[0, 0]] + peanut(r, [], False)
    else:
        r = peanut(r, cw, False)
    if not s:
        s += [[]]
    if n:
        s += [[] for _ in range(n-len(s)+1)]
    s[n] += [r] if s[n] else [{"alt":alt}, r]
    if name and r[0] and not r[2]:
        file_pos[0] = "file_after"
    if name or meta:
        if len(s) > total_names[0]:
            total_names[0] = len(s)

def y(y, yn=False):
    y = y.split("=", 1)[1].strip()
    if yn:
        if os.path.exists(y):
            return y
        return True if y.lower()[0] == "y" else False
    else:
        return y

offset = y(rules[5])
date = datetime.utcnow() + timedelta(hours=int(offset))
fdate = date.strftime('%Y') + "-" + date.strftime('%m') + "-XX"



def new_picker():
    return {"replace":[], "send":[], "defuse":False, "visit":False, "part":[], "dict":[], "html":[], "icon":[], "links":[], "inlinefirst":True, "expect":[], "dismiss":False, "pattern":[[], [], False, False], "message":[], "key":[], "folder":[], "choose":[], "file":[], "file_after":[], "files":False, "name":[], "extfix":"", "urlfix":[], "url":[], "pages":[], "paginate":[], "checkpoint":False, "savelink":False, "ready":False}



file_pos = ["file"]
def picker(s, rule):
    if rule.startswith("send "):
        rule = rule.split(" ", 2)
        s["send"] += [[rule[1], rule[2]] if len(rule) == 2 else [rule[1], []]]
    elif rule.startswith("defuse"):
        s["defuse"] = True
    elif rule.startswith("visit"):
        s["visit"] = True
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
    elif rule.startswith("message "):
        s["message"] += [rule.split("message ", 1)[1]]
    elif rule.startswith("choose "):
        c = rule.split("choose ", 1)[1].rsplit(" = ", 1)
        c[0] = peanut(c[0], [], False)[0][1]
        c[1] = c[1].split(" > ")
        s["choose"] += [c]
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
        s["paginate"][n] += [[x[0].split(" "), z]] if s["paginate"][n] else [{"alt":0}, [x[0].split(" "), z]]
    elif rule.startswith("checkpoint"):
        s["checkpoint"] = True
    elif rule.startswith("ready"):
        s["ready"] = True
    elif rule.startswith("savelink"):
        s["savelink"] = "savelink" if rule == "savelink" else rule.split("savelink ", 1)[1]
    else:
        return
    return True



# Loading referer, sort, and custom dir rules, pickers, and inline file rejection by file types from rulefile
bgcolor = False
fgcolor = "3"
customdir = {}
sorter = {}
md5er = []
referers = {}
hydras = {}
mozilla = {}
exempt = []
dir = ""
ticks = []
site = "inline"
pickers = {site:new_picker()}
total_names = [0]
for rule in rules:
    if not rule or rule.startswith("#"):
        continue



    rr = rule.split(" for ")
    if len(rr) == 2 and rr[0].startswith("md5"):
        md5er += [rr[1]]
    elif len(rr) == 2 and rr[0].startswith("Mozilla/5.0"):
        mozilla.update({rr[1]: rr[0]})
    elif len(rr) == 2 and rr[1].startswith("http"):
        if rr[0].startswith("http"):
            referers.update({rr[1]: rr[0]})
        elif len(r := ast(rr[0]).split("*")) == 2:
            customdir.update({rr[1]: r})
        elif len(r := rr[0].split(" ")) == 2:
            hydras.update({rr[1]: r})
        else:
            kill("\n There is at least one of the bad custom dir rules (no asterisk or too many).")
    elif len(rr) == 2 and rr[1].startswith('.') or len(rr) == 2 and rr[1].startswith('www.'):
        c = new_cookie()
        c.update({'domain': rr[1], 'name': rr[0].split(" ")[0], 'value': rr[0].split(" ")[1]})
        cookies.set_cookie(cookiejar.Cookie(**c))
        if not shuddup == 2: shuddup = False



    elif len(sr := rule.split(" seconds rarity ")) == 2:
        ticks += [[int(x) for x in sr[0].split("-")]]*int(sr[1].split("%")[0])
    elif rule == "collisionisreal":
        collisionisreal = True
    elif rule == "editisreal":
        editisreal = True
    elif rule == "buildthumbnail":
        buildthumbnail = True
    elif rule == "showpreview":
        showpreview = True
    elif rule == "verifyondisk":
        verifyondisk = True
    elif rule == "theyfuckedup":
        ssl._create_default_https_context = ssl._create_unverified_context
    elif rule == "shuddup":
        shuddup = 2
    elif rule.startswith('bgcolor '):
        bgcolor = rule.replace("bgcolor ", "")
    elif rule.startswith('fgcolor '):
        fgcolor = rule.replace("fgcolor ", "")
    elif rule.startswith('!'):
        pickers[site]["pattern"][1 if rule.startswith("!!") else 0] += [rule.lstrip("!")]
    elif rule.startswith('.'):
        pickers[site]["pattern"][1] += [rule]
    elif rule.startswith("\\"):
        dir = rule.split("\\", 1)[1]
        if dir.endswith("\\"):
            if dir in sorter:
                print(f"{tcoloro} SORTER: \\{dir} must be announced only once.{tcolorx}")
            sorter.update({dir: [False]})
        else:
            dir = dir.rsplit("\\", 1)
            dir[0] += "\\"
            if dir[0] in sorter:
                print(f"{tcoloro} SORTER: \\{dir[0]} must be announced only once.{tcolorx}")
            sorter.update({dir[0]: [False, dir[1]]})
    elif rule.startswith("!\\"):
        dir = rule.split("!\\", 1)[1]
        if dir.endswith("\\"):
            if dir in sorter:
                print(f"{tcoloro} SORTER: \\{dir} must be announced only once.{tcolorx}")
            sorter.update({dir: [True]})
        else:
            dir = dir.rsplit("\\", 1)
            dir[0] += "\\"
            if dir[0] in sorter:
                print(f"{tcoloro} SORTER: \\{dir[0]} must be announced only once.{tcolorx}")
            sorter.update({dir[0]: [True, dir[1]]})
    elif rule.startswith("http"):
        for n in range(total_names[0]):
            if not pickers[site]["name"][n]:
                kill(f"\n One of the name pickers for sequential name assemblement was skipped.")
        total_names[0] = 0
        site = rule
        if not site in pickers:
            pickers.update({site:new_picker()})
        file_pos[0] = "file"
    elif picker(pickers[site], rule):
        pass
    elif dir:
        sorter[dir] += [rule]
    else:
        exempt += [rule]

for n in range(total_names[0]):
    if not pickers[site]["name"][n]:
        kill(f"\n One of the name pickers for sequential name assemblement was skipped.")

if bgcolor:
    tcolorx = ansi_color(bgcolor, fgcolor)
    sys.stdout.write(tcolorx + cls)



HTMLserver = y(rules[0], True)
Browser = y(rules[1])
Mail = y(rules[2])
Geistauge = y(rules[3], True)
proxy = y(rules[6])
if HTMLserver:
    restartserver()
else:
    print(" HTML SERVER: OFF")
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
        print(" MAIL: Please add your two email addresses (sender/receiver)\n\n TRY AGAIN!")
        sys.exit()
    if len(Mail) < 3:
        import getpass
        Mail += [getpass.getpass(prompt=f" {Mail[0]}'s password (automatic if saved as third address): ")]
        echo("", 1)
    if not shuddup == 2:
        shuddup = False
else:
    print(" MAIL: NONE")
if Geistauge:
    try:
        import numpy, cv2
        from PIL import Image
        Image.MAX_IMAGE_PIXELS = 400000000
        print(" GEISTAUGE: ON")
    except:
        kill(f" GEISTAUGE: Additional prerequisites required - please execute in another command prompt with:\n\n{echo_pip()} install pillow\n{echo_pip()} install numpy\n{echo_pip()} install opencv-python")
elif verifyondisk:
    kill(f""" GEISTAUGE: I must be enabled for "verifyondisk" declared in {rulefile}.""")
elif buildthumbnail:
    kill(f""" GEISTAUGE: I must be enabled for "buildthumbnail" declared in {rulefile}.""")
else:
    print(" GEISTAUGE: OFF")
if "socks5://" in proxy and proxy[10:]:
    if not ":" in proxy[10:]:
        kill(" PROXY: Invalid socks5:// address, it must be socks5://X.X.X.X:port OR socks5://user:pass@X.X.X.X:port\n\n TRY AGAIN!")
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



if not shuddup:
    choice(bg=["4c", "%color%"])
    buffer = f"\n{tcolorr} TO YOURSELF: {rulefile} contains personal information like mail, password, cookies. Edit {rulefile} before sharing!"
    if HTMLserver:
        buffer += f"\n{tcoloro}{skull()} HTML SERVER: Anyone accessing your server can open {rulefile} reading personal information like mail, password, cookies"
    echo(f"""{buffer}\n{tcoloro} Add "shuddup" to {rulefile} to dismiss this message.{tcolorx}""", 0, 1)



tn = [len(ticks)]
ticking = [False]
def timer(e="", ind=True, listen=[True], notlisten=[False]):
    if not ticks:
        ticks.append([4, 8])
        tn[0] = len(ticks)
        echo(f"""\n"#-# seconds rarity 100%" in {rulefile} to customize timer, add another timer to manipulate rarity.\n""", 1, 1)
        return
    if not ticking[0]:
        ticking[0] = True
        r = ticks[int(tn[0]*random())]
        s = r[0]+int((r[1]-r[0]+1)*random())
        for sec in range(s):
            echo(f"{e} {s-sec} . . .")
            time.sleep(1)
            if pgtime[0] < int(time.time()/5):
                pgtime[0] = int(time.time()/5)
                pg[0] = 0
                title(monitor())
            if Keypress[26]:
                Keypress[26] = False
                break
            if not any(not x for x in listen) or any(notlisten):
                break
        ticking[0] = False
    elif ind:
        while ticking[0]:
            time.sleep(0.5)



Keypress_err = ["Some error happened. (R)etry (A)lways (S)kip once (X)auto defuse antibot with (F)irefox: "]
def retry(stderr):
    # Warning: urllib has slight memory leak
    Keypress[18] = False
    while True:
        if not Keypress_prompt[0]:
            Keypress_prompt[0] = True
            if stderr:
                if Keypress[1]:
                    e = f"{retries[0]} retries (P)ause (S)kip once"
                    if Keypress[20]:
                        timer(f"{e}, reloading in", listen=[Keypress[1]], notlisten=[Keypress[19]])
                    else:
                        echo(e)
                    Keypress[18] = True if Keypress[1] else False
                if not Keypress[18]:
                    title(monitor())
                    Keypress_err[0] = f"{stderr} (R)etry (A)lways (S)kip once (X)auto defuse antibot with (F)irefox: "
                    sys.stdout.write(Keypress_err[0])
                    sys.stdout.flush()
                    while True:
                        if Keypress[18] or Keypress[1]:
                            break
                        if Keypress[19]:
                            Keypress[19] = False
                            Keypress_prompt[0] = False
                            return
                        if Keypress[6]:
                            Keypress[6] = False
                            return 2
                        time.sleep(0.1)
            else:
                echo(f"{retries[0]} retries (S)kip one, wait it out, or press X to quit trying . . . ")
            time.sleep(0.1)
            retries[0] += 1
            title(monitor())
            Keypress_prompt[0] = False
            return True
        elif Keypress[18]:
            time.sleep(0.1) # so I don't return too soon to turn off another Keypress[18] used to turn off Keypress_prompt.
            return True
        time.sleep(0.1)



def fetch(url, stderr="", dl=0, threadn=0, data=None):
    referer = x[0] if (x := [v for k, v in referers.items() if url.startswith(k)]) else ""
    ua = x[0] if (x := [v for k, v in mozilla.items() if url.startswith(k)]) else 'Mozilla/5.0'
    headers = {x[0][0]:x[0][1]} if (x := [v for k, v in hydras.items() if url.startswith(k)]) else {}
    headers.update({'User-Agent':ua, 'Referer':referer, 'Origin':referer})
    while True:
        try:
            headers.update({'Range':f'bytes={dl}-', 'Accept':"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"})
            resp = request.urlopen(request.Request(saint(url=url), headers=headers, data=data))
            break
        except HTTPError as e:
            if stderr or Keypress[24] and not Keypress[19]:
                el = retry(f"{stderr} ({e.code} {e.reason})")
                if el == 2:
                    driver(saint(url=url))
                    Keypress_prompt[0] = False
                    Keypress[18] = True
                elif not el:
                    return 0, str(e.code)
            else:
                Keypress[19] = False
                return 0, str(e.code)
        except URLError as e:
            if "CERTIFICATE_VERIFY_FAILED" in str(e.reason):
                echo("", 0, 1)
                if context:
                    kill(f""" {e.reason}\n\n They fucked up deploying their certificates (probably).\n Add "theyfuckedup" to {rulefile} to bypass this kind of error if you're willing to take risks.""")
                else:
                    kill(f""" {e.reason}\n\n Either they fucked up deploying their certificates or this Python is just having shitty certificate validator.\n Try execute optional prerequisites in another command prompt with:\n\n{echo_pip()} install certifi""")
            if stderr or Keypress[24] and not Keypress[19]:
                if not retry(f"{stderr} ({e.reason})"):
                    return 0, e.reason
            else:
                Keypress[19] = False
                return 0, e.reason
        except:
            if stderr or Keypress[24] and not Keypress[19]:
                el = retry(f"{stderr} (closed by host)")
                if el == 2:
                    echo(" BROWSER: Maybe not.", 0, 1)
                    Keypress_prompt[0] = False
                    Keypress[18] = True
                elif not el:
                    return 0, "closed by host"
            else:
                Keypress[19] = False
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
    Keypress[26] = False
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
                if Keypress[26]:
                    resp, err = fetch(url, stderr, dl, threadn)
                    if not resp:
                        return 0, err
                    if resp.status == 200 and dl > 0:
                        kill(threadn, "server doesn't allow resuming download. Delete the .part file to start again.")
                    Keypress[26] = False
        echo(f"{threadn:>3} Download completed: {url}", 0, 1)
        os.rename(todisk + ".part", todisk)
        if Keypress_prompt[0]:
            sys.stdout.write(Keypress_err[0])
            sys.stdout.flush()
        stdout[0] = ""
        stdout[1] = ""
        return 1, 0
    else:
        data = b''
        while True:
            try:
                block = resp.read(262144)
                if not block:
                    if not total or dl == total:
                        stdout[0] = ""
                        stdout[1] = ""
                        if utf8:
                            try:
                                return data.decode("utf-8"), 0
                            except:
                                try:
                                    return zlib.decompress(data, 16+zlib.MAX_WBITS).decode("utf-8"), 0
                                except:
                                    todisk = saint(parse.unquote(url.split("/")[-1]))
                                    sys.stdout.write(f" Not an UTF-8 file! Save on disk as {todisk} to open it in another program? (S)ave (D)iscard: ")
                                    sys.stdout.flush()
                                    if choice("sd") == 1:
                                        with open(todisk, 'wb') as f:
                                            f.write(data);
                                        echo(f"{threadn:>3} Download completed: {url}", 0, 1)
                                    if Keypress_prompt[0]:
                                        sys.stdout.write(Keypress_err[0])
                                        sys.stdout.flush()
                                    return 1, 0
                        else:
                            return data, 0
                    if not retry(stderr):
                        return 0, err
                    resp, err = fetch(url, stderr, dl, threadn)
                    if not resp:
                        return 0, err
                    if resp.status == 200:
                        data = b''
                        dl = 0
                    continue
            except KeyboardInterrupt:
                resp, err = fetch(url, stderr, dl, threadn)
                if not resp:
                    return 0, err
                if resp.status == 200:
                    data = b''
                    dl = 0
                continue
            except:
                if not retry(stderr):
                    return 0, err
                resp, err = fetch(url, stderr, dl, threadn)
                if not resp:
                    return 0, err
                if resp.status == 200:
                    data = b''
                    dl = 0
                continue
            data += block
            Bytes = len(block)
            dl += Bytes
            echoMBs(threadn, Bytes, int(dl/total*256) if total else 0)
            echo(threadn, f"{int(dl/1048576)} MB", friction=True)
            if Keypress[26]:
                resp, err = fetch(url, stderr, dl, threadn)
                if not resp:
                    return 0, err
                if resp.status == 200:
                    data = b''
                    dl = 0
                Keypress[26] = False



def echolinks(download):
    while True:
        threadn, todisk, onserver, sleep = download.get()
        conflict = [[], []]
        for n in range(len(onserver)):
            if n and not collisionisreal:
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
        download.task_done()
download = Queue()
for i in range(8):
    t = Thread(target=echolinks, args=(download,))
    t.daemon = True
    t.start()



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
    inline = pickers["inline"]["pattern"]
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
    if rejected and showpreview:
        if rejected in filename.lower():
            print(f"{tcolor}{origin:>18}: {dir}{filename.lower().replace(rejected, tcolorr + rejected + tcolor)}{tcolorx}")
        else:
            print(f"{tcolor}  Not in whitelist: {dir}{tcolorb}{filename}{tcolorx}")
    return rejected



def get_cd(subdir, file, pattern, makedirs=False, preview=False):
    link = file["link"]
    todisk = batchname + "/" + file["name"].replace("\\", "/")
    if rule := [v for k, v in customdir.items() if k in link]:
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
        elif not preview and not os.path.exists(dir):
            if makedirs or [ast(x) for x in exempt if ast(x) == dir.replace("/", "\\")]:
                try:
                    os.makedirs(dir)
                except:
                    buffer = "\\" + dir.replace("/", "\\")
                    kill(f"Can't make folder {buffer} because there's a file using that name, I must exit!")
            else:
                error[1] += [todisk]
                error[2] += [f"&gt; Error downloading (dir): {link}"]
                print(f" Error downloading (dir): {link}")
                link = ""
    elif not preview:
        dir = subdir + x[0] + "/" if len(x := todisk.rsplit("/", 1)) == 2 else subdir
        if isrej(todisk, pattern):
            link = ""
        elif not os.path.exists(batchname + "/"):
            try:
                os.makedirs(batchname + "/")
            except:
                buffer = "\\" + dir.replace("/", "\\")
                kill(f"Can't make folder {buffer} because there's a file using that name, I must exit!")
    if not preview:
        if makedirs and not os.path.exists(dir):
            try:
                os.makedirs(dir)
            except:
                buffer = "\\" + dir.replace("/", "\\")
                kill(f"Can't make folder {buffer} because there's a file using that name, I must exit!")
        file.update({"name":todisk, "edited":file["edited"]})
    return [link, todisk, file["edited"]]



def downloadtodisk(fromhtml, oncomplete, makedirs=False):
    if not fromhtml:
        threadn = 0
        while True:
            threadn += 1
            echothreadn.append(threadn)
            download.put((threadn, "Key listener test", ["Key listener test"], random()*0.5))
            if threadn == 200:
                break
        try:
            download.join()
        except KeyboardInterrupt:
            pass
        return
    error[0] = []
    error[1] = []
    error[2] = []
    htmlname = fromhtml["name"]
    htmlpart = fromhtml["partition"]
    pattern = fromhtml["pattern"]
    subdir = ""
    queued = {}
    lastfilen = newfilen[0]



    # Partition and rebuild HTML
    filelist = [[], []]
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
            if os.path.exists(p := f"{subdir}{thumbnail_dir}partition.json"):
                with open(p, 'r') as f:
                    p = json.loads(f.read())
            else:
                p = {}
            if (part := frompart(f"{subdir}{thumbnail_dir}partition.json", p, htmlpart, pattern)):
                new_relics = {}
                for key in part.keys():
                    part[key].update({"visible": False if part[key]["keywords"] and isrej(part[key]["keywords"][0], pattern) else True})
                    new_relics.update({key: part[key]})
                parttohtml(subdir, htmlname, new_relics, filelist, pattern)
        else:
            echo("Filelist is empty!", 0, 1)
        return
    if len(filelist) == 1:
        echothreadn.append(0)
        download.put((0, filelist[0][1], [filelist[0][0]], 0))
        try:
            download.join()
        except KeyboardInterrupt:
            pass
        return



    # Autosave (1/3)
    dirs = set()
    htmldirs = {}
    for onserver, ondisk, edited, key in filelist:



        # Autosave (2/3) and load partition.json
        dir = ondisk.rsplit("/", 1)[0] + "/"
        if not dir in dirs and not dirs.add(dir):
            if os.path.exists(p := f"{dir}{thumbnail_dir}partition.json"):
                with open(p, 'r') as f:
                    htmldirs.update({dir:json.loads(f.read())})
            else:
                htmldirs.update({dir:{}})
        if dir in htmldirs and key in htmldirs[dir] and not pattern[3]:
            if len(htmldirs[dir][key]["keywords"]) < 2:
                continue
            k = htmldirs[dir][key]["keywords"][1]
            if not edited == "0" and not edited == k:
                if os.path.exists(ondisk):
                    if editisreal:
                        old = ".old_file_" + k
                        os.rename(ondisk, ren(ondisk, old))
                        thumbnail = ren(ondisk, '_small')
                        if os.path.exists(thumbnail):
                            os.rename(thumbnail, ren(thumbnail, old))
                    else:
                        print(f"  Edited on server: {ondisk}")
                        continue
            else:
                continue

        if not onserver:
            continue
        if conflict := [k for k in queued.keys() if ondisk.lower() == k.lower()]:
            ondisk = conflict[0]
        queued.update({ondisk: [onserver] + (queued[ondisk] if queued.get(ondisk) else [])})



    for dir in htmldirs.keys():
        for icon in fromhtml["icons"]:
            if not os.path.exists(dir + thumbnail_dir + icon["name"]):
                if err := get(icon["link"], dir + thumbnail_dir + icon["name"])[1]:
                    echo(f""" Error downloading ({err}): {icon["link"]}""", 0, 1)

        if page := fromhtml["page"]:
            file = dir + page["name"] + ".URL"
            if not os.path.exists(file):
                with open(file, 'w') as f:
                    f.write(f"""[InternetShortcut]
URL={page["link"]}""")
                buffer = file.replace("/", "\\")
                echo(f" File created: \\{buffer}", 0, 1)

        if not os.path.exists(dir + thumbnail_dir):
            os.makedirs(dir + thumbnail_dir)



        if (part := frompart(f"{dir}{thumbnail_dir}partition.json", htmldirs[dir], htmlpart, pattern)) or verifyondisk:
            new_relics = {}
            for key in part.keys():
                part[key].update({"visible": False if part[key]["keywords"] and isrej(part[key]["keywords"][0], pattern) else True})
                new_relics.update({key: part[key]})
            parttohtml(dir, htmlname, new_relics, filelist, pattern)



    threadn = 0
    for ondisk, onserver in queued.items():
        threadn += 1
        echothreadn.append(threadn)
        download.put((threadn, ondisk, onserver, 0))
    try:
        download.join()
    except KeyboardInterrupt:
        pass



    # Autosave (3/3), build thumbnails and errorHTML
    if buildthumbnail:
        echo("Building thumbnails . . .")
        for dir in htmldirs.keys():
            for file in next(os.walk(dir))[2]:
                thumbnail = f"{dir}{thumbnail_dir}{ren(file, '_small')}"
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
            Keypress[3] = False
            while not Keypress[3]:
                time.sleep(0.1)
            Keypress[3] = False
    if os.path.isfile(batchdir + "chromedriver.exe"):
        if not os.path.exists(batchdir + "chromedriver"):
            os.makedirs(batchdir + "chromedriver")
        # import undetected_chromedriver as uc
        # return uc.Chrome()
        options = webdriver.ChromeOptions()
        options.arguments.extend([f'user-data-dir={batchdir}chromedriver', f"user-agent={mozilla['http']}", '--disable-blink-features=AutomationControlled', "--no-default-browser-check", "--no-first-run"])
        driver = webdriver.Chrome(options=options)
        driver.execute_cdp_cmd(
            "Page.addScriptToEvaluateOnNewDocument",
            {
                "source": """
                    let objectToInspect = window,
                        result = [];
                    while(objectToInspect !== null) 
                    { result = result.concat(Object.getOwnPropertyNames(objectToInspect));
                      objectToInspect = Object.getPrototypeOf(objectToInspect); }
                    result.forEach(p => p.match(/.+_.+_(Array|Promise|Symbol)/ig)
                                        &&delete window[p])
                    """
            },
        )
        return driver
    elif os.path.isfile(batchdir + "geckodriver.exe"):
        if not os.path.exists(batchdir + "geckodriver"):
            os.makedirs(batchdir + "geckodriver")
        options = webdriver.FirefoxOptions()
        options.arguments.extend(['--profile', batchdir + "geckodriver"])
        options.set_preference('general.useragent.override', mozilla['http'])
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
    if not driver_running[0].execute_script('return navigator.userAgent') == mozilla['http']:
        echo(f" BROWSER: My user-agent didn't match to an user-agent spoofer.", 0, 1)
    # ff_login(url)
    echo("(C)ontinue when finished defusing.")
    Keypress[3] = False
    while not Keypress[3]:
        time.sleep(0.1)
    Keypress[3] = False
    try:
        for bc in driver_running[0].get_cookies():
            if "httpOnly" in bc: del bc["httpOnly"]
            if "expiry" in bc: del bc["expiry"]
            if "sameSite" in bc: del bc["sameSite"]
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



def carrot(array, z, cw, new, my_conditions, saint):
    a = ""
    aa = ""
    p = ""
    update_array = [array[0], array[1]]
    ii = False
    cc = False
    carrot_saver = []
    if not "*" in z:
        if z in update_array[0]:
            if met(update_array[0], my_conditions):
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
            if met(update_array[0], my_conditions):
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
            if met(y[1], my_conditions):
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
            if not met(p, my_conditions):
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



def carrots(arrays, x, cw=[], any=True, saint=False):
    update_array = []
    x, my_conditions = conditions(x)
    new = []
    for array in arrays:
        while True:
            update_array = carrot(array, x, cw, new, my_conditions, saint)
            if not update_array:
                break
            array = update_array[1]
            if not any:
                break
        new += [array]
    arrays = new
    return arrays



def linear(d, z, r):
    dt = []
    for x in z:
        dc = d
        if not x[0]:
            if r:
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
            elif x[4]:
                kill(0, x[4])
            else:
                return
        if not dc:
            return
        # dc = str(dc)
        if x[5]:
            dc = x[5].join(s.strip() for s in dc.replace("\\", "/").split("/"))
        if x[1] and not any(c for c in x[1] if c == dc) or x[2] and not met(dc, x[2]):
            if x[4]:
                kill(0, x[4])
            else:
                return
        if x[3]:
            dt += [dc.join(x[3])]
        else:
            dt += [dc]
    return dt



def branch(d, z, r):
    ds = []
    t = type(d).__name__
    for x in z[0][0].split(" > "):
        x = x.split(" >> ")
        if not x[0]:
            if len(z[0]) >= 2:
                if t == "list":
                    for x in d:
                        ds += branch(x, [z[0][1:]] + z[1:], r)
                elif t == "dict":
                    for x in d.values():
                        ds += branch(x, [z[0][1:]] + z[1:], r)
                return ds
            else:
                break
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
    if len(z[0]) == 1:
        if not t == "list" and not t == "dict":
            return ds
        if z[0][0]:
            dx = []
            if t == "list":
                for dc in d:
                    if dt := linear(dc, z[1], r):
                        if len(z) > 2:
                            dx += [dt + b for b in branch(dc, [z[2].split(" > 0")] + z[3:], r)]
                        else:
                            dx += [dt]
            elif t == "dict":
                for x in d.values():
                    if dt := linear(x, z[1], r):
                        dx += [dt]
            return dx
        else:
            if dt := linear(d, z[1], r):
                if len(z) > 2:
                    return [dt + b for b in branch(d, [z[2].split(" > 0")] + z[3:], r)]
                else:
                    return [dt]
    else:
        if t == "list":
            for x in d:
                ds += branch(x, [z[0][1:]] + z[1:], r)
        elif t == "dict":
            for x in d.values():
                ds += branch(x, [z[0][1:]] + z[1:], r)
    return ds

def tree(d, z, r=False):
    # tree(dictionary, [branching keys, [[linear keys, choose, conditions, customize with, stderr and kill, replace slashes], [linear keys, 0 accept any, 0 no conditions, 0 no customization, 0 continue without, 0 no slash replacement]]])
    for x in z[1::2]:
        if not x[0][0]:
            print(f"{tcoloro} Last key > 0 is view only. You must establish a next key for use in picker rules.{tcolorx}")
    z[0] = [x.split(" > ", 1)[1] if x.startswith(" > ") else x for x in z[0].split(" > 0")]
    return branch(d, z, r)



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
            new_name = ""
            for x in pick["name"]:
                new_name_err = True
                for z, cw, a in x[1:]:
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
            if e := pick["extfix"]:
                if len(ext := carrots([[url, ""]], e, [".", ""], False)) == 2 and not new_name.endswith(ext := ext[-2][1]):
                    new_name += ext
            if file_after:
                url = array[1]
            update_html[-1][1] = new_link(url, folder + parse.unquote(new_name), htmlpart[key]["keywords"][1] if key in htmlpart and len(htmlpart[key]["keywords"]) > 1 else 0)
            if not file_after:
                update_html += [[update_array[0], '']]
        elif not file_after:
            update_html += [[array[0], '']]
        url = array[1]
    return update_html, new_name_err



def tree_files(db, k, f, cw, pick, htmlpart, folder, filelist, pos):
    master_key = ["", [["0"]]]
    file = f[0]
    if not k:
        key = [["0"]]
    else:
        key = [[k[1][1], 0, 0, 0, 0, 0]]
        if k[0][0]:
            if len(z := k[1][0].split(k[0][0] if k[0][0].startswith("0") else k[0][0] + " > 0", 1)) == 2:
                file = z[1]
                master_key = [k[0][0], [[k[0][1], 0, 0, 0, 0, 0]]]
        elif k[0][1]:
            master_key = ["", [[k[0][1], 0, 0, 0, 0, 0]]]



    if pick["choose"]:
        c = pick["choose"][pos-1]
    else:
        c = ["", []]
    meta = []
    linear_name = []
    off_branch_name = []
    stderr = "there's no name asset found in dictionary for this file."
    for z in pick["name"]:
        if not z[0]["alt"]:
            meta += [[]]
            for m, cwf, a in z[1:]:
                if off_branch_name:
                    cwf = ["".join(off_branch_name) + cwf[0], cwf[1]]
                meta[-1] += [[m, cwf]]
            off_branch_name = []
            linear_name += [[1]]
            continue
        z, cwf, a = z[pos]
        if not z:
            continue
        if f[0] == z[0]:
            if off_branch_name:
                cwf = [cwf[0] + "".join(off_branch_name), cwf[1]]
                off_branch_name = []
            linear_name += [[z[1], 0, 0, cwf, stderr, 0]]
        else:
            x = tree(db, [z[0], [[z[1], 0, 0, cwf, stderr, 0]]])
            off_branch_name += [x[0][0]] if x else []
    files = tree(db, master_key + [file, key + [[c[0], c[1], 0, 0, 0, 0], [f[1], 0, f[2], cw, 0, 0]] + linear_name])
    if c[1]:
        cf = []
        for cc in c[1]:
            if [cx := x[:2] + x[3:] for x in files if x[2] == cc]:
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
                if len(c := carrots([[file[2], ""]], y, cwf, False)) == 2 and c[-2][1]:
                    fp += [c[-2][1]]
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
        for z, cw, a in y[1:]:
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
                    tree_files(db, k, z, cw, pick, htmlpart, folder, filelist, pos)
            elif not db:
                for p in part:
                    key = "0"
                    for k in keys[1:]:
                        if not k:
                            continue
                        if len(d := carrots([p], k[1], [], False)) == 2:
                            key = d[0][1]
                            break
                    html, name_err = carrot_files(carrots([p], z, cw, pick["files"]), htmlpart, key, pick, "" if y[0]["alt"] else page, folder, file_after)
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
            x = "".join(y[0] + y[1] for y in carrots([[x, ""]], r[0], r[1].split("*", 1)))
        else:
            x = x.replace(r[0], r[1])
    return x



def get_data(threadn, page, url, pick):
    data = ""
    if not pick["ready"]:
        echo(f""" {"into" if url else "Visiting"} {page}""", 0, 1)
    if pick["defuse"]:
        driver(page)
    if pick["visit"]:
        fetch(page, stderr="Error visiting the page to visit")
    if pick["send"]:
        for x in pick["send"]:
            post = x[1] if x[1] else url
            data, err = fetch(post, stderr="Error sending data", data=str(x[0]).encode('utf-8'))
            if err:
                print(f" Error visiting ({err}): {page}")
                return 0, 0
        data = data.read()
    if not data:
        data, err = get(url if url else page, utf8=True, stderr="Update cookie or referer if these are required to view", threadn=threadn)
        if err:
            print(f" Error visiting ({err}): {url if url else page}")
            return 0, 0
        elif len(data) < 4:
            return 0, 0
    title(monitor())
    data = ''.join([x.strip() for x in data.splitlines()])
    if pick["part"]:
        part = []
        for z in pick["part"]:
            part += [[x[1], ""] for x in carrots([[data, ""]], z)]
    else:
        part = [[data, ""]]
    for p in part:
        p[0] = rp(p[0], pick["replace"])
    return data, part



def pick_in_page(scraper):
    while True:
        data = 0
        url = 0
        threadn, pick, start, page, pagen, more_pages, alerted_pages, fromhtml = scraper.get()
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
                    if len(c := carrots([[page, ""]], y[1], [], False)) == 2:
                        page = y[0] + c[-2][1] + y[2]
                        redir = True
                else:
                    page = page.replace(y[1], y[0])
                    redir = True
            if redir and not pick["ready"]:
                echo(f" Updated url with a permanent redirection from {url}", 0, 1)
        if x := pick["url"]:
            url = page
            for y in x:
                if "*" in y[1]:
                    if len(c := carrots([[url, ""]], y[1], [], False)) == 2:
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
                for z, cw, a in y[1:]:
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
                            c = z[1].rsplit(" = ", 1)
                            found = tree(db, [z[0], [[c[0], c[1].split(" > ") if len(c) == 2 else 0, 0, 0, 0, 0, 0]]])
                            if y[0]["alt"] and found or not y[0]["alt"] and not found:
                                break
                        else:
                            found = True if [x[1] for x in carrots(part, z, [], False)][0] else False
                            if y[0]["alt"] and found or not y[0]["alt"] and not found:
                                break
                if y[0]["alt"] and found or not y[0]["alt"] and not found:
                    found_all += [True]
                else:
                    found_all += [False]
                    break
            if all(found_all):
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
                more_pages += [[start, page, pagen]]
                timer(f"{alerted[0]}, resuming unalerted pages in" if alerted[0] else "Not quite as expected! Reloading in", listen=[Keypress[3], Keypress[19]] if alerted[0] else [False])
        if any(pick[x] for x in ["folder", "pages", "html", "icon", "dict", "file", "file_after"]) and not data:
            data, part = get_data(threadn, page, url, pick)
            if not data:
                proceed = False
        if proceed and pick["dict"]:
            for y in pick["dict"]:
                if len(c := carrots(part, y)) == 2:
                    data = c[0][1]
        if proceed and not folder:
            if proceed and pick["folder"]:
                for y in pick["folder"]:
                    name_err = True
                    for z, cw, a in y[1:]:
                        if a:
                            if not db:
                                db = opendb(data)
                            for d in tree(db, [z[0], [[z[1], 0, 0, 0, 0, " ꍯ "]]]):
                                folder += d[0]
                                name_err = False
                        elif y[0]["alt"]:
                            if x := [x[1] for x in carrots([[data, ""]], z, cw, False, " ꍯ ") if x[1]]:
                                folder += x[0]
                                name_err = False
                                break
                        else:
                            if len(x := carrots([[page, ""]], z, cw, False, " ꍯ ")) == 2:
                                folder += x[0][1]
                                name_err = False
                                break
                    if name_err:
                        kill(0, "there's no suitable name asset for folder creation. Check folder pickers and try again.")
                if name_err:
                    break
                fromhtml["folder"] = folder
                echo("", 0, 1)
                echo(f"Folder assets assembled! From now on the downloaded files will go to this directory: {tcolorg}\\{folder}{tcolorx}*\nAdditional folders are made by custom dir rules in {rulefile}.", 0, 2)
            elif proceed and (x := pick["savelink"]):
                fromhtml["page"] = new_link(page, x, 0)
        if proceed and pick["pages"]:
            for y in pick["pages"]:
                for z, cw, a in y[1:]:
                    if a:
                        if not db:
                            db = opendb(data)
                        pages = tree(db, [z[0], [[z[1], 0, 0, cw, 0, 0]]])
                        if pages and not pages[0][0] == "None":
                            for p in pages:
                                if not p[0] == page and not page + p[0] == page:
                                    px = p[0] if y[0]["alt"] else page.rsplit("/", 1)[0] + "/" + p[0]
                                    more_pages += [[start, px, pagen]]
                                    if pick["checkpoint"]:
                                        print(f"Checkpoint: {px}\n")
                    else:
                        for p in [x[1] for x in carrots([[data, ""]], z, cw) if x[1]]:
                            if not p == page and not page + p == page:
                                px = p if y[0]["alt"] else page.rsplit("/", 1)[0] + "/" + p
                                more_pages += [[start, px, pagen]]
                                if pick["checkpoint"]:
                                    print(f"Checkpoint: {px}\n")
        if proceed and pick["paginate"]:
            for y in pick["paginate"]:
                new = page
                for z in y[1:]:
                    l = carrots([[new, ""]], z[0][0])[0][1] if len(z[0]) > 1 else ""
                    l_fix = z[1][0]
                    x = carrots([[new, ""]], z[0][1 if len(z[0]) > 1 else 0])[0][1]
                    if (p := z[1][1]).isdigit() or p[1:].isdigit():
                        if not x.isdigit():
                            kill(f""" String captured: {x}
 Calculate with (+): {p}

Paginate picker is broken, captured string must be digit for calculator +/- mode!""")
                        x = int(x) + int(p)
                    elif z[1][1]:
                        p, _, a = peanut(z[1][1], [], False)
                        if a:
                            if not data:
                                data, part = get_data(threadn, page, url, pick)
                                if not data:
                                    break
                            if not db:
                                db = opendb(data)
                            x = tree(db, [p[0], [[p[1], 0, 0, 0, 0, 0]]])[-1][0]
                    r_fix = z[1][2]
                    r = carrots([[new, ""]], z[0][2])[0][1] if len(z[0]) == 3 else ""
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
                for z, cw, a in y[1:]:
                    if a:
                        if not db:
                            db = opendb(data)
                        for p_k in part_keys[1:]:
                            master_key = ["", [["0"]]]
                            z0 =  z[0]
                            if not p_k:
                                key = [["0"]]
                            else:
                                if z0 == p_k[1][0]:
                                    key = [[p_k[1][1], 0, 0, 0, 0, 0]]
                                else:
                                    continue
                                if p_k[0][0]:
                                    if len(x := p_k[1][0].split(p_k[0][0], 1)) == 2:
                                        z0 = x[1]
                                        master_key = [p_k[0][0], [[p_k[0][1], 0, 0, 0, 0, 0]]]
                                elif p_k[0][1]:
                                    master_key = ["", [[p_k[0][1], 0, 0, 0, 0, 0]]]
                            for html in tree(db, master_key + [z0, key + [[z[1], 0, 0, cw, 0, 0]]]):
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
                                if len(d := carrots([[p[0], ""]], p_k[1], [], False)) == 2:
                                    key = d[0][1]
                                    break
                            c = carrots([[p[0], ""]], z, cw, False)
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
                        for z, cw, a in y[1:]:
                            if a:
                                continue
                            html = carrot_files(carrots(html, z, cw, pick["files"]), htmlpart, k, pick, "" if y[0]["alt"] else page, folder, file_after)[0]
                    file_after = True
                htmlpart[k]["html"] += html
            keywords = {}
            pos = 0
            for y in pick["key"][1:]:
                for z in y[1:]:
                    z, cw, a = z[1:]
                    if a:
                        if not db:
                            db = opendb(data)
                        for p_k in part_keys[1:]:
                            if not p_k:
                                key = [["0", 0, 0, 0, 0, 0]]
                            else:
                                if z[0] == p_k[1][0]:
                                    key = [[p_k[1][1], 0, 0, 0, 0, 0]]
                                else:
                                    continue
                            for d in tree(db, [z[0], [[z[1], 0, 0, 0, 0, 0]] + key]):
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
                                if len(d := carrots([[p[0], ""]], p_k[1], [], False)) == 2:
                                    key = d[0][1]
                                    break
                            if not key in keywords:
                                keywords.update({key: ["", ""]})
                            if pos < 2:
                                if not keywords[key][pos] and len(x := carrots([p], z, cw, False)) == 2:
                                    keywords[key][pos] = x[0][1]
                            else:
                                for x in carrots([p], z, cw)[:-1]:
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
                    for z, _, a in y[1:]:
                        if a:
                            if not db:
                                db = opendb(data)
                            url = tree(db, [z[0], [[z[1], 0, 0, 0, 0, 0]]])[0][0]
                            ext = ""
                            for x in imagefile:
                                if x in url:
                                    ext = x
                            fromhtml["icons"] += [new_link(url, f"""icon{" " + str(pos) if pos else ""}{ext}""", 0)]
                        else:
                            if len(c := carrots(part, z, [], False)) == 2:
                                url = c[0][1]
                                ext = ""
                                for x in imagefile:
                                    if x in url:
                                        ext = x
                                fromhtml["icons"] += [new_link(url, f"""icon{" " + str(pos) if pos else ""}{ext}""", 0)]
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
                        stdout += f"{tcolorb}{x[0]}{tcolorr} -> {tcolorg}\\{buffer}\n"
                    for h in htmlpart[k]["html"]:
                        if h[1]:
                            x = get_cd("", h[1], pattern, preview=True)
                            buffer = x[1].replace("/", "\\")
                            stdout += f"{tcolorb}{x[0]}{tcolorr} -> {tcolorg}\\{buffer}\n"
                if not x:
                    stdout += f"{tcolorr} No files found in this page (?) Check pattern, add more file pickers, using cookies can make a difference." + "\n"
                echo(stdout + tcolorx)
        if proceed and not pick["ready"]:
            fromhtml["ready"] = False
        echothreadn.remove(threadn)
        scraper.task_done()



scraper = Queue()
for i in range(8):
    t = Thread(target=pick_in_page, args=(scraper,))
    t.daemon = True
    t.start()



def new_p(z):
    return {z:{"html":[], "keywords":[], "files":[]}}

def new_part(threadn=0):
    new = {threadn:new_p("0")} if threadn else new_p("0")
    return {"ready":True, "page":"", "name":"", "folder":"", "makehtml":False, "pattern":[[], [], False, False], "icons":[], "inlinefirst":True, "partition":new}

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
        htmlname = fromhtml["name"]
        htmlpart = fromhtml["partition"]
        stdout = ""
        if fromhtml["makehtml"]:
            stdout += f"\n Then create " + tcolorg + fromhtml["folder"] + "gallery.html" + tcolorx + " with\n"
            if x := fromhtml["icons"]:
                stdout += f"""{tcolorg}█{"█ █".join([i["name"] for i in x])}█\n"""
            if x := fromhtml["page"]:
                stdout += f"""{tcoloro}<h2><a href="{x["link"]}">{x["name"]}</a></h2>\n"""
            for k in htmlpart.keys():
                if htmlpart[k]["keywords"] or htmlpart[k]["html"] or htmlpart[k]["files"]:
                    keywords = htmlpart[k]["keywords"]
                    title = keywords[0] if keywords and keywords[0] else f"ꍯ Part {k} ꍯ"
                    timestamp = keywords[1] if len(keywords) > 1 and keywords[1] else "No timestamp"
                    afterwords = ", ".join(kw for kw in keywords[2:]) if len(keywords) > 2 else "None"
                    stdout += f"{tcolorx}{k} :: {tcolor}{tcolorb}{title} [{tcolor}{timestamp}{tcolorr} Keywords: {afterwords}{tcolorb}]\n"
                    for file in htmlpart[k]["files"]:
                        stdout += tcolorg + file["name"].rsplit("\\")[-1] + "\n"
                    if html := htmlpart[k]["html"]:
                        for h in html:
                            if h[0]:
                                stdout += tcoloro + h[0]
                            if h[1]:
                                stdout += tcolorg + "█" + h[1]["name"].rsplit("\\")[-1] + "█"
                        stdout += "\n"
        echo(f"""{stdout}{tcolorx} ({tcolorb}Download file {tcolorr}-> {tcolorg}to disk{tcolorx}) - Add scraper instruction "ready" in {rulefile} to stop previews for this site (C)ontinue or return to (M)ain menu: """, 0, 1)
        Keypress[13] = False
        Keypress[3] = False
        while not Keypress[13] and not Keypress[3]:
            time.sleep(0.1)
        Keypress[3] = False
        if Keypress[13]:
            Keypress[13] = False
            return
    downloadtodisk(fromhtml, "Autosave declared completion.", makedirs=True)



pgs = [8]
def scrape(startpages):
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
            get_pick = [x for x in pickers.keys() if page.startswith(x)]
            if not get_pick:
                print(f"I don't have a scraper for {page}")
                break
            pick = pickers[get_pick[0]]
            if not start:
                start = page
                shelf.update({start: new_part(threadn)})
                fromhtml = shelf[start]
                fromhtml["pattern"] = pickers[get_pick[0]]["pattern"]
                fromhtml["inlinefirst"] = pick["inlinefirst"]
            else:
                fromhtml = shelf[start]
                fromhtml["partition"].update({threadn:new_p("0")})
            scraper.put((threadn, pick, start, page, pagen, more_pages, alerted_pages, fromhtml))
        try:
            scraper.join()
        except KeyboardInterrupt:
            pass # Ctrl + C
        pgs[0] = 8
        seen = set()
        more_pages = [x for x in more_pages if not x[1] in seen and not seen.add(x[1])]
        for _, page, _ in more_pages:
            if page in visited and not visited.add(page):
                print(f"{tcolorr}Already visited {page} loophole warning{tcolorx}")
                # more_pages.remove(page)
        if not more_pages and not alerted_pages:
            break
        pages = more_pages
        if alerted[0]:
            if not more_pages:
                echo(alerted[0])
                time.sleep(1)
            if Keypress[3]:
                Keypress[3] = False
                pages += alerted_pages
                alerted_pages = []
                alerted[0] = False
                choice(bg=["2e", "%color%"])
            elif Keypress[19]:
                Keypress[19] = False
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
    dctii = cv2.dct(numpy.float32(Image.open(file).convert("L").resize((64, 64), Image.ANTIALIAS)))[:12,:12]
    return format(int(''.join(str(b) for b in 1*(dctii > numpy.median(dctii)).flatten()), 2), 'x')



def phthread(ph_q):
    while True:
        threadn, total, file, filevs, accu = ph_q.get()
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
        ph_q.task_done()
ph_q = Queue()
for i in range(8):
    t = Thread(target=phthread, args=(ph_q,))
    t.daemon = True
    t.start()



def scanthread(filelist, filevs, savwrite):
    accu = []
    threadn = 0
    total = len(filelist)
    for file in filelist:
        threadn += 1
        ph_q.put((threadn, total, file, filevs, accu))
    ph_q.join()
    if accu:
        savwrite.write(bytes('\n'.join(accu) + "\n", 'utf-8'))
        savwrite.flush()
    print("100%")



def tosav(fp, filevs=""):
    fp = fp.replace("\\", "/")
    savread = opensav(sav)
    savwrite = open(sav, 'ab')
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
        print("\n - - - - " + subfolder + " - - - -")
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



def container(dir, ondisk, pattern=False):
    if ondisk.lower().endswith(tuple(videofile)):
        data = f"""<div class="frame"><video height="200" autoplay><source src="{ondisk.replace("#", "%23")}"></video><div class="sources">{ondisk}</div></div>\n"""
    elif ondisk.lower().endswith(tuple(imagefile)):
        if buildthumbnail:
            thumbnail = f"{subdir}{thumbnail_dir}" + ren(file.rsplit("/", 1), "_small")
        else:
            thumbnail = ondisk
        data = f"""<div class="frame"><a class="fileThumb" href="{ondisk.replace("#", "%23")}"><img class="lazy" data-src="{thumbnail.replace("#", "%23")}"></a><div class="sources">{ondisk}</div></div>\n"""
    else:
        data = f"""<a href=\"{ondisk.replace("#", "%23")}"><div class="aqua" style="height:174px; width:126px;">{ondisk}</div></a>\n"""
        if os.path.exists(dir + ondisk.rsplit(".", 1)[0] + "/"):
            data += f"""<a href="{ondisk.rsplit(".", 1)[0].replace("#", "%23")}"><div class="aqua" style="height:174px;"><i class="aqua" style="border-width:0 3px 3px 0; padding:3px; -webkit-transform: rotate(-45deg); margin-top:82px;"></i></div></a>\n"""
    return data



def container_c(ondisk, label):
    if HTMLserver:
        if os.path.exists(batchdir + ondisk.replace(batchdir, "")):
            ondisk = ondisk.replace(batchdir, "").replace("#", "%23").replace("\\", "/")
        else:
            return f"""<div class="frame"><div class="edits">Rebuild HTML with<br />{batchfile} in another<br />dir is required to view</div>{label}</div> """
    else:
        ondisk = "file:///" + ondisk.replace("#", "%23")
    return f"""<div class="frame"><a class="fileThumb" href="{ondisk}"><img class="lazy" data-src="{ondisk}"></a><br />{label}</div>
"""



def new_html(builder, htmlname, listurls, pattern=[], imgsize=200):
    if not listurls:
        listurls = "Maybe in another page."
    return """<!DOCTYPE html>
<html>
<meta charset="UTF-8"/>
<meta name="format-detection" content="telephone=no">
""" + f"<title>{htmlname}</title>" + """
<style>
html,body{background-color:#10100c; color:#088 /*088 cb7*/; font-family:consolas, courier; font-size:14px;}
a{color:#6cb /*efdfa8*/;}
a:visited{color:#bfe;}
.external{color:#db6;}
.external:visited{color:#ed9;}

img {vertical-align:top;}
h2 {margin:4px;}
button {padding:1px 4px;}
[contenteditable]:focus {outline: none;}

.aqua{background-color:#006666; color:#33ffff; border:1px solid #22cccc;}
.carbon, .files, .time{background-color:#10100c /*10100c 112230 07300f*/; border:3px solid #6a6a66 /*6a6a66 367 192*/; border-radius:12px;}
.time{white-space:pre-wrap; color:#ccc; font-size:90%; line-height:1.6;}
.cell, .mySlides{background-color:#1c1a19; border:none; border-radius:12px;}
.edits{background-color:#330717; border:3px solid #912; border-radius:12px; color:#f45; padding:12px; margin:6px; word-wrap:break-word;}
.previous{background-color:#f1f1f1; color:black; border:none; border-radius:10px; cursor:pointer;}
.next{background-color:#444; color:white; border:none; border-radius:10px; cursor:pointer;}
.nextword{margin-left:8px; display:inline-block; color:#6fe; background-color:#066; border:none; padding:0px 8px;}
.nextword::placeholder {color:#3cb;}
.dark{background-color:rgba(0, 0, 0, 0.5); color:#fff; border:none; border-radius:10px; cursor:pointer;}
.reverse{background-color:#63c; color:#d9f; border:none; border-radius:10px; cursor:pointer;}
.tangerine{background-color:#c60; color:#fc3; border:none; border-radius:10px; cursor:pointer;}
.edge{background-color:#261; color:#8c4; border:none; border-radius:10px; cursor:pointer;}

.sources{font-size:80%; width:200px;}
.container{display:block; position:relative;}
.frame{display:inline-block; vertical-align:top; position:relative;}
.aqua{display:inline-block; vertical-align:top; padding:12px; word-wrap:break-word;}
.carbon, .time, .files, .edits{display:inline-block; vertical-align:top;}
.carbon, .time, .cell, .mySlides, .files, .edits{padding:8px; margin:6px; word-wrap:break-word;}
.mySlides{white-space:pre-wrap; padding-right:32px;}
.close_button {position:absolute; top:15px; right:15px;}
.tooltip {display:none; position:relative; cursor:default; font-family:sans-serif; font-size:12px;}
.cursor_tooltip {padding:0px 8px; font-family:sans-serif; font-size:90%; z-index:9999999; left:0px; top:0px; right:initial; pointer-events:none;}
.carbon, .files, .edits{margin-right:12px;}
.cell{overflow:auto; width:calc(100% - 30px); display:inline-block; vertical-align:text-top;}
.postMessage{white-space:pre-wrap;}
.menu {color:#9b859d; background-color:#110c13;}
.exitmenu {color:#f45; background-color:#2d0710;}
.stdout {white-space:pre-wrap; color:#9b859d; background-color:#110c13; border:2px solid #221926; display:inline-block; padding:6px; min-height:0px;}
.schande{opacity:0.5; position:absolute; top:158px; text-align:center; line-height:34px; height:34px; cursor:pointer; min-width:40px; border:2px solid transparent; background-clip: padding-box; box-shadow:inset 0 0 0 2px #c44; padding:2px; background-color:#602; color:#f45; -webkit-user-select:none;}
.save{box-shadow:inset 0 0 0 2px #367; background-color:#142434; color:#2a9;}
.spinner {position:absolute; border-top:9px solid #6cc; height:6px; width:3px; top:162px; left:24px; pointer-events:none; animation-name:spin; animation-duration: 1000ms; animation-timing-function: linear;}
.left {position:absolute; border-bottom:2px solid #f66; border-left:2px solid #f66; height:5px; width:5px; transform:rotate(45deg); top:166px; left:86px; pointer-events:none;}
.right {position:absolute; border-bottom:2px solid #6cc; border-left:2px solid #6cc; height:5px; width:5px; transform:rotate(225deg); top:166px; left:21px; pointer-events:none;}
@keyframes spin {
  from {
    transform:rotate(0deg);
  }
  to {
    transform:rotate(360deg);
  }
}
</style>
<script>
var xhr = new XMLHttpRequest();
function send(b, e){
  xhr.open("POST", '', true);
  xhr.setRequestHeader('Content-Type', 'application/octet-stream');
  xhr.send(b);
  xhr.responseType = "arraybuffer";
  xhr.onreadystatechange = function() {
    if (xhr.readyState === 4) {
      let r = new TextDecoder().decode(xhr.response);
      if (r.length <= 100){
        e.target.setAttribute("data-tooltip", r);
      } else {
        e.target.setAttribute("data-tooltip", "Please connect to the HTML server");
      }
      FFmove(e);
    }
  }
}

function lazykeys() {
  lazykey = document.querySelectorAll(".time");
  var partObserver = new IntersectionObserver(function(parts, observer) {
    parts.forEach(function(e) {
      if (e.isIntersecting) {
        var t = e.target;
        var d = document.createElement("div");
        d.classList.add("nextword");
        d.addEventListener("click", edit_key);
        if(keywords[t.id]){
          d.innerHTML = keywords[t.id]
        } else {
          d.innerHTML = "+"
        }
        t.appendChild(d);
        partObserver.unobserve(t);
      }
    });
  });

  lazykey.forEach(function(e) {
    partObserver.observe(e);
  });
}

function loadkeys(){
  var isTainted = true
  xhr.overrideMimeType("application/json");
  xhr.open('GET', "keywords.json", true);
  xhr.setRequestHeader("Cache-Control", "no-cache, no-store, max-age=0")
  xhr.send();
  xhr.onreadystatechange = function() {
    if (xhr.readyState === 4) {
      if (xhr.status !== 404 && xhr.responseText) {
        keywords = JSON.parse(xhr.responseText);
        lazykeys();
      } else if (xhr.responseText){
        keywords = {}
        lazykeys();
      } else {
        local_tooltip.style.display = "inline-block";
        local_tooltip.innerHTML = "⚠";
        local_tooltip.setAttribute("data-tooltip", "Not loaded on HTML server: HTML server is used for custom keywords and interacting with Schande/Save buttons.");
      }
    }
    isTainted = false
  }
}

var key_busy = false;
function edit_key(e){
  function submit_key(){
    var body = {[t.parentNode.id]:i.value}
    var b = JSON.stringify({"kind":"keywords", "ondisk":"keywords.json", body})
    if (i.value){
      send(b, e);
      t.innerHTML = i.value;
    } else if (t.innerHTML !== "+"){
      send(b, e);
      t.innerHTML = "+"
    }
    t.parentNode.removeChild(i);
    i.removeEventListener("keyup", read_key);
    t.style.display = "inline-block";
  }

  function read_key(k) {
    if (k.keyCode === 13) {
      submit_key()
      key_busy = false;
    }
  }

  if (key_busy){
    if(e.target.hasAttribute("data-tooltip")){
      e.target.removeAttribute("data-tooltip")
      i.focus({preventScroll:true});
      i.scrollIntoView({block: "start", behavior: "smooth"});
    } else {
      e.target.setAttribute("data-tooltip", "Busy typing another keyword. Click here again to take you there.");
      FFmove(e);
      let left = () => {
        e.target.removeAttribute("data-tooltip")
        e.target.removeEventListener("mouseleave", left);
      }
      e.target.addEventListener("mouseleave", left);
    }
  } else {
    var t = e.target;
    key_busy = true;
    i = document.createElement("input");
    i.setAttribute("type", "text");
    i.classList.add("nextword");
    i.placeholder = "Add more keywords..."
    if (t.innerHTML !== "+"){
      i.value = t.innerHTML;
    }
    
    i.addEventListener("keydown", read_key);
    t.style.display = "none";
    t.parentNode.appendChild(i);
    i.focus();
  }
}

function plaintext(elem, e) {
  e.preventDefault();
  var text = e.clipboardData.getData('text/plain');
  window.document.execCommand('insertText', false, text);
}

function echo(B, b) {
  if (!b) B = "\\n" + B
  if (b) B = " " + B
  stdout.innerHTML += B;
}

var Expand = function(c, t) {
  if(!c.naturalWidth) {
    return setTimeout(Expand, 10, c, t);
  }
  c.style.maxWidth = "100%";
  c.style.display = "";
  t.style.display = "none";
  t.style.opacity = "";
};

var FFdown = function(e) {
  var t = e.target;
  var a = t.parentNode;
  if (t.hasAttribute("data-schande")) {
    var b = JSON.stringify({"kind":t.innerHTML, "ondisk":t.getAttribute("data-schande"), "body":""});
    var d = document.createElement("div");
    a.appendChild(d);
    t.addEventListener('touchmove', function(e) {e.preventDefault()});
    if (t.classList.contains("save")){
      d.classList.add("spinner");
      var timeoutID = setTimeout(function() {
        if (isTouch){
          d.classList.remove("spinner");
          d.classList.add("right");
          var X = e.pageX;
          var Y = e.pageY;
          t.addEventListener('touchend', function(z) {
            if (-20 < (Y - z.pageY) && (Y - z.pageY) < 20 && (z.pageX - X) > 50){
              d.classList.remove("right");
              send(b, e);
            }
          });
          t.addEventListener('mouseleave', function() {d.classList.remove("right")})
        } else {
          send(b, e)
        }
      }.bind(t.addEventListener('click', function() {
        clearTimeout(timeoutID);
        d.classList.remove("spinner");
      })).bind(t.addEventListener('mouseleave', function() {
        clearTimeout(timeoutID);
        d.classList.remove("spinner");
      })).bind(t.addEventListener('touchmove', function() {
        clearTimeout(timeoutID);
        d.classList.remove("spinner");
      })), 1000);
    } else {
      if (isTouch){
        d.classList.add("left");
        var X = e.pageX;
        var Y = e.pageY;
        t.addEventListener('touchend', function(z) {
          if (-20 < (Y - z.pageY) && (Y - z.pageY) < 20 && (X - z.pageX) > 50){
            d.classList.remove("left");
            send(b, e);
          }
        });
        t.addEventListener('mouseleave', function() {d.classList.remove("left")})
      } else {
        t.addEventListener('mouseup', function() {
          send(b, e)
        });
      }
    }
  }
}

var FFclick = function(e) {
  var t = e.target;
  var a = t.parentNode;
  if (a.classList != undefined && a.classList.contains("fileThumb")) {
    e.preventDefault();
    if(t.hasAttribute("data-src")) {
      var c = document.createElement("img");
      c.setAttribute("src", a.getAttribute("href"));
      c.style.display = "none";
      a.appendChild(c);
      t.style.opacity = "0.75";
      setTimeout(Expand, 10, c, t);
    } else {
      a.firstChild.style.display = "";
      a.removeChild(t);
      a.offsetTop < window.pageYOffset && a.scrollIntoView({block: "start", behavior: "smooth"});
    }
  }
};

var FFmove = function(e) {
  var t = e.target;
  if (t.hasAttribute("data-tooltip")) {
    tooltip.style.left = (e.pageX + 10) + "px";
    tooltip.style.top = (e.pageY + 10) + "px";
    tooltip.style.display = "inline-block";
    tooltip.innerHTML = t.getAttribute("data-tooltip");
  } else {
    tooltip.style.display = "none";
  }
}

var FFover = function(e) {
  var t = e.target;
  var a = t.parentNode;
  if(a.classList != undefined && a.classList.contains("fileThumb") && !a.parentNode.hasAttribute("busy")) {
    a = a.parentNode;
    var d = document.createElement("div");
    d.innerHTML = "<div class='schande save'>Save</div><div class='schande' style='left:48px;'>Schande!</div>";
    a.appendChild(d);
    let isover = function(g) {
      g.target.style.opacity = 1
      if (g.target.classList.contains("schande")) {
        g.target.setAttribute("data-schande", t.getAttribute("data-src"))
      }
      g.target.removeEventListener("mouseover", isover);
      let left = () => {
        g.target.style.opacity = 0.5
        g.target.removeEventListener("mouseleave", left);
      }
      g.target.addEventListener("mouseleave", left);
    }
    d.addEventListener("mouseover", isover);
    let left = () => {
      setTimeout(function(){
        a.removeChild(d);
      }, 1)
      a.removeAttribute("busy")
      a.removeEventListener("mouseleave", left);
    }
    a.setAttribute("busy", true)
    a.addEventListener("mouseleave", left);
  }
}

document.addEventListener("click", FFclick);
document.addEventListener("touchstart", FFdown);
document.addEventListener("mousedown", FFdown);
document.addEventListener("mousemove", FFmove);
document.addEventListener("mouseover", FFover);

Filters = {};
Filters.tmpCtx = document.createElement('canvas').getContext('2d');

Filters.createImageData = function (w,h) {
  return this.tmpCtx.createImageData(w,h);
};

function Convolute(pixels, weights) {
  var side = Math.round(Math.sqrt(weights.length));
  var halfSide = Math.floor(side/2);

  var src = pixels.data;
  var sw = pixels.width;
  var sh = pixels.height;

  var w = sw;
  var h = sh;
  var output = Filters.createImageData(w, h);
  var dst = output.data;

  for (var y=0; y<h; y++) {
    for (var x=0; x<w; x++) {
      var sy = y;
      var sx = x;
      var dstOff = (y*w+x)*4;
      var r=0, g=0, b=0, a=0;
      for (var cy=0; cy<side; cy++) {
        for (var cx=0; cx<side; cx++) {
          var scy = Math.min(sh-1, Math.max(0, sy + cy - halfSide));
          var scx = Math.min(sw-1, Math.max(0, sx + cx - halfSide));
          var srcOff = (scy*sw+scx)*4;
          var wt = weights[cy*side+cx];
          r += src[srcOff] * wt;
          g += src[srcOff+1] * wt;
          b += src[srcOff+2] * wt;
          a += src[srcOff+3] * wt;
        }
      }
      dst[dstOff] = r;
      dst[dstOff+1] = g;
      dst[dstOff+2] = b;
      dst[dstOff+3] = 255;
    }
  }
  return output;
};

function quicklook(e) {
  if(e.target.classList.contains("lazy")) {
    e.preventDefault();
    var t = e.target;
    var c = {};
    var isTainted = false;
    if(geistauge) {
      var s = new Image();
      s.src = t.parentNode.getAttribute("href");

      c = document.createElement("canvas");
      c.style = cs;
      c.setAttribute("id", "quicklook")
      c.width = s.width
      c.height = s.height
      context = c.getContext("2d")

      if (geistauge == "edge") {
        isTainted = true;
        s.onload = function () {
          edgediff(s, s.width, s.height, context);
          isTainted = false;
          t.removeAttribute("data-tooltip");
        }
      } else {
        let fp = new Image();
        let p = t.parentNode.parentNode.parentNode.childNodes[1].childNodes[0];
        if (p == undefined || p.nodeName != "A") {
          fp.src = s.src;
        } else {
          fp.src = p.getAttribute("href");
        }
        if(fp.src == s.src) {
          context.fillRect(0, 0, s.width, s.height);
        } else {
          isTainted = true;
          s.onload = function () {
            var cgl = document.createElement("canvas");
            gl = cgl.getContext("webgl2")
            if (geistauge == "reverse") {
              fp.onload = difference(fp, s.width, s.height, s, context, gl, side=true);
            } else if (geistauge == "tangerine") {
              fp.onload = difference(s, s.width, s.height, fp, context, gl, side=true);
            } else {
              fp.onload = difference(s, s.width, s.height, fp, context, gl);
            }
          isTainted = false;
          t.removeAttribute("data-tooltip");
          }
        }
      }
      setTimeout(function(){
        if (isTainted) {
          t.setAttribute("data-tooltip", `"Edge detect" and "Geistauge" are canvas features and they require Cross-Origin Resource Sharing (CORS)<br>(Google it but tl;dr: Try HTML server)`)
          FFmove(e)
        }
      }, 1)
      t.parentNode.appendChild(c);
    } else {
      c = document.createElement("img");
      c.style = cs;
      c.setAttribute("id", "quicklook")
      c.setAttribute("src", t.parentNode.getAttribute("href"));
      t.parentNode.appendChild(c);
    }
    let left = () => {
      setTimeout(function(){
        t.parentNode.removeChild(c);
      }, 40);
      t.removeEventListener("mouseleave", left);
      t.removeAttribute("data-tooltip");
    }
    t.addEventListener("mouseleave", left);
  }
}



function edgediff(s, cw, ch, context) {
  context.drawImage(s, 0, 0, cw, ch);
  var grayscale = context.getImageData(0, 0, cw, ch);
  var imageData1 = Convolute(grayscale, [-1, -1, -1, -1,  8, -1, -1, -1, -1])
  context.putImageData(imageData1, 0, 0);
}



function ghost(rgb) {
  for (var i = 0; i < rgb.length; i += 4) {
    if(rgb[i] == 0 && rgb[i+1] == 0 && rgb[i+2] == 0){
      rgb[i] = 0;
      rgb[i+1] = 0;
      rgb[i+2] = 0;
      rgb[i+3] = 255;
    } else if(rgb[i] > 12 || rgb[i+1] > 12 || rgb[i+2] > 12){
      rgb[i] = 255;
      rgb[i+1] = 255;
      rgb[i+2] = 255;
      rgb[i+3] = 255;
    } else if(rgb[i] > 10 || rgb[i+1] > 10 || rgb[i+2] > 10){
      rgb[i] = 208;
      rgb[i+1] = 192;
      rgb[i+2] = 240;
      rgb[i+3] = 255;
    } else if(rgb[i] > 8 || rgb[i+1] > 8 || rgb[i+2] > 8){
      rgb[i] = 176;
      rgb[i+1] = 128;
      rgb[i+2] = 224;
      rgb[i+3] = 255;
    } else if(rgb[i] > 6 || rgb[i+1] > 6 || rgb[i+2] > 6){
      rgb[i] = 144;
      rgb[i+1] = 64;
      rgb[i+2] = 192;
      rgb[i+3] = 255;
    } else if(rgb[i] > 4 || rgb[i+1] > 4 || rgb[i+2] > 4){
      rgb[i] = 112;
      rgb[i+1] = 32;
      rgb[i+2] = 160;
      rgb[i+3] = 255;
    } else if(rgb[i] > 2 || rgb[i+1] > 2 || rgb[i+2] > 2){
      rgb[i] = 64;
      rgb[i+1] = 16;
      rgb[i+2] = 128;
      rgb[i+3] = 255;
    } else if(rgb[i] > 0 || rgb[i+1] > 0 || rgb[i+2] > 0){
      rgb[i] = 32;
      rgb[i+1] = 8;
      rgb[i+2] = 96;
      rgb[i+3] = 255;
    };
  }
}

function diff(a, b) {
  for (var i = 0; i < b.length; i += 4) {
    if (a[i] == b[i] && a[i+1] == b[i+1] && a[i+2] == b[i+2]) {
      b[i+3] = 0
    }
  }
}

function darkside(a, b) {
  for (var i = 0; i < b.length; i += 4) {
    b[i] -= a[i];
    b[i+1] -= a[i+1];
    b[i+2] -= a[i+2];
  }
  ghost(b)
}

function darkdiff(a, b) {
  for (var i = 0; i < b.length; i += 4) {
    b[i] = Math.abs(b[i] - a[i]);
    b[i+1] = Math.abs(b[i+1] - a[i+1]);
    b[i+2] = Math.abs(b[i+2] - a[i+2]);
  }
  ghost(b)
}

var rgb, rgb2;

function difference(s, cw, ch, fp, context, gl, side=false) {
  context.drawImage(s, 0, 0, cw, ch);
  rgb = context.getImageData(0, 0, cw, ch);
  context.drawImage(fp, 0, 0, cw, ch);
  rgb2 = context.getImageData(0, 0, cw, ch);
  if(side){
    darkside(rgb.data, rgb2.data)
  } else {
    darkdiff(rgb.data, rgb2.data)
  }
  context.putImageData(rgb2, 0, 0);
}

var geistauge = false;
var co = "position:fixed; right:0; top:0; z-index:1; pointer-events:none;"
var cf = co + "max-height: 100vh; max-width: 100vw;";
var cs = co
var fit = false;
var slideIndex = 1;
function swap(e) {
  var t = e.target;
  let d = document.getElementById("ge");
  let a = d.getAttribute("data-sel").split(", ");
  if(e.which == 83 && !geistauge) {
    geistauge = true;
    d.classList = "previous";
    d.innerHTML = a[1];
    t.addEventListener("keyup", function(k) {
      if(k.which == 83) {
        d.classList = "next";
        d.innerHTML = a[0];
        geistauge = false;
      }
    });
  } else if(e.which == 65 && !geistauge) {
    geistauge = "reverse";
    d.classList = "reverse";
    d.innerHTML = a[2];
    t.addEventListener("keyup", function(k) {
      if(k.which == 65) {
        d.classList = "next";
        d.innerHTML = a[0];
        geistauge = false;
      }
    });
  } else if(e.which == 68 && !geistauge) {
    geistauge = "tangerine";
    d.classList = "tangerine";
    d.innerHTML = a[3];
    t.addEventListener("keyup", function(k) {
      if(k.which == 68) {
        d.classList = "next";
        d.innerHTML = a[0];
        geistauge = false;
      }
    });
  } else if(e.which == 87 && !geistauge) {
    geistauge = "edge";
    d.classList = "edge";
    d.innerHTML = a[4];
    t.addEventListener("keyup", function(k) {
      if(k.which == 87) {
        d.classList = "next";
        d.innerHTML = a[0];
        geistauge = false;
      }
    });
  } else if(e.which == 16 && !fit) {
    fit = true;
    cs = cf
    let tc = document.getElementById("quicklook")
    if(tc) {
      tc.style = cs;
    }
    let d = document.getElementById("fi");
    let a = d.getAttribute("data-sel").split(", ");
    d.classList = "previous";
    d.innerHTML = a[1];
    document.addEventListener("mouseover", quicklook);
    t.addEventListener("keyup", function(k) {
      if(k.which == 16) {
        d.classList = "tangerine";
        d.innerHTML = a[2];
        cs = co
        let tc = document.getElementById("quicklook")
        if(tc) {
          tc.style = cs;
        }
        fit = false;
      }
    });
  }
}

document.addEventListener("keydown", swap);

function previewg(e) {
  let a = e.getAttribute("data-sel").split(", ");
  if (e.classList.contains("next")) {
    e.classList = "previous";
    e.innerHTML = a[1];
    geistauge = true;
  } else if(e.classList.contains("previous")) {
    e.classList = "reverse";
    e.innerHTML = a[2];
    geistauge = "reverse";
  } else if(e.classList.contains("reverse")) {
    e.classList = "tangerine";
    e.innerHTML = a[3];
    geistauge = "tangerine";
  } else if(e.classList.contains("tangerine")) {
    e.classList = "edge";
    e.innerHTML = a[4];
    geistauge = "edge";
  } else {
    e.classList = "next";
    e.innerHTML = a[0];
    geistauge = false;
  }
}

function preview(e) {
  let a = e.getAttribute("data-sel").split(", ");
  if (e.classList.contains("next")) {
    e.classList = "previous";
    e.innerHTML = a[1];
    document.addEventListener("mouseover", quicklook);
    fit = true;
    cs = cf
  } else if(e.classList.contains("previous")) {
    e.classList = "tangerine";
    e.innerHTML = a[2];
    cs = co
    fit = false;
  } else if(e.classList.contains("tangerine")) {
    e.classList = "next";
    e.innerHTML = a[0];
    cs = co
    document.removeEventListener("mouseover", quicklook);
    fit = false;
  } else {
    e.classList = "next";
    e.innerHTML = a[0];
    cs = co
    document.removeEventListener("mouseover", quicklook);
    fit = false;
  }
}

function showDivs(n) {
  var i;
  var x = document.getElementsByClassName("mySlides");
  if (n > x.length) {slideIndex = 1}
  if (n < 1) {slideIndex = x.length} ;
  for (i = 0; i < x.length; i++) {
    x[i].style.display = "none";
  }
  x[slideIndex-1].style.display = "block";
  var expandImg = document.getElementById("expandedImg");
  expandImg.parentElement.style.display = "inline-block";
}

function resizeImg(n) {
  var x = document.getElementsByClassName("lazy");
  for (var i=0; i < x.length; i++) {
    if (n === 'auto') {
      x[i].style.maxWidth = '100%';
    } else {
      x[i].style.maxWidth = 'none';
    };
    x[i].style.height = n;
  }
}

function resizeCell(n) {
  var x = document.getElementsByClassName("cell");
  for (var i=0; i < x.length; i++) {
    x[i].style.width = n;
  }
}

function hideSources() {
  var x = document.getElementsByClassName("sources");
  for (var i=0; i < x.length; i++) {
    if (x[i].style.display === "none") {
      x[i].style.display = "";
    } else {
      x[i].style.display = "none";
    }
  }
}

function hideParts(e, t='', a=true) {
  if (t.length == 1) return;
  t = t.toLowerCase().split(" ");
  var tp = []
  for (var p=0; p < t.length; p++) {
    if(t[p].length > 1){
      tp.push(t[p])
    }
  }
  var x = document.getElementsByClassName("cell");
  var c, f;
  c = false;
  if (!e){
    for (var i=0; i < x.length; i++) {
      x[i].style.display = 'inline-block';
    }
    return
  }
  e = e.split('.');
  if (e.length > 1){
    e[0] = e[1]
    c = true
  }
  var fx = tp.length
  for (var i=0; i < x.length; i++) {
    var fp = '';
    if (c){
      fp = x[i].getElementsByClassName(e[0])
      if (fp.length > 0){
        fp = fp[0].textContent;
      } else {
        x[i].style.display = 'none';
        continue
      }
    } else {
      fp = x[i].getElementsByTagName(e[0])
      if (fp.length > 0){
        fp = fp[0].textContent;
      } else {
        x[i].style.display = 'none';
        continue
      }
    }
    f = false;
    fp = fp.toLowerCase();
    for (var p=0; p < tp.length; p++) {
      if (tp[p] && fp.includes(tp[p])){
        f = true;
        break;
      }
    };
    if (fx && !a && !f && fp || fx && a && f && fp){
      x[i].style.display = 'none';
    } else {
      x[i].style.display = 'inline-block';
    }
  }
}

var isTouch, keywords, stdout;
var dir = location.href.substring(0, location.href.lastIndexOf('/')) + "/";
window.onload = () => {
  var links = document.getElementsByTagName('a');
  for(var i=0; i<links.length; i++) {
    if (!links[i].href.startsWith(dir)){
      links[i].classList.add("external");
      links[i].target = "_blank";
    }
  }
  if('ontouchstart' in window){isTouch = true;};
  stdout = document.getElementById("stdout");
  if(!stdout.isContentEditable){
    stdout.setAttribute("onpaste", "plaintext(this, event)");
    stdout.setAttribute("contenteditable", "true");
  }
  lazyload();
  loadkeys();
}

function lazyload() {
  var lazyloadImages;

  lazyloadImages = document.querySelectorAll(".lazy");
  var imageObserver = new IntersectionObserver(function(entries, observer) {
    entries.forEach(function(e) {
      if (e.isIntersecting) {
        var t = e.target;
        t.src = t.dataset.src;
        imageObserver.unobserve(t);
      }
    });
  });

  lazyloadImages.forEach(function(e) {
    e.style.height =""" + f""" "{imgsize}""" + """px"
    e.style.width = "auto"
    imageObserver.observe(e);
  });
}
</script>
<body>
<div class="dark close_button cursor_tooltip" id="tooltip" style="padding:0px 8px; font-family:sans-serif; font-size:90%; z-index:9999999; left:0px; top:0px; right:initial; pointer-events:none;"></div><div style="display:block; height:20px;"></div><div class="container" style="display:none;">
<button class="dark" onclick="this.parentElement.style.display='none'">&times;</button>""" + f"""<div class="mySlides">{listurls}</div>
<img id="expandedImg">
</div>
<div style="display:block; height:10px;"></div><div style="background:#0c0c0c; height:20px; border-radius: 0 0 12px 0; position:fixed; padding:6px; top:0px; z-index:1;">
<button class="next" onclick="showDivs(slideIndex = 1)">Links in this HTML</button>
<button class="next" onclick="resizeImg('{imgsize}px')">1x</button>
<button class="next" onclick="resizeImg('{imgsize*2}px')">2x</button>
<button class="next" onclick="resizeImg('{imgsize*4}px')">4x</button>
<button class="next" onclick="resizeImg('auto')">1:1</button>
<button class="next" onclick="resizeCell('calc(100% - 30px)')">&nbsp;.&nbsp;</button>
<button class="next" onclick="resizeCell('calc(50% - 33px)')">. .</button>
<button class="next" onclick="resizeCell('calc(33.33% - 34px)')">...</button>
<button class="next" onclick="resizeCell('calc(25% - 35px)')">....</button>
<button id="fi" class="next" onclick="preview(this)" data-sel="Preview, Preview [ ], Preview 1:1" data-tooltip="Shift down - fit image to screen<br>Shift up - pixel by pixel">Preview</button>
<button id="ge" class="next" onclick="previewg(this)" data-sel="Original, vs left, vs left &lt;, vs left &gt;, Find Edge" data-tooltip="W - Edge detect<br>A - Geistauge: compare to left<br>S - Geistauge: bright both<br>D - Geistauge: compare to right (this)<br>Enable preview from toolbar then mouse-over an image while holding a key to see effects.">Original</button>
<button class="next" onclick="hideSources()">Sources</button>
<input class="next" type="text" oninput="hideParts('h2', this.value, false);" style="padding-left:8px; padding-right:8px; width:140px;" value="{" ".join(pattern[1])}" placeholder="Search title">
<input class="next" type="text" oninput="hideParts('h2', this.value);" style="padding-left:8px; padding-right:8px; width:140px;" value="{" ".join(pattern[0])}" placeholder="Ignore title">
<button class="next" onclick="hideParts('.edits')">Edits</button>
<button class="next" onclick="hideParts()">&times;</button>
<div class="dark local_tooltip" id="local_tooltip"></div>
<div class="stdout" id="stdout" style="display:none;" onpaste="plaintext(this, event);" contenteditable="plaintext-only" spellcheck=false></div>
</div>
{builder}</body>
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



def frompart(partfile, relics, htmlpart, pattern):
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
                else:
                    break
            if not relics[key]["html"] == new_relics[key]["html"] or not relics[key]["keywords"] == new_relics[key]["keywords"]:
                part.update({key:new_relics[key]})
                part_is = "updated"
            else:
                part.update({key:relics[key]})
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



def parttohtml(subdir, htmlname, part, filelist, pattern):
    files = []
    for file in next(os.walk(subdir))[2]:
        if not file.endswith(tuple(specialfile)) and not file.startswith("icon"):
            files += [file]
    stray_files = sorted(set(files).difference(x[1].rsplit("/", 1)[-1] for x in filelist))

    if verifyondisk:
        gethreadn = 0
        for file in files:
            gethreadn += 1
            ge_q.put((gethreadn, htmlname, len(files), file))
        ge_q.join()
        echo(" GEISTAUGE: 100%", 0, 1)

    for file in stray_files:
        key = file.split(".", 1)[0]
        if not key in part.keys():
            if not "0" in part.keys():
                part.update(new_p("0"))
                part["0"].update({"visible": True})
            key = "0"
        if "stray_files" in part[key]:
            part[key]["stray_files"] += [file]
        else:
            part[key]["stray_files"] = [file]

    tohtml(subdir, htmlname, part, pattern)

    for file in stray_files:
        if not file.endswith(tuple(specialfile)) and isrej(file, pattern):
            ondisk = f"{subdir}{file}".replace("/", "\\")
            echo(f"Blacklisted file saved on disk: {ondisk}", 0, 1)
            error[2] += [f"&gt; Blacklisted file saved on disk: {ondisk}"]

    if buildthumbnail:
        echo("Building thumbnails . . .")



def tohtml(subdir, htmlname, part, pattern):
    builder = ""
    listurls = ""



    n = 0
    while True:
        icon = "icon.png" if not n else f"icon {n}.png"
        if os.path.exists(f"{subdir}{thumbnail_dir}{icon}"):
            builder += f"""<img src="{thumbnail_dir}{icon}" height="100px">\n"""
        else:
            break
        n += 1
    if os.path.exists(page := f"{subdir}{thumbnail_dir}savelink.URL"):
        with open(page, 'r') as f:
            builder += f"""<h2><a href="{f.read().splitlines()[1].replace("URL=", "")}">{htmlname}</a></h2>"""



    if buildthumbnail:
        echo("Building thumbnails . . .")



    for key in part.keys():
        keywords = part[key]["keywords"]
        title = f"<h2>{keywords[0]}</h2>" if keywords and keywords[0] else f"""<h2 style="color:#666;">ꍯ Part {key} ꍯ</h2>"""
        content = ""
        if key == "0":
            if "stray_files" in part[key]:
                title = "<h2>Unsorted</h2>"
                content = "No matching partition found for this files. Either partition IDs are not assigned properly in file names or they're just really strays.\n"
            elif not part[key]["html"]:
                continue
        new_container = False
        end_container = False
        builder += """<div class="cell">\n""" if part[key]["visible"] else """<div class="cell" style="display:none;">\n"""
        if len(keywords) > 1:
            timestamp = keywords[1] if keywords[1] else "No timestamp"
            afterkeys = ", ".join(x for x in keywords[2:] if x) if len(keywords) > 2 else "None"
            builder += f"""<div class="time" id="{key}" style="float:right;">Part {key} ꍯ {timestamp}\nKeywords: {afterkeys}</div>\n"""
        builder += title
        if part[key]["files"]:
            builder += "<div class=\"files\">\n"
            for file in part[key]["files"]:
                builder += container(subdir, file, pattern)
            builder += "</div>\n"
        if "stray_files" in part[key]:
            builder += "<div class=\"edits\">\n"
            for file in part[key]["stray_files"]:
                # os.rename(subdir + file, subdir + "Stray files/" + file)
                builder += container(subdir, file, pattern)
            builder += "<br><br>File(s) not on server\n</div>\n"
        if html := part[key]["html"]:
            builder += """<div class="postMessage">"""
            for array in html:
                if len(array) == 2:
                    if new_container:
                        content += "<div class=\"carbon\">\n"
                        end_container = True
                        new_container = False
                    if array[1]:
                        content += f"""{array[0]}{container(subdir, array[1], pattern)}"""
                    else:
                        content += array[0]
                elif end_container:
                    if new_container:
                        content += "<div class=\"carbon\">\n"
                        new_container = False
                    else:
                        new_container = True
                    content += array[0] + "</div>"
                else:
                    content += array[0]
                    new_container = True
            if "<a href=\"" in content:
                urls = content.split("<a href=\"")
                links = ""
                for link in urls[1:]:
                    link = link.split("\"", 1)[0]
                    links += f"""<a href="{link}">{link}</a><br>"""
                listurls += f"""# From <a href="#{key}">#{key}</a> :: {keywords[0]}<br>{links}\n"""
            builder += f"{content}</div>\n"
        elif not part[key]["files"]:
            builder += "<div class=\"edits\">Rebuild HTML with a different login/tier may be required to view</div>\n"
        builder += "</div>\n\n"
    gallery_is = "created"
    if os.path.exists(subdir + "gallery.html"):
        gallery_is = "updated"
    with open(subdir + "gallery.html", 'wb') as f:
        f.write(bytes(new_html(builder, htmlname, listurls, pattern), "utf-8"))
    buffer = subdir.replace("/", "\\")
    print(f" File {gallery_is}: \\{buffer}gallery.html ")



def label(m, s, html=False):
    if m[3] == s[3]:
        label = ("<span>" if html else "") + "Identical"
    elif m[0] > s[0] and m[1] > s[1]:
        label = ("""<span style="color:#ff0000;">""" if html else tcolorr) + f"{s[0]} x {s[1]}"
    elif m[0] >= s[0] and m[1] > s[1] or m[0] > s[0] and m[1] <= s[1]:
        label = ("""<span style="color:#eedd99;">""" if html else tcolor) + "Stretched/Un"
    elif m[0] == s[0] and m[1] == s[1]:
        label = ("""<span style="color:#ffaa33;">""" if html else tcoloro) + "Artifact/Un"
    else:
        label = ("""<span style="color:#00ff00;">""" if html else tcolorg) + f"{s[0]} x {s[1]}"
    sizevs = (int(s[2])-int(m[2]))/int(m[2])*100
    if sizevs < 0:
        label += f"""</span> <span style="color:#66cc66;">{sizevs:.2f}%</span>""" if html else f" {tcolorg}{sizevs:.2f}%{tcolorx}"
    elif sizevs == 0:
        label += ("</span>" if html else tcolorx) + " 0.00%"
    else:
        label += f"""</span> <span style="color:#cc6666;">{sizevs:.2f}%</span>""" if html else f" {tcolorr}{sizevs:.2f}%{tcolorx}"
    return label



def tohtml_geistauge(delete=False):
    start = time.time()
    print(f"\n Now compiling duplicates to {batchname} HTML . . . kill this CLI to cancel.\n")
    builder = ""
    counter = 1
    db = opensav(sav).splitlines()
    db.sort(key=lambda s: s.split(" ", 1)[1].replace("\\", ""))
    datagroup = {}
    for line in db:
        phash, file = line.split(" ", 1)
        datagroup.setdefault(phash, [])
        datagroup[phash].append(file)
    new_savx = opensav(savx).splitlines()
    savsread = opensav(savs).splitlines()
    for phash in datagroup.keys():
        fplist = datagroup[phash]
        if phash in savsread and delete:
            for file in fplist:
                if os.path.exists(file):
                    f = file.rsplit("/", 1)
                    trashdir = f"{f[0]} Trash 2/"
                    if not os.path.exists(trashdir):
                        os.makedirs(trashdir)
                    os.rename(file, trashdir + f[1])
                    # os.remove(file)
            continue
        if len(fplist := [x for x in fplist if os.path.exists(x)]) < 2:
            continue
        Perfectexemption = True
        for file in fplist:
            if not any(word in file for word in exempt):
                Perfectexemption = False
        if Perfectexemption:
            continue
        fplist = iter(fplist)
        builder2 = ""
        fp = [0, 0, 0, 0]
        file = next(fplist)
        file2 = next(fplist)
        while True:
            fp2 = [0, 0, 0, 0]
            for line in new_savx:
                if file2 in line:
                    fp2 = list(map(int, line.split(" ", 3)[:3])) + [line.split(" ", 4)[3]]
                    break
            if not fp2[3]:
                fp2 = whsm(file2)
                new_savx += [" ".join([str(x) for x in fp2]) + f" {file2}"]
            if not fp[3]:
                for line in new_savx:
                    if file in line:
                        fp = list(map(int, line.split(" ", 3)[:3])) + [line.split(" ", 4)[3]]
                        break
                if not fp[3]:
                    fp = whsm(file)
                    new_savx += [" ".join([str(x) for x in fp]) + f" {file}"]
            if fp[3] == fp2[3] and delete:
                if not any(word in file2 for word in exempt):
                    if os.path.exists(file2):
                        os.remove(file2)
                elif not any(word in file for word in exempt):
                    if os.path.exists(file):
                        os.remove(file)
                    file = file2
                if file2 := next(fplist, None):
                    continue
                else:
                    break
            builder2 += container_c(file2, label(fp, fp2, html=True))
            if not (file2 := next(fplist, None)):
                break
        if builder2:
            builder += f"""<div class="container">
{container_c(file, f"{fp[0]} x {fp[1]}")}{builder2}</div>

"""
            counter += 1
        if counter % 512 == 0:
            morehtml = htmlfile.replace(".html", f" {int(counter/512)}.html")
            with open(morehtml, 'wb') as f:
                f.write(bytes(new_html(builder, batchname, ""), 'utf-8'))
            with open(savx, 'wb') as f:
                f.write(bytes("\n".join(new_savx), 'utf-8'))
            print("\"" + morehtml + "\" created!")
            builder = ""
            counter += 1
    morehtml = htmlfile.replace(".html", f" {int(counter/512) + 1}.html")
    with open(morehtml, 'wb') as f:
        f.write(bytes(new_html(builder, batchname, ""), 'utf-8'))
    with open(savx, 'wb') as f:
        f.write(bytes("\n".join(new_savx), 'utf-8'))
    print("\"" + morehtml + "\" created!")
    print(f"total runtime: {time.time()-start}")



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
    elif savefiles[0]:
        buffer = ""
        for ondisk in savefiles[0]:
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
                buffer += f" Save: {tcolorg}{ondisk}{tcolorx}\n"
            else:
                buffer += f" Unscanned: {tcolorb}{ondisk}{tcolorx}\n"
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
    buffer = ""
    trashlist = {}
    for file in delfiles[0]:
        if os.path.exists(file):
            f = file.rsplit("/", 1)
            if not f[0] in trashlist:
                trashlist.update({f[0]:[]})
            trashlist[f[0]] += [f[1]]
            stdout = f[0].replace("/", "\\")
            buffer += f"{tcolorb}{stdout}\\{f[1]}{tcolorr} -> {tcolorg}{stdout} Trash\\{f[1]}{tcolorx}\n"
    if not trashlist:
        echo("No schande'd files!", 0, 1)
        return
    echo(buffer, 0, 1)
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
        delfiles[0] = []
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
                tohtml_geistauge(True)
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
        file = parse.unquote(input("Add file to delete list: ").rstrip().replace("file:///", "").replace("http://localhost:8886/", batchdir))
        if file.lower() == "x":
            return
        if file.lower() == "v":
            for dfile in delfiles[0]:
                print(dfile)
        elif file.lower() == "r":
            file = parse.unquote(input("Remove file from delete list: ").rstrip().replace("file:///", "").replace("http://localhost:8886/", batchdir))
            while True:
                try:
                    delfiles[0].remove(file)
                    choice(bg=["2a", "%color%"])
                except:
                    choice(bg=["08", "%color%"])
                    break
        elif file.lower() == "d" and delfiles[0]:
            delnow()
        elif os.path.exists(file):
            choice(bg=["4c", "%color%"])
            delfiles[0] += [file]
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
            print(f" {tcolorg}Featuring image is unique!{tcolorx} But come on, let's compile HTML from database so you can find duplication faster.")
        elif not found:
            print(f" {tcolorg}Featuring image is unique! Nothing like it in database!{tcolorx}")
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
            print(f"\n {tcolorr}Reference image is corrupted.{tcolorx}")
            return
        if hash == hash2:
            fp = whsm(fp)
            print(f"\n Featuring: {fp[0]} x {fp[1]}\n Reference: {label(m, whsm(s))}")
        else:
            print(f"\n {tcolorg}Use your eyes, they're different{tcolorx}")
    print(f"total runtime: {time.time()-start}")



def finish_sort():
    if not os.path.exists(batchname + "/"):
        choice(bg=True)
        print(f" \\{batchname}\\ doesn't exist! Nothing to sort.")
        return
    mover = {}
    for file in next(os.walk(batchname + "/"))[2]:
        for n in md5er:
            if len(c := carrots([[file,""]], n, [], False)) == 2 and not c[0][0] and not c[-1][0]:
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
        for dir in sorter.keys():
            if sorter[dir][0]:
                found = False
                for n in sorter[dir][1:]:
                    if fnmatch(file, n):
                        found = True
                        break
                if not found:
                    print(f"{tcolorb}{batchname}\\ {tcolorr}-> {tcolorg}{dir}{tcolor}{file}{tcolorx}")
                    mover.update({file:dir})
                    break
            else:
                for n in sorter[dir][1:]:
                    if fnmatch(file, n):
                        print(f"{tcolorb}{batchname}\\ {tcolorr}-> {tcolorg}{dir}{tcolor}{file}{tcolorx}")
                        mover.update({file:dir})
                        break
    if not mover:
        choice(bg=True)
        print(f" Nothing to sort! Check and add or update pattern if there are files in \\{batchname}\\ needed to be sorted.")
        return
    sys.stdout.write(f" ({tcolorb}From directory {tcolorr}-> {tcolorg}to a more deserving directory{tcolorx}) {tcd} for non-existent directories - (C)ontinue ")
    sys.stdout.flush()
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
        html = [tcolorz("ffffff") + x[0]]
        c = 0xffffff
        for y in x[1:]:
            c -= 0x224400
            y = y.split("}")
            html += ["{" + tcolorz(str(hex(c if c > 0 else 0x111111)[2:])) + y[0]]
            for z in y[1:]:
                c += 0x224400
                html += [tcolorz(str(hex(c if c > 0 else 0x111111)[2:])) + "}" + z]
        return ''.join(html + [tcolorx])
    a = [[html,""]]
    for z in ["http://", "https://", "/"]:
        a = carrots(a, f"'{z}*' not starts with >", ["'" + z, "'"])
        a = carrots(a, f"\"{z}*\" not starts with >", ["\"" + z, "\""])
    z = []
    for x in a:
        y = tcolor
        if x[1][-4:-1] == ".js":
            y = tcoloro
        elif ".json" in x[1] or "/api/" in x[1]:
            y = tcolorb
        elif x[1][1:5] == "http":
            y = tcolorg
        z += [x[0] + y + x[1] + tcolorx]
    return "".join(z)



savepage = [{}]
def view_in_page(data, z, cw, a):
    if a:
        if x := tree(data, [z[0], [[z[1], 0, 0, cw, 0, 0]]], True):
            for y in x:
                echo(syntax(str(y[0]), True), 0, 1)
                savepage[0]["part"] += [y[0]]
        else:
            echo(f"{tcoloro}Last few keys doesn't exist, try again.{tcolorx}", 0, 2)
    else:
        if len(z.split("*")) > 1:
            if len(c := carrots([[data, ""]], z, cw)) > 1:
                for x in c:
                    echo(x[1], 0, 1)
                    savepage[0]["part"] += [x[1]]
            else:
                echo(f"{tcolorr}Pattern doesn't exist, try again.{tcolorx}", 0, 2)
        else:
            echo(f"{tcolorr}Cannot find in page with no asterisk.{tcolorx}", 0, 2)
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
                    z, cw, a = peanut(key, [], False)
                    if a:
                        data = opendb(data)
                    view_in_page(data, z, cw, a)
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
            z, cw, a = peanut(i, [], False)
            part = savepage[0]["part"]
            savepage[0]["part"] = []
            for data in part:
                view_in_page(data, z, cw, a)



def list_remote(remote):
    echo(f" - - {(datetime.utcnow() + timedelta(hours=int(offset))).strftime('%Y-%m-%d %H:%M:%S')} - - ", 0, 1)
    with subprocess.Popen([remote, "-l"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, bufsize=1, universal_newlines=True) as p:
        listed = False
        for line in p.stdout:
            if not line.startswith(tuple(["Sum: ", "    ID   Done"])):
                listed = True
                line = line.rstrip()
                id = line[:6].strip()
                percent = line[6:13].strip()
                status = line[59:71].strip() 
                name = line[72:].strip()
                echo(f"{id:>3} {status} {percent} {name}", 0, 1, clamp='█')
        if not listed:
            echo("No torrents to list!", 0, 1)
        echo("", 0, 1)



def start_remote(remote):
    shuddup = {"stdout":subprocess.DEVNULL, "stderr":subprocess.DEVNULL}
    keys = [*"0123456789", "All", *"dfsglmrei"]
    pos = 0
    sel = 14
    remove = []
    stdout = "STOP"
    if not torrent_menu[0]:
        echo(""" Key listener (torrent/file viewer):
  > Press D, F to decrease or increase number by 10
  > Press S, G to (S)top/start (G)etting selected item
  > Press L, M to re/(L)ist all items or return to torrent (M)anager/(M)ain menu

 Key listener (torrent management):
  > Press R, E, I to (R)emove torrent, view fil(E)s of selected torrent, or (I)nput new torrent""", 0, 2)
    while True:
        if torrent_menu[0]:
            el = input(f"Select TORRENT by number to {stdout}: {f'{pos/10:g}' if pos else ''}", keys if sel == 18 else keys[:10] + keys[11:])
            if not sel == 18 and el > 10:
                el += 1
        else:
            el = 15 + input("(I)nput new torrent, (L)ist or return to (M)ain menu: ", [keys[15], keys[16], keys[19]])
            if el == 18:
                el = 20
            torrent_menu[0] = True
        if el == 12:
            pos -= 10 if pos > 0 else 0
            echo("", 1)
        elif el == 13:
            pos += 10
            echo("", 1)
        elif el == 16:
            if sel == 18 and remove:
                intime = time.time()
                if intime > Keypress_time[0]+0.5:
                    echo(f"Press L twice in quick succession to remove: {' '.join(x for x in remove)}", 1, 1)
                    Keypress_time[0] = intime
                else:
                    for r in remove:
                        subprocess.Popen([remote, "-t", r, "-r"], **shuddup)
                    remove = []
                    pos = 0
                    sel = 14
                    stdout = "STOP"
                    time.sleep(0.5)
                    echo("", 1)
                    list_remote(remote)
            else:
                echo("", 1)
                list_remote(remote)
        elif el == 17:
            return
        elif el == 20:
            echo("", 1)
            buffer = "cancel"
            while True:
                i = input(f"Magnet/torrent link, enter nothing to {buffer}: ")
                if i.startswith("magnet:") or i.startswith("http") or i.endswith(".torrent"):
                    subprocess.Popen([remote, "-w", batchdir + "Transmission", "--start-paused", "-a", i, "-sr", "0"], **shuddup)
                    buffer = "finish"
                    pos = 0
                    sel = 15
                    stdout = "START"
                elif not i:
                    echo("", 1)
                    if buffer == "finish":
                        list_remote(remote)
                    break
                else:
                    choice(bg=True)
                    echo("Invalid input", 0, 2)
        elif el > 13:
            sel = el
            pos = 0
            remove = []
            if el == 14:
                stdout = "STOP"
            elif el == 15:
                stdout = "START"
            elif el == 18:
                stdout = "REMOVE, (A)ll"
            elif el == 19:
                stdout = "VIEW file list"
            echo("", 1)
        else:
            if sel == 14:
                if el == 11:
                    echo("", 1)
                else:
                    subprocess.Popen([remote, "-t", str(el-1+pos), "-S"], **shuddup)
            elif sel == 15:
                if el == 11:
                    echo("", 1)
                else:
                    subprocess.Popen([remote, "-t", str(el-1+pos), "-s"], **shuddup)
            elif sel == 18:
                if el == 11:
                    subprocess.Popen([remote, "-t", "all", "-r"], **shuddup)
                    remove = []
                    sel = 14
                else:
                    remove += [str(el-1+pos)]
                    stdout = "REMOVE, (A)ll, press L twice to confirm above, press R to clear"
            elif sel == 19:
                if el == 11:
                    echo("", 1)
                    continue
                pose = 0
                sele = 14
                stdoute = "STOP getting"
                i = 16
                while True:
                    if i == 12:
                        pose -= 10 if pose > 0 else 0
                        echo("", 1)
                    elif i == 13:
                        pose += 10
                        echo("", 1)
                    elif i == 16:
                        echo(f" - - {(datetime.utcnow() + timedelta(hours=int(offset))).strftime('%Y-%m-%d %H:%M:%S')} - - ", 0, 1)
                        with subprocess.Popen([remote, "-t", str(el-1+pos), "-f"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, bufsize=1, universal_newlines=True) as p:
                            listed = False
                            for line in p.stdout:
                                line = line.rstrip()
                                if line and not line.startswith("  #  Done") and not line.endswith("files):"):
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
                    elif i == 17:
                        echo("", 1)
                        break
                    elif i > 13:
                        sele = i
                        pose = 0
                        if i == 14:
                            stdoute = "STOP getting"
                        elif i == 15:
                            stdoute = "GET"
                        echo("", 1)
                    else:
                        if sele == 14:
                            if i == 11:
                                subprocess.Popen([remote, "-t", str(el-1+pos), "-G", "all"], **shuddup)
                            else:
                                subprocess.Popen([remote, "-t", str(el-1+pos), "-G", str(i-2+pose)], **shuddup)
                        elif sele == 15:
                            if i == 11:
                                subprocess.Popen([remote, "-t", str(el-1+pos), "-g", "all"], **shuddup)
                            else:
                                subprocess.Popen([remote, "-t", str(el-1+pos), "-g", str(i-2+pose)], **shuddup)
                    i = input(f"Select FILE by number to {stdoute}, (A)ll: {f'{pose/10:g}' if pose else ''}", keys[:17])



def torrent_get(fp=""):
    if sys.platform == "win32":
        daemon = "C:/Program Files/Transmission/transmission-daemon.exe"
        remote = "C:/Program Files/Transmission/transmission-remote.exe"
        if not os.path.exists(daemon):
            echo(" Download and install Transmission x64 for Windows in default location from https://github.com/transmission/transmission/releases and then try again.", 0, 1)
            return
    elif sys.platform == "linux":
        if not os.path.exists("/usr/bin/transmission-daemon") or not os.path.exists("/usr/bin/transmission-remote"):
            os.system("apk add transmission-daemon")
            os.system("apk add transmission-cli")
        daemon = "transmission-daemon"
        remote = "transmission-remote"
    else:
        echo("Unimplemented for this system!")
        return
    shuddup = {"stdout":subprocess.DEVNULL, "stderr":subprocess.DEVNULL}
    subprocess.Popen([daemon, "-f"], **shuddup, shell=True)
    if fp:
        subprocess.Popen([remote, "-w", batchdir + "Transmission", "--start-paused", "-a", fp, "-sr", "0"], **shuddup)
    start_remote(remote)
    return



def read_input(fp):
    if any(word for word in pickers.keys() if fp.startswith(word)):
        run_input[0] = fp
    elif fp.startswith("http") and not fp.startswith("http://localhost"):
        if fp.endswith("/"):
            choice(bg=True)
            echo(" I don't have a scraper for that!", 0, 2)
        else:
            run_input[1] = fp
    elif fp.startswith("magnet"):
        torrent_get(fp)
    elif os.path.exists(fp):
        if fp.endswith("partition.json"):
            subdir = fp.rsplit("/", 1)[0] + "/"
            htmlname = fp.rsplit("/", 2)[-2]
            if os.path.exists(p := f"{subdir}{thumbnail_dir}savelink.URL"):
                with open(p, 'r') as f:
                    page = f.read().splitlines()[1].replace("URL=", "")
            else:
                page = input("URL file not found, please guess original url to provide pattern for this partition: ")
            get_pick = [x for x in pickers.keys() if page.startswith(x)]
            if not get_pick:
                kill("Couldn't recognize this url, I must exit!")
            pattern = pickers[get_pick[0]]["pattern"]
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



def read_file():
    if not os.path.exists(textfile):
        open(textfile, 'w').close()
    print(f"Reading {textfile} . . .")
    with open(textfile, 'r', encoding="utf-8") as f:
        textread = f.read().splitlines()
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
        if any(word for word in pickers.keys() if line.startswith(word)):
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



busy[0] = True
if filelist:
    if len(filelist) > 1:
        kill(f"""
 Only one input at a time is allowed! It's a good indication that you should reorganize better
 if there are too many folders to input and you don't want to use input's parent.{'''

 Geistauge is also disabled which can be a reminder that this is not the setup to run Geistauge.
 May I suggest having another copy of this script with Geistauge enabled in different directory?''' if not Geistauge else ""}""")
    read_input(filelist[0])
busy[0] = False



def unrecognized(k):
    echo("", 1)
    echo(f"Keypress {k} unrecognized", 0, 1)
    if not busy[0]:
        ready_input()

def pressed(k, s=True):
    echo("", 1)
    Keypress["?ABCDEFGHIJKLMNOPQRSTUVWXYZ".index(k)] = s
    if not busy[0]:
        ready_input()

def keylistener():
    while True:
        el = choice("abcdefghijklmnopqrstuvwxyz0123456789")
        if el == 1:
            pressed("A")
            Keypress[24] = True
        elif el == 2:
            if sys.platform == "win32":
                if not Browser:
                    choice(bg=True)
                    echo(f""" No browser selected! Please check the "Browser =" setting in {rulefile}""", 0, 1)
                elif HTMLserver:
                    os.system(f"""start "" "{Browser}" "http://localhost:8886/" """)
                else:
                    echo(" HTML SERVER: Maybe not.", 0, 1)
            else:
                echo(" BROWSER: Maybe not.", 0, 1)
            if not busy[0]:
                ready_input()
        elif el == 3:
            pressed("C")
        elif el == 4:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            delmode()
            ready_input()
        elif el == 5:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo(help(), 0, 1)
            ready_input()
        elif el == 6:
            pressed("F")
        elif el == 7:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            if not Geistauge:
                choice(bg=True)
                echo(" GEISTAUGE: Maybe not.", 0, 1)
            else:
                tohtml_geistauge()
            ready_input()
        elif el == 8:
            unrecognized("H")
        elif el == 9:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            if fp := input("Enter input, enter nothing to cancel: ").rstrip().replace("\"", "").replace("\\", "/"):
                read_input(fp)
            else:
                echo("", 1)
                echo("", 1)
            ready_input()
        elif el == 10:
            intime = time.time()
            if intime > Keypress_time[0]+0.5:
                Keypress_time[0] = intime
                if not servers[0] or portkilled():
                    echo(" HTML SERVER: Press J twice in quick succession to restart servers.", 1, 1)
                else:
                    echo(" HTML SERVER: Press J twice in quick succession to stop servers.", 1, 1)
            else:
                if portkilled():
                    restartserver()
                else:
                    stopserver()
            if not busy[0]:
                ready_input()
        elif el == 11:
            c = False
            for c in cookies:
                echo(str(c), 1, 2)
            if not c:
                echo("No cookies!", 1, 1)
            if not busy[0]:
                ready_input()
        elif el == 12:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            run_input[2] = True
        elif el == 13:
            if busy[0]:
                pressed("M")
                continue
            echo("", 1)
            torrent_get()
            echo("", 1)
            ready_input()
        elif el == 14:
            unrecognized("N")
        elif el == 15:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            finish_sort()
            ready_input()
        elif el == 16:
            pressed("A", False)
        elif el == 17:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            run_input[3] = True
        elif el == 18:
            pressed("R")
        elif el == 19:
            pressed("S")
        elif el == 20:
            if ticks:
                echo(f"""COOLDOWN {"DISABLED" if Keypress[20] else "ENABLED"}""", 1, 2)
            else:
                echo(f"""Timer not enabled, please add "#-# seconds rarity 100%" in {rulefile}, add another timer to manipulate rarity.""", 1, 2)
            pressed("T", False if Keypress[20] else True)
        elif el == 21:
            unrecognized("U")
        elif el == 22:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            source_view()
            ready_input()
        elif el == 23:
            unrecognized("W")
        elif el == 24:
            echo(f"""SET ALL ERROR DOWNLOAD REQUESTS TO: {"SKIP" if Keypress[24] else "RETRY"}""", 1, 2)
            pressed("X", False if Keypress[24] else True)
            Keypress[1] = True
        elif el == 25:
            unrecognized("Y")
        elif el == 26:
            pressed("Z")
        elif 0 <= (n := min(el-27, 8)) < 9:
            echo(f"""MAX PARALLEL DOWNLOAD SLOT: {n} {"(pause)" if not n else ""}""", 1, 1)
            dlslot[0] = n
            if not busy[0]:
                ready_input()
        else:
            pressed("Z")
t = Thread(target=keylistener)
t.daemon = True
t.start()
print(f"""
 Key listener:
  > Press X to enable or disable indefinite retry on error downloading files (for this session).
  > Press S to skip next error once during downloading files.
  > Press T to enable or disable cooldown during errors (reduce server strain).
  > Press K to view cookies.
  > Press 1 to 8 to set max parallel download of 8 available slots, 0 to pause.
  > Press Z or CtrlC to break and reconnect of the ongoing downloads or to end timer instantly.

 Key listener (ready input):
  > Press I, L to enter (I)nput or (L)oad list from {textfile}.
  > Press O to s(O)rt files.
  > Press M, E to open torrent (M)anager or h(E)lp document.""")



echo(mainmenu(), 0, 1)
ready_input()
while True:
    if run_input[0]:
        busy[0] = True
        scrape([["", run_input[0], [0]]])
        run_input[0] = False
        busy[0] = False
        echo("", 0, 1)
        ready_input()
    if run_input[1]:
        busy[0] = True
        x = new_part()
        x["partition"]["0"]["files"] = [new_link(run_input[1], parse.unquote(run_input[1].split("/")[-1]), 0)]
        downloadtodisk(x, "Autosave declared completion.")
        run_input[1] = False
        busy[0] = False
        echo("", 0, 1)
        ready_input()
    if run_input[2]:
        busy[0] = True
        read_file()
        run_input[2] = False
        busy[0] = False
        echo("", 0, 1)
        ready_input()
    if run_input[3]:
        busy[0] = True
        downloadtodisk(False, "Key listener test")
        run_input[3] = False
        busy[0] = False
        echo("", 0, 1)
        ready_input()
    try:
        time.sleep(0.1)
    except KeyboardInterrupt:
        echo(skull(), 0, 1)
        choice(bg=["4c", "%color%"])
        ready_input()



"""
::MacOS:           open /Applications/Python\ 3.10/Install\ Certificates.command
::Linux/MacOS:     python3 -x /drag/n/drop/the/batchfile

::if MacOS (pip=sudo python3 -m pip) else if Linux (pip=pip3)
::update pip:      %pip% install --upgrade pip
::install package: %pip% install name_of_the_missing_package

:loaded
set color=0e && set stopcolor=05
color %color%
set batchfile=%~0
if %cd:~-1%==\ (set batchdir=%cd%) else (set batchdir=%cd%\)
set txtfile=%~n0.txt
set txtfilex=%~dpn0.txt

setlocal enabledelayedexpansion
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

set pythondir=%userprofile%\AppData\Local\Programs\Python\
chcp 65001>nul
if exist "!txtfilex!" for /f "delims=" %%i in ('findstr /b /i "Python = " "!txtfilex!"') do set string=%%i&& set string=!string:~9!&& goto check
:check
chcp 437>nul
if not "!string!"=="" (set pythondir=!string!)
set x=Python 3.10
set cute=!x:.=!
set cute=!cute: =!
set pythondirx=!pythondir!!cute!
if exist "!pythondirx!\python.exe" (cd /d "!pythondirx!" && color %color%) else (color %stopcolor%
echo.
if "!string!"=="" (echo  I can't seem to find \!cute!\python.exe^^! Install !x! in default location please, or edit this batch file.&&echo.&&echo  Download the latest !x!.x from https://www.python.org/downloads/) else (echo  Please fix path to \!cute!\python.exe in "Python =" setting in !txtfile!)
echo.
echo  I must exit^^!
pause%>nul
exit)
set pythondir=!pythondir:\=\\!

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
python.exe -x "!batchfile!" "!filelist!" "!pythondir!" "!batchdir!"
set filelist=
color %stopcolor%
echo.
echo Restart CLI? Press any key to continue . . .
pause >nul
goto start
"""
