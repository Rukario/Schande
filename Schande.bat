@echo off && goto loaded

import os, sys, getpass, smtplib, ssl, socket, socks, time, zlib, json
from datetime import datetime
from http import cookiejar
from http.server import SimpleHTTPRequestHandler, HTTPServer
from queue import Queue
from socketserver import ThreadingMixIn
from threading import Thread
from urllib import parse, request
from codecs import encode, decode
from random import random
# from selenium import webdriver

# Local variables
if len(sys.argv) > 3:
    filelist = list(filter(None, sys.argv[1].split("//")))
    pythondir = sys.argv[2].replace("\\\\", "\\")
    # batchdir = sys.argv[3].replace("\\\\", "\\") # grabs "start in" argument
else:
    filelist = []
    pythondir = ""
batchdir = os.path.dirname(os.path.realpath(__file__)).replace("\\", "/")
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
specialfile = ["gallery.html", "partition.json"]

busy = [False]
cooldown = [False]
echothreadn = []
error = [[]]
offlineprompt = [False]
offlinepromptx = [False]
newfilen = [0]
retryall = [False]
retries = [0]
retryx = [False]
seek = [False]
sf = [0]
skiptonext = [False]

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



def title(echo):
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
 - - - - Drag'n'drop / Input - - - -
 + Drag'n'drop and enter folder to add to database.
 + Drag'n'drop and enter image file to compare with another image, while scanning new folder, or find in database.

 - - - - Schande HTML - - - -
 + Press B to launch HTML in your favorite browser.
 | Press G to re/compile HTML from database (your browser will be used as comparison GUI).
 | Press D to delete non-exempted duplicate images immediately with a confirmation.
 +  > One first non-exempt in path alphabetically will be kept if no other duplication are exempted.

 - - - - Input - - - -
 + Enter file:/// or http://localhost url to enter delete mode.
 | Enter http(s):// to download file. Press V for page source viewing.
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
 |  "visit"              visit especially for cookies before redirection.
 |  "urlfix ...*... with ...*..." permanent redirector.
 |  "url ...*... with ...*... redirector. Original url will be used for statement and scraper loop.
 |  "send X Y"           send data (X) to url (Y) or to current page url (no Y) before accessing page.
 |  "part ...*..."       partitioning the page.
 |  "key ... > ..."      pick identifier and start HTML builder, attribute partition, keywords, and files to this.
 |  "html ...*..."       pick article from page/partition for HTML builder. API: pick content for HTML-based pickers.
 |                       HTML-based file pickers will look through articles for inline files too.
 |  "replace ...*... with ...*..." find'n'replace before start picking in page/partition.
 |  "title ...*..."      pick and use as folder from first scraped page.
 |  "folder ...*..."     from url.
 |  "choose .. > .. = X" choose file by a match in another key. "X > X" for multiple possibilities in priority order.
 |  "expect ...*..."     put scraper into loop, exit when a pattern is found in page. "unexpect" for opposition.
 |  "message ..."        customize alert message. Leave blank to exit loop without alerting.
 |  "file(s) ...*..."    pick first or all files to download, "relfile(s)" for relative urls.
 |  "name ...*..."       pick name for each file downloading. There's no file on disk without a filename!
 |  "meta ...*..."       from url.
 |  "extfix ...*..."     fix name without extension from url (detected by ending mismatch).
 |  "pages ...*..."      pick more pages to scrape in parallel, "relpages" for relative urls.
 |  "saveurl"            save first scraped page url as URL file in same directory where files are downloading.
 |
 | Page picker will make sure all pages are unique to visit, but older pages can cause loophole.
 | Repeat a picker with different pattern for multiple possibilities/actions.
 | folder#, title#, name#, meta# to assemble assets together sequentially.
 | key# for title (key1), timestamp (key2) then keywords (key3 each) for HTML builder.
 |  "...*..."            HTML-based picker.
 |  "... > ..."          API/QS-based picker.
 | API/QS (Query String) supported pickers: part, html, key, expect, files, name, pages.
 | Magic key: " > 0 > " to iterate a list, " > * > " to iterate all within, " >> " to load a dictionary from inside QS.
 | During API each file picker must be accompanied by name picker and all HTML-based name/meta pickers must descend.
 |
 | Manipulating asterisk:
 |  > Multiple asterisks to pick the last asterisk better and/or to discard others.
 |  > Arrange name and file pickers if needed to follow their position in page. file before -> name -> file after.
 |  > Arrange html and file pickers whether to download inline file or filelist on conflict of the same file name.
 |  > First with match will be chosen first. This doesn't apply to html and plural pickers such as files, pages.
 |  > Name match closest to the file will be chosen. file before -> name to before -> name to after -> file after.
 |
 | Right-to-left:
 |  > Use caret "^..." to get the right match. Do "^..*^.." or "..*^.." (greedy), don't put asterisk after caret ^*
 |  > The final asterisk of the non-caret will be greedy and chosen. First asterisk if every asterisk has caret.
 |  > Using caret will finish with one chosen match.
 |
 | For difficult asterisks:
 |  "X # letters" (# or #-#) after any picker so the match is expected to be that amount.
 |  "X ends/starts with X" after any picker. "not" for opposition.
 |
 | Protip: replace picker to discard what you don't need before complicating pickers with many asterisks or carets.
 | Customize the chosen one with prepend and append using "X customize with ...*..." after any picker.
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
def tidy(offset, append):
    if offset == 0:
        data = append + "\n\n" + "\n".join(rules)
    else:
        data = "\n".join(rules[:offset]) + "\n" + append + "\n" + "\n".join(rules[offset:])
    with open(rulefile, 'wb') as f:
        f.write(bytes(data, 'utf-8'))
    return data.splitlines()
offset = 0
settings = ["Launch HTML server = No", "Browser = ", "Mail = ", "Geistauge = No", "Python = " + pythondir, "Proxy = socks5://"]
for setting in settings:
    if not rules[offset].replace(" ", "").startswith(setting.replace(" ", "").split("=")[0]):
        if not offset and not "#" in "".join(rules):
            rules = tidy(offset, setting)
        else:
            rules = tidy(offset, setting)
        print(f"""Added new setting "{setting}" to {rulefile}!""")
    offset += 1



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
            print("Success sending!                           ")
        except:
            print("Sending failed! Try turning on https://myaccount.google.com/lesssecureapps and make sure user and password is correct.")
    elif not d:
        print("You should consider using Mail if you want alert over Mail.")
    else:
        print("Dismissing                                 ")
    print(" | " + "\n | ".join(message.splitlines()) + "\n")



def alert(m, s, d=False):
    title("! " + batchfile + monitor())
    send(s, m, d)
    if not d:
        print("(C)ontinue")
        choice("c", bg="2e")



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
        if keys: el = os.system(f"choice /c:{keys} /n")
        if bg: os.system("color %color%")
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



def input(i="Your Input: ", c=False):
    sys.stdout.write(str(i))
    sys.stdout.flush()
    if c:
        return choice(c)
    else:
        return sys.stdin.readline()



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
        fx[0][x if threadn else 0] = fp[ff%257]
    s = time.time()
    if echofriction[0] < int(s*eps):
        echofriction[0] = int(s*eps)
        stdout[1] = "\n\033]0;" + f"""[{newfilen[0]} new{f" after {retries[0]} retries" if retries[0] else ""}] {FAVORITE} {''.join(fx[0][:len(echothreadn) if threadn else 1])} {MBs[0]} MB/s""" + "\007\033[A"
    else:
        echofriction[0] = int(s*eps)
    if Bstime[0] < int(s):
        Bstime[0] = int(s)
        MBs[0] = f"{(Bs[0]+Bytes)/1048576:.2f}"
        Bs[0] = Bytes
    else:
        Bs[0] += Bytes
fx = [[fp[0]]*8]



pg = [0]
tp = " ․⁚⋮456789abcdef⍿"
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
    return f""" ꊱ {" ꊱ ".join(["".join(x) for x in ts])} ꊱ"""



def status():
    return f"""[{newfilen[0]} new{f" after {retries[0]} retries" if retries[0] else ""}] """



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
Mail = y(rules[2])
Geistauge = y(rules[3], True)
proxy = y(rules[5])
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
        Mail += [getpass.getpass(prompt=f" {Mail[0]}'s password (automatic if saved as third address): ")]
        echo("", b=1)
else:
    print(" MAIL: NONE")
if Geistauge:
    try:
        import numpy, cv2, hashlib
        print(" GEISTAUGE: ON")
    except:
        print(f" GEISTAUGE: Additional prerequisites required - please execute in another command prompt with:\n\n{sys.exec_prefix}\Scripts\pip.exe install numpy\n{sys.exec_prefix}\Scripts\pip.exe install opencv-python")
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

def saint(name=False, url=False):
    if url:
        url = list(parse.urlsplit(url))
        url2 = url[2].rsplit("/", 1)
        url[2] = url2[0] + "/" + parse.quote(url2[1])
        return parse.urlunsplit(url)
    else:
        return "".join(i for i in name.replace("/", "\\") if i not in "\":*?<>|")[:200]



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
        s["send"] += [[rule[1], rule[2]] if len(rule) == 2 else [rule[1], []]]
    elif rule[0].startswith("visit"):
        s["visit"] = True
    elif rule[0].startswith("part "):
        s["part"] += [rule[0].split("part ", 1)[1]]
    elif rule[0].startswith("html "):
        s["html"] += [rule[0].split("html ", 1)[1]]
        if s["file"] or s["file2"]:
            s["inlinefirst"] = False
    elif rule[0].startswith("key"):
        at(s["key"], rule[0].split("key", 1)[1])
    elif rule[0].startswith("folder"):
        at(s["folder"], rule[0].split("folder", 1)[1], False)
    elif rule[0].startswith("title"):
        at(s["folder"], rule[0].split("title", 1)[1])
    elif rule[0].startswith("expect"):
        at(s["expect"], rule[0].split("expect", 1)[1])
    elif rule[0].startswith("unexpect"):
        at(s["expect"], rule[0].split("unexpect", 1)[1], False)
    elif rule[0].startswith("dismiss"):
        s["dismiss"] = True
    elif rule[0].startswith("message "):
        s["message"] += [rule[0].split("message ", 1)[1]]
    elif rule[0].startswith("choose "):
        s["choose"] += [rule[0].split("choose ", 1)[1]]
    elif rule[0].startswith("file "):
        at(s["file2" if s["name"] else "file"], rule[0].split("file", 1)[1])
    elif rule[0].startswith("relfile "):
        at(s["file2" if s["name"] else "file"], rule[0].split("relfile", 1)[1], False)
    elif rule[0].startswith("files "):
        at(s["file2" if s["name"] else "file"], rule[0].split("files", 1)[1])
        s["files"] = True
    elif rule[0].startswith("relfiles "):
        at(s["file2" if s["name"] else "file"], rule[0].split("relfiles", 1)[1], False)
        s["files"] = True
    elif rule[0].startswith("owner "):
        s["owner"] += [rule[0].split("owner ", 1)[1]]
    elif rule[0].startswith("name"):
        at(s["name"], rule[0].split("name", 1)[1])
    elif rule[0].startswith("meta"):
        at(s["name"], rule[0].split("meta", 1)[1], False)
    elif rule[0].startswith("extfix "):
        s["extfix"] = rule[0].split("extfix ", 1)[1]
    elif rule[0].startswith("urlfix "):
        rule = rule[0].split(" ", 1)[1].split(" with ", 1)
        x = rule[1].split("*", 1)
        s["urlfix"] = [x[0], [rule[0]], x[1]]
    elif rule[0].startswith("url "):
        rule = rule[0].split(" ", 1)[1].split(" with ", 1)
        x = rule[1].split("*", 1)
        s["url"] = [x[0], [rule[0]], x[1]]
    elif rule[0].startswith("pages "):
        at(s["pages"], rule[0].split("pages", 1)[1])
    elif rule[0].startswith("relpages "):
        at(s["pages"], rule[0].split("relpages", 1)[1], False)
    elif rule[0].startswith("checkpoint"):
        s["checkpoint"] = True
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
mozilla = {}
exempt = []
mag = []
med = []
scraper = {}
def new_scraper():
    return {"replace":[], "send":[], "visit":False, "part":[], "html":[], "inlinefirst":True, "expect":[], "dismiss":False, "message":[], "key":[], "folder":[], "choose":[], "file":[], "file2":[], "files":False, "owner":[], "name":[], "extfix":"", "urlfix":[], "url":[], "pages":[], "checkpoint":False, "saveurl":False, "ready":False}
scraper.update({"void":new_scraper()})
site = "void"
ticks = []
for rule in rules:
    if not rule or rule.startswith("#"):
        continue
    elif rule.startswith('.'):
        mag += [rule]
    elif rule.startswith('!.'):
        med += [rule.replace("!.", ".", 1)]
    elif len(rule := rule.split(" seconds rarity ")) == 2:
        ticks += [[int(x) for x in rule[0].split("-")]]*int(rule[1].split("%")[0])
    elif len(rule := rule[0].split(" for ")) == 2:
        if rule[0].startswith("md5"):
            rename += [rule[1]]
        elif rule[0].startswith("Mozilla/5.0"):
            mozilla.update({rule[1]: rule[0]})
        elif rule[1].startswith("http"):
            if rule[0].startswith("http"):
                referers.update({rule[1]: rule[0]})
            elif not len(explicate(rule[0]).split("*")) == 2:
                print("\n There is at least one of the bad custom dir rules (no asterisk or too many).")
                sys.exit()
            else:
                customdir.update({rule[1]: rule[0]})
        elif rule[1].startswith('.') or rule[1].startswith('www.'):
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



tn = [len(ticks)]
ticking = [False]
def timer(e="", all=True):
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
            echo(f"{e}Reloading in {s-sec} . . .")
            time.sleep(1)
            if pgtime[0] < int(time.time()/5):
                pgtime[0] = int(time.time()/5)
                pg[0] = 0
                title(batchfile + monitor())
            if seek[0]:
                seek[0] = False
                break
        ticking[0] = False
    elif all:
        while ticking[0]:
            time.sleep(0.5)



def retry(stderr):
    # Warning: urllib has slight memory leak
    retryall[0] = False
    while True:
        if not offlineprompt[0]:
            offlineprompt[0] = True
            # raise
            if stderr:
                if offlinepromptx[0]:
                    e = f"{retries[0]} retries (Q)uit trying "
                    if cooldown[0]:
                        timer(e)
                    else:
                        echo(e)
                else:
                    title(status() + FAVORITE)
                    print(f"{stderr} (R)etry? (A)lways (N)ext")
                    el = choice("ran", True)
                    if el == 1:
                        retryall[0] = True
                    elif el == 2:
                        offlinepromptx[0] = True
                    elif el == 3:
                        offlineprompt[0] = False
                        return
            else:
                echo(f"{retries[0]} retries (S)kip one, wait it out, or press X to quit trying . . . ")
            time.sleep(0.5)
            title(status() + FAVORITE)
            retries[0] += 1
            offlineprompt[0] = False
            return True
        elif retryall[0]:
            return True
        time.sleep(0.5)



#, "Accept-Encoding":"gzip, deflate, br", "DNT":1, "Upgrade-Insecure-Requests":1
def fetch(url, context=None, headers={'User-Agent':'Mozilla/5.0'}, stderr="", dl=0, threadn=0, data=None):
    while True:
        try:
            headers.update({'Range':f'bytes={dl}-', 'Accept':"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"})
            resp = request.urlopen(request.Request(saint(url=url), headers=headers, data=data), context=context)
            break
        except:
            if stderr or retryx[0] and not skiptonext[0]:
                if not retry(stderr):
                    return
            else:
                skiptonext[0] = False
                return
    return resp



def get(url, todisk="", utf8=False, conflict=[[], []], context=None, headers={'User-Agent':'Mozilla/5.0', 'Referer':"", 'Origin':""}, headonly=False, stderr="", threadn=0):
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
                        if utf8:
                            try:
                                return data.decode("utf-8")
                            except:
                                return zlib.decompress(data, 16+zlib.MAX_WBITS).decode("utf-8")
                        else:
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
            referer = x[0] if (x := [v for k, v in referers.items() if url.startswith(k)]) else ""
            ua = x[0] if (x := [v for k, v in mozilla.items() if url.startswith(k)]) else 'Mozilla/5.0'
            if n:
                if not conflict[0]:
                    conflict[0] += [todisk]
                todisk = f" ({n+1}).".join(todisk.rsplit(".", 1))
                conflict[0] += [todisk]
            if os.path.exists(todisk):
                echo(f"{threadn:>3} Already downloaded: {todisk}", 0, 1)
            elif el := get(url, todisk=todisk, conflict=conflict, headers={'User-Agent':ua, 'Referer':referer, 'Origin':referer}, threadn=threadn):
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
        todisk = f"""{folder}{prepend}{name}{append}{ext}""" # "\\" in file["name"] can work like folder after prepend
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
    todisk = todisk.replace("\\", "/")
    if not preview:
        if makedirs and not os.path.exists(os.path.split(todisk)[0]):
            os.makedirs(os.path.split(todisk)[0])
        file.update({"name":todisk, "edited":file["edited"]})
    return [url, todisk, file["edited"]]



FAVORITE = batchfile
def downloadtodisk(htmlassets, makedirs=False):
    filelist = []
    filelisthtml = []
    htmlpart = htmlassets["partition"]
    for key in htmlpart.keys():
        for file in htmlpart[key]["files"]:
            if not file["name"]:
                print(f""" I don't have a scraper for {file["url"]}""")
            else:
                filelist += [cd(file, makedirs) + [key]]
        for html in htmlpart[key]["html"]:
            if len(html) == 2 and html[1]:
                if not html[1]["name"]:
                    print(f""" I don't have a scraper for {html[1]["url"]}""")
                else:
                    filelisthtml += [cd(html[1], makedirs) + [key]]
    if htmlassets["inlinefirst"]:
        filelist = filelisthtml + filelist
    else:
        filelist += filelisthtml
    if error[0]:
        print(f"""\n There is at least one of the bad custom dir rules (non-existent dir).""")
        done = []
        for x in error[0]:
            d = os.path.split(x)[0] + "\\"
            if d in done:
                continue
            else:
                done += [d]
            print(f"  {d}")
        print("\n Add following dirs as new rules (preferably only for those intentional) to allow auto-create dirs (developer note: currently unimplemented).")

    if not filelist:
        print("Filelist is empty!")
        return
    html = []
    log = []

    if len(filelist) == 1:
        echothreadn.append(0)
        download.put((0, [], [], filelist[0][1], filelist[0][0]))
        download.join()
        return
    queued = {}

    lastfilen = newfilen[0]
    dirs = set()
    htmldirs = {}
    for file in filelist:
        fp = file[3]
        dir = file[1].rsplit("/", 1)[0] + "/"
        if not dir in dirs and not dirs.add(dir):
            if os.path.exists(dir + "partition.json"):
                with open(dir + "partition.json", 'r') as f:
                    htmldirs.update({dir:json.loads(f.read())})
            else:
                htmldirs.update({dir:{}})
        if dir in htmldirs and fp in htmldirs[dir]:
            if len(htmldirs[dir][fp]["keywords"]) < 2:
                continue
            k = htmldirs[dir][fp]["keywords"][1]
            if not file[2] == "0" and not file[2] == k:
                if os.path.exists(file[1]):
                    if editisreal:
                        old = ".old_file_" + k
                        os.rename(file[1], ren(file[1], old))
                        thumbnail = ren(file[1], append="_small")
                        if os.path.exists(thumbnail):
                            os.rename(thumbnail, ren(thumbnail, old))
                    else:
                        print(f"  Edited on server: {file[1]}")
                        continue
            else:
                continue

        if not file[0]:
            continue
        if conflict := [k for k in queued.keys() if file[1].lower() == k.lower()]:
            file[1] = conflict[0]
        queued.update({file[1]: [file[0]] + (queued[file[1]] if queued.get(file[1]) else [])})

    threadn = 0
    for ondisk, onserver in queued.items():
        threadn += 1
        echothreadn.append(threadn)
        download.put((threadn, html, log, ondisk, onserver))
    download.join()
    title(status() + batchfile)

    if len(htmlpart.keys()) > 1:
        newfile = False if lastfilen == newfilen[0] else True
        if error[0]:
            for x in error[0]:
                htmlpart.pop(os.path.basename(x).split(".", 1)[0], None)
        print(f"""{"Nothing new to download." if not newfile else ""}{" There are failed downloads I will try again later." if error[0] else ""}""")

        for dir in htmldirs.keys():
            if not (x := os.path.exists(dir + "gallery.html")) or newfile:
                orphfiles = []
                for file in next(os.walk(dir))[2]:
                    if not file.endswith(tuple(specialfile)):
                        orphfiles += [file]
                tohtml(dir, htmlassets, set(orphfiles).difference([x[1].rsplit("/", 1)[-1] for x in filelist]))
    error[0] = []



def met(p, n):
    if n[1] and p.endswith(n[1]) or n[2] and not p.endswith(n[2]) or n[3] and p.startswith(n[3]) or n[4] and not p.startswith(n[4]) or n[5] and not n[5][0] <= len(p) <= n[5][1]:
        return
    return True



def carrot(array, z, new, n):
    a = ""
    aa = ""
    p = ""
    new_array = [array[0], array[1]]
    ii = False
    cc = False
    cs = []
    z = [0, z]
    pc = False
    while True:
        ac = False
        z = z[-1].split("*", 1)
        if z[0].startswith("^"):
            cs += [z[0].split("^", 1)[1]]
            if len(z) == 2:
                continue
            z[0] = ""
            cc = True
        if len(z) == 2 and not z[0] and not z[1]:
            if met(new_array[0], n):
                array[0] = ""
                new += [["", new_array[0]]]
            return
        elif len(z) == 2 and not z[0]:
            y = ["", new_array[0]]
        elif not z[0]:
            y = [new_array[0], ""]
        elif not len(y := new_array[0].split(z[0], 1)) == 2:
            return
        if len(z) == 2 and not z[1]:
            if met(y[1], n):
                array[0] = ""
                new += [[y[0], y[1]]]
            return
        if cs:
            cs.reverse()
            c = [y[0], y[1]]
            sc = ""
            for cz in cs:
                if not len(c := c[0].rsplit(cz, 1)) == 2:
                    return
                if cc:
                    y[1] = c[1]
                    c[1] = ""
                    cc = False
                sc = cz + c[1] + sc
            aa += c[0] + sc
            if not ii:
                ii = True, c[0]
            y[0] = c[0] if pc else c[1]
            ac = True
            cs = []
        if len(z) == 2:
            new_array[0] = y[1]
            aa += y[0] + z[0]
            if not ii:
                ii = True, y[0]
            pc = True
        else:
            p = y[0]
            if ac:
                y[0] = ""
            if not met(p, n):
                p = ""
                new_array[0] = y[1]
                a = aa + y[0] + z[0]
            else:
                new_array[0] = y[1]
                a = ii[1] if ii else y[0]
            if n[0]:
                p = n[0][0] + p + n[0][1]
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
    return data



def grab(d, z):
    dt = []
    for x in z[1]:
        dc = d
        if not x[0]:
            continue
        elif x[0] == "0":
            return dt + ["0"]
        for y in x[0].split(" > "):
            y = y.split(" >> ")
            if not y[0]:
                continue
            if dc and y[0] in dc:
                try:
                    dc = dc[y[0]]
                except:
                    print(f"{tcolorr}Try again with >> {y[0]} instead of > {y[0]}{tcolorx}")
                    return
                if len(y) == 2:
                    dc = json.loads(dc)
                    if dc and y[1] in dc:
                        dc = dc[y[1]]
            elif x[3]:
                kill(0, x[3])
            else:
                return
        if x[1] and not any(c for c in x[1] if c == str(dc)):
            return
        if x[2]:
            dt += [str(dc.join(x[2]))]
        else:
            dt += [str(dc)]
    return dt



def nest(d, z):
    ds = []
    n = 1 if z[0][0] else 0
    for k in z[0][0].split(" > "):
        x = k.split(" >> ")
        if not x[0]:
            continue
        if x[0] == "*":
            for y in d.values():
                ds += nest(y, [[z[0][0].split("* > ", 1)[1]] + z[0][1:], z[1]])
            return ds
        if x[0] in d:
            try:
                d = d[x[0]]
            except:
                print(f"{tcolorr}Try again with >> {x[0]} instead of > {x[0]}{tcolorx}")
                return
            if len(x) == 2:
                d = json.loads(d)
                if x[1] in d:
                    d = d[x[1]]
                else:
                    return ds
        else:
            return ds
    if len(z[0]) == 1:
        if n:
            dx = []
            for dc in d:
                if dt := grab(dc, z):
                    dx += [dt]
            if dx:
                return dx
        else:
            if dt := grab(d, z):
                return [dt]
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
    if " > " in x:
        x = x.rsplit(" > 0", 1)
        if len(x) == 1:
            x = ["", x[0]]
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



def carrot_files(threadn, assets, htmlpart, key, na, pick, alt, filelist, after):
    file = ""
    for asset in assets:
        if after:
            file = asset[1]
        if file:
            if not alt:
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
            filelist += [[key, {"url":file, "name":saint(folder[0] + parse.unquote(name)), "edited":htmlpart[key]["keywords"][1] if key in htmlpart and len(htmlpart[key]["keywords"]) > 1 else "0"}]]
        file = asset[1]
    return assets, na



def pick_files(threadn, data, db, part, htmlpart, pick, pickf, filelist, pos, after):
    for y in pickf:
        na = True
        for z in y[1:]:
            f, cw, a = peanut(z)
            if pick["key"] and pick["key"][0]:
                kx = pick["key"][0]
            else:
                kx = [0, 0]
            if a:
                pos += 1
                if not db:
                    db = opendb(data)
                for k in kx[1:]:
                    if not k:
                        key = [["0", 0, 0, 0]]
                    else:
                        k = peanut(k)[0]
                        if f[0] == k[0]:
                            key = [[k[1], 0, 0, 0]]
                        else:
                            continue
                    if pick["choose"]:
                        c = pick["choose"][pos-1].rsplit(" = ", 1)
                        c[0] = peanut(c[0])[0][1]
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
                        z, cwf, _ = peanut(z[pos])
                        if f[0] == z[0]:
                            name += [[z[1], 0, [cwf[0], cwf[1] + "".join(name2)] if name2 else cwf, "there's no name asset found in dictionary for this file."]]
                            name2 = []
                        else:
                            name2 += [nested(db, [z[0], [[z[1], 0, cwf, "there's no name asset found in dictionary for this file."]]])[0][0]]
                    files = nested(db, [f[0], [[c[0], c[1], 0, 0], [f[1], 0, cw, 0]] + name + key])
                    if c[1]:
                        cf = []
                        for cc in c[1]:
                            if [cx := x[1:] for x in files if x[0] == cc]:
                                cf = cx
                                break
                        files = [cf]
                    if not files or not files[0]:
                        continue
                    for z in name2:
                        for file in files:
                            file += [file[1]]
                            file[1] = z
                    for file in files:
                        name = file[1]
                        key = file[2]
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
                        filelist += [[key, {"url":file[0], "name":saint(folder[0] + name), "edited":htmlpart[key]["keywords"][1] if key in htmlpart and len(htmlpart[key]["keywords"]) > 1 else "0"}]]
            else:
                for p in part:
                    key = "0"
                    for k in kx[1:]:
                        if k and len(d := carrots([p], k, False)) == 2:
                            key = d[0][1]
                            break
                    na = carrot_files(threadn, carrots([p], f, pick["files"], cw), htmlpart, key, na, pick, y[0]["alt"], filelist, after)[1]
                for k in htmlpart.keys():
                    if x := htmlpart[k]["html"]:
                        x, na = carrot_files(threadn, carrots(x, f, pick["files"], cw), htmlpart, k, na, pick, y[0]["alt"], filelist, after)
                        htmlpart[k]["html"] = x
            if not pick["files"] and not na:
                break
    return pos



def rp(x, p):
    for r in p:
        x = "".join(y[0] + y[1] for y in carrots([[x, ""]], r[0], True, r[1].split("*", 1)))
    return x



def page_assets(queue):
    while True:
        data = ""
        url = ""
        threadn, page, more, htmlassets = queue.get()
        htmlpart = htmlassets["partition"]
        pick = scraper[[x for x in scraper.keys() if page.startswith(x)][0]]
        htmlassets["inlinefirst"] = pick["inlinefirst"]
        pg[0] += 1
        if pick["visit"]:
            fetch(page, stderr="Error visiting visit page")
        if x := pick["urlfix"]:
            for y in x[1]:
                page = x[0] + carrots([[page, ""]], y, False)[-2][1] + x[2]
        if not pick["ready"]:
            print(f" Visiting {page}")
        if x := pick["url"]:
            for y in x[1]:
                url = x[0] + carrots([[page, ""]], y, False)[-2][1] + x[2]
        referer = x[0] if (x := [v for k, v in referers.items() if page.startswith(k)]) else ""
        ua = x[0] if (x := [v for k, v in mozilla.items() if page.startswith(k)]) else 'Mozilla/5.0'
        if pick["send"]:
            for x in pick["send"]:
                post = x[1] if x[1] else url
                data = fetch(post, stderr="Error sending data", data=str(x[0]).encode('utf-8'))
            if not data:
                print(f" Error visiting {page}")
                break
            data = data.read()
        if not data and (data := get(url if url else page, utf8=True, headers={'User-Agent':ua, 'Referer':referer, 'Origin':referer}, stderr="Error or dead (update cookie or referer if these are required to view)", threadn=threadn)):
            data = data.replace("\n ", "").replace("\n", "")
        elif not data:
            print(f" Error visiting {page}")
            break
        title(batchfile + monitor())
        db = ""
        if pick["expect"]:
            pos = 0
            for y in pick["expect"]:
                for z in y[1:]:
                    z, cw, a = peanut(z)
                    if a:
                        pos += 1
                        if pick["choose"]:
                            c = pick["choose"][pos-1].rsplit(" = ", 1)
                            c[0] = peanut(c[0])[0][1]
                            c[1] = c[1].split(" > ")
                        else:
                            c = [[], []]
                        result = nested(json.loads(data), [z[0], [[c[0], c[1], 0, 0], [z[1], 0, 0, 0]]])
                        if y[0]["alt"] and result:
                            if not pick["dismiss"] and Browser:
                                os.system(f"""start "" "{Browser}" "{page}" """)
                            alert(page, pick["message"][pos-1] if pick["message"] and len(pick["message"]) >= pos else "As expected", pick["dismiss"])
                        elif not y[0]["alt"] and not result:
                            if not pick["dismiss"] and Browser:
                                os.system(f"""start "" "{Browser}" "{page}" """)
                            alert(page, pick["message"][pos-1] if pick["message"] and len(pick["message"]) >= pos else "Not any longer", pick["dismiss"])
                        else:
                            more += [page]
                            timer("Not quite as expected! ", False)
                    else:
                        if y[0]["alt"] and z in part[0][0]:
                            if not pick["dismiss"] and Browser:
                                os.system(f"""start "" "{Browser}" "{page}" """)
                            alert(page, pick["message"][pos-1] if pick["message"] and len(pick["message"]) >= pos else "As expected", pick["dismiss"])
                        elif not y[0]["alt"] and not z in part[0][0]:
                            if not pick["dismiss"] and Browser:
                                os.system(f"""start "" "{Browser}" "{page}" """)
                            alert(page, pick["message"][pos-1] if pick["message"] and len(pick["message"]) >= pos else "Not any longer", pick["dismiss"])
                        else:
                            more += [page]
                            timer("Not quite as expected! ", False)
        if pick["part"]:
            part = []
            for z in pick["part"]:
                part += [[x[1], ""] for x in carrots([[data, ""]], z, True)]
        else:
            part = [[data, ""]]
        if not folder[0]:
            if pick["folder"]:
                for y in pick["folder"]:
                    for z in y[1:]:
                        z, cw, a = peanut(z, ["", "\\"])
                        if a:
                            if not db:
                                db = opendb(data)
                            for d in nested(db, [z[0], [[z[1], 0, 0, 0]]]):
                                folder[0] += d[0]
                        elif y[0]["alt"]:
                            folder[0] += [x[1] for x in carrots(part, z, False, cw) if x[1]][0]
                            # part = [[x[0], ""] for x in c]
                            # part = [["".join(x[0] for x in c), ""]]
                        else:
                            folder[0] += [x[1] for x in carrots([[page, ""]], z, False, cw) if x[1]][0]
            if pick["saveurl"]:
                htmlassets["page"] = {"url":page, "name":saint(folder[0] + folder[0].rsplit("\\", 2)[-2] + ".URL"), "edited":0}
        if pick["pages"]:
            for y in pick["pages"]:
                for z in y[1:]:
                    z, cw, a = peanut(z)
                    if a:
                        if not db:
                            db = opendb(data)
                        pages = nested(db, [z[0], [[z[1], 0, 0, 0]]])
                        if pages and not pages[0][0] == "None":
                            for p in pages:
                                if not p[0] == page and not page + p[0] == page:
                                    px = p[0] if y[0]["alt"] else page + p[0]
                                    more += [px]
                                    if pick["checkpoint"]:
                                        print(f"Checkpoint: {px}\n")
                    else:
                        for p in [x[1] for x in carrots(part, z, True, cw) if x[1]]:
                            if not p[1] == page and not page + p[1] == page:
                                px = p[1] if y[0]["alt"] else page + p[1] 
                                more += [px]
                                if pick["checkpoint"]:
                                    print(f"Checkpoint: {px}\n")
        if pick["html"]:
            html = []
            if pick["key"] and pick["key"][0]:
                kx = pick["key"][0]
            else:
                kx = [0, 0]
            for z in pick["html"]:
                z, cw, a = peanut(z)
                if a:
                    if not db:
                        db = opendb(data)
                    for k in kx[1:]:
                        if not k:
                            key = [["0", 0, 0, 0]]
                        else:
                            k = peanut(k)[0]
                            if z[0] == k[0]:
                                key = [[k[1], 0, 0, 0]]
                            else:
                                continue
                        for d in nested(db, [z[0], [[z[1], 0, 0, 0]] + key]):
                            html += [[d[0], d[1]]]
                else:
                    new_part = []
                    for p in part:
                        key = "0"
                        for k in kx[1:]:
                            if len(d := carrots([[p[0], ""]], k, False)) == 2:
                                key = d[0][1]
                                break
                        c = carrots([[p[0], ""]], z, False, cw)
                        html += [[c[0][1], key]]
                        new_part += [["".join(x[0] for x in c), ""]]
                    part = new_part
            for x in html:
                if not x[1] in htmlpart:
                    htmlpart.update({x[1]:{"html":[], "keywords":[], "files":[]}})
                htmlpart[x[1]].update({"html":[[rp(x[0], pick["replace"]), ""]] + htmlpart[x[1]]["html"]})
            keywords = {}
            kpos = 0
            for k in pick["key"][1:]:
                for z in k[1:]:
                    z, cw, a = peanut(z)
                    if a:
                        if not db:
                            db = opendb(data)
                        for k in kx[1:]:
                            if not k:
                                key = [["0", 0, 0, 0]]
                            else:
                                k = peanut(k)[0]
                                if z[0] == k[0]:
                                    key = [[k[1], 0, 0, 0]]
                                else:
                                    continue
                            if not key[0][0] in keywords:
                                keywords.update({key[0][0]: ["", ""]})
                            for d in nested(db, [z[0], [[z[1], 0, 0, 0]] + key]):
                                keywords[d[1]] += [d[0]]
                    else:
                        for p in part:
                            key = "0"
                            for k in kx[1:]:
                                if len(d := carrots([[p[0], ""]], k, False)) == 2:
                                    key = d[0][1]
                                    break
                            if not key in keywords:
                                keywords.update({key: ["", ""]})
                            if kpos < 2:
                                if not keywords[key][kpos] and len(x := carrots([p], z, False, cw)) == 2:
                                    keywords[key][kpos] = x[0][1]
                            else:
                                for x in carrots([p], z, True, cw)[:-1]:
                                    keywords[key] += [x[1]]
                kpos += 1
            for x in keywords.keys():
                if not x in htmlpart:
                    htmlpart.update({x:{"html":[], "keywords":[], "files":[]}})
                htmlpart[x]["keywords"] += [rp(y, pick["replace"]) for y in keywords[x]]
        else:
            for p in part:
                p[0] = rp(p[0], pick["replace"])
        filelist = []
        pos = 0
        if pick["file"]:
            pos = pick_files(threadn, data, db, part, htmlpart, pick, pick["file"], filelist, pos, False)
        if pick["file2"]:
            pos = pick_files(threadn, data, db, part, htmlpart, pick, pick["file2"], filelist, pos, True)
        if pick["file"] or pick["file2"]:
            for file in filelist:
                k = file[0]
                if not k in htmlpart:
                    htmlpart.update({k:{"html":[], "keywords":[], "files":[]}})
                htmlpart[k].update({"files":[file[1]] + htmlpart[k]["files"]})
            if not pick["ready"]:
                x = ""
                for file in filelist:
                    x = cd(file[1], preview=True)
                    print(tcolorb + x[0] + tcolorr + " -> " + tcolorg + x[1] + tcolorx)
                if not x:
                    print(f"{tcolorr} No files found in this page (?) Check pattern, add more file pickers, check for bad asterisks in other pickers.{tcolorx}")
                ready[0] = False
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
def scrape(pages):
    htmlassets = {"page":"", "inlinefirst":True, "partition":{"0":{"html":[], "keywords":[], "files":[]}}}
    folder[0] = ""
    pages = iter(pages)
    while True:
        threadn = 0
        more = []
        visited = set()
        for url in pages:
            threadn += 1
            echothreadn.append(threadn)
            queue.put((threadn, url, more, htmlassets))
        try:
            queue.join()
        except:
            pass
        pages = set(filter(None, more))
        for page in pages:
            if page in visited and not visited.add(page):
                print(f"{tcolorr}Already visited {page} loophole warning{tcolorx}")
                # pages.remove(page)
        if not pages:
            break
        pages = iter(pages)
    title(status() + batchfile)

    if htmlassets["partition"]:
        if not ready[0]:
            htmlpart = htmlassets["partition"]
            if len(htmlpart) > 1 or htmlpart["0"]["html"]:
                print("\n Then create " + tcolorg + folder[0] + "gallery.html" + tcolorx + " with")
                for k in htmlpart.keys():
                    if k == "0" and not htmlpart[k]["files"]:
                        continue
                    print(k)
                    if x := htmlpart[k]["keywords"]:
                        keywords = ", ".join(f"{kw}" for kw in x[2:])
                        print(tcolorb + (x[0] if len(x) > 0 and x[0] else "No title for " + k) + tcolor + " Timestamp: " + (x[1] if len(x) > 1 else "No timestamp") + tcolorr + " Keywords: " + (keywords if keywords else "None") + tcolorx)
                    for file in htmlpart[k]["files"]:
                        print(tcolorg + file["name"].rsplit("\\")[-1] + tcolorx)
                    if htmlpart[k]["html"]:
                        for html in htmlpart[k]["html"]:
                            if html[0]:
                                print(tcoloro + html[0] + " ", end="")
                                if html[1]:
                                    print(tcolor + html[1] + " ", end="")
                        print(tcolorx)
            sys.stdout.write(f""" ({tcolorb}Download file {tcolorr}-> {tcolorg}to disk{tcolorx}) - Add scraper instruction "ready" in {rulefile} to stop previews for this site (C)ontinue """)
            sys.stdout.flush()
            if not choice("c") == 1:
                kill(0)
        downloadtodisk(htmlassets, makedirs=True)
        if x := htmlassets["page"]:
            with open(cd(x, preview=True)[1], 'w') as f:
                f.write(f"""[InternetShortcut]
URL={x["url"]}""")
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
    m = m.replace("\\", "/")
    savread = opensav(sav)
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
        for dir, folders, files in os.walk(f"{m}/{subfolder}"):
            dir = m + "/" + os.path.relpath(dir, m).replace("\\", "/") + "/"
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
    return append.join(os.path.splitext(filename) if filename.count(".") > 1 else [filename, ""])



def container(ondisk, depth=0, check=True):
    filename = ondisk.rsplit("/", 1)[-1]
    relfile = ondisk.split("/", depth)[-1]
    if filename.lower().endswith(tuple(videofile)):
        data = f"""<div class="frame"><video height="200" autoplay><source src="{relfile.replace("#", "%23")}"></video><div class="sources">{filename}</div></div>\n"""
    elif filename.lower().endswith(tuple(imagefile)):
        if buildthumbnail and not "/Thumbnails/" in relfile:
            thumb = "/Thumbnails/".join(ren(relfile, "_small").rsplit("/", 1))
            if not os.path.exists(mainfolder + thumb):
                try:
                    img = Image.open(ondisk)
                    w, h = img.size
                    if h > 200:
                        img.resize((int(w*(200/h)), 200), Image.ANTIALIAS).save(mainfolder + thumb, subsampling=0, quality=100)
                    else:
                        img.save(mainfolder + thumb)
                except:
                    pass
        else:
            thumb = relfile
        data = f"""<div class="frame"><a class="fileThumb" href="{relfile.replace("#", "%23")}"><img class="lazy" data-src="{thumb.replace("#", "%23")}"></a><div class="sources">{filename}</div></div>\n"""
    elif os.path.exists(ondisk):
        data = f"""<a href=\"{relfile.replace("#", "%23")}"><div class="aqua" style="height:174px; width:126px;">{filename}</div></a>\n"""
        if os.path.exists(ondisk.rsplit(".", 1)[0] + "/"):
            data += f"""<a href="{relfile.rsplit(".", 1)[0].replace("#", "%23")}"><div class="aqua" style="height:174px;"><i class="aqua" style="border-width:0 3px 3px 0; padding:3px; -webkit-transform: rotate(-45deg); margin-top:82px;"></i></div></a>\n"""
    else:
        data = f"""<a href=\"{relfile.replace("#", "%23")}"><div style="display:inline-block; vertical-align:top; border:1px solid #b2b2b2; border-top:1px solid #4c4c4c; border-left:1px solid #4c4c4c; padding:12px; height:174px; width:126px; word-wrap: break-word;">☠️</div></a>\n"""
    return data



def container_c(file, label):
    if HTMLserver:
        if os.path.exists(batchdir + file.replace(batchdir, "")):
            file = file.replace(batchdir, "").replace("#", "%23").replace("\\", "/")
        else:
            return f"""<div class="frame"><div class="edits">Rebuild HTML with<br />{batchfile} in another<br />dir is required to view</div>{label}</div> """
    else:
        file = "file:///" + file.replace("#", "%23")
    return f"""<div class="frame"><a class="fileThumb" href="{file}"><img class="lazy" data-src="{file}"></a><br />{label}</div>
"""



def new_html(builder, title, listurls, imgsize=200):
    if not listurls:
        listurls = "Maybe in another page."
    return """<!DOCTYPE html>
<html>
<meta charset="utf-8"/>
""" + f"<title>{title}</title>" + """
<script>
var Expand = function(c, t) {
  if(!c.naturalWidth) {
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

      if (geistauge == "edge") {
        s.onload = function () {
          edgediff(s, s.width, s.height, context);
        }
      } else {
        var m = new Image();
        m.src = t.parentNode.parentNode.parentNode.childNodes[1].childNodes[0].getAttribute("href");
        if(m.src == s.src) {
          context.fillRect(0, 0, s.width, s.height);
        } else {
          s.onload = function () {
            var cgl = document.createElement("canvas");
            gl = cgl.getContext("webgl2")
            if (geistauge == "reverse") {
              m.onload = difference(m, s.width, s.height, s, context, gl, side=true);
            } else if (geistauge == "tangerine") {
              m.onload = difference(s, s.width, s.height, m, context, gl, side=true);
            } else {
              m.onload = difference(s, s.width, s.height, m, context, gl);
            }
          }
        }
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
    d.innerHTML = "vs left"
    t.addEventListener("keyup", function(k) {
      if(k.which == 83) {
        d.classList = "next";
        d.innerHTML = "Original"
        geistauge = false;
      }
    });
  } else if(e.which == 65 && !geistauge) {
    geistauge = "reverse";
    let d = document.getElementById("ge");
    d.classList = "reverse";
    d.innerHTML = "vs left <"
    t.addEventListener("keyup", function(k) {
      if(k.which == 65) {
        d.classList = "next";
        d.innerHTML = "Original"
        geistauge = false;
      }
    });
  } else if(e.which == 68 && !geistauge) {
    geistauge = "tangerine";
    let d = document.getElementById("ge");
    d.classList = "tangerine";
    d.innerHTML = "vs left >"
    t.addEventListener("keyup", function(k) {
      if(k.which == 68) {
        d.classList = "next";
        d.innerHTML = "Original"
        geistauge = false;
      }
    });
  } else if(e.which == 87 && !geistauge) {
    geistauge = "edge";
    let d = document.getElementById("ge");
    d.classList = "edge";
    d.innerHTML = "Find Edge"
    t.addEventListener("keyup", function(k) {
      if(k.which == 87) {
        d.classList = "next";
        d.innerHTML = "Original"
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
    d.classList = "previous";
    d.innerHTML = "Preview [ ]"
    document.addEventListener("mouseover", quicklook);
    t.addEventListener("keyup", function(k) {
      if(k.which == 16) {
        d.classList = "tangerine";
        d.innerHTML = "Preview 1:1"
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

function previewg(e, a, r=false, t=false, x=false) {
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
  } else if(e.classList.contains("tangerine")) {
    if(x) {
      e.classList = "edge";
      e.innerHTML = x;
      geistauge = "edge";
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

function preview(e, a, f=false) {
  if (e.classList.contains("next")) {
    e.classList = "previous";
    e.setAttribute("data-html-original", e.innerHTML);
    e.innerHTML = a;
    document.addEventListener("mouseover", quicklook);
    fit = true;
    cs = cf
  } else if(e.classList.contains("previous")) {
    if(f) {
        e.classList = "tangerine";
        e.innerHTML = f;
        cs = co
        fit = false;
    } else {
        e.classList = "next";
        e.innerHTML = e.getAttribute("data-html-original");
        cs = co
        document.removeEventListener("mouseover", quicklook);
        fit = false;
    }
  } else {
    e.classList = "next";
    e.innerHTML = e.getAttribute("data-html-original");
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

function hideParts(text, display) {
  var x = document.getElementsByClassName("container");
  for (var i=0; i < x.length; i++) {
    if (x[i].textContent.split("\\n")[2].toLowerCase().includes(text.toLowerCase())) {
      x[i].style.display = display[0];
    } else {
      x[i].style.display = display[1];
    }
  }
}

function orphFiles(n) {
  var x = document.getElementsByClassName("cell");
  for (var i=0; i < x.length; i++) {
    if (x[i].getElementsByClassName('edits').length > 0||n) {
      x[i].style.display = "block";
    } else {
      x[i].style.display = "none";
    }
  }
}

var links = document.getElementsByTagName('a');
for(var i=0; i<links.length; i++)
{links[i].target = "_blank";}

var slideIndex = 1;
showDivs(slideIndex);

function plusDivs(n)
{showDivs(slideIndex += n);}

function currentDiv(n)
{showDivs(slideIndex = n);}

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
    """ + f"""image.style.height = "{imgsize}""" + """px"
    image.style.width = "auto"
    imageObserver.observe(image);
  });
}
</script>
<style>
html,body{background-color:#10100c; color:#088 /*cb7*/; font-family:consolas, courier; font-size:14px;}
a{color:#dc8 /*efdfa8*/;}
a:visited{color:#cccccc;}
.aqua{background-color:#006666; color:#33ffff; border:1px solid #22cccc;}
.aquatext{color:#22cccc}
.carbon, .time{background-color:#10100c; border:4px solid #6a6a66; border-radius:16px;}
.time{color:#ffffff;}
.cell, .files, .mySlides{background-color:#1c1a19; border:none; border-radius:16px;}
.files{background-color:#112230 /*07300f*/; border:4px solid #367 /*192*/; border-radius:16px;}
.edits{background-color:#330717; border:4px solid #912; border-radius:16px; color:#f45;}
.previous{background-color:#f1f1f1; color:black; border:none; border-radius:10px; cursor:pointer;}
.next{background-color:#444; color:white; border:none; border-radius:10px; cursor:pointer;}
.closebtn{background-color:rgba(0, 0, 0, 0.5); color:#fff; border:none; border-radius:10px; cursor:pointer;}

.edits{background-color:#330717; border:4px solid #912; border-radius:16px; color:#f45; padding:12px; margin:6px; word-wrap:break-word;}
.frame{display:inline-block; vertical-align:top; position:relative;}
.previous{background-color:#f1f1f1; color:black; border:none; border-radius:10px; cursor:pointer;}
.reverse{background-color:#63c; color:#d9f; border:none; border-radius:10px; cursor:pointer;}
.tangerine{background-color:#c60; color:#fc3; border:none; border-radius:10px; cursor:pointer;}
.edge{background-color:#261; color:#8c4; border:none; border-radius:10px; cursor:pointer;}
.next{background-color:#444; color:white; border:none; border-radius:10px; cursor:pointer;}
.sources{font-size:80%; width:200px;}

img{vertical-align:top;}
.container{display:block; position:relative;}
.frame{display:inline-block; vertical-align:top;}
.sources{font-size:80%; width:200px;}
.aqua{display:inline-block; vertical-align:top; padding:12px; word-wrap:break-word;}
.carbon, .time, .files, .edits{display:inline-block; vertical-align:top;}
.carbon, .time, .cell, .mySlides, .files, .edits{padding:12px; margin:6px; word-wrap:break-word;}
.mySlides{padding-right:32px;}
.closebtn{position:absolute; top:15px; right:15px;}
</style>
<body>
<div style="display:block; height:20px;"></div><div class="container">
<button class="closebtn" onclick="this.parentElement.style.display='none'">&times;</button>""" + f"""<div class="mySlides">{listurls}</div>
<img id="expandedImg">
</div>
<p>
<div style="display:block; height:10px;"></div><div style="background:#0c0c0c; height:20px; border-radius: 0 0 12px 0; position:fixed; padding:6px; top:0px; z-index:1;">
<button class="next" onclick="currentDiv(1)">Links in this HTML</button>
<button class="next" onclick="resizeImg('{imgsize}px')">1x</button>
<button class="next" onclick="resizeImg('{imgsize*2}px')">2x</button>
<button class="next" onclick="resizeImg('{imgsize*4}px')">4x</button>
<button class="next" onclick="resizeImg('auto')">1:1</button>
<button id="fi" class="next" onclick="preview(this, 'Preview [ ]', 'Preview 1:1')">Preview</button>
<button id="ge" class="next" onclick="previewg(this, 'vs left', 'vs left <', 'vs left >', 'Find Edge')">Original</button>
<button class="next" onclick="hideSources()">Sources</button>
<input class="next" type="text" oninput="hideParts(this.value, ['block', 'none']);" style="padding-left:8px; padding-right:8px; width:140px;" placeholder="Search title">
<input class="next" type="text" oninput="hideParts(this.value, ['none', 'block']);" style="padding-left:8px; padding-right:8px; width:140px;" placeholder="Ignore title">
<button class="next" onclick="orphFiles()">Edits</button>
<button class="next" onclick="hideParts('', ['block', 'none'])">&times;</button>
<button class="next" onclick="orphFiles(1)">&times;</button></div>
<p>
{builder}</body>
<script>
lazyload();
</script>
</html>"""



def tohtml(dir, htmlassets, orphfiles):
    builder = ""
    listurls = ""
    htmlpart = htmlassets["partition"]



    if page := htmlassets["page"]:
        builder += "<h2>Paysite: <a href=\"" + page["url"] + "\">" + page["name"] + "</a></h2>"



    for key in htmlpart.keys():
        htmlx = {}
        files = []
        seen = set()
        for file in htmlpart[key]["files"]:
            if not file["name"] in seen and not seen.add(file["name"]):
                files += [file["name"].rsplit("/", 1)[-1]]
        htmlpart[key]["files"] = files
        for asset in htmlpart[key]["html"]:
            if len(asset) == 2 and asset[1]:
                asset[1]["name"] = asset[1]["name"].rsplit("/", 1)[-1]



    partfile = dir + "partition.json"
    if not os.path.exists(partfile):
        with open(partfile, 'w') as f:
            f.write(json.dumps(htmlpart))
    with open(partfile, 'r', encoding="utf-8") as f:
        relics = json.loads(f.read())
    orphid = iter(relics.keys())
    part = {}
    for id in htmlpart.keys():
        if not id in relics:
            part.update({id:htmlpart[id]})
            continue
        for idx in orphid:
            if not id == idx:
                part.update({idx:relics[idx]})
            else:
                break
        if not relics[id]["html"] or relics[id]["keywords"] < htmlpart[id]["keywords"]:
            part.update({id:htmlpart[id]})
        else:
            part.update({id:relics[id]})
    with open(partfile, 'w') as f:
        f.write(json.dumps(part))



    for file in orphfiles:
        if file.endswith(tuple(specialfile)):
            continue
        id = file.split(".", 1)[0]
        if not id in part.keys():
            id = "0"
        if "orphfiles" in part[id]:
            part[id]["orphfiles"] += [file]
        else:
            part[id]["orphfiles"] = [file]
    if buildthumbnail:
        if not os.path.exists(dir + "Thumbnails/"):
            os.makedirs(dir + "Thumbnails/")
        echo("Building thumbnails . . .")



    for id in part.keys():
        if id == "0":
            if "orphfiles" in part[id]:
                title = "Unorganized"
                content = "No matching partition found for this files. Either partition IDs are not assigned properly in file names or they're just really orphans.\n<p>"
            else:
                continue
        else:
            title = part[id]["keywords"][0] if part[id]["keywords"][0] else "No title for " + id
            content = ""
        new_container = False
        end_container = False
        time = part[id]["keywords"][1] if part[id]["keywords"][1] else "No timestamp"
        keywords = ", ".join(x for x in part[id]["keywords"][2:]) if len(part[id]["keywords"]) > 2 else "None"
        builder += f"""<div class=\"cell\">
<div class="time" id="{id}" style="float:right;"><p>Part ID: {id}<p>{time}<p>Keywords: {keywords}</div>
<h1>{title}</h1>"""
        # if file := part[id]["file"]:
        #     builder += "<div class=\"carbon\">\n"
        #     builder += container(file["name"], 1)
        #     builder += "</div>\n"
        # files = [x for x in part[id]["files"] if not file or not file == x]
        files = [x for x in part[id]["files"]]
        if files:
            builder += "<div class=\"files\">\n"
            for file in files:
                builder += container(file, 1)
            builder += "</div>\n"
        if "orphfiles" in part[id]:
            builder += "<div class=\"edits\">\n"
            for file in part[id]["orphfiles"]:
                builder += container(file, 1)
            builder += "<p>orphaned file(s)</p>\n</div>\n"
        if html := part[id]["html"]:
            for asset in html:
                if len(asset) == 2:
                    if new_container:
                        content += "<div class=\"carbon\">\n"
                        end_container = True
                        new_container = False
                    if asset[1]:
                        content += f"""{asset[0]}{container(asset[1], 1)}"""
                    else:
                        content += asset[0]
                elif end_container:
                    if new_container:
                        content += "<div class=\"carbon\">\n"
                        new_container = False
                    else:
                        new_container = True
                    content += asset[0] + "</div><p>"
                else:
                    content += asset[0]
                    new_container = True
            if "<a href=\"" in content:
                urls = content.split("<a href=\"")
                links = ""
                for link in urls[1:]:
                    link = link.split("\"", 1)[0]
                    links += f"""<a href="{link}">{link}</a><br>"""
                listurls += f"""<p># From <a href="#{id}">#{id}</a> :: {title}<br>{links}\n"""
            builder += f"<p>{content}\n"
        else:
            builder += "<br><div class=\"edits\">Rebuild HTML with higher tier is required to view</div>\n"
        builder += "</div>\n\n"
    with open(dir + "gallery.html", 'wb') as f:
        f.write(bytes(new_html(builder, batchname, listurls), "utf-8"))



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



def tohtml_g(delete=False):
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
            builder2 += container_c(file2, label(m, s, html=True))
            if not (file2 := next(v, None)):
                break
        if builder2:
            builder += f"""<div class="container">
{container_c(file, f"{m[0]} x {m[1]}")}{builder2}</div>

"""
            counter += 1
        if counter % 512 == 0:
            morehtml = htmlfile.replace(".html", f" {int(counter/512)}.html")
            with open(morehtml, 'wb') as f:
                f.write(bytes(new_html(builder, batchname, ""), 'utf-8'))
            with open(savx, 'wb') as f:
                f.write(bytes("\n".join(dbz), 'utf-8'))
            print("\"" + morehtml + "\" created!")
            builder = ""
            counter += 1
    morehtml = htmlfile.replace(".html", f" {int(counter/512) + 1}.html")
    with open(morehtml, 'wb') as f:
        f.write(bytes(new_html(builder, batchname, ""), 'utf-8'))
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
    s = input("Drag'n'drop and enter another image to compare, more folder to scan, or empty to find in database: ").rstrip().strip('\"')
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
    if not os.path.exists(mf):
        choice(bg=True)
        print(f" {tmf} doesn't exist! Nothing to organize.")
        return
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
    print("Finished organizing!")



def syntax(html):
    a = [[html,""]]
    for z in ["http://", "https://", "/"]:
        a = carrots(a, f"'{z}*' not starts with >", True, ["'" + z, "'"])
        a = carrots(a, f"\"{z}*\" not starts with >", True, ["\"" + z, "\""])
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



# browser = webdriver.Firefox()
# browser.get('https://www.patreon.com/api/user/9325459')
while False:
    if """FOUND""" in browser.page_source:
        echo("FOUND", 0, 1)
    else:
        echo("Nope", 0, 1)
    for bc in browser.get_cookies():
        if "httpOnly" in bc: del bc["httpOnly"]
        if "expiry" in bc: del bc["expiry"]
        if "sameSite" in bc: del bc["sameSite"]
        c = new_cookie()
        c.update(bc)
        cookie.set_cookie(cookiejar.Cookie(**c))
    print(cookie)
    input("Refresh?\r")
    browser.refresh()



def run_input(m):
    if m == "x":
        return
    elif any(word for word in scraper.keys() if m.startswith(word)):
        scrape([m])
    elif m.startswith("http") and not m.startswith("http://localhost"):
        if m.endswith("/"):
            choice(bg=True)
            print(" I don't have a scraper for that!")
        else:
            downloadtodisk({"page":"", "inlinefirst":True, "partition":{"0":{"html":"", "keywords":[], "files":[{"url":m, "name":saint(parse.unquote(m.split("/")[-1])), "edited":0}]}}})
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
        print("Invalid input or not on disk")
        choice(bg=True)



def ready_input():
    sys.stdout.write("Enter (I)nput mode or ready to (O)rganize, (H)elp: ")
    sys.stdout.flush()



input_mode = [""]
def keylistener():
    while True:
        el = choice("bcdghioqstvx")
        if el == 1:
            if Browser and HTMLserver:
                os.system(f"""start "" "{Browser}" "http://localhost:8886/{batchname} 1.html" """)
            elif Browser:
                os.system(f"""start "" "{Browser}" "{batchdir}{batchname} 1.html" """)
            else:
                choice(bg=True)
                print(f""" No browser selected! Please check the "Browser =" setting in {rulefile}""")
            print("""
 Browser key listener (Not here!):
  > W - Edge detect when previewing an image
  > A - Geistauge: compare to left when previewing an image
  > S - Geistauge: bright both when previewing an image
  > D - Geistauge: compare to right (this) when previewing an image
  > Shift - Fit image to screen

 "Edge detect" and "Geistauge" are canvas features and they require "Access-Control-Allow-Origin: *" (try HTML server)
""")
            ready_input()
        elif el == 2:
            for c in cookie:
                echo(str(c), 1, 2)
        elif el == 3:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            if not Geistauge:
                choice(bg=True)
                print(" GEISTAUGE: Maybe not.")
            else:
                choice(bg="4c")
                if input("Drag'n'drop and enter my SAV file: ").rstrip().replace("\"", "") == f"{batchdir}{sav}":
                    skull()
                    tohtml_g(delete=True)
            ready_input()
        elif el == 4:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            if not Geistauge:
                choice(bg=True)
                print(" GEISTAUGE: Maybe not.")
            else:
                tohtml_g()
            ready_input()
        elif el == 5:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            sys.stdout.write("Open (H)elp unless you mean (I)nput mode (HTTP...), e(X)it: ")
            sys.stdout.flush()
            el = choice("hix")
            if el == 1:
                quicktutorial()
                ready_input()
            elif el == 2:
                input_mode[0] = input("Enter valid input, e(X)it: ").rstrip().replace("\"", "")
                if not input_mode[0]:
                    choice(bg=True)
                    ready_input()
        elif el == 6:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            input_mode[0] = input("Enter valid input, e(X)it: ").rstrip().replace("\"", "")
            if not input_mode[0]:
                choice(bg=True)
                ready_input()
        elif el == 7:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            finish_organize()
            ready_input()
        elif el == 8:
            echo("", 1)
            skiptonext[0] = True
        elif el == 9:
            echo("", 1)
            offlinepromptx[0] = False
        elif el == 10:
            if ticks:
                echo(f"""COOLDOWN {"DISABLED" if cooldown[0] else "ENABLED"}""", 1, 1)
            else:
                echo(f"""Timer not enabled, please add "#-# seconds rarity 100%" in {rulefile}, add another timer to manipulate rarity.""", 1, 1)
            cooldown[0] = False if cooldown[0] else True
        elif el == 11:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            while True:
                m = input("Enter URL to view source, append URL with key > s > to read it as dictionary, e(X)it: ").rstrip()
                if m.startswith("http"):
                    referer = x[0] if (x := [v for k, v in referers.items() if m.startswith(k)]) else ""
                    ua = x[0] if (x := [v for k, v in mozilla.items() if m.startswith(k)]) else 'Mozilla/5.0'
                    m = m.split(" ", 1)
                    data = get(m[0], utf8=True, headers={'User-Agent':ua, 'Referer':referer, 'Origin':referer}, stderr="Page loading failed successfully")
                    if data:
                        if len(m) == 2:
                            z = m[1].rsplit(" > 0", 1)
                            if len(z) == 1:
                                z = ["", z[0]]
                            if x := nested(opendb(data), [z[0], [[z[1], 0, 0, 0]]]):
                                for y in x:
                                    print(y[0])
                            else:
                                print(f"{tcolorr}Last few keys doesn't exist, try again.{tcolorx}")
                        else:
                            data = "\n".join([s.rstrip() if s.rstrip() else "" for s in data.replace("	", "    ").splitlines()])
                            print(syntax(data))
                elif m == "x":
                    break
                else:
                    choice(bg=True)
            ready_input()
        elif el == 12:
            echo(f"""SET ALL ERROR DOWNLOAD REQUESTS TO: {"SKIP" if retryx[0] else "RETRY"}""", 1, 1)
            retryx[0] = False if retryx[0] else True
            offlinepromptx[0] = True
        else:
            seek[0] = True
t = Thread(target=keylistener)
t.daemon = True
t.start()
print("""
 Key listener:
  > Press X to enable or disable indefinite retry on error downloading files (for this session).
  > Press S to skip next error once during downloading files.
  > Press T to enable or disable cooldown during errors (reduce server strain).
  > Press C to view cookies.
  > Press Ctrl + C to break and reconnect of the ongoing downloads or to end timer instantly.
""")



# Loading filelist from detected urls in textfile
if not os.path.exists(textfile):
    open(textfile, 'w').close()
print(f"Reading {textfile} . . .")
with open(textfile, 'r', encoding="utf-8") as f:
    textread = f.read().splitlines()
htmlassets = {"page":"", "partition":{"0":{"html":"", "keywords":[], "files":[]}}}
imore = []
for url in textread:
    if not url or url.startswith("#"):
        continue
    elif not url.startswith("http"):
        continue
    if any(word for word in scraper.keys() if url.startswith(word)):
        imore += [url]
    else:
        name = parse.unquote(url.split("/")[-1])
        htmlassets["partition"]["0"]["files"] += [{"url":url, "name":saint(name), "edited":0}]



if filelist:
    busy[0] = True
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
    busy[0] = False
else:
    busy[0] = True
    if htmlassets["partition"]["0"]["files"]:
        downloadtodisk(htmlassets)
    elif imore:
        scrape(imore)
    else:
        print(f" No urls in {textfile}! Doing so will enable parallel downloading urls and resume the interrupted downloads.")
    busy[0] = False



mainmenu()
ready_input()
while True:
    if input_mode[0]:
        busy[0] = True
        run_input(input_mode[0])
        input_mode[0] = ""
        busy[0] = False
        ready_input()
    time.sleep(0.1)



"""
::MacOS - Install Python 3 then open Terminal and enter:
open /Applications/Python\ 3.9/Install\ Certificates.command
sudo python3 -m pip install --upgrade pip
sudo python3 -m pip install PySocks
sudo python3 -m pip install Pillow
python3 -x /drag/n/drop/the/batchfile

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
if exist "!pythondirx!\python.exe" (cd /d "!pythondirx!" && color %color%) else (color %stopcolor%
echo.
if "!string!"=="" (echo  I can't seem to find \!x: 3.=3!\python.exe^^! Install !x! in default location please, or edit this batch file.&&echo.&&echo  Download the latest !x!.x from https://www.python.org/downloads/) else (echo  Please fix path to \!x: 3.=3!\python.exe in "Python =" setting in !txtfile!)
echo.
echo  I must exit^^!
pause%>nul
exit)
set pythondir=!pythondir:\=\\!

if exist Lib\site-packages\socks.py (echo.) else (goto install)
::if exist Lib\site-packages\selenium (echo.) else (goto instal)
if exist Lib\site-packages\PIL (goto start) else (echo.)

:install
echo  Hold on . . . I need to install the missing packages.
if exist "Scripts\pip.exe" (echo.) else (color %stopcolor% && echo  PIP.exe doesn't seem to exist . . . Please install Python properly^^! I must exit^^! && pause>nul && exit)
python -m pip install --upgrade pip
Scripts\pip.exe install PySocks
::Scripts\pip.exe install selenium
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
