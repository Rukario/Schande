@echo off && goto loaded

import os, sys, ssl, socket, socks, time, json
from datetime import datetime
from http import cookiejar
from http.server import SimpleHTTPRequestHandler, HTTPServer
from queue import Queue
from socketserver import ThreadingMixIn
from threading import Thread
from urllib import parse, request
from codecs import encode, decode

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
mf = batchname + "/"
tmf = "\\" + mf.replace("/", "\\")
cd = batchname + " cd/"
tcd = "\\" + cd.replace("/", "\\")
htmlfile = batchname + ".html"
rulefile = batchname + ".cd"
sav = batchname + ".sav"
savx = batchname + ".savx"
textfile = batchname + ".txt"

archivefile = [".7z", ".rar", ".zip"]
imagefile = [".gif", ".jpe", ".jpeg", ".jpg", ".png"]
videofile = [".mkv", ".mp4", ".webm"]
specialfile = ["magnificent.txt", "mediocre.txt", ".ender"]

newfilen = [0]
echothreadn = []
error = [[]]
offlineprompt = [False]
offlinepromptx = [False]
retries = [0]
retryx = [False]
retryall = [False]
skiptonext = [False]
sf = [0]
disableinput = False
# Keylistener will break input() unless input() didn't exist

# HTML builder
buildthumbnail = False
# True if you want to serve pages efficiently. It'll take a while to build new thumbnails from large collection.

# Local variables for debugging
collisionisreal = False
editisreal = False

if buildthumbnail:
    from PIL import Image
    Image.MAX_IMAGE_PIXELS = 400000000
    import subprocess

# Geistauge and organize tools
from fnmatch import fnmatch
from PIL import Image



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



def mainmenu():
    print("""
 - - - - Drag'n'drop - - - -
 + Drag'n'drop the featuring folder and hit Enter to add to database.
 | Drag'n'drop the featuring image and hit Enter to compare with reference image,
 | while scanning new folder, or find in database.
 + The featuring/reference folder will be added to database, image(s) will not.

 - - - - Input/Paste - - - -
 + Enter V to load a page for page source viewing.
 | Enter B to launch HTML in your favorite browser.
 | Enter C to re/compile HTML from database (your browser will be used as comparison GUI).
 | Enter D to delete non-exempted duplicate images immediately with a confirmation.
 |  > One first non-exempt in path alphabetically will be kept if no other duplication are exempted.
 | Enter file:/// or http://localhost url to enter delete mode.
 | Enter http(s):// to download file.
 + Enter valid site to start a scraper.
""")



def skull():
    print("""
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
""")
    choice(bg="4c")



def quicktutorial():
    print(f"""
 {rulefile} is collection of rules that defines how files are downloaded and organized.

 - - - - Manager - - - -
 + Rule syntax for while downloading:
 |  "key value for .site"     cookie for a site that requires login.
 |  "http... for http..."     visit page with referer.
 |  "...\\* for http..."       custom dir for downloads, {tmf} if no custom dir specified.
 |  "...*date\\* for http..."  custom dir for downloads, "*date" will become "{date}".
 |  "...\\...*... for http..." and the file are also renamed (prepend/append).
 |  "...*... for http..."     and they go to {tmf} while renamed.
 |
 | Rule syntax for organizing from {tmf}:
 |  "... for ..."             organize matching (commas are forbidden here, write rule per line like usual)
 |  "... !for ..., ..., ..."  organize non-matching (commas for multiple matches or it'll take everything!)
 |  The pattern after for/!for uses unix wildcard, meaning ? matches 1 character, * matches everything.
 |
 | First rule in list will take its turn to handle the download/file before else.
 | If {rulefile} tried to organize files to the non-existent folder, they go to {tcd} instead.
 |  It can help ensure that no other rule can organize them any more (first rule = first to organize).
 +  Conveniently used to migrate to another directory where the folder actually exists.

 - - - - Scraper - - - -
 You need to:
  > know how to view page source or API.
  > know how to create pattern with asterisks or keys. Pages will be provided without newlines ("\\n") for convenience.
  > keep testing! Pages are full of variables. Develop solid asterisks/keys and flag scraper "ready" to stop previews.

 + Rule syntax for scraping (aka pickers):
 |  "http..."            validates a site to start a scraper, attribute all pickers to this.
 |  "urlfix ...*... with ...*..." redirector.
 |  "send X Y"           send data (Y) to url (X) before accessing page.
 |  "body ...*..."       pick part of the page. API: pick content for HTML-based pickers.
 |  "replace X with X"   find'n'replace before start picking in page/body.
 |  "title ...*..."      pick and use as folder from first scraped page.
 |  "folder ...*..."     from url.
 |  "choose .. > .. = X" choose file by a match in another key. "X > X" for multiple possibilities in priority order.
 |  "file(s) ...*..."    pick first or all files to download, "relfile(s)" for relative urls.
 |  "name ...*..."       pick name for each file downloading. There's no file on disk without a filename!
 |  "meta ...*..."       from url.
 |  "extfix ...*..."     fix name without extension from url (detected by ending mismatch).
 |  "pages ...*..."      pick more pages to scrape in parallel, "relpages" for relative urls.
 |  "saveurl"            save first scraped page url as URL file in same directory where files are downloading.
 |
 | Page asterisks will be unique, but asterisks to older pages can cause loophole.
 | Repeat a picker with different pattern for multiple possibilities/actions.
 | folder#, title#, name#, meta# to assemble assets together sequentially.
 |  "...*..."            HTML-based picker.
 |  "... > ..."          API/QS-based picker, " > 0 > " to iterate a list, " >> " to load a dictionary from inside QS.
 | API/QS (Query String) supported pickers: body, files, name, pages.
 | During API each file picker must be accompanied by name picker and all HTML-based name/meta pickers must descend.
 |
 | Manipulating asterisk:
 |  > Multiple asterisks to pick the last asterisk better and/or to discard others.
 |  > Arrange name and file pickers if needed to follow their position in page. file before -> name -> file after.
 |  > First with match will be chosen first. This doesn't apply to body and plural pickers such as files, pages.
 |  > Name match closest to the file will be chosen. file before -> name to before -> name to after -> file after.
 |
 | Right-to-left:
 |  > Use caret "^..." to get the right match. Resets on next asterisk unless there's caret again.
 |  > The final non-caret asterisk will be chosen. First asterisk if every asterisk has caret.
 |
 | For difficult asterisks:
 |  "X # letters" (# or #-#) after any picker so the match is expected to be that amount.
 |  "X ends/starts with X" after any picker. "not" for opposition.
 |
 | Customize asset with prepend and append using "X customize with ...*..." after any picker.
 + Folder and title pickers will be auto-assigned with \\ to work as folder unless customized.

 - - - - Geistauge - - - -
 + Invalid rule in {rulefile} will become Geistauge's pattern exemption, e.g. "path" for:
 |  Z:\\path\\01.png
 |  Z:\\path\\02.png
 |
 + No exemption if at least one similar image doesn't have a pattern.
""")



if not os.path.exists(rulefile):
    open(rulefile, 'w').close()
if os.path.getsize(rulefile) < 1:
    quicktutorial()
    print(f"Please add a rule in rule file ({rulefile}) and restart CLI to continue.")
    sys.exit()
print(f"Reading {rulefile} . . .")
with open(rulefile, 'r', encoding="utf-8") as f:
    rules = f.read().splitlines()



def tidy(offset, append, comment=""):
    if offset == 0:
        data = append + "\n\n" + "\n".join(rules) + comment
    else:
        data = "\n".join(rules[:offset]) + "\n" + append + "\n" + "\n".join(rules[offset:])
    with open(rulefile, 'wb') as f:
        f.write(bytes(data, 'utf-8'))
    return data.splitlines()



def new_comment():
    return ""
comment = ""
offset = 0
settings = ["Launch HTML server = No", "Browser = ", "Geistauge = No", "Python = " + pythondir, "Proxy = socks5://"]
for setting in settings:
    if not rules[offset].replace(" ", "").startswith(setting.replace(" ", "").split("=")[0]):
        if not offset and not "#" in "".join(rules):
            comment = new_comment()
            rules = tidy(offset, setting, comment=comment)
        else:
            rules = tidy(offset, setting)
        print(f"""Added new setting "{setting}" to {rulefile}!""")
    offset += 1
if comment:
    print(f"\n New comments (# comment) and download filters were added to {rulefile}.\n You may want to check/edit there then restart CLI before I download artpieces with filters and settings.")
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



class RangeHTTPRequestHandler(SimpleHTTPRequestHandler):
    def send_head(self):
        self.range = (0, 0)
        self.total = 0
        path = self.translate_path(self.path)
        if os.path.isdir(path):
            return SimpleHTTPRequestHandler.send_head(self)
        ctype = self.guess_type(path)
        if path.endswith("/"):
            self.send_error(404, "File not found")
            return None
        try:
            f = open(path, 'rb')
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
            if start >= size:
                self.send_error(416, self.responses.get(416)[0])
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
            if 'Range' in self.headers:
                self.send_response(206)
            else:
                self.send_response(200)
            self.send_header('Accept-Ranges', 'bytes')
            self.send_header('Content-Range', 'bytes %s-%s/%s' % (start, end, size))
            self.send_header('Content-type', ctype)
            self.send_header('Content-Length', str(end-start+1))
            self.send_header('Last-Modified', self.date_time_string(fs.st_mtime))
            self.end_headers()
            return f
        except:
            print("DISCONNECTED")

    def copyfile(self, source, outputfile):
        dl = self.range[0]
        total = self.total
        source.seek(dl)
        sf[0] += 1
        thread = sf[0]
        echothreadn.append(-thread)
        try:
            while buf := source.read(262144):
                Bytes = len(buf)
                dl += Bytes
                echoMBs(-thread, -Bytes, -int(dl/total*256) if total else 0)
                outputfile.write(buf)
            print("DONE")
        except:
            print("DISCONNECTED")
        echothreadn.remove(-thread)



def handler(directory):
    SimpleHTTPRequestHandler.error_message_format = "<html><title>404</title><style>html,body{white-space:pre; background-color:#0c0c0c; color:#fff; font-family:courier; font-size:14px;}</style><body> .          .      .      . .          .       <p>      .              .         .             <p>         .     🦦 -( 404 )       .  <p>   .      .           .       .       . <p>     .         .           .       .     </body></html>"
    def _init(self, *args, **kwargs):
        return RangeHTTPRequestHandler.__init__(self, *args, directory=self.directory, **kwargs)
    return type(f'RangeHTTPRequestHandler<{directory}>', (RangeHTTPRequestHandler,), {'__init__': _init, 'directory': directory})
class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    pass
def startserver(port, directory):
    d = os.path.basename(directory)
    d = f"\\{d}\\" if d else "current drive"
    print(f""" HTML SERVER: Serving {d} at port {port}""")
    ThreadedHTTPServer(("", port), handler(directory)).serve_forever()



# Loading settings from rulefile
def y(y, yn=False):
    y = y.split("=", 1)[1].strip()
    if yn:
        if os.path.exists(y):
            return y
        return True if y.lower()[0] == "y" else False
    else:
        return y
HTMLserver = y(rules[0], True)
Browser = y(rules[1])
Geistauge = y(rules[2], True)
proxy = y(rules[4])
if HTMLserver:
    port = 8885
    directories = [os.getcwd()]
    for directory in directories:
        port += 1
        t = Thread(target=startserver, args=(port,directory,))
        t.daemon = True
        t.start()
else:
    print(" HTML SERVER: OFF")
if Browser:
    print(" BROWSER: " + Browser.replace("\\", "/").rsplit("/", 1)[-1])
else:
    print(" BROWSER: NONE")
if Geistauge:
    try:
        import numpy, cv2, hashlib
        print(" GEISTAUGE: ON")
    except:
        print(f" GEISTAUGE: Additional prerequisites required - please execute in another command prompt with:\n\n{sys.exec_prefix}\Scripts\pip.exe install numpy==1.19.3\n{sys.exec_prefix}\Scripts\pip.exe install opencv-python")
        sys.exit()
else:    
    print(" GEISTAUGE: OFF")
if "socks5://" in proxy and proxy[10:]:
    if not ":" in proxy[10:]:
        print(" PROXY: Invalid socks5:// address, it must be socks5://X.X.X.X:port OR socks5://user:pass@X.X.X.X:port\n\n TRY AGAIN!")
        sys.exit()
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



cookie = cookiejar.MozillaCookieJar("cookies.txt")
if os.path.exists("cookies.txt"):
    cookie.load()
def new_cookie():
    return {'port_specified':False, 'domain_specified':False, 'domain_initial_dot':False, 'path_specified':False, 'version':0, 'port':None, 'path':'/', 'secure':None, 'expires':None, 'comment':None, 'comment_url':None, 'rest':{"HttpOnly": None}, 'rfc2109':False, 'discard':True, 'domain':None, 'name':None, 'value':None}



def explicate(rule):
    return rule.replace("*date", date).replace("/", "\\")



def at(a, r, alt=True):
    n, r = r.split(" ", 1)
    n = int(n) if n else 0
    if not a:
        a += [[]]
    if n:
        a += [[] for _ in range(n-len(a)+1)]
    a[n] += [r] if a[n] else [{"alt":alt}, r]



def topicker(s, rule):
    if rule[0].startswith("send "):
        rule = rule[0].split(" ", 2)
        s["send"] += [[rule[1], rule[2]]]
    elif rule[0].startswith("body "):
        s["body"] += [rule[0].split("body ", 1)[1]]
    elif rule[0].startswith("folder"):
        at(s["folder"], rule[0].split("folder", 1)[1], alt=False)
    elif rule[0].startswith("title"):
        at(s["folder"], rule[0].split("title", 1)[1])
    elif rule[0].startswith("choose "):
        s["choose"] += [rule[0].split("choose ", 1)[1]]
    elif rule[0].startswith("file "):
        at(s["file2" if s["name"] else "file"], rule[0].split("file", 1)[1])
    elif rule[0].startswith("relfile "):
        at(s["file2" if s["name"] else "file"], rule[0].split("relfile", 1)[1], alt=False)
    elif rule[0].startswith("files "):
        at(s["file2" if s["name"] else "file"], rule[0].split("files", 1)[1])
        s["files"] = True
    elif rule[0].startswith("relfiles "):
        at(s["file2" if s["name"] else "file"], rule[0].split("relfiles", 1)[1], alt=False)
        s["files"] = True
    elif rule[0].startswith("name"):
        at(s["name"], rule[0].split("name", 1)[1])
    elif rule[0].startswith("meta"):
        at(s["name"], rule[0].split("meta", 1)[1], alt=False)
    elif rule[0].startswith("extfix "):
        s["extfix"] = rule[0].split("extfix ", 1)[1]
    elif rule[0].startswith("urlfix "):
        rule = rule[0].split(" ", 1)[1].split(" with ", 1)
        x = rule[1].split("*", 1)
        s["urlfix"] = [x[0], [rule[0]], x[1]]
    elif rule[0].startswith("pages "):
        at(s["pages"], rule[0].split("pages", 1)[1])
    elif rule[0].startswith("relpages "):
        at(s["pages"], rule[0].split("relpages", 1)[1], alt=False)
    elif rule[0].startswith("ready"):
        s["ready"] = True
    elif rule[0].startswith("saveurl"):
        s["saveurl"] = True
    else:
        return
    return True



# Loading referer, organize, and custom dir rules, pickers, and global file rejection by file types from rulefile
customdir = {}
organize = {}
rename = []
referers = {}
exempt = []
mag = []
med = []
scraper = {}
def new_scraper():
    return {"replace":[], "send":[], "body":[], "folder":[], "choose":[], "file":[], "file2":[], "files":False, "name":[], "extfix":"", "urlfix":"", "pages":[], "saveurl":False, "ready":False}
scraper.update({"void":new_scraper()})
site = "void"
for rule in rules:
    if not rule or rule.startswith("#"):
        continue
    elif rule.startswith('.'):
        mag += [rule]
    elif rule.startswith('!.'):
        med += [rule.replace("!.", ".", 1)]
    elif len(rule := rule.split(" for ")) == 2:
        if rule[0].startswith("md5"):
            rename += [rule[1]]
        elif rule[1].startswith("http"):
            if rule[0].startswith("http"):
                referers.update({rule[1]: rule[0]})
            elif not len(explicate(rule[0]).split("*")) == 2:
                print("\n There is at least one of the bad custom dir rules (no asterisk or too many).")
                sys.exit()
            else:
                customdir.update({rule[1]: rule[0]})
        elif rule[1].startswith('.'):
            c = new_cookie()
            c.update({'domain': rule[1], 'name': rule[0].split(" ")[0], 'value': rule[0].split(" ")[1]})
            cookie.set_cookie(cookiejar.Cookie(**c))
        else:
            organize.update({rule[1]: [rule[0], False]})
    elif len(rule := rule[0].split(" !for ")) == 2:
        organize.update({rule[1]: [rule[0], True]})
    elif rule[0].startswith("http"):
        site = rule[0]
        if not site in scraper:
            scraper.update({site:new_scraper()})
    elif rule[0].startswith("replace "):
        rule = rule[0].split(" ", 1)[1].split(" with ", 1)
        scraper[site]["replace"] += [[rule[0], rule[1]]]
    elif topicker(scraper[site], rule):
        pass
    else:
        exempt += [rule[0]]
request.install_opener(request.build_opener(request.HTTPCookieProcessor(cookie)))
# cookie.save()



# Loading filelist from detected urls in textfile
if not os.path.exists(textfile):
    open(textfile, 'w').close()
print(f"\nReading {textfile} . . .")
with open(textfile, 'r', encoding="utf-8") as f:
    textread = f.read().splitlines()
htmlassets = {"filelist":[]}
for url in textread:
    if not url or url.startswith("#"):
        continue
    elif not url.startswith("http"):
        continue
    name = parse.unquote(url.split("/")[-1])
    htmlassets["filelist"] += [{"url":url, "name":name, "edited":0}]



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



def choice(keys="", bg=False):
    if sys.platform == "win32":
        if bg: os.system(f"""color {"%stopcolor%" if bg == True else bg}""")
        if keys: errorlevel = os.system(f"choice /c:{keys} /n")
        if bg: os.system("color %color%")
    else:
        if keys: errorlevel = os.system("""while true; do
read -s -n 1 errorlevel || break
case $errorlevel in
""" + "\n".join([f"{k} ) exit {e+1};;" for e, k in enumerate(keys)]) + """
esac
done""")
    echo(tcolorx)
    if not keys: return
    if errorlevel >= 256:
        errorlevel /= 256
    return errorlevel



seek = [False]
def keylistener():
    while True:
        el = choice("xsq")
        if el == 1:
            echo(f"""SET ALL ERROR DOWNLOAD REQUESTS TO: {"SKIP" if retryx[0] else "RETRY"}""", 1, 1)
            retryx[0] = False if retryx[0] else True
            offlinepromptx[0] = True
        elif el == 2:
            echo("", 1)
            skiptonext[0] = True
        elif el == 3:
            echo("", 1)
            offlinepromptx[0] = False
        else:
            seek[0] = True
if disableinput:
    t = Thread(target=keylistener)
    t.daemon = True
    t.start()
    print("""
 Key listener:
  > Press X to enable or disable indefinite retry on error downloading files (for this session).
  > Press S to skip next error once during downloading files.
""")



def retry(stderr):
    # Warning: urllib has slight memory leak
    retryall[0] = False
    while True:
        if not offlineprompt[0]:
            offlineprompt[0] = True
            # raise
            if stderr:
                if offlinepromptx[0]:
                    echo(f"""{retries[0]} retries{" (Q)uit trying"}""")
                else:
                    title("OFFLINE", True)
                    print(f"{stderr} (R)etry? (A)lways (N)ext")
                    el = choice("ran", True)
                    if el == 1:
                        retryall[0] = True
                    elif el == 2:
                        offlinepromptx[0] = True
                    elif el == 3:
                        title(FAVORITE, True)
                        offlineprompt[0] = False
                        return
            else:
                echo(f"{retries[0]} retries (S)kip one, wait it out, or press X to quit trying . . . ")
            time.sleep(0.5)
            title(FAVORITE, True)
            retries[0] += 1
            offlineprompt[0] = False
            return True
        elif retryall[0]:
            return True
        time.sleep(0.5)



def fetch(url, context=None, headers={}, stderr="", dl=0, threadn=0, data=None):
    while True:
        try:
            headers.update({'Range':f'bytes={dl}-', 'User-Agent': 'Mozilla/5.0', 'Accept': "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"})
            resp = request.urlopen(request.Request(url, headers=headers, data=data), context=context)
            break
        except:
            if stderr or retryx[0] and not skiptonext[0]:
                if not retry(stderr):
                    return
            else:
                skiptonext[0] = False
                return
    return resp



def get(url, todisk="", conflict=[[], []], context=None, headers={'Referer':"", 'Origin':""}, headonly=False, stderr="", threadn=0):
    echourl = f"{url[:87]}{(url[87:] and '█')}"
    dl = 0
    if todisk:
        echo(threadn, f"{threadn:>3} Downloading 0 / 0 MB {echourl}")
        if os.path.exists(todisk + ".part"):
            dl = os.path.getsize(todisk + ".part")
    else:
        echo(threadn, "0 MB")
    if not (resp := fetch(url, context, headers, stderr, dl, threadn)):
        return
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
        return 1
    if headonly and not stderr:
        return total
    if todisk:
        if conflict[0]:
            if not total in conflict[1]:
                for file in conflict[0]:
                    if os.path.exists(file):
                        conflict[1] += [os.path.getsize(file)]
            if total in conflict[1]:
                echo("Filename collision + same filesize, safe to ignore", 0, 1)
                return 2
        conflict[1] += [total]
        echo(threadn, f"""{threadn:>3} Downloading {f"{dl/1073741824:.2f}" if GB else int(dl/1048576)} / {MB} {echourl}""")
        with open(todisk + ".part", 'ab') as f:
            while True:
                try:
                    block = resp.read(262144)
                    if not block:
                        if not total or dl == total:
                            break
                        if not retry(stderr) or not (resp := fetch(url, context, headers, stderr, dl, threadn)):
                            return
                        if resp.status == 200 and dl > 0:
                            kill(threadn, "server doesn't allow resuming download. Delete the .part file to start again.")
                        continue
                except KeyboardInterrupt:
                    resp = fetch(url, context, headers, stderr, dl, threadn)
                    if resp.status == 200 and dl > 0:
                        kill(threadn, "server doesn't allow resuming download. Delete the .part file to start again.")
                    continue
                except:
                    if not retry(stderr) or not (resp := fetch(url, context, headers, stderr, dl, threadn)):
                        return
                    if resp.status == 200 and dl > 0:
                        kill(threadn, "server doesn't allow resuming download. Delete the .part file to start again.")
                    continue
                f.write(block)
                Bytes = len(block)
                dl += Bytes
                echoMBs(threadn, Bytes, int(dl/total*256) if total else 0)
                echo(threadn, f"""{threadn:>3} Downloading {f"{dl/1073741824:.2f}" if GB else int(dl/1048576)} / {MB} {echourl}""", friction=True)
                if seek[0]:
                    resp = fetch(url, context, headers, stderr, dl, threadn)
                    if resp.status == 200 and dl > 0:
                        kill(threadn, "server doesn't allow resuming download. Delete the .part file to start again.")
                    seek[0] = False
        echo(f"{threadn:>3} Download completed: {url}", 0, 1)
        os.rename(todisk + ".part", todisk)
        stdout[0] = ""
        stdout[1] = ""
        return 1
    else:
        data = b''
        while True:
            try:
                block = resp.read(262144)
                if not block:
                    if not total or dl == total:
                        stdout[0] = ""
                        stdout[1] = ""
                        return data
                    if not retry(stderr) or not (resp := fetch(url, context, headers, stderr, dl, threadn)):
                        return
                    if resp.status == 200:
                        data = b''
                        dl = 0
                    continue
            except KeyboardInterrupt:
                resp = fetch(url, context, headers, stderr, dl, threadn)
                if resp.status == 200:
                    data = b''
                    dl = 0
                continue
            except:
                if not retry(stderr) or not (resp := fetch(url, context, headers, stderr, dl, threadn)):
                    return
                if resp.status == 200:
                    data = b''
                    dl = 0
                continue
            data += block
            Bytes = len(block)
            dl += Bytes
            echoMBs(threadn, Bytes, int(dl/total*256) if total else 0)
            echo(threadn, f"{int(dl/1048576)} MB", friction=True)
            if seek[0]:
                resp = fetch(url, context, headers, stderr, dl, threadn)
                if resp.status == 200:
                    data = b''
                    dl = 0
                seek[0] = False



def echosession(download):
    while True:
        threadn, html, log, todisk, onserver = download.get()
        conflict = [[], []]
        for n in range(len(onserver)):
            if n and not collisionisreal:
                continue
            url = onserver[n]
            referer = x[0] if (x := [v for k, v in referers.items() if k in url]) else ""
            if n:
                if not conflict[0]:
                    conflict[0] += [todisk]
                todisk = f" ({n+1}).".join(todisk.rsplit(".", 1))
                conflict[0] += [todisk]
            if os.path.exists(todisk):
                echo(f"{threadn:>3} Already downloaded: {todisk}", 0, 1)
            elif el := get(url, todisk=todisk, conflict=conflict, headers={'Referer':referer, 'Origin':referer}, threadn=threadn):
                if el == 1:
                    newfilen[0] += 1
                    html.append("<a href=\"" + todisk.replace("#", "%23") + "\"><img src=\"" + todisk.replace("#", "%23") + "\" height=200px></a>")
            else:
                error[0] += [todisk]
                echo(f"{threadn:>3} Error downloading: {url}", 0, 1)
                log.append(f"&gt; Error downloading: {url}")
        echothreadn.remove(threadn)
        download.task_done()
download = Queue()
for i in range(8):
    t = Thread(target=echosession, args=(download,))
    t.daemon = True
    t.start()



def cd(file, makedirs=False, preview=False):
    threadn = 0
    url = file["url"] if preview else file.pop("url")
    todisk = mf + file["name"]
    if rule := [v for k, v in customdir.items() if k in url]:
        name, ext = os.path.splitext(file["name"])
        name = name.rsplit("/", 1)
        if len(name) == 2:
            folder = name[0] + "/"
            name = name[1]
        else:
            folder = ""
            name = name[0]
        prepend, append = explicate(rule[0]).split("*")
        todisk = f"""{folder}{prepend}{name}{append}{ext}""".replace("\\", "/") # "\\" in file["name"] can work like folder after prepend
        ondisk = os.path.split(todisk)[0]
        if not preview and not os.path.exists(ondisk):
            if makedirs or [explicate(x) for x in exempt if explicate(x) == os.path.split(todisk)[0] + "/"]:
                os.makedirs(ondisk)
            else:
                print(f" Error downloading: {url}")
                error[0] += [todisk]
                url = ""
    elif not os.path.exists(mf):
        os.makedirs(mf)
    if not preview:
        if makedirs and not os.path.exists(os.path.split(todisk)[0]):
            os.makedirs(os.path.split(todisk)[0])
        file.update({"name":todisk, "edited":file["edited"]})
    return [url, todisk, file["edited"]]



FAVORITE = batchfile
def downloadtodisk(htmlassets, makedirs=False):
    filelist = []
    error[0] = []
    for file in htmlassets["filelist"]:
        filelist += cd(file, makedirs)
    if error[0]:
        print(f"""\n There is at least one of the bad custom dir rules (non-existent dir), add new rule e.g. "{os.path.split(error[0][0])[0] + "/"}" to allow creating this dir.\n""")



    if not filelist:
        print("Filelist is empty!")
        return
    html = []
    log = []



    if len(filelist) == 3:
        get(filelist[0], todisk=filelist[1])
        return
    queued = {}
    files = iter(filelist)
    for onserver in files:
        ondisk = next(files)
        edited = next(files)
        if not onserver:
            continue
        if conflict := [k for k in queued.keys() if ondisk.lower() == k.lower()]:
            ondisk = conflict[0]
        queued.update({ondisk: [onserver] + (queued[ondisk] if queued.get(ondisk) else [])})



    threadn = 0
    for ondisk, onserver in queued.items():
        threadn += 1
        echothreadn.append(threadn)
        download.put((threadn, html, log, ondisk, onserver))
    download.join()
    title(batchfile, True)



def met(p, n):
    if n[1] and p.endswith(n[1]) or n[2] and not p.endswith(n[2]) or n[3] and p.startswith(n[3]) or n[4] and not p.startswith(n[4]) or n[5] and not n[5][0] <= len(p) <= n[5][1]:
        return
    return True



def carrot(x, asset, new, n):
    a = ""
    aa = ""
    p = ""
    d = asset.copy()
    i = ""
    ii = True
    cc = False
    carets = []
    z = [0, x]
    while True:
        cp = False
        z = z[-1].split("*", 1)
        if z[0].startswith("^"):
            carets += [z[0].split("^", 1)[1]]
            if len(z) == 2:
                continue
            z[0] = ""
            cc = True
        if len(z) == 2 and not z[0] and not z[1]:
            if met(d[0], n):
                asset[0] = ""
                new += [["", d[0]]]
            return
        elif len(z) == 2 and not z[0]:
            y = ["", d[0]]
        elif not z[0]:
            y = [d[0], ""]
        elif not len(y := d[0].split(z[0], 1)) == 2:
            return
        if len(z) == 2 and not z[1]:
            if met(y[1], n):
                asset[0] = ""
                new += [[y[0], y[1]]]
            return
        if carets:
            carets.reverse()
            c = y.copy()
            cz = ""
            for caret in carets:
                if not len(c := c[0].rsplit(caret, 1)) == 2:
                    return
                if cc:
                    y[1] = c[1]
                    cc = False
                cz = caret if cc else caret + c[1] + cz
            aa += c[0] + cz
            if ii:
                i = c[0]
                ii = False
            y[0] = c[1]
            cp = True
            carets = []
        if len(z) == 2:
            d[0] = y[1]
            aa += y[0] + z[0]
            if ii:
                i = y[0]
                ii = False
        else:
            p = y[0]
            if cp:
                y[0] = ""
            if not met(p, n):
                p = ""
                d[0] = y[1]
                a = aa + y[0] + z[0]
            elif ii:
                d[0] = y[1]
                a = i + y[0]
            else:
                d[0] = y[1]
                a = i
            if p and n[0]:
                p = n[0][0] + p + n[0][1]
            new += [[a, p]]
            return True, d



def carrots(data, x, any=True, cw=[]):
    p = []
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
    for asset in data:
        while True:
            p = carrot(x, asset, new, n)
            if not p or not any:
                break
            asset = p[1]
        new += [asset]
    data = new
    return data



def nest(d, z):
    ds = []
    for k in z[0][0].split(" > "):
        x = k.split(" >> ")
        if not x[0]:
            continue
        if x[0] in d:
            d = d[x[0]]
            if len(x) == 2:
                d = json.loads(d)
                if x[1] in d:
                    d = d[x[1]]
                else:
                    return ds
        else:
            return ds
    if len(z[0]) == 1:
        dt = []
        for x in z[1]:
            dc = d
            if not x["key"]:
                continue
            y = x["key"].split(" > ")
            for z in y:
                if dc and z in dc:
                    dc = dc[z]
                    if "cw" in x and x["cw"]:
                        dc = dc.join(x["cw"])
                elif "error" in x and x["error"]:
                    kill(0, x["error"])
                else:
                    return ds
            if "value" in x and not any(c for c in x["value"] if c == str(dc)):
                return ds
            dt += [str(dc)]
        ds = [dt]
    else:
        for x in d:
            ds += nest(x, [z[0][1:], z[1]])
    return ds
def nested(d, z):
    z[0] = z[0].split(" > 0")
    return nest(d, z)



def peanut(x, cw=[], a=False):
    if len(x := x.rsplit(" customize with ", 1)) == 2:
        cw = x[1].rsplit("*", 1)
        if not len(cw) == 2:
            kill("There is no asterisk while customizing a pick.")
    x = x[0]
    if not "*" in x:
        a = True
    return x, cw, a



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



def saint(name):
    return "".join(i for i in name if i not in "\"/:*?<>|")[:200]



def page_assets(queue):
    while True:
        threadn, page, more, htmlassets = queue.get()
        pick = scraper[[x for x in scraper.keys() if page.startswith(x)][0]]
        if x := pick["urlfix"]:
            for y in x[1]:
                page = x[0] + carrots([[page, ""]], y, False)[-2][1] + x[2]
        if not pick["ready"]:
            print(f" Visiting {page}")
        if pick["send"]:
            for x in pick["send"]:
                fetch(x[0], stderr="Error sending data", data=str(x[1]).encode('utf-8'))
        referer = x[0] if (x := [v for k, v in referers.items() if k in page]) else ""
        if data := get(page, headers={'Referer':referer, 'Origin':referer}, stderr="Error or dead (update cookie or referer if these are required to view)"):
            data = data.decode("utf-8").replace("\n ", "").replace("\n", "")
        else:
            break
        db = ""
        if pick["body"]:
            body = ""
            for z in pick["body"]:
                z, cw, a = peanut(z)
                if a:
                    if not db:
                        db = opendb(data)
                    z = z.rsplit(" > ", 1)
                    for d in nested(db, [z[0], [{"key":z[-1], "error":""}]]):
                        body += d[0]
                else:
                    body += "".join(x[0] for x in carrots([[data, ""]], z, False, cw))
            body = body.replace("\n ", "").replace("\n", "")
            for x in pick["replace"]:
                body = body.replace(x[0], x[1])
            body = [[body, ""]]
        else:
            for x in pick["replace"]:
                data = data.replace(x[0], x[1])
            body = [[data, ""]]
        if not folder[0]:
            if pick["folder"]:
                for y in pick["folder"]:
                    for z in y[1:]:
                        z, cw, a = peanut(z, ["", "/"])
                        if a:
                            if not db:
                                db = opendb(data)
                            z = z.rsplit(" > ", 1)
                            for d in nested(db, [z[0], [{"key":z[-1], "error":""}]]):
                                folder[0] += d[0]
                        elif y[0]["alt"]:
                            if len(c := carrots(body, z, False, cw)) == 2:
                                folder[0] += c[-2][1]
                                body = [["".join(x[0] for x in c), ""]]
                        else:
                            if len(c := carrots([[page, ""]], z, False, cw)) == 2:
                                folder[0] += c[-2][1]
            if pick["saveurl"]:
                htmlassets["page"] = {"url":page, "name":saint(folder[0] + folder[0].rsplit("/", 2)[-2] + ".URL"), "edited":0}
        if pick["pages"]:
            for y in pick["pages"]:
                for z in y[1:]:
                    z, cw, a = peanut(z)
                    if a:
                        if not db:
                            db = opendb(data)
                        z = z.rsplit(" > ", 1)
                        pages = nested(db, [z[0], [{"key":z[-1], "error":""}]])
                        if pages and not pages[0][0] == "None":
                            more += [p[0] if y[0]["alt"] else page + p[0] for p in pages if not p[0] == page and not page + p[0] == page]
                    else:
                        pages = carrots(body, z, True, cw)
                        more += [p[1] if y[0]["alt"] else page + p[1] for p in pages if not p[1] == page and not page + p[1] == page]
                        body = [["".join(x[0] for x in pages), ""]]
        filelist = []
        if pick["file"] or pick["file2"]:
            after = False
            pos = 0
            for p in [pick["file"], pick["file2"]]:
                for y in p:
                    na = True
                    for z in y[1:]:
                        z, cw, a = peanut(z)
                        if a:
                            pos += 1
                            if not db:
                                db = opendb(data)
                            f = z.rsplit(" > ", 1)
                            if pick["choose"]:
                                c = pick["choose"][pos-1].rsplit(" = ", 1)
                                c[0] = c[0].replace(f[0], "", 1).split(" > ", 1)[1]
                                c[1] = c[1].split(" > ")
                            else:
                                c = ["", []]
                            meta = []
                            name = []
                            name2 = []
                            for z in pick["name"]:
                                if not z[0]["alt"]:
                                    meta += [z[1:]]
                                    continue
                                z, cwf, a = peanut(z[pos])
                                z = z.rsplit(" > ", 1)
                                if f[0] == z[0]:
                                    name += [{"key":z[-1], "cw":[cwf[0], cwf[1] + "".join(name2)] if name2 else cwf, "error":"there's no name asset found in dictionary for this file."}]
                                    name2 = []
                                else:
                                    name2 += [nested(db, [z[0], [{"key":z[-1], "cw":cwf, "error":"there's no name asset found in dictionary for this file."}]])[0][0]]
                            files = nested(db, [f[0], [{"key":c[0], "value":c[1]}, {"key":f[-1], "cw":cw}] + name])
                            if c[1]:
                                cf = []
                                for cc in c[1]:
                                    if [k := x[1:] for x in files if x[0] == cc]:
                                        cf = k
                                        break
                                files = [cf]
                            if not files or not files[0]:
                                break
                            for z in name2:
                                for file in files:
                                    file += [z]
                            for file in files:
                                name = "".join(file[1:])
                                if e := pick["extfix"]:
                                    e, cwx, a = peanut(e, [".", ""])
                                    if len(ext := carrots([[file[0], ""]], e, False, cwx)) == 2 and not name.endswith(ext := ext[-2][1]):
                                        name += ext
                                for m in meta:
                                    m2 = ""
                                    for z in m:
                                        z, cwx, a = peanut(z)
                                        if len(n := carrots([[file[0], ""]], z, False, cwx)) == 2:
                                            m2 += n[-2][1]
                                    name = m2 + name
                                filelist += [{"url":file[0], "name":saint(folder[0] + name), "edited":0}]
                        else:
                            assets = carrots(body, z, pick["files"], cw)
                            file = ""
                            for asset in assets:
                                if after:
                                    file = asset[1]
                                if file:
                                    if not y[0]["alt"]:
                                        file = page + file
                                    name = ""
                                    for x in pick["name"]:
                                        na = True
                                        for z in x[1:]:
                                            z, cw, a = peanut(z)
                                            if a:
                                                continue
                                            elif x[0]["alt"]:
                                                v = asset[0]
                                                if len(n := carrots([[v, ""]], z, True, cw)) >= 2:
                                                    name += n[-2 if after else 0][1]
                                                    na = False
                                            else:
                                                v = file
                                                if len(n := carrots([[v, ""]], z, False, cw)) == 2:
                                                    name += n[-2][1]
                                                    na = False
                                        if na:
                                            kill(threadn, f"""there's no match for name asset: {x[1:]} in""", view=v)
                                    if pick["extfix"]:
                                        e, cw, a = peanut(e, [".", ""])
                                        if len(ext := carrots([[file, ""]], e, False, cw)) == 2 and not name.endswith(ext := ext[-2][1]):
                                            name += ext
                                    filelist += [{"url":file, "name":saint(folder[0] + parse.unquote(name)), "edited":0}]
                                file = asset[1]
                        if not pick["files"] and not na:
                            break
                after = True
            if not filelist and not pick["ready"]:
                print(f"{tcolorr} No files found in this page (?) Check pattern, add more file pickers, check for bad asterisks in other pickers.{tcolorx}")
        if filelist and not pick["ready"]:
            for file in filelist:
                x = cd(file, preview=True)
                print(tcolorb + x[0] + tcolorr + " -> " + tcolorg + x[1] + tcolorx)
            ready[0] = False
        htmlassets["filelist"] += filelist
        echothreadn.remove(threadn)
        queue.task_done()
    echothreadn.remove(threadn)
    queue.task_done()
queue = Queue()
for i in range(8):
    t = Thread(target=page_assets, args=(queue,))
    t.daemon = True
    t.start()



folder = [""]
ready = [True]
def scrape(page):
    htmlassets = {"page":"", "filelist":[]}
    threadn = 0
    folder[0] = ""
    pages = iter([page])
    more = []
    while True:
        for url in pages:
            threadn += 1
            echothreadn.append(threadn)
            queue.put((threadn, url, more, htmlassets))
        queue.join()
        pages = set(filter(None, more))
        if not pages:
            break
        pages = iter(pages)
        more = []
    title(batchfile, True)

    if htmlassets["filelist"]:
        if not ready[0]:
            print(f""" ({tcolorb}Download file {tcolorr}-> {tcolorg}to disk{tcolorx}) - Add scraper instruction "ready" in {rulefile} to stop previews for this site (C)ontinue""")
            if not choice("c") == 1:
                kill(0)
        downloadtodisk(htmlassets, makedirs=True)
        if x := htmlassets["page"]:
            x = cd(x, preview=True)
            with open(x[1], 'w') as f:
                f.write(f"""[InternetShortcut]
URL={x[0]}""")
    return True



def whsm(file):
    f = Image.open(file)
    try:
        w, h = f.size
        s = os.path.getsize(file)
        m = hashlib.md5(f.tobytes()).hexdigest()
        #with open(file, 'rb') as f: print(f"{m}\n{hashlib.md5(f.read()).hexdigest()}")
    except:
        raise
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
            accu.append(f"{hash} {file}")
            if filevs and filevs == hash:
                print(f"{file}\nSame file found! (C)ontinue")
                choice("c", "2e")
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



def todb(m, filevs=""):
    savread = opensavr(sav)
    savwrite = open(sav, 'ab')
    filelist = []
    error[0] = []
    title("Top directory")
    print("\n - - - - Top - - - -")
    for file in next(os.walk(m))[2]:
        if not file.lower().endswith(tuple(imagefile)):
            continue
        if (file := f"{m}/{file}") in savread:
            continue
        else:
            filelist += [file]
    scanthread(filelist, filevs, savwrite)



    for subfolder in next(os.walk(m))[1]:
        filelist = []
        title(subfolder)
        print("\n - - - - " + subfolder + " - - - -")
        for root, folders, files in os.walk(f"{m}/{subfolder}"):
            for file in files:
                if not file.lower().endswith(tuple(imagefile)):
                    continue
                if (file := f"{m}/{os.path.relpath(root, m)}/{file}") in savread:
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
    return append.join(os.path.splitext(filename) if filename.count(".") > 1 else [filename, ""])



def container(file, label):
    if HTMLserver:
        if os.path.exists(batchdir + file.replace(batchdir, "")):
            file = file.replace(batchdir, "").replace("#", "%23").replace("\\", "/")
        else:
            return f"""<div class="frame"><div class="edits">Rebuild HTML with<br />{batchfile} in another<br />dir is required to view</div>{label}</div> """
    else:
        file = "file:///" + file.replace("#", "%23")
    return f"""<div class="frame"><a class="fileThumb" href="{file}"><img class="lazy" data-src="{file}"></a><br />{label}</div>
"""



def new_html(builder, imgsize=200):
    return """<!DOCTYPE html>
<html>
<script>
var Expand = function(c, t) {
  if(!c.naturalWidth)
  {
    return setTimeout(Expand, 10, c, t);
  }
  c.style.maxWidth = "100%";
  c.style.display = "";
  t.style.display = "none";
  t.style.opacity = "";
};

var Expander = function(e) {
  var t = e.target;
  if(t.parentNode.classList.contains("fileThumb")) {
    e.preventDefault();
    if(t.hasAttribute("data-src")) {
      var c = document.createElement("img");
      c.setAttribute("src", t.parentNode.getAttribute("href"));
      c.style.display = "none";
      t.parentNode.appendChild(c);
      t.style.opacity = "0.75";
      setTimeout(Expand, 10, c, t);
    } else {
      var a = t.parentNode;
      a.firstChild.style.display = "";
      a.removeChild(t);
      a.offsetTop < window.pageYOffset && a.scrollIntoView({top: 0, behavior: "smooth"});
    }
  }
};

document.addEventListener("click", Expander);

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
    if(geistauge) {
      var s = new Image();
      s.src = t.parentNode.getAttribute("href");

      c = document.createElement("canvas");
      c.style = cs;
      c.setAttribute("id", "quicklook")
      c.width = s.width
      c.height = s.height
      context = c.getContext("2d")
      var cgl = document.createElement("canvas");
      gl = cgl.getContext("webgl2")

      var m = new Image();
      m.src = t.parentNode.parentNode.parentNode.childNodes[1].childNodes[0].getAttribute("href");
      if(m.src == s.src) {
        context.fillRect(0, 0, s.width, s.height);
      } else {
        s.onload = function () {
          if (geistauge == "reverse") {
            m.onload = difference(m, s.width, s.height, s, context, gl, side=true);
          } else if (geistauge == "tangerine") {
            m.onload = difference(s, s.width, s.height, m, context, gl, side=true);
          } else {
            m.onload = difference(s, s.width, s.height, m, context, gl);
          }
        }
      }
      t.parentNode.appendChild(c);
    } else if(edge) {
      var s = new Image();
      s.src = t.parentNode.getAttribute("href");

      c = document.createElement("canvas");
      c.style = cs;
      c.setAttribute("id", "quicklook")
      c.width = s.width
      c.height = s.height
      context = c.getContext("2d")

      s.onload = function () {
        edgediff(s, s.width, s.height, context);
      }
      t.parentNode.appendChild(c);
    } else {
      c = document.createElement("img");
      c.style = cs;
      c.setAttribute("id", "quicklook")
      c.setAttribute("src", t.parentNode.getAttribute("href"));
      t.parentNode.appendChild(c);
    }
    let listener = () => {
      setTimeout(function(){t.parentNode.removeChild(c);}, 40);
      t.removeEventListener("mouseleave", listener);
    }
    t.addEventListener("mouseleave", listener);
  }
}

document.addEventListener("mouseover", quicklook);



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

function difference(s, cw, ch, m, context, gl, side=false) {
  context.drawImage(s, 0, 0, cw, ch);
  rgb = context.getImageData(0, 0, cw, ch);
  context.drawImage(m, 0, 0, cw, ch);
  rgb2 = context.getImageData(0, 0, cw, ch);
  if(side){
    darkside(rgb.data, rgb2.data)
  } else {
    darkdiff(rgb.data, rgb2.data)
  }
  context.putImageData(rgb2, 0, 0);
}

var edge = false;
var geistauge = false;
var co = "position:fixed; right:0; top:0; z-index:1; pointer-events:none;"
var cf = co + "max-height: 100vh; max-width: 100vw;";
var cs = co
var fit = false;
function swap(e) {
  var t = e.target;
  if(e.which == 83 && !geistauge) {
    geistauge = true;
    let d = document.getElementById("ge");
    d.classList = "previous";
    t.addEventListener("keyup", function(k) {
      if(k.which == 83) {
        d.classList = "next";
        geistauge = false;
      }
    });
  } else if(e.which == 65 && !geistauge) {
    geistauge = "reverse";
    let d = document.getElementById("ge");
    d.classList = "reverse";
    t.addEventListener("keyup", function(k) {
      if(k.which == 65) {
        d.classList = "next";
        geistauge = false;
      }
    });
  } else if(e.which == 68 && !geistauge) {
    geistauge = "tangerine";
    let d = document.getElementById("ge");
    d.classList = "tangerine";
    t.addEventListener("keyup", function(k) {
      if(k.which == 68) {
        d.classList = "next";
        geistauge = false;
      }
    });
  } else if(e.which == 87 && !edge) {
    edge = true;
    let d = document.getElementById("ed");
    d.classList = "previous";
    t.addEventListener("keyup", function(k) {
      if(k.which == 87) {
        d.classList = "next";
        edge = false;
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
    d.classList = "previous";
    t.addEventListener("keyup", function(k) {
      if(k.which == 16) {
        d.classList = "next";
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

function previewe(e, a) {
  if (e.classList.contains("next")) {
    e.classList = "previous";
    e.setAttribute("data-html-original", e.innerHTML);
    e.innerHTML = a;
    edge = true;
  } else {
    e.classList = "next";
    e.innerHTML = e.getAttribute("data-html-original");
    edge = false;
  }
}

function previewg(e, a, r=false, t=false) {
  if (e.classList.contains("next")) {
    e.classList = "previous";
    e.setAttribute("data-html-original", e.innerHTML);
    e.innerHTML = a;
    geistauge = true;
  } else if(e.classList.contains("previous")) {
    if(r) {
      e.classList = "reverse";
      e.innerHTML = r;
      geistauge = "reverse";
    } else {
      e.classList = "next";
      e.innerHTML = e.getAttribute("data-html-original");
      geistauge = false;
    }
  } else if(e.classList.contains("reverse")) {
    if(t) {
      e.classList = "tangerine";
      e.innerHTML = t;
      geistauge = "tangerine";
    } else {
      e.classList = "next";
      e.innerHTML = e.getAttribute("data-html-original");
      geistauge = false;
    }
  } else {
    e.classList = "next";
    e.innerHTML = e.getAttribute("data-html-original");
    geistauge = false;
  }
}

function previewf(e, a) {
  if (e.classList.contains("next")) {
    e.classList = "previous";
    e.setAttribute("data-html-original", e.innerHTML);
    e.innerHTML = a;
    fit = true;
    cs = cf
  } else {
    e.classList = "next";
    e.innerHTML = e.getAttribute("data-html-original");
    cs = co
    fit = false;
  }
}

function hidePosts(text, display) {
  var x = document.getElementsByClassName("container");
  for (var i=0; i < x.length; i++) {
    if (x[i].textContent.toLowerCase().includes(text.toLowerCase())) {
      x[i].style.display = display[0];
    } else {
      x[i].style.display = display[1];
    }
  }
}

function lazyload() {
  var lazyloadImages;

  lazyloadImages = document.querySelectorAll(".lazy");
  var imageObserver = new IntersectionObserver(function(entries, observer) {
    entries.forEach(function(entry) {
      if (entry.isIntersecting) {
        var image = entry.target;
        image.src = image.dataset.src;
        imageObserver.unobserve(image);
      }
    });
  });

  lazyloadImages.forEach(function(image) {
    image.style.height = "200px"
    image.style.width = "auto"
    imageObserver.observe(image);
  });
}
</script>
<style>
.edits{background-color:#330717; border:4px solid #912; border-radius:16px; color:#f45; padding:12px; margin:6px; word-wrap:break-word;}
.frame{display:inline-block; vertical-align:top; position:relative;}
.previous{background-color:#f1f1f1; color:black; border:none; border-radius:10px; cursor:pointer;}
.reverse{background-color:#8822dd; color:black; border:none; border-radius:10px; cursor:pointer;}
.tangerine{background-color:#ffaa33; color:black; border:none; border-radius:10px; cursor:pointer;}
.next{background-color:#444; color:white; border:none; border-radius:10px; cursor:pointer;}
.sources{font-size:80%; width:200px;}
</style>
<body>
<meta charset="utf-8"/>
<style>
html,body
{background-color:#0c0c0c; color:#9900ff; font-family:consolas; font-size:14px;}
</style>""" + f"""<div style="display:block; height:10px;"></div><div style="background:#0c0c0c; height:20px; border-radius: 0 0 12px 0; position:fixed; padding:6px; top:0px; z-index:1;">
<button id="ed" class="next" onclick="previewe(this, 'Edge Detect')">Edge Detect</button>
<button id="ge" class="next" onclick="previewg(this, 'Geistauge !', 'Geistauge <', 'Geistauge >')">Geistauge</button>
<button id="fi" class="next" onclick="previewf(this, 'Fit')">Fit</button>
<input class="next" type="text" oninput="hidePosts(this.value, ['block', 'none']);" style="padding-left:8px; padding-right:8px; width:140px;" placeholder="Search">
<input class="next" type="text" oninput="hidePosts(this.value, ['none', 'block']);" style="padding-left:8px; padding-right:8px; width:140px;" placeholder="Ignore">
<button class="next" onclick="hidePosts('', ['block', 'none'])">&times;</button></div>
<p>
{builder}</body>
<script>
lazyload();
</script>
</html>"""



def label(m, s, html=False):
    if m[3] == s[3]:
        label = "Identical"
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



def tohtml(delete=False):
    start = time.time()
    print("\n Now compiling duplicates to HTML . . . kill this CLI to cancel.\n")
    builder = ""
    counter = 1
    db = opensav(sav).splitlines()
    db.sort(key=lambda s: s.split(" ", 1)[1].replace("\\", ""))
    datagroup = {}
    for line in db:
        phash, file = line.split(" ", 1)
        datagroup.setdefault(phash, [])
        datagroup[phash].append(file)
    dbz = opensav(savx).splitlines()
    for v in datagroup.values():
        if len(v := [x for x in v if os.path.exists(x)]) < 2:
            continue
        Perfectexemption = True
        for file in v:
            if not any(word in file for word in exempt):
                Perfectexemption = False
        if Perfectexemption:
            continue
        v = iter(v)
        builder2 = ""
        m = [0, 0, 0, 0]
        file = next(v)
        file2 = next(v)
        while True:
            s = [0, 0, 0, 0]
            for line in dbz:
                if file2 in line:
                    s = list(map(int, line.split(" ", 3)[:3])) + [line.split(" ", 4)[3]]
                    break
            if not s[3]:
                s = whsm(file2)
                dbz += [" ".join([str(x) for x in s]) + f" {file2}"]
            if not m[3]:
                for line in dbz:
                    if file in line:
                        m = list(map(int, line.split(" ", 3)[:3])) + [line.split(" ", 4)[3]]
                        break
                if not m[3]:
                    m = whsm(file)
                    dbz += [" ".join([str(x) for x in m]) + f" {file}"]
            if m[3] == s[3] and delete:
                if not any(word in file2 for word in exempt):
                    if os.path.exists(file2):
                        os.remove(file2)
                elif not any(word in file for word in exempt):
                    if os.path.exists(file):
                        os.remove(file)
                    file = file2
                if file2 := next(v, None):
                    continue
                else:
                    break
            builder2 += container(file2, label(m, s, html=True))
            if not (file2 := next(v, None)):
                break
        if builder2:
            builder += f"""<div class="container">
{container(file, f"{m[0]} x {m[1]}")}{builder2}</div>

"""
            counter += 1
        if counter % 512 == 0:
            morehtml = htmlfile.replace(".html", f" {int(counter/512)}.html")
            with open(morehtml, 'wb') as f:
                f.write(bytes(new_html(builder), 'utf-8'))
            with open(savx, 'wb') as f:
                f.write(bytes("\n".join(dbz), 'utf-8'))
            print("\"" + morehtml + "\" created!")
            builder = ""
            counter += 1
    morehtml = htmlfile.replace(".html", f" {int(counter/512) + 1}.html")
    with open(morehtml, 'wb') as f:
        f.write(bytes(new_html(builder), 'utf-8'))
    with open(savx, 'wb') as f:
        f.write(bytes("\n".join(dbz), 'utf-8'))
    print("\"" + morehtml + "\" created!")
    print(f"total runtime: {time.time()-start}")



def compare(m):
    try:
        hash = ph(m)
    except:
        print(" Featuring image is corrupted.")
        sys.exit()
    s = input("Drag'n'drop the reference image and hit Enter to compare, reference folder to scan, or empty to find in database: ").rstrip().strip('\"')
    start = time.time()
    if not s:
        db = opensav(sav).splitlines()
        found = False
        indb = False
        print()
        for line in db:
            hash2, s = line.split(" ", 1)
            if hash == hash2:
                if m != s:
                    if os.path.exists(s):
                        print(f"{hash2} {s} (still exists)")
                    else:
                        print(f"{hash2} {s} (non-existent)")
                    found = True
                else:
                    indb = True
        if not found and indb:
            print(" Featuring image is unique! But come on, let's compile HTML from database so you can find duplication faster.")
        elif not found:
            print(" Featuring image is unique! Nothing like it in database!")
        else:
            print(f"{hash} {m} (featuring image)\nSame file found! (C)ontinue")
            choice("c", "2e")
    elif os.path.isdir(s):
        m = s
        todb(m, hash)
    else:
        try:
            hash2 = ph(s)
        except:
            print(" Reference image is corrupted.")
            sys.exit()
        if hash == hash2:
            m = whsm(m)
            print(f"\n Featuring: {m[0]} x {m[1]}\n Reference: {label(m, whsm(s))}")
        else:
            print("\n They're different")
    print(f"total runtime: {time.time()-start}\n")



def delmode(m):
    file = parse.unquote(m.replace("file:///", "").replace("http://localhost:8886/", batchdir))
    if os.path.exists(file):
        delfiles = [file]
        choice(bg="4c")
    else:
        choice(bg="08")
        return
    print("\n This is my shortcut to delete the file alongside browser.\n Enter another file:/// local url then/or (V)iew/(R)emove/(D)elete/E(X)it\n Nothing is really deleted until you enter D twice.\n")
    while True:
        file = parse.unquote(input("Add file to delete list: ").rstrip().replace("file:///", "").replace("http://localhost:8886/", batchdir))
        if file.lower() == "x":
            return
        if file.lower() == "v":
            for dfile in delfiles:
                print(dfile)
        elif file.lower() == "r":
            file = parse.unquote(input("Remove file from delete list: ").rstrip().replace("file:///", "").replace("http://localhost:8886/", batchdir))
            while True:
                try:
                    delfiles.remove(file)
                    choice(bg="2a")
                except:
                    choice(bg="08")
                    break
        elif file.lower() == "d" and delfiles:
            choice(bg="4c")
            print("(D)elete again to confirm (A)bort")
            if choice("da") == 1:
                for dfile in delfiles:
                    try:
                        os.remove(dfile)
                    except:
                        continue
                skull()
                delfile = []
                return
        elif os.path.exists(file):
            choice(bg="4c")
            delfiles += [file]
        else:
            choice(bg="08")



def takeme(file, folder):
    if not os.path.exists(folder + file):
        try:
            os.rename(mf + file, folder + file)
        except:
            if not os.path.exists(cd):
                os.makedirs(cd)
            if not os.path.exists(cd + file):
                os.rename(mf + file, cd + file)
            else:
                print(f"""I want to (D)elete source file because destination file already exists:
 source:      {mf}{file}
 destination: {cd}{file}""")
                if choice("d") == 1:
                    os.remove(mf + file)
    else:
        print(f"""I want to (D)elete source file because destination file already exists:
 source:      {mf}{file}
 destination: {folder}{file}""")
        if choice("d") == 1:
            os.remove(mf + file)



def finish_organize():
    for file in next(os.walk(mf))[2]:
        if len(c := carrots(file, rename, multi=False)) == 2 and not c[0][0] and not c[-1][0]:
            ondisk = mf + file
            with open(ondisk, 'rb') as f:
                s = f.read()
            ext = os.path.splitext(ondisk)[1].lower()
            m = hashlib.md5(s).hexdigest()
            file = m + ext
            if not os.path.exists(m + ext):
                os.rename(ondisk, mf + file)
            else:
                print(f"I want to (D)elete {ondisk} because {file} already exists.")
                if choice("d") == 1:
                    os.remove(ondisk)
        for name, folder in organize.items():
            if folder[1]:
                found = False
                for fn in name.split(", "):
                    if fnmatch(file, fn):
                        found = True
                        break
                if not found:
                    takeme(file, folder[0])
            elif fnmatch(file, filename):
                takeme(file, folder[0])
                break



if filelist:
    m = filelist[0]
    if len(filelist) > 1:
        print(f"""
 Only one input at a time is allowed! It's a good indication that you should reorganize better
 if there are too many folders to input and you don't want to use input's parent.{'''

 Geistauge is also disabled which can be a reminder that this is not the setup to run Geistauge.
 May I suggest having another copy of this script with Geistauge enabled in different directory?''' if not Geistauge else ""}""")
        sys.exit()
    print(f"""Loading featuring {"folder" if os.path.isdir(m) else "image"} successful: "{m}" """)
    if not Geistauge:
        print("\n GEISTAUGE: Maybe not.")
        sys.exit()
    if os.path.isdir(m):
        todb(m)
    else:
        compare(m)
else:
    if htmlassets["filelist"]:
        downloadtodisk(htmlassets)
    else:
        print(f" No urls in {textfile}! Doing so will enable parallel downloading urls and resume the interrupted downloads.")
mainmenu()
while True:
    m = input("Enter valid input or ready to (O)rganize, (H)elp: ").rstrip().replace("\"", "")
    if m == "h":
        quicktutorial()
    elif m == "v":
        m = input("Enter URL: ").rstrip()
        if m.startswith("http"):
            referer = x[0] if (x := [v for k, v in referers.items() if k in m]) else ""
            html = get(m, headers={'Referer':referer, 'Origin':referer}, stderr="Page loading failed successfully")
            if html:
                html = "\n".join([s.rstrip() if s.rstrip() else "" for s in html.decode("utf-8").replace("	", "    ").splitlines()])
                print(html)
                # with open(f"{batchdir}{batchname} (source).html", 'wb') as f:
                #     f.write(bytes(html, 'utf-8'))
        else:
            choice(bg=True)
    elif any(word for word in scraper.keys() if m.startswith(word)):
        scrape(m)
    elif m.startswith("http") and not m.startswith("http://localhost"):
        if m.endswith("/"):
            choice(bg=True)
            print(" I don't have a scraper for that!")
        else:
            downloadtodisk({"filelist":[{"url":m, "name":parse.unquote(m.split("/")[-1])[:200], "edited":0}]})
    elif m == "o":
        if os.path.exists(mf):
            finish_organize()
        else:
            choice(bg=True)
            print(f" {tmf} doesn't exist! Nothing to organize.")
    elif m == "b":
        if Browser and HTMLserver:
            os.system(f"""start "" "{Browser}" "http://localhost:8886/{batchname} 1.html" """)
        elif Browser:
            os.system(f"""start "" "{Browser}" "{batchdir}{batchname} 1.html" """)
        else:
            choice(bg=True)
            print(f""" No browser selected! Please check the "Browser =" setting in {rulefile}""")
            continue
        print("""
 HTML key/mouse listener:
  > W - Edge detect when previewing an image
  > A - Geistauge: compare to left when previewing an image
  > S - Geistauge: bright both when previewing an image
  > D - Geistauge: compare to right (this) when previewing an image
  > Shift - Fit image to screen

 "Edge detect" and "Geistauge" are canvas features and they require "Access-Control-Allow-Origin: *" (try HTML server)
""")
    elif m == "c":
        if not Geistauge:
            choice(bg=True)
            print(" GEISTAUGE: Maybe not.")
        else:
            tohtml()
    elif m == "d":
        if not Geistauge:
            choice(bg=True)
            print(" GEISTAUGE: Maybe not.")
        else:
            choice(bg="4c")
            if not input("Drag'n'drop and enter my SAV file: ").rstrip().replace("\"", "") == f"{batchdir}{sav}":
                continue
            skull()
            tohtml(delete=True)
    elif m.startswith("file:///") or m.startswith("http://localhost"):
        if not Geistauge:
            choice(bg=True)
            print(" GEISTAUGE: Maybe not.")
        else:
            delmode(m)
    elif os.path.exists(m):
        if not Geistauge:
            choice(bg=True)
            print(" GEISTAUGE: Maybe not.")
        elif os.path.isdir(m):
            todb(m)
        else:
            compare(m)
    else:
        choice(bg=True)



"""
::MacOS - Install Python 3 then open Terminal and enter:
open /Applications/Python\ 3.9/Install\ Certificates.command
sudo python3 -m pip install --upgrade pip
sudo python3 -m pip install PySocks
sudo python3 -m pip install Pillow
sudo python3 -m pip install numpy
sudo python3 -m pip install opencv-python
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
::if exist Lib\site-packages\cv2 (echo.) else (goto install)
::if exist Lib\site-packages\numpy\ (echo.) else (goto install)
if exist Lib\site-packages\PIL (goto start) else (echo.)

:install
echo  Hold on . . . I need to install the missing packages.
if exist "Scripts\pip.exe" (echo.) else (color %stopcolor% && echo  PIP.exe doesn't seem to exist . . . Please install Python properly^^! I must exit^^! && pause>nul && exit)
python -m pip install --upgrade pip
Scripts\pip.exe install PySocks
::Scripts\pip.exe install opencv-python
::Scripts\pip.exe install numpy==1.19.3
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
