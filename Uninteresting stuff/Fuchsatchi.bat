@echo off && goto loaded

import os, sys, ssl, time, json, zlib, inspect, smtplib, hashlib
from datetime import datetime
from fnmatch import fnmatch
from http import cookiejar
from http.server import SimpleHTTPRequestHandler, HTTPServer, ThreadingHTTPServer
from queue import Queue
from socketserver import ThreadingMixIn
from threading import Thread
from urllib import parse, request
from urllib.error import HTTPError, URLError
from random import random

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
batchdirx = batchdir.replace("\\", "\\\\") + "\\\\"
batchfile = os.path.basename(__file__)
batchname = os.path.splitext(batchfile)[0]
os.chdir(batchdir)

date = datetime.now().strftime('%Y') + "-" + datetime.now().strftime('%m') + "-XX"
cd = batchname + " cd/"
tcd = "\\" + batchname + " cd\\"
htmlfile = batchname + ".html"
rulefile = batchname + ".txt" # ".cd"
sav = batchname + ".sav"
savm = batchname + ".savm"
savp = batchname + ".savp"
savx = batchname + ".savx"
textfile = batchname + ".txt"

archivefile = [".7z", ".rar", ".zip"]
imagefile = [".gif", ".jpe", ".jpeg", ".jpg", ".png"]
videofile = [".mkv", ".mp4", ".webm"]
specialfile = ["magnificent.txt", "mediocre.txt", ".ender"]

alerted = [False]
busy = [False]
cooldown = [False]
dlslot = [8]
echothreadn = []
error = [[]]
htmlname = batchfile
newfilen = [0]
Keypress_prompt = [False]
Keypress_A = [False]
Keypress_B = [False]
Keypress_C = [False]
Keypress_F = [False]
Keypress_R = [False]
Keypress_S = [False]
Keypress_X = [False]
Keypress_CtrlC = [False]
retries = [0]
sf = [0]

# Probably useless settings
collisionisreal = False
editisreal = False
buildthumbnail = False
favoriteispledged = False
Kemonoparty = False
shuddup = True



def ansi(c):
    if len(c) == 3:
        c = "".join(x*2 for x in c)
    return ";".join(str(int(x, 16)) for x in [c[0:2], c[2:4], c[4:6]])

def ansi_color(b=False, f="3"):
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
sys.stdout.write("Non-ANSI-compliant Command Prompt/Terminal (expect lot of visual glitches): Upgrade to Windows 10 if you're on Windows.")



def mainmenu():
    return """
 Delete the ender file if:
  > You need files that was rejected by your filter list in the past.
  > The deleted files you want them back.
"""
def ready_input():
    sys.stdout.write("Ready to (L)oad your favorite artists from textfile: ")
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
    pass



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

def echo(threadn, b=0, f=0, clamp='', friction=False):
    if not str(threadn).isdigit():
        stdout[0] = ""
        stdout[1] = ""
        sys.stdout.write("\033[A"*b + f"{threadn:<{columns()}}" + "\n"*f + "\r")
    elif not echothreadn or threadn == echothreadn[0]:
        c = columns()
        if clamp:
            b = f"{b[:c-1]}{(b[c-1:] and clamp)}"
        if friction:
            stdout[0] = f"{b:<{c}}\r"
        else:
            stdout[0] = ""
            stdout[1] = ""
            sys.stdout.write(f"{b:<{c}}\r")
    else:
        return



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



def debug(e="echoed", b=0, f=1):
    c = inspect.getframeinfo(inspect.stack()[1][0])
    echo(f"""{tcolorz("cccccc")}{c.lineno} {c.function}() {e}{tcolorx}""", b, f)



def choice(keys="", bg=False, persist=False):
    if sys.platform == "win32":
        if bg: os.system(f"""color {"%stopcolor%" if bg == True else bg}""")
        if keys: el = os.system(f"choice /c:{keys} /n")
        if bg and not persist: os.system("color %color%")
        echo(tcolorx)
    else:
        if keys: el = os.system("""while true; do
read -s -n 1 el || break
case $el in
""" + "\n".join([f"{k} ) exit {e+1};;" for e, k in enumerate(keys)]) + """
esac
done""")
        echo(tcolorx, 0, 1)
    if not keys:
        return
    if el >= 256:
        el /= 256
    return int(el)



def input(i="Your Input: ", choices=False):
    sys.stdout.write(str(i))
    sys.stdout.flush()
    if choices:
        keys = ""
        for c in choices:
            keys += c[0]
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
                echo(str(i) + choices[el-1], 1, 1)
                return el
    else:
        return sys.stdin.readline().replace("\n", "")



def new_rules():
    return """

- - - - Favorite Artists - - - -
end
# finish scanning artists (does not scan any further)

# To add new artists, find their ID, then append each with their name, please do not backspace or continue number after ID. E.G.
312424.zaush
312424/Adam Wan
# Insert a slash to use ending as folder E.G. \\Adam Wan\\ for Zaush.

then
# resume next artists

fanbox
1092867.b@commission

# Appended names are for you to identify, they can be renamed (please also make your changes symmetrical to existing folders).
# Artists from different paysites can be grouped by paysite name headings ("Fanbox", "Fantia", "Patreon"). Without them, I will assume everyone is from Patreon.


- - - - Probably useless settings - - - -
Do not edit uneducated.
bgcolor 005A80
fgcolor 6
# collisionisreal
# editisreal
# buildthumbnail
# favoriteispledged


- - - - Spoofer - - - -
Mozilla/5.0 for http
4-8 seconds rarity 75%
# 12-24 seconds rarity 23%
# 64-128 seconds rarity 2%

# __ddg1 ... for .kemono.party
# FANBOXSESSID ... for .fanbox.cc
# session_id ... for .patreon.com
# __cf_bm ... for .patreon.com
https://www.fanbox.cc for https://api.fanbox.cc


- - - - Sorter - - - -
* for https://fanbox.pixiv.net/images/
* for https://downloads.fanbox.cc/images/
* for https://www.patreon.com
* for https://c10.patreonusercontent.com
* for https://kemono.party/
* for https://data.kemono.party/
Update me/* for https://

# Whitelist - File types to download (blank or comment out all to download any).
.gif
.jpe
.jpg
.jpeg
.png
#.mp4
#.webm

# Blacklist - No effect until all extension names in whitelist are blanked or commented out.
!.7z
!.rar
!.zip
!.pdf
!.psd
!.sai
!.mp4
!.webm

# Per-artist filter how-to:
# mediocre.txt in artist folder to blacklist matching pattern, this will incorporate with inline filters (here).
# magnificent.txt in artist folder to whitelist matching pattern, this will override inline filters but not mediocre.txt. While mediocre.txt is king, inline filters will still be overridden by this.
# Write "inherit" in magnificent.txt to inherit other rules from inline filters, adding flexibility. Illustrated example:

#                          inline's !.zip = all but .zip
# mag's .zip             + inline's !.zip = .zip only
# mag's .zip + "inherit" + inline's !.zip = all

# Filters are case insensitive.
# Filters start/end are non-anchored, asterisk (*) will be literal and unnecessary.
# Anchored ending if there's a period at the beginning, to avoid matching pattern of an extension name in file names.
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
offset = 0
settings = ["Launch HTML server = ", "Show mediocre = No", "Patrol mediocre = No", "Python = " + pythondir, "Proxy = socks5://"]
for setting in settings:
    if not rules[offset].replace(" ", "").startswith(setting.replace(" ", "").split("=")[0]):
        if offset == 0:
            setting += "Yes" if input(f"Launch HTML server? (Y)es/(N)o: ", "yn") == 1 else "No"
            echo("", 1, 0)
            echo(f" Inline tutorial and download filters were added to {rulefile}.\n You may want to check/edit there before I download artpieces with filters and settings.", 0, 2)
        rules.insert(offset, setting)
        print(f"""Added new setting "{setting}" to {rulefile}!""")
        new_setting = True
    offset += 1
if new_setting:
    with open(rulefile, 'wb') as f:
        f.write(bytes("\n".join(rules), 'utf-8'))



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
        stdout[1] = "\n\033]0;" + f"""[{newfilen[0]} new{f" after {retries[0]} retries" if retries[0] else ""}] {htmlname} {''.join(fx[0][:len(echothreadn) if threadn else 1])} {MBs[0]} MB/s""" + "\007\033[A"
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
    def do_GET(self):
        if '?' in self.path:
            self.path = self.path.split('?')[0]
        SimpleHTTPRequestHandler.do_GET(self)

    def do_POST(self):
        if (x := int(self.headers['Content-Length'])) < 200:
            x = self.rfile.read(x).decode('utf-8').replace("/", "\\")
            print(f"{os.getcwd()}\{x}")
            # self.wfile.write(bytes(f"GET request for {self.path}", 'utf-8'))

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



if not os.path.exists(batchname + "/"):
    os.makedirs(batchname + "/")
cookies = cookiejar.MozillaCookieJar(batchname + "/cookies.txt")
if os.path.exists(batchname + "/cookies.txt"):
    cookies.load()
def new_cookie():
    return {'port_specified':False, 'domain_specified':False, 'domain_initial_dot':False, 'path_specified':True, 'version':0, 'port':None, 'path':'/', 'secure':False, 'expires':None, 'comment':None, 'comment_url':None, 'rest':{"HttpOnly": None}, 'rfc2109':False, 'discard':True, 'domain':None, 'name':None, 'value':None}



def ast(rule, key="0"):
    return rule.replace("*date", date).replace("*id", key).replace("/", "\\")

def saint(name=False, url=False):
    if url:
        url = list(parse.urlsplit(url))
        url2 = url[2].rsplit("/", 1)
        url[2] = url2[0] + "/" + parse.quote(url2[1], safe="%")
        return parse.urlunsplit(url)
    else:
        return "".join(i for i in parse.unquote(name).replace("/", "\\") if i not in "\":*?<>|")[:200]



# Loading referer, sort, and custom dir rules, and inline file rejection by file types from rulefile
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
ready = True
inline_m = [[], []]
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
        personal = True



    elif len(sr := rule.split(" seconds rarity ")) == 2:
        ticks += [[int(x) for x in sr[0].split("-")]]*int(sr[1].split("%")[0])
    elif rule == "collisionisreal":
        collisionisreal = True
    elif rule == "editisreal":
        editisreal = True
    elif rule == "buildthumbnail":
        buildthumbnail = True
    elif rule == "headonly":
        ready = False
    elif rule == "shuddup":
        shuddup = 2
    elif rule == "favoriteispledged":
        favoriteispledged = True
    elif rule == "Kemono.party":
        Kemonoparty = True
    elif rule.startswith('bgcolor '):
        bgcolor = rule.replace("bgcolor ", "")
    elif rule.startswith('fgcolor '):
        fgcolor = rule.replace("fgcolor ", "")
    elif rule.startswith('!.'):
        inline_m[0] += [rule.replace("!.", ".", 1)]
    elif rule.startswith('.'):
        inline_m[1] += [rule]
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
    elif dir:
        sorter[dir] += [rule]
    else:
        exempt += [rule]

if bgcolor:
    tcolorx = ansi_color(bgcolor, fgcolor)
    sys.stdout.write(tcolorx + cls)



print(f"Reading settings from {rulefile} . . .")
def y(y, yn=False):
    y = y.split("=", 1)[1].strip()
    if yn:
        if os.path.exists(y):
            return y
        return True if y.lower()[0] == "y" else False
    else:
        return y
HTMLserver = y(rules[0], True)
Showpattern = y(rules[1], True)
Patrol = y(rules[2], True)
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
print(f""" SHOW MEDIOCRE: {"ON" if Showpattern else "OFF"}""")
sevenz = Patrol if os.path.isfile(Patrol) and Patrol.endswith("7z.exe") else ""
print(f""" PATROL MEDIOCRE: {("ON (7-Zip armed)" if sevenz else "ON (7-Zip for archive scan support, but no path to it is provided)") if Patrol else "OFF"}""")
if "socks5://" in proxy and proxy[10:]:
    if not ":" in proxy[10:]:
        kill(" PROXY: Invalid socks5:// address, it must be socks5://X.X.X.X:port OR socks5://user:pass@X.X.X.X:port\n\n TRY AGAIN!")
    try:
        import socket, socks
    except:
        kill(f" PROXY: Additional prerequisites required - please execute in another command prompt with:\n\n{sys.exec_prefix}\Scripts\pip.exe install sysocks")
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
if Patrol or buildthumbnail:
    try:
        from PIL import Image
        Image.MAX_IMAGE_PIXELS = 400000000
        import subprocess
    except:
        kill(f" GEISTAUGE: Additional prerequisites required - please execute in another command prompt with:\n\n{sys.exec_prefix}\Scripts\pip.exe install pillow")



print(f"\n Ready to scrape (visible string means disabled, copy to {rulefile} and restart CLI to enable):")
print(f"""  > Kemono.party{"" if Kemonoparty else ": Kemono.party"}""")
Patreoncookie = False
Fanboxcookie = False
Fantiacookie = False
for c in cookies:
    if c.domain == ".patreon.com" and c.name == "session_id":
        if not len(c.value) == 43:
            print("  > Patreon: cookie value must fit 43 characters in length.\n\n TRY AGAIN!")
            sys.exit()
        Patreoncookie = True
        print("  > Patreon")
    elif c.domain == ".fanbox.cc" and c.name == "FANBOXSESSID":
        FANBOXSESSID = c.value.split("_", 1)
        if not len(FANBOXSESSID) == 2 or not FANBOXSESSID[0].isdigit() or not len(FANBOXSESSID[1]) == 32:
            print("  > Fanbox: cookie value must be somewhere close to 40 characters in length.\n\n TRY AGAIN!")
            sys.exit()
        Fanboxcookie =True
        print("  > Fanbox")
    elif c.domain == ".fantia.jp" and c.name == "_session_id":
        if not len(c.value) == 32:
            print("  > Fantia: cookie value must fit 32 characters in length.\n\n TRY AGAIN!")
            sys.exit()
        Fantiacookie = True
        print("  > Fantia")
if not Patreoncookie:
    print("""  > Patreon: session_id <value> for .patreon.com""")
if not Fanboxcookie:
    print("""  > Fanbox: FANBOXSESSID <value> for .fanbox.cc""")
if not Fantiacookie:
    print("""  > Fantia: _session_id <value> for .fantia.jp""")
if not Patreoncookie and not Fanboxcookie and not Fantiacookie and not Kemonoparty:
    print("\n I'm useless (please enable any one of the above)")
    sys.exit()



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
            if Keypress_CtrlC[0]:
                Keypress_CtrlC[0] = False
                break
        ticking[0] = False
    elif all:
        while ticking[0]:
            time.sleep(0.5)



def retry(stderr):
    # Warning: urllib has slight memory leak
    Keypress_R[0] = False
    while True:
        if not Keypress_prompt[0]:
            Keypress_prompt[0] = True
            if stderr:
                if Keypress_A[0]:
                    e = f"{retries[0]} retries (Q)uit trying "
                    if cooldown[0]:
                        timer(e)
                    else:
                        echo(e)
                    Keypress_R[0] = True
                else:
                    title(status() + batchname)
                    sys.stdout.write(f"{stderr} (R)etry? (A)lways (S)kip defuse antibot with (F)irefox: ")
                    sys.stdout.flush()
                    while True:
                        if Keypress_R[0] or Keypress_A[0]:
                            break
                        if Keypress_S[0]:
                            Keypress_S[0] = False
                            Keypress_prompt[0] = False
                            return
                        if Keypress_F[0]:
                            Keypress_F[0] = False
                            Keypress_prompt[0] = False
                            return 2
                        time.sleep(0.1)
            else:
                echo(f"{retries[0]} retries (S)kip one, wait it out, or press X to quit trying . . . ")
            time.sleep(0.1)
            retries[0] += 1
            title(status() + batchname)
            Keypress_prompt[0] = False
            return True
        elif Keypress_R[0]:
            return True
        time.sleep(0.1)



def fetch(url, context=None, stderr="", dl=0, threadn=0, data=None):
    referer = x[0] if (x := [v for k, v in referers.items() if url.startswith(k)]) else ""
    ua = x[0] if (x := [v for k, v in mozilla.items() if url.startswith(k)]) else 'Mozilla/5.0'
    headers = {x[0][0]:x[0][1]} if (x := [v for k, v in hydras.items() if url.startswith(k)]) else {}
    headers.update({'User-Agent':ua, 'Referer':referer, 'Origin':referer})
    while True:
        try:
            headers.update({'Range':f'bytes={dl}-', 'Accept':"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"})
            resp = request.urlopen(request.Request(saint(url=url), headers=headers, data=data), context=context)
            break
        except HTTPError as e:
            if stderr or Keypress_X[0] and not Keypress_S[0]:
                el = retry(f"{stderr} ({e.code} {e.reason})")
                if el == 2:
                    firefox(saint(url=url))
                    Keypress_prompt[0] = False
                elif not el:
                    return 0, str(e.code)
            else:
                Keypress_S[0] = False
                return 0, str(e.code)
        except URLError as e:
            if stderr or Keypress_X[0] and not Keypress_S[0]:
                if not retry(f"{stderr} (e.reason)"):
                    return 0, e.reason
            else:
                Keypress_S[0] = False
                return 0, e.reason
        except:
            if stderr or Keypress_X[0] and not Keypress_S[0]:
                if not retry(f"{stderr} (closed by host)"):
                    return 0, "closed by host"
            else:
                Keypress_S[0] = False
                return 0, "closed by host"
    return resp, 0



# context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
# context = ssl.create_default_context(purpose=ssl.Purpose.SERVER_AUTH)
# request.install_opener(request.build_opener(request.HTTPSHandler(context=context)))
request.install_opener(request.build_opener(request.HTTPCookieProcessor(cookies)))
# cookie.save()

def get(url, todisk="", utf8=False, conflict=[[], []], context=None, headonly=False, stderr="", threadn=0):
    dl = 0
    if todisk:
        echo(threadn, f"{threadn:>3} Downloading 0 / 0 MB {url}", clamp='█')
        if os.path.exists(todisk + ".part"):
            dl = os.path.getsize(todisk + ".part")
    else:
        echo(threadn, "0 MB")
    Keypress_S[0] = False
    Keypress_CtrlC[0] = False
    while echothreadn and echothreadn.index(threadn) >= dlslot[0]:
        time.sleep(0.1)
    resp, err = fetch(url, context, stderr, dl, threadn)
    if not resp:
        return err
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
        echo(threadn, f"""{threadn:>3} Downloading {f"{dl/1073741824:.2f}" if GB else int(dl/1048576)} / {MB} {url}""", clamp='█')
        with open(todisk + ".part", 'ab') as f:
            while True:
                try:
                    block = resp.read(262144)
                    if not block:
                        if not total or dl == total:
                            break
                        if not retry(stderr):
                            return err
                        resp, err = fetch(url, context, stderr, dl, threadn)
                        if not resp:
                            return err
                        if resp.status == 200 and dl > 0:
                            kill(threadn, "server doesn't allow resuming download. Delete the .part file to start again.")
                        continue
                except KeyboardInterrupt:
                    resp, err = fetch(url, context, stderr, dl, threadn)
                    if resp.status == 200 and dl > 0:
                        kill(threadn, "server doesn't allow resuming download. Delete the .part file to start again.")
                    continue
                except:
                    if not retry(stderr):
                        return err
                    resp, err = fetch(url, context, stderr, dl, threadn)
                    if not resp:
                        return err
                    if resp.status == 200 and dl > 0:
                        kill(threadn, "server doesn't allow resuming download. Delete the .part file to start again.")
                    continue
                f.write(block)
                Bytes = len(block)
                dl += Bytes
                echoMBs(threadn, Bytes, int(dl/total*256) if total else 0)
                echo(threadn, f"""{threadn:>3} Downloading {f"{dl/1073741824:.2f}" if GB else int(dl/1048576)} / {MB} {url}""", clamp='█', friction=True)
                if Keypress_CtrlC[0]:
                    resp, err = fetch(url, context, stderr, dl, threadn)
                    if resp.status == 200 and dl > 0:
                        kill(threadn, "server doesn't allow resuming download. Delete the .part file to start again.")
                    Keypress_CtrlC[0] = False
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
                                try:
                                    return zlib.decompress(data, 16+zlib.MAX_WBITS).decode("utf-8")
                                except:
                                    todisk = saint(parse.unquote(url.split("/")[-1]))
                                    sys.stdout.write(f" Not an UTF-8 file! Save on disk as {todisk} to open it in another program? (S)ave (D)iscard: ")
                                    sys.stdout.flush()
                                    if choice("sd") == 1:
                                        with open(todisk, 'wb') as f:
                                            f.write(data);
                                        echo(f"{threadn:>3} Download completed: {url}", 0, 1)
                                    return
                        else:
                            return data
                    if not retry(stderr):
                        return err
                    resp, err = fetch(url, context, stderr, dl, threadn)
                    if not resp:
                        return err
                    if resp.status == 200:
                        data = b''
                        dl = 0
                    continue
            except KeyboardInterrupt:
                resp, err = fetch(url, context, stderr, dl, threadn)
                if resp.status == 200:
                    data = b''
                    dl = 0
                continue
            except:
                if not retry(stderr):
                    return err
                resp, err = fetch(url, context, stderr, dl, threadn)
                if not resp:
                    return err
                if resp.status == 200:
                    data = b''
                    dl = 0
                continue
            data += block
            Bytes = len(block)
            dl += Bytes
            echoMBs(threadn, Bytes, int(dl/total*256) if total else 0)
            echo(threadn, f"{int(dl/1048576)} MB", friction=True)
            if Keypress_CtrlC[0]:
                resp, err = fetch(url, context, stderr, dl, threadn)
                if resp.status == 200:
                    data = b''
                    dl = 0
                Keypress_CtrlC[0] = False



def echolinks(download):
    while True:
        threadn, html, log, todisk, onserver = download.get()
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
            elif (err := get(url, todisk=todisk, conflict=conflict, threadn=threadn)) == 1:
                newfilen[0] += 1
                html.append(container(todisk))
            else:
                error[0] += [todisk]
                echo(f"{threadn:>3} Error downloading ({err}): {url}", 0, 1)
                log.append(f"&gt; Error downloading ({err}): {url}")
        echothreadn.remove(threadn)
        download.task_done()
download = Queue()
for i in range(8):
    t = Thread(target=echolinks, args=(download,))
    t.daemon = True
    t.start()



def check(string, patterns, majestic=False):
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
    if found and not majestic or not found and majestic:
        return pattern.lower()
    else:
        return ""



def isrej(filename, rejlist):
    if not rejlist:
        return ""
    mediocre, magnificent, inherit = rejlist
    rejected = ""
    origin = ""
    if "/" in filename:
        dir, filename = filename.rsplit("/", 1)
        dir = f"{batchname}/{htmlname}/{dir}/"
    else:
        dir = f"{batchname}/{htmlname}/"
    if mediocre:
        origin = "mediocre.txt"
        rejected = check(filename, mediocre)
    if not rejected and inherit:
        rejected = check(filename, magnificent, majestic=True)
        if rejected and inline_m[1]:
            rejected = check(filename, inline_m[1], majestic=True)
        elif rejected and inline_m[0]:
            origin = rulefile
            rejected = check(filename, inline_m[0])
        else:
            rejected = ""
    elif not rejected and magnificent:
        rejected = check(filename, magnificent, majestic=True)
    elif not rejected and inline_m[1]:
        rejected = check(filename, inline_m[1], majestic=True)
    elif not rejected and inline_m[0]:
        origin = rulefile
        rejected = check(filename, inline_m[0])
    if rejected and Showpattern:
        if rejected in filename.lower():
            print(f"{tcolor}{origin:>18}: {dir}{filename.lower().replace(rejected, tcolorr + rejected + tcolor)}{tcolorx}")
        else:
            print(f"{tcolor}  Not in whitelist: {dir}{tcolorb}{filename}{tcolorx}")
    return rejected



def ren(filename, append):
    return append.join(os.path.splitext(filename) if filename.count(".") > 1 else [filename, ""])



def get_cd(file, rejlist, log, makedirs=False, preview=False, subdir=""):
    link = file["link"] if preview else file.pop("link")
    todisk = file["name"].replace("\\", "/")
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
        if isrej(todisk, rejlist):
            link = ""
        elif not preview and not os.path.exists(dir):
            if makedirs or [ast(x) for x in exempt if ast(x) == dir.replace("/", "\\")]:
                try:
                    os.makedirs(dir)
                except:
                    buffer = "\\" + dir.replace("/", "\\")
                    kill(f"Can't make folder {buffer} because there's a file using that name, I must exit!")
            else:
                log.append(f"&gt; Error downloading (dir): {link}")
                print(f" Error downloading (dir): {link}")
                error[0] += [todisk]
                link = ""
    elif not preview:
        dir = subdir + x[0] + "/" if len(x := todisk.rsplit("/", 1)) == 2 else subdir
        if isrej(todisk, rejlist):
            link = ""
        if not os.path.exists(batchname + "/"):
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



def downloadtodisk(fromhtml, paysite=False, makedirs=False):
    error[0] = []
    filelist = []
    filelisthtml = []
    fromhtml_pm = fromhtml["paysite" if paysite else "mirror"]
    htmlpart = fromhtml_pm["partition"]
    htmlname = fromhtml["htmlname"]
    html = []
    log = []
    for key in htmlpart.keys():
        for file in htmlpart[key]["files"]:
            if not file["name"]:
                print(f""" I don't have a scraper for {file["link"]}""")
            else:
                if (x := get_cd(file, fromhtml["m"], log, makedirs, subdir=f"{batchname}/{htmlname}/") + [key])[0]:
                    filelist += [x]
        for array in htmlpart[key]["html"]:
            if len(array) == 2 and array[1]:
                if not array[1]["name"]:
                    print(f""" I don't have a scraper for {array[1]["link"]}""")
                else:
                    if (x := get_cd(array[1], fromhtml["m"], log, makedirs, subdir=f"{batchname}/{htmlname}/") + [key])[0]:
                        filelisthtml += [x]
    if fromhtml["inlinefirst"]:
        filelist = filelisthtml + filelist
    else:
        filelist += filelisthtml
    if error[0]:
        buffer = "\n There is at least one of the bad custom dir rules (non-existent dir).\n"
        echoed = []
        for e in error[0]:
            if not (e := os.path.split(e)[0].replace("/", "\\") + "\\") in echoed:
                echoed += [e]
                buffer += f"  {e}\n"
        echo(f"{buffer} Add following dirs as new rules (preferably only for those intentional) to allow auto-create dirs.", 0, 2)

    if not filelist:
        if fromhtml_pm["makehtml"]:
            tohtml(batchname + "/" + htmlname + "/", htmlname, fromhtml_pm, [], fromhtml["m"])
        else:
            print("Filelist is empty!")
        return
    if len(filelist) == 1:
        echothreadn.append(0)
        download.put((0, [], [], filelist[0][1], [filelist[0][0]]))
        try:
            download.join()
        except KeyboardInterrupt:
            pass
        return
    queued = {}
    lastfilen = newfilen[0]



    # Ender (1/3)
    ender = False
    enderread = []
    last_key = 0
    new_ender = ""
    new_enderread = set([])
    for file in next(os.walk(f"{batchname}/{htmlname}/"))[2]:
        if file.endswith(".ender"):
            ender = file
            with open(f"{batchname}/{htmlname}/{ender}", 'r') as f:
                enderread = f.read().splitlines()
            new_enderread.update(enderread)




    for onserver, filename, edited, key in filelist:
        ondisk = f"{batchname}/{htmlname}/{filename}"



        # Ender (2/3)
        part_key = filename.rsplit("/", 1)[-1].split(".", 1)[0]
        if not new_ender:
            new_ender = os.path.splitext(filename)[0].split(".", 1)[0] + ".ender"
        if line := [x for x in enderread if part_key in x]:
            if not onserver:
                continue
            if int(edited) > 0 and int(edited) > int(line[0].rsplit(" ", 1)[-1]):
                if os.path.exists(ondisk):
                    if editisreal:
                        old = ".old_file_" + line[0].split(" ")[1]
                        os.rename(ondisk, f"{batchname}/{htmlname}/{ren(filename, old)}")
                        thumbnail = f"{batchname}/{htmlname}/HTML assets/" + ren(filename, append="_small")
                        if os.path.exists(thumbnail):
                            os.rename(thumbnail, ren(thumbnail, old))
                    else:
                        last_key = part_key
                        print(f"  Edited on server: {ondisk}")
                        continue
                if not part_key == last_key:
                    last_key = part_key
                    new_enderread.remove(line[0])
                    new_enderread.add(f"{part_key} {edited}")
            else:
                continue
        elif int(edited) > 0:
            new_enderread.add(f"{part_key} {edited}")
        else:
            new_enderread.add(f"{part_key}")



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
    try:
        download.join()
    except KeyboardInterrupt:
        pass



    # Ender (3/3) and rebuild HTML
    newfile = False if lastfilen == newfilen[0] else True
    new_enderread = sorted(new_enderread)
    if error[0]:
        error[0] = [os.path.basename(x).split(".", 1)[0] for x in error[0]]
        new_enderread = [x for x in new_enderread if x and x.split()[0] not in error[0]]
    if paysite and not newfile:
        print("You've got everything from this artist at tier you pledged to!")
    elif ender:
        print(f"""Ender file tripped.{" Nothing new to download." if not newfile else ""}{" There are failed downloads I will try again later." if error[0] else ""}""")
        if newfile and ender:
            os.remove(f"{batchname}/{htmlname}/{ender}")
            ender = False
    if not ender:
        with open(f"{batchname}/{htmlname}/{new_ender}", 'w') as f:
            f.write("\n".join(new_enderread))
        if os.path.exists(f"{batchname}/{htmlname}.html"):
            os.remove(f"{batchname}/{htmlname}.html")
    if not (x := os.path.exists(f"{batchname}/{htmlname}.html")) or Patrol:
        orphan_files = []
        for file in next(os.walk(f"{batchname}/{htmlname}/"))[2]:
            if not file.endswith(tuple(specialfile)):
                orphan_files += [file]
        if not x:
            tohtml(batchname + "/" + htmlname + "/", htmlname, fromhtml_pm, set(orphan_files).difference(x[1].rsplit("/", 1)[-1] for x in filelist), fromhtml["m"])
        if Patrol:
            print()
            total = len(orphan_files)
            patrolthreadn = 0
            for file in orphan_files:
                patrolthreadn += 1
                patrol.put((patrolthreadn, folder, fromhtml["m"], total, file, log))
            patrol.join()
            print(" PATROL MEDIOCRE: 100%")

    html.sort()
    htmldata[0] += [('\n'.join(html) + "\n<br>" if html else "") + '\n<br>'.join(log)]



firefox_running = [False]
def new_firefox():
    if os.path.isfile(batchdir + "geckodriver.exe"):
        try:
            from selenium import webdriver
        except:
            echo(f"\nSELENIUM: Additional prerequisites required - please execute in another command prompt with:\n\n{sys.exec_prefix}\Scripts\pip.exe install selenium", 0, 2)
        options = webdriver.FirefoxOptions()
        # options.add_argument("--headless")
        return webdriver.Firefox(options=options)
    else:
        echo(f"\n Download and extract the latest win64 package from https://github.com/mozilla/geckodriver/releases and then try again.", 0, 2)
def ff_login():
    revisit = False
    for c in cookies:
        if dom == c.domain:
            revisit = True
            firefox_running[0].add_cookie({"name":c.name, "value":c.value, "domain":c.domain})
    if revisit:
        firefox_running[0].get(url)
def firefox(url):
    dom = parse.urlparse(url).netloc.replace("www", "")
    if not firefox_running[0]:
        if f := new_firefox():
            firefox_running[0] = f
        else:
            return
    firefox_running[0].get(url)
    time.sleep(1)
    # ff_login()
    # echo("(C)ontinue when finished defusing.")
    # Keypress_C[0] = False
    # while not Keypress_C[0]:
    #     time.sleep(0.1)
    # Keypress_C[0] = False
    for bc in firefox_running[0].get_cookies():
        if "httpOnly" in bc: del bc["httpOnly"]
        if "expiry" in bc: del bc["expiry"]
        if "sameSite" in bc: del bc["sameSite"]
        c = new_cookie()
        c.update(bc)
        cookies.set_cookie(cookiejar.Cookie(**c))
    return True



def container(ondisk, rejlist=[], depth=0):
    filename = ondisk.rsplit("/", 1)[-1]
    relfile = ondisk.split("/", depth)[-1]
    if isrej(filename, rejlist):
        return f"""<div class="frame"><div class="aqua">🦦 -( Mediocre )</div><div class="sources">{filename}</div></div>\n"""
    else:
        if filename.lower().endswith(tuple(videofile)):
            data = f"""<div class="frame"><video height="200" autoplay><source src="{relfile.replace("#", "%23")}"></video><div class="sources">{filename}</div></div>\n"""
        elif filename.lower().endswith(tuple(imagefile)):
            if buildthumbnail and not "/HTML assets/" in relfile:
                thumb = "/HTML assets/".join(ren(relfile, "_small").rsplit("/", 1))
                if not os.path.exists(batchname + "/" + thumb):
                    try:
                        img = Image.open(ondisk)
                        w, h = img.size
                        if h > 200:
                            img.resize((int(w*(200/h)), 200), Image.ANTIALIAS).save(batchname + "/" + thumb, subsampling=0, quality=100)
                        else:
                            img.save(batchname + "/" + thumb)
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



def new_html(builder, htmlname, listurls, imgsize=200):
    if not listurls:
        listurls = "Maybe in another page."
    return """<!DOCTYPE html>
<html>
<meta charset="UTF-8"/>
<meta name="format-detection" content="telephone=no">
""" + f"<title>{htmlname}</title>" + """
<style>
html,body{background-color:#10100c; color:#088 /*088 cb7*/; font-family:consolas, courier; font-size:14px;}
a{color:#dc8 /*efdfa8*/;}
a:visited{color:#cccccc;}
.aqua{background-color:#006666; color:#33ffff; border:1px solid #22cccc;}
.carbon, .files, .time{background-color:#10100c /*10100c 112230 07300f*/; border:3px solid #6a6a66 /*6a6a66 367 192*/; border-radius:12px;}
.time{white-space:pre-wrap; color:#ccc; font-size:90%; line-height:1.6;}
.cell, .mySlides{background-color:#1c1a19; border:none; border-radius:12px;}
.edits{background-color:#330717; border:3px solid #912; border-radius:12px; color:#f45;}
.previous{background-color:#f1f1f1; color:black; border:none; border-radius:10px; cursor:pointer;}
.next{background-color:#444; color:white; border:none; border-radius:10px; cursor:pointer;}
.closebtn{background-color:rgba(0, 0, 0, 0.5); color:#fff; border:none; border-radius:10px; cursor:pointer;}

.edits{background-color:#330717; border:3px solid #912; border-radius:12px; color:#f45; padding:12px; margin:6px; word-wrap:break-word;}
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
.carbon, .time, .cell, .mySlides, .files, .edits{padding:8px; margin:6px; word-wrap:break-word;}
.mySlides{white-space:pre-wrap; padding-right:32px;}
.closebtn{position:absolute; top:15px; right:15px;}
.carbon, .files, .edits{margin-right:12px;}
.cell{overflow:auto; width:calc(100% - 30px); display:inline-block; vertical-align:text-top;}
h2{margin:4px;}
.postMessage{white-space:pre-wrap;}
[contenteditable]:focus {outline: none;}
::selection { background: transparent; }
.menu {color:#9b859d; background-color:#110c13;}
.exitmenu {color:#f45; background-color:#2d0710;}
.stdout {white-space:pre-wrap; color:#9b859d; background-color:#110c13; border:2px solid #221926; display:inline-block; padding:6px; min-height:0px;}
.schande{opacity:0.5; position:absolute; top:150px; text-align:center; line-height:40px; height:40px; margin:3px; cursor:pointer; min-width:50px; border:2px solid #f66; background-color:#602; color:#f45;}
.saint{border:2px solid #6f6; background-color:#260; color:#4f5;}
</style>
<script>
var xhr = new XMLHttpRequest();
function send(b){
  xhr.open("POST", '', true);
  xhr.setRequestHeader('Content-Type', 'application/octet-stream');
  xhr.send(b);
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

var FFclick = function(e) {
  var t = e.target;
  var a = t.parentNode;
  if (t.hasAttribute("data-saint")) {
    send(t.getAttribute("data-saint"));
  } else if (t.hasAttribute("data-schande")) {
    send(t.getAttribute("data-schande"));
  } else if (a.classList.contains("fileThumb")) {
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
  if(t.classList.contains("lazy") && !t.hasAttribute("busy")) {
    var d = document.createElement("div");
    d.innerHTML = "<div class='schande saint' style='display:none;'>Saint</div><div class='schande' style='/*left:54px;*/'>Schande!</div>";
    var a = t.parentNode.parentNode;
    a.appendChild(d);
    let isover = function(g) {
      g.target.style.opacity = 1
      if (g.target.classList.contains("saint")) {
        g.target.setAttribute("data-schande", t.getAttribute("data-src"))
      } else {
        g.target.setAttribute("data-saint", t.getAttribute("data-src"))
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
      t.removeAttribute("busy")
      a.removeEventListener("mouseleave", left);
    }
    t.setAttribute("busy", true)
    a.addEventListener("mouseleave", left);
  }
}

document.addEventListener("click", FFclick);
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
        var m = new Image();
        m.src = t.parentNode.parentNode.parentNode.childNodes[1].childNodes[0].getAttribute("href");
        if(m.src == s.src) {
          context.fillRect(0, 0, s.width, s.height);
        } else {
          isTainted = true;
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
  t = t.toLowerCase();
  var x = document.getElementsByClassName("cell");
  var c;
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
  for (var i=0; i < x.length; i++) {
    var m = '';
    if (c){
      m = x[i].getElementsByClassName(e[0])
      if (m.length > 0){
        m = m[0].textContent;
      } else {
        x[i].style.display = 'none';
        continue
      }
    } else {
      m = x[i].getElementsByTagName(e[0])
      if (m.length > 0){
        m = m[0].textContent;
      } else {
        x[i].style.display = 'none';
        continue
      }
    }
    m = m.toLowerCase().includes(t);
    if (!a && !m && t || a && m && t) {
      x[i].style.display = 'none';
    } else {
      x[i].style.display = 'inline-block';
    }
  }
}

window.onload = () => {
  var links = document.getElementsByTagName('a');
  for(var i=0; i<links.length; i++) {
    links[i].target = "_blank";
  }
  stdout = document.getElementById("stdout");
  if(!stdout.isContentEditable){
    stdout.setAttribute("onpaste", "plaintext(this, event)");
    stdout.setAttribute("contenteditable", "true");
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
    """ + f"""image.style.height = "{imgsize}""" + """px"
    image.style.width = "auto"
    imageObserver.observe(image);
  });
}
</script>
<body>
<div id="tooltip" class="closebtn" style="padding:0px 8px; font-family:sans-serif; z-index:9999999; left:0px; top:0px; right:initial; pointer-events:none;"></div><div style="display:block; height:20px;"></div><p class="stdout" id="stdout" style="display:none;" onpaste="plaintext(this, event);" contenteditable="plaintext-only" spellcheck=false><div class="container" style="display:none;">
<button class="closebtn" onclick="this.parentElement.style.display='none'">&times;</button>""" + f"""<div class="mySlides">{listurls}</div>
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
<input class="next" type="text" oninput="hideParts('h2', this.value, false);" style="padding-left:8px; padding-right:8px; width:140px;" placeholder="Search title">
<input class="next" type="text" oninput="hideParts('h2', this.value);" style="padding-left:8px; padding-right:8px; width:140px;" placeholder="Ignore title">
<button class="next" onclick="hideParts('.edits')">Edits</button>
<button class="next" onclick="hideParts()">&times;</button></div>
{builder}</body>
<script>
lazyload();
</script>
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



def tohtml(subdir, htmlname, fromhtml, orphan_files, rejlist):
    builder = ""
    listurls = ""
    htmlpart = fromhtml["partition"]
    thumbnail_dir = "HTML assets/"
    if not os.path.exists(subdir + thumbnail_dir):
        os.makedirs(subdir + thumbnail_dir)
    new_relics = htmlpart.copy()



    for icon in fromhtml["icons"]:
        if not os.path.exists(subdir + thumbnail_dir + icon["name"]):
            if not (err := get(icon["link"], subdir + thumbnail_dir + icon["name"])) == 1:
                echo(f""" Error downloading ({err}): {icon["link"]}""", 0, 1)
        builder += f"""<img src="{htmlname}/{thumbnail_dir}{icon["name"]}" height="100px">\n"""
    if x := fromhtml["page"]:
        builder += f"""<h2>Paysite: <a href="{x["link"]}">{x["name"]}</a></h2>"""



    for key in new_relics.keys():
        new_relics[key] = htmlpart[key].copy()
        files = []
        duplicates = set()
        for file in htmlpart[key]["files"]:
            if not file["name"] in duplicates and not duplicates.add(file["name"]):
                files += [file["name"].rsplit("/", 1)[-1]]
        new_relics[key]["files"] = files
        for array in new_relics[key]["html"]:
            if len(array) == 2 and array[1]:
                array[1]["name"] = array[1]["name"].rsplit("/", 1)[-1]



    partfile = subdir + thumbnail_dir + "partition.json"
    gallery_is = "updated"
    if not os.path.exists(partfile):
        gallery_is = "created"
        with open(partfile, 'w') as f:
            f.write(json.dumps(new_relics))
    with open(partfile, 'r', encoding="utf-8") as f:
        relics = json.loads(f.read())
    orphan_keys = iter(relics.keys())
    part = {}
    for key in new_relics.keys():
        if not key in relics:
            part.update({key:new_relics[key]})
            continue
        for orphan_key in orphan_keys:
            if not key == orphan_key:
                part.update({orphan_key:relics[orphan_key]})
            else:
                break
        if not relics[key]["html"] or not relics[key]["keywords"] == new_relics[key]["keywords"]:
            part.update({key:new_relics[key]})
        else:
            part.update({key:relics[key]})
    with open(partfile, 'w') as f:
        f.write(json.dumps(part))
    buffer = partfile.replace("/", "\\")
    print(f" File {gallery_is}: {buffer}")



    for file in orphan_files:
        if file.endswith(tuple(specialfile)) or file.startswith("icon"):
            continue
        key = file.split(".", 1)[0]
        if not key in part.keys():
            key = "0"
        if "orphan_files" in part[key]:
            part[key]["orphan_files"] += [file]
        else:
            part[key]["orphan_files"] = [file]
    if buildthumbnail:
        echo("Building thumbnails . . .")



    for key in part.keys():
        keywords = part[key]["keywords"]
        if key == "0":
            if "orphan_files" in part[key]:
                title = "<h2>Unsorted</h2>"
                content = "No matching partition found for this files. Either partition IDs are not assigned properly in file names or they're just really orphans.\n"
            else:
                continue
        else:
            title = f"<h2>{keywords[0]}</h2>" if keywords and keywords[0] else f"""<h2 style="color:#666;">ꍯ Part {key} ꍯ</h2>"""
            content = ""
        new_container = False
        end_container = False
        builder += """<div class="cell">\n"""
        if len(keywords) > 1:
            time = keywords[1] if keywords[1] else "No timestamp"
            keywords = ", ".join(x for x in keywords[2:]) if len(keywords) > 2 else "None"
            builder += f"""<div class="time" id="{key}" style="float:right;">Part {key} ꍯ {time}<sup><span style="font-size:80%;">UTC</span></sup>\nKeywords: {keywords}</div>\n"""
        builder += title
        if part[key]["files"]:
            builder += "<div class=\"files\">\n"
            for file in part[key]["files"]:
                builder += container(subdir + file, rejlist, 1)
            builder += "</div>\n"
        if "orphan_files" in part[key]:
            builder += "<div class=\"edits\">\n"
            for file in part[key]["orphan_files"]:
                # os.rename(subdir + file, subdir + "Orphaned files/" + file)
                builder += container(subdir + file, rejlist, 1)
            builder += "<br><br>orphaned file(s)\n</div>\n"
        if html := part[key]["html"]:
            builder += """<div class="postMessage">"""
            for array in html:
                if len(array) == 2:
                    if new_container:
                        content += "<div class=\"carbon\">\n"
                        end_container = True
                        new_container = False
                    if array[1]:
                        content += f"""{array[0]}{container(subdir + array[1]["name"], rejlist, 1)}"""
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
                listurls += f"""# From <a href="#{key}">#{key}</a> :: {part[key]["keywords"][0]}<br>{links}\n"""
            builder += f"{content}</div>\n"
        elif not part[key]["files"]:
            builder += "<div class=\"edits\">Rebuild HTML with a different login/tier may be required to view</div>\n"
        builder += "</div>\n\n"
    with open(f"{batchname}/{htmlname}.html", 'wb') as f:
        f.write(bytes(new_html(builder, htmlname, listurls), "utf-8"))
    print(f" File {gallery_is}: {batchname}\\{htmlname}.html ")



def patrolthread(patrol):
    while True:
        patrolthreadn, folder, rejlist, total, file, log = patrol.get()
        ondisk = batchname + "/" + folder + file
        if not file.endswith(tuple(specialfile)) and isrej(file, rejlist):
            print(f"  Mediocre on disk: {ondisk}")
            log.append(f"&gt; Mediocre on disk: {ondisk}")
        elif file.endswith(tuple(imagefile)):
            try:
                image = Image.open(ondisk)
                image.verify()
            except:
                print(f" Corrupted on disk: {ondisk}")
                log.append(f"&gt; Corrupted on disk: {ondisk}")
        elif sevenz and file.endswith(tuple(archivefile)):
            if subprocess.call(f'"{sevenz}" t -pBadPassword "{ondisk}"', stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL):
                print(f" Corrupted on disk: {ondisk}")
                log.append(f"&gt; Corrupted on disk: {ondisk}")
        if patrolthreadn%8 == 0:
            echo(" PATROL MEDIOCRE: " + str(int((patrolthreadn / total) * 100)) + "%")
        patrol.task_done()
patrol = Queue()
for i in range(8):
    t = Thread(target=patrolthread, args=(patrol,))
    t.daemon = True
    t.start()



pledges = []
if Patreoncookie:
    print("Checking your pledges on Patreon . . .")
    resp, err = fetch("https://www.patreon.com/api/pledges?include=creator.null&fields[pledge]=&fields[user]=")
    try:
        api = json.loads(resp.read().decode('utf-8'))
    except:
        kill(0, f"Patreon cookie may be outdated ({err}).", r="Patreon cookie")
    artists = api["data"]
    for artist in artists:
        pledges += [artist["relationships"]["creator"]["data"]["id"]]
    resp, err = fetch("https://www.patreon.com/api/stream?include=user.null&fields[post]=&fields[user]=")
    api = json.loads(resp.read().decode("utf-8"))
    if not "included" in api:
        kill(0, "You haven't pledged to any artists on Patreon!", r="Patreon cookie")
    for artist in api["included"]:
       pledges += [artist["id"]]
    pledges = list(dict.fromkeys(pledges))
    if not pledges and not favoriteispledged:
        kill(0, "You haven't pledged to any artists on Patreon!", r="Patreon cookie")
if Fanboxcookie:
    referers.update({"https://api.fanbox.cc/":"https://www.fanbox.cc"})
    print("Checking your pledges on Fanbox . . .")
    resp, err = fetch("https://api.fanbox.cc/plan.listSupporting")
    try:
        api = json.loads(resp.read().decode('utf-8'))
    except:
        kill(0, f"Fanbox cookie may be outdated ({err}).", r="Fanbox cookie")
    artists = api["body"]
    if not artists and not favoriteispledged:
        kill(0, "You haven't pledged to any artists on Fanbox!", r="Fanbox cookie")
    else:
        for artist in artists:
            pledges += [artist["user"]["userId"]]
if Fantiacookie:
    print("Checking your pledges on Fantia . . .")
    resp, err = fetch("https://fantia.jp/mypage/users/plans")
    try:
        html = resp.read().decode('utf-8')
    except:
        kill(0, f"Fantia cookie may be outdated ({err}).", r="Fantia cookie")
    if not html:
        kill(0, "You haven't pledged to any artists on Fantia!", r="Fantia cookie")



def new_p(z):
    return {z:{"html":[], "keywords":[], "files":[]}}

def new_part(threadn=0):
    new = {threadn:new_p("0")} if threadn else new_p("0")
    return {"ready":True, "page":"", "folder":"", "makehtml":False, "campaign_id":None, "icons":[], "inlinefirst":True, "partition":new}

def fanbox_avatars(threadn, htmlname, id):
    api = json.loads(get(f"https://api.fanbox.cc/creator.get?userId={id}", stderr=f"Broken API on Fanbox for {htmlname}", threadn=threadn).decode('utf-8'))
    if obj := api["body"]:
        return {"page":{"link":f"""https://{obj["creatorId"]}.fanbox.cc/""", "name":obj["user"]["name"]}, "icons":[{"link":obj["user"]["iconUrl"], "name":"avatar.png", "edited":0}, {"link":obj["coverImageUrl"], "name":"cover.png", "edited":0}]}

def fantia_avatars(threadn, htmlname, id):
    api = json.loads(get("https://fantia.jp/api/v1/fanclubs/" + id, stderr=f"Broken API on Fantia for {htmlname}", threadn=threadn).decode('utf-8'))
    if obj := api["fanclub"]:
        return {"page":{"link":f"https://fantia.jp/fanclubs/{id}", "name":obj["fanclub_name_with_creator_name"]}, "icons":[{"link":obj["icon"]["original"], "name":"avatar.png", "edited":0}, {"link":obj["cover"]["original"], "name":"cover.png", "edited":0}]}

def patreon_avatars(threadn, htmlname, id):
    if not (data := get("https://www.patreon.com/api/user/" + id, utf8=True, stderr=f"Broken API on Patreon while fetching profile for {htmlname}\n > Or failed at Patreon's aggressive anti-bot detection\n > To pass: provide your browser's user-agent string and cookie value for __cf_bm\n\n", threadn=threadn)).isdigit():
        api = json.loads(data)
        if obj := api["included"][0]["attributes"]:
            return {"page":{"link":api["data"]["attributes"]["url"], "name":api["data"]["attributes"]["vanity"]}, "campaign_id":api["data"]["relationships"]["campaign"]["data"]["id"], "icons":[{"link":obj["avatar_photo_url"], "name":"avatar.png", "edited":0}, {"link":obj["cover_photo_url"], "name":"cover.png", "edited":0}]}



def fanbox_assets(threadn, htmlname, id):
    fromhtml = new_part()
    fromhtml.update(fanbox_avatars(threadn, htmlname, id))
    url = f"https://api.fanbox.cc/post.listCreator?userId={id}&limit=10"
    while True:
        api = get(url, stderr=f"Broken API on Fanbox for {htmlname}", threadn=threadn)
        if not api:
            return fromhtml
        api = json.loads(api.decode('utf-8'))
        for next_obj in api["body"]["items"]:
            key = next_obj["id"]
            keywords = [next_obj["title"], next_obj["updatedDatetime"].replace("T", " ").split("+", 1)[0]]
            edited = keywords[1].split(" ", 1)[0].replace("-", "")
            html = []
            filelist = []
            if not next_obj["body"]:
                filelist = []
            elif "text" in next_obj["body"]:
                html = [[hyperlink(next_obj["body"]["text"].replace("\n", "<br>")), ""]]
                filelist += next_obj["body"]["images"] if "images" in next_obj["body"] else []
            elif "blocks" in next_obj["body"]:
                for block in next_obj["body"]["blocks"]:
                    if "text" in block:
                        html += [["<p>" + hyperlink(block["text"].replace("\n", "<br>")), ""]]
                    else:
                        url = next_obj["body"]["imageMap"][block["imageId"]]["originalUrl"]
                        html += [["<p>", {"link":url, "name":key + "." + url.rsplit("/", 1)[1], "edited":edited}]]
                filelist = []
            files = []
            for file in filelist:
                url = file["originalUrl"]
                files += [{"link":url, "name":key + "." + url.rsplit("/", 1)[1], "edited":edited}]
            fromhtml["partition"].update({key:{"keywords":keywords, "html":html, "files":files}})
        if api["body"]["nextUrl"]:
            url = api["body"]["nextUrl"]
        else:
            break
    return fromhtml



def fantia_assets(threadn, htmlname, id):
    fromhtml = new_part()
    fromhtml.update(fantia_avatars(threadn, htmlname, id))
    page = 1
    while True:
        html = get(f'https://fantia.jp/fanclubs/{id}/posts?page={page}', stderr=f"Error getting new page for {htmlname} on Fantia", threadn=threadn).decode("utf-8")
        html = html.replace("\n", "").replace("<div class=\"post-meta\">", "\n").replace(u"\u2028"," ").splitlines()
        for part in html[1:]:
            key = part.split("href=\"/posts/", 1)[1].split("\"", 1)[0]
            assets = get("https://fantia.jp/posts/" + key, stderr=f"Error getting new page for {htmlname} on Fantia", threadn=threadn).decode("utf-8")
        page += 1
    return fromhtml

    print(f"Yiff.party's dead, Jim.")
    html = get('https://yiff.party/fantia/' + id, stderr=f"Error getting new page for {htmlname} on Fantia", threadn=threadn).decode("utf-8")
    html = html.replace("\n", "").replace("style=\"background: url('", "\n").replace("yp-info-img\" src=\"", "\n").replace(u"\u2028"," ").splitlines()
    fromhtml.update({"cover":html[1].split("'", 1)[0]})
    fromhtml.update({"avatar":html[2].split("\"", 1)[0]})
    html = html[2].split("<div class=\"container\">")[1]
    html = html.replace("<a href=\"/fantia/posts/", "\n").splitlines()[1:]
    edited = 0
    for part in html:
        key = part.split("\"", 1)[0]
        assets = get('https://yiff.party/fantia/posts/' + key, stderr=f"Error reading posts for {htmlname} on Fantia", threadn=threadn).decode("utf-8")
        assets = assets.replace(u"\u2028","\n").replace("\n ", "\n").replace("\n", "\\n").replace("col s12 l9\">\\n", "\nheader", 1).replace("<div class=\"yp-post-content\">\\n", "\ncontent").replace("<div class=\"col s12 l3\">", "\n").splitlines()
        files = []
        html = []
        keywords = ["Untitled"]
        for asset in assets[1:]:
            if asset.startswith("header"):
                asset = asset.replace("header", "", 1)
                if asset.startswith("<a href=\""):
                    url = asset.split("\"", 2)[1]
                    name = key + "." + url.rsplit(".", 1)[1]
                    files += [{"link":url, "name":name[:200], "edited":edited}]
                keywords[0], header = asset.split("<h2>")[1].split("</h2>\\n", 1)
                html += [[header.replace("\\n", "<br>").replace("<p class=\"preline\">", "", 1)]]
            elif asset.startswith("content"):
                asset = asset.replace("content", "", 1).replace("<div class=\"yp-post-gallery\">\\n<div class=\"row\">\\n", "\n").splitlines()
                if len(asset) == 2:
                    html += [[asset[0].replace("\\n", "<br>"), ""]]
                    asset = asset[1].rsplit("\\n</div>", 2)[0].replace("\\n", "").replace("<div class=\"col s12 m6\"><a href=\"", "\nimagefile\"").splitlines()
                    for gallery in asset:
                        if gallery.startswith("imagefile"):
                            url = gallery.split("\"", 2)[1]
                            name =  key + " " + url.rsplit("/", 3)[1] + "." + url.rsplit("/", 2)[1] + "." + url.rsplit(".", 1)[1]
                            html += [["", {"link":url, "name":name, "edited":edited}]]
                else:
                    asset = asset[0].split("</div>", 1)[0].replace("\\n", "<br>").replace("<p class=\"preline\">", "").replace("</p>", "")
                    if "<div class=\"yp-post-download\">" in asset:
                        asset, download = asset.rsplit("<a href=\"", 1)
                        url, name = download.split("\" download=\"")
                        name = key + " " + url.rsplit("/", 2)[1] + "." + name.split("\"", 1)[0]
                        html += [[asset, ""]]
                        html += [["", {"link":url, "name":name[:200], "edited":edited}]]
                    else:
                        html += [[asset, ""]]
                html += [[""]]
        fromhtml["partition"].update({key:{"keywords":keywords, "html":html, "files":[]}})
    return fromhtml



def kp_fanbox_assets(threadn, htmlname, id):
    fromhtml = new_part()
    page = 0
    while True:
        if (api := get(f"https://kemono.party/api/fanbox/user/{id}?o={page*25}", stderr=f"Broken API on kemono.party for {htmlname}\n > Or failed at Kemono's aggressive anti-bot detection\n > To pass: provide your browser's user-agent string and cookie value for __ddg1\n\n", threadn=threadn)).isdigit():
            return
        if not (api := json.loads(api.decode('utf-8'))):
            break
        for next_obj in api:
            pos = 0
            key = next_obj["id"]
            keywords = [next_obj["title"], datetime.strptime(next_obj["published"], "%a, %d %b %Y %H:%M:%S GMT").isoformat(" ")]
            # desired result is "YYYY-MM-DD HH:MM:SS"
            edited = keywords[1].split(" ", 1)[0].replace("-", "")
            files = []
            if file := next_obj["file"]:
                ext = file["name"].rsplit(".", 1)[-1]
                if ext == "jpe":
                    ext = "jpeg"
                files += [{"link":"https://kemono.party" + file["path"], "name":f"{key}.{pos:03}.{ext}", "edited":edited}]
            if attachments := next_obj["attachments"]:
                for file in attachments:
                    pos += 1
                    ext = file["name"].rsplit(".", 1)[-1]
                    if ext == "jpe":
                        ext = "jpeg"
                    files += [{"link":"https://kemono.party" + file["path"], "name":f"{key}.{pos:03}.{ext}", "edited":edited}]
            html = []
            if next_obj["content"]:
                next_obj = next_obj["content"].replace("\n", "").replace("<p>", "").replace("<br></p>", "").replace("</p>", "").split("<br>")
                if len(next_obj) > 1:
                    for block in next_obj:
                        block = block.split("<img src=")
                        if len(block) > 1:
                            pos += 1
                            url = "https://kemono.party" + block[1].split("\"")[1]
                            ext = url.rsplit("/", 1)[1].rsplit(".", 1)[-1]
                            if ext == "jpe":
                                ext = "jpeg"
                            html += [["<p>", {"link":url, "name":f"{key}.{pos:03}.{ext}", "edited":edited}]]
                        else:
                            block = block[0].split("<a href=")
                            if len(block) > 1:
                                pos += 1
                                url = "https://kemono.party" + block[1].split("\"")[1]
                                ext = url.rsplit("/", 1)[1].rsplit(".", 1)[-1]
                                if ext == "jpe":
                                    ext = "jpeg"
                                html += [["<p>", {"link":url, "name":f"{key}.{pos:03}.{ext}", "edited":edited}]]
                            else:
                                html += [["<p>" + hyperlink(block[0]), ""]]
                else:
                    html += [[hyperlink(next_obj[0].replace("<br />", "<br>")), ""]]
            fromhtml["partition"].update({key:{"keywords":keywords, "html":html, "files":files}})
        page += 1
    return fromhtml



def kp_fantia_assets(threadn, htmlname, id):
    fromhtml = new_part()
    page = 0
    while True:
        if (api := get(f"https://kemono.party/api/fantia/user/{id}?o={page*25}", stderr=f"Broken API on kemono.party for {htmlname}\n > Or failed at Kemono's aggressive anti-bot detection\n > To pass: provide your browser's user-agent string and cookie value for __ddg1\n\n", threadn=threadn)).isdigit():
            return
        if not (api := json.loads(api.decode('utf-8'))):
            break
        for next_obj in api:
            pos = 0
            key = next_obj["id"]
            keywords = [next_obj["title"], datetime.strptime(next_obj["published"], "%a, %d %b %Y %H:%M:%S GMT").isoformat(" ")]
            # desired result is "YYYY-MM-DD HH:MM:SS"
            edited = keywords[1].split(" ", 1)[0].replace("-", "")
            files = []
            if file := next_obj["file"]:
                pos += 1
                ext = file["name"].rsplit(".", 1)[-1]
                if ext == "jpe":
                    ext = "jpeg"
                files += [{"link":"https://kemono.party" + file["path"], "name":f"{key}.{pos:03}.{ext}", "edited":edited}]
            if attachments := next_obj["attachments"]:
                for file in attachments:
                    pos += 1
                    ext = file["name"].rsplit(".", 1)[-1]
                    if ext == "jpe":
                        ext = "jpeg"
                    files += [{"link":"https://kemono.party" + file["path"], "name":f"{key}.{pos:03}.{ext}", "edited":edited}]
            html = []
            if next_obj["content"]:
                next_obj = next_obj["content"].split("\n")
                if len(next_obj) > 1:
                    for block in next_obj:
                        html += [[hyperlink(block[0]), ""]]
                else:
                    html += [[hyperlink(next_obj[0]), ""]]
            fromhtml["partition"].update({key:{"keywords":keywords, "html":html, "files":files}})
        page += 1
    return fromhtml



def kp_patreon_assets(threadn, htmlname, id):
    fromhtml = new_part()
    if Patreoncookie and (data := patreon_avatars(threadn, htmlname, id)):
        fromhtml.update(data)
    page = 0
    while True:
        if (api := get(f"https://kemono.party/api/patreon/user/{id}?o={page*25}", stderr=f"Broken API on kemono.party for {htmlname}\n > Or failed at Kemono's aggressive anti-bot detection\n > To pass: provide your browser's user-agent string and cookie value for __ddg1\n\n", threadn=threadn)).isdigit():
            return
        if not (api := json.loads(api.decode('utf-8'))):
            break
        for next_obj in api:
            key = next_obj["id"]
            keywords = [next_obj["title"], datetime.strptime(next_obj["published"], "%a, %d %b %Y %H:%M:%S GMT").isoformat(" ")]
            # desired result is "YYYY-MM-DD HH:MM:SS"
            edited = keywords[1].split(" ", 1)[0].replace("-", "")
            files = []
            if file := next_obj["file"]:
                files += [{"link":"https://kemono.party" + file["path"], "name":saint(key + "." + file["name"]), "edited":edited}]
            if attachments := next_obj["attachments"]:
                for file in attachments:
                    files += [{"link":"https://kemono.party" + file["path"], "name":saint(key + "." + file["name"]), "edited":edited}]
            html = []
            embed = ""
            if next_obj["embed"]:
                url = next_obj["embed"]["url"]
                embed = f"""<p><a href="{url}">{url}</a></p>"""
            if next_obj["content"]:
                next_obj = ["", next_obj["content"]]
                while True:
                    next_obj = next_obj[1].split("<img data-media-id=\"", 1)
                    if len(next_obj) == 2:
                        image, next_obj[1] = next_obj[1].split(">", 1)
                        name, url = image.split("\" src=\"")
                        url = url.split("\"", 1)[0]
                        try:
                            ext = url.rsplit("/", 1)[1].split("?")[0].split(".")[1]
                            name = f"""{key}.{name}.{ext}"""
                        except:
                            name = url
                        html += [[next_obj[0], {"link":"https://kemono.party" + url, "name":saint(name), "edited":edited}]]
                    else:
                        break
                html += [[next_obj[0] + embed, ""]]
            fromhtml["partition"].update({key:{"keywords":keywords, "html":html, "files":files}})
        page += 1
    return fromhtml



def patreon_assets(threadn, htmlname, id):
    fromhtml = new_part()
    if data := patreon_avatars(threadn, htmlname, id):
        fromhtml.update(data)
    else:
        return
    url = "https://www.patreon.com/api/posts?include=attachments%2Cimages.null%2Caudio.null&fields[post]=content%2Ccurrent_user_can_view%2Cedited_at%2Cembed%2Cpost_file%2Cpost_type%2Ctitle&fields[media]=download_url%2Cfile_name%2Cowner_id&sort=-published_at&filter[campaign_id]=" + fromhtml["campaign_id"]
    while True:
        if (api := get(url, stderr=f"Broken API on Patreon while fetching posts for {htmlname}\n > Or failed at Patreon's aggressive anti-bot detection\n > To pass: provide your browser's user-agent string and cookie values for __cf_bm and __cfuid\n\n", threadn=threadn)).isdigit():
            return
        api = json.loads(api.decode('utf-8'))
        if not "included" in api or not "data" in api:
            break
        edited = {}
        for next_obj in api["data"]:
            key = next_obj["id"]
            next_obj = next_obj["attributes"]
            keywords = [next_obj["title"], next_obj["edited_at"].replace("T", " ").split(".", 1)[0] if next_obj["edited_at"] else "0"]
            edited.update({key:keywords[1].split(" ", 1)[0].replace("-", "")})
            html = []
            files = []
            embed = ""
            if next_obj["current_user_can_view"]:
                if file := next_obj["post_file"]:
                    files += [{"link":file["url"], "name":key + "." + file["name"], "edited":edited[key]}]
                if next_obj["embed"]:
                    url = next_obj["embed"]["url"]
                    embed = f"""<p><a href="{url}">{url}</a></p>"""
                next_obj = ["", next_obj["content"]]
                while True:
                    next_obj = next_obj[1].split("<img data-media-id=\"", 1)
                    if len(next_obj) == 2:
                        image, next_obj[1] = next_obj[1].split("\">", 1)
                        name, url = image.split("\" src=\"")
                        name = f"""{key}.{name}.{url.rsplit("/", 1)[1].split("?")[0].split(".")[1]}"""
                        html += [[next_obj[0], {"link":url, "name":name, "edited":edited[key]}]]
                    else:
                        break
                html += [[next_obj[0] + embed, ""]]
            fromhtml["partition"].update({key:{"keywords":keywords, "html":html, "files":files}})
        for attachment in api["included"]:
            if attachment["type"] == "attachment":
                key = attachment["relationships"]["post"]["data"]["id"]
                fromhtml["partition"][key]["files"] += [{"link":attachment["attributes"]["url"], "name":f"""{key}.{attachment["attributes"]["name"][:200]}""", "edited":edited[key]}]
            if "type" in attachment and attachment["type"] == "media" and "download_url" in attachment["attributes"]:
                key = attachment["attributes"]["owner_id"]
                fromhtml["partition"][key]["files"] += [{"link":attachment["attributes"]["download_url"], "name":f"""{key}.{attachment["attributes"]["file_name"].rsplit("/", 1)[-1][:200]}""", "edited":edited[key]}]
        if "links" in api and "next" in api["links"]:
            url = api["links"]["next"]
        else:
            break
    return fromhtml



def get_assets(artworks):
    while True:
        threadn, shelf, id, htmlname, HOME = artworks.get()
        mirror_assets = []
        paysite_assets = []
        if Kemonoparty:
            if HOME == "Fanbox":
                mirror_assets = kp_fanbox_assets(threadn, htmlname, id)
            elif HOME == "Fantia":
                mirror_assets = kp_fantia_assets(threadn, htmlname, id)
            elif HOME == "Patreon":
                mirror_assets = kp_patreon_assets(threadn, htmlname, id)
            print(f"Fetched new data for {htmlname}")
        if id in pledges:
            if HOME == "Fanbox":
                paysite_assets = fanbox_assets(threadn, htmlname, id)
            elif HOME == "Fantia":
                paysite_assets = fantia_assets(threadn, htmlname, id)
            elif HOME == "Patreon":
                paysite_assets = patreon_assets(threadn, htmlname, id)
            print(f"Fetched new data for {htmlname} ({HOME})")
        shelf.update({HOME + id: {"htmlname":htmlname, "m":[[], [], False], "inlinefirst": False, "mirror": mirror_assets, "paysite": paysite_assets}})
        fromhtml = shelf[HOME + id]
        if os.path.exists(x := f"{batchname}/{htmlname}/mediocre.txt"):
            with open(x, 'r', encoding='utf-8') as f:
                fromhtml["m"][0] = f.read().splitlines()
        if os.path.exists(x := f"{batchname}/{htmlname}/magnificent.txt"):
            with open(x, 'r', encoding='utf-8') as f:
                fromhtml["m"][1] = f.read().splitlines()
            if "inherit" in fromhtml["m"][1]:
                fromhtml["m"][2] = True
        echothreadn.remove(threadn)
        artworks.task_done()
    echothreadn.remove(threadn)
    artworks.task_done()



artworks = Queue()
for i in range(8):
    t = Thread(target=get_assets, args=(artworks,))
    t.daemon = True
    t.start()



def nextshelf(fromhtml, paysite=False):
    if not ready:
        fromhtml_pm = fromhtml["paysite" if paysite else "mirror"]
        htmlpart = fromhtml_pm["partition"]
        stdout = ""
        for k in htmlpart.keys():
            for file in htmlpart[k]["files"]:
                x = get_cd(file, [], fromhtml["m"], preview=True)
                stdout += tcolorb + x[0] + tcolorr + " -> " + tcolorg + x[1].replace("/", "\\") + "\n"
            for h in htmlpart[k]["html"]:
                if h[1]:
                    x = get_cd(h[1], [], fromhtml["m"], preview=True)
                    stdout += tcolorb + x[0] + tcolorr + " -> " + tcolorg + x[1].replace("/", "\\") + "\n"
        stdout += f"{tcolorx}\n Then create {tcolorg}{batchname}\\{htmlname}.html{tcolorx} with\n"
        if x := fromhtml_pm["icons"]:
            stdout += f"""{tcolorg}█{"█ █".join([i["name"] for i in x])}█\n"""
        if x := fromhtml_pm["page"]:
            stdout += f"""{tcoloro}<h2><a href="{x["link"]}">{x["name"]}</a></h2>\n"""
        for k in htmlpart.keys():
            if k == "0" and not htmlpart[k]["files"]:
                continue
            stdout += tcolorx + k + tcolor + "\n"
            if x := htmlpart[k]["keywords"]:
                keywords = ", ".join(f"{kw}" for kw in x[2:])
                stdout += tcolorb + (x[0] if len(x) > 0 and x[0] else "No title for " + k) + tcolor + " Timestamp: " + (x[1] if len(x) > 1 and x[1] else "No timestamp") + tcolorr + " Keywords: " + (keywords if keywords else "None") + "\n"
            for file in htmlpart[k]["files"]:
                stdout += tcolorg + file["name"].rsplit("\\")[-1] + "\n"
            if html := htmlpart[k]["html"]:
                for h in html:
                    if h[0]:
                        stdout += tcoloro + h[0]
                    if h[1]:
                        stdout += tcolorg + "█" + h[1]["name"].rsplit("\\")[-1] + "█"
                stdout += "\n"
        echo(f"""{stdout}{tcolorx} ({tcolorb}Download file {tcolorr}-> {tcolorg}to disk{tcolorx}) - Add scraper instruction "ready" in {rulefile} to stop previews for this site (C)ontinue or (B)ack to main menu: """, 0, 1)
        Keypress_B[0] = False
        Keypress_C[0] = False
        while not Keypress_B[0] and not Keypress_C[0]:
            time.sleep(0.1)
        Keypress_C[0] = False
        if Keypress_B[0]:
            Keypress_B[0] = False
            return
    downloadtodisk(fromhtml, paysite)



htmldata = [[]]
def scrape(pages):
    shelf = {}
    queued = []
    threadn = 0

    for htmlname, id, HOME in pages:
        if favoriteispledged:
            pledges += [id]
        if HOME + id in queued:
            continue
        queued += [HOME + id]
        threadn += 1
        echothreadn.append(threadn)
        artworks.put((threadn, shelf, id, htmlname, HOME))
    htmlname = batchfile
    try:
        artworks.join()
    except KeyboardInterrupt:
        pass # Ctrl + C

    for htmlname, id, HOME in pages:
        if not os.path.exists(f"{batchname}/{htmlname}/"):
            os.makedirs(f"{batchname}/{htmlname}/")
        if shelf[HOME + id]["mirror"]:
            print(f"\n - - - - {htmlname} - - - -")
            title(status() + htmlname)
            htmldata[0] += [f"<p>- - - - {htmlname} - - - -</p>"]
            nextshelf(shelf[HOME + id])
        if shelf[HOME + id]["paysite"]:
            print(f"\n - - - - {htmlname} (only on {HOME}) - - - -")
            title(f"{status()}{htmlname} (only on {HOME})")
            htmldata[0] += [f"<p>- - - - {htmlname} (only on {HOME}) - - - -</p>"]
            nextshelf(shelf[HOME + id], True)



run_input = ["", "", False]
def read_input(m):
    return



def readfile():
    if not os.path.exists(textfile):
        open(textfile, 'w').close()
    print(f"Reading {textfile} . . .")
    with open(textfile, 'r', encoding="utf-8") as f:
        textread = f.read().splitlines()
    pages = []
    nextpages = []
    HOME = "Patreon"
    for line in textread[6:]:
        if not line:
            continue
        elif line.lower() == "fanbox":
            HOME = "Fanbox"
            continue
        elif line.lower() == "fantia":
            HOME = "Fantia"
            continue
        elif line.lower() == "patreon":
            HOME = "Patreon"
            continue
        elif line == "then":
            nextpages += [pages]
            pages = []
            continue
        elif line == "end":
            break
        if not line[0].isdigit() or " seconds rarity " in line:
            continue
        id = ""
        for d in line:
            if d.isdigit():
                id += d
            else:
                break
        if not line.replace(id, ""):
            print(f"\nPlease append name (any name) to {id} e.g. {id}.name or {id}name in {rulefile} then try again.\nThe name must not start with number!")
            return
        htmlname = line.replace("\\", "/").rsplit("/", 1)[-1]
        pages += [[htmlname, id, HOME]]
    nextpages += [pages]

    if nextpages:
        resume = False
        htmldata[0] = []
        for pages in nextpages:
            if resume:
                print("\n Resuming next favorites")
            else:
                resume = True
            scrape(pages)

    if newfilen[0] or not os.path.exists(htmlfile) or Patrol:
        with open(htmlfile, 'wb') as f:
            f.write(bytes(new_html("\n".join(htmldata[0]), "Today download result", ""), 'utf-8'))
        builder = ""
        for file in next(os.walk(batchname + "/"))[2]:
            if not file.endswith(".html"):
                continue
            htmlname = file.replace(".html", "")
            if not os.path.exists(f"{batchname}/{htmlname}/"):
                continue
            builder += f"""
    <div class="cell">

    <h2>{htmlname}</h2>
    <div class="carbon">{container(f"{htmlname}/HTML assets/avatar.png")}</div>
    <div class="files" style="display:inline-block;">{container(f"{htmlname}/HTML assets/cover.png")}</div>
    <p><a href="{file}">{file}</a>\n</div>"""
        with open(batchname + "/" + "index.html", 'wb') as f:
            f.write(bytes(new_html(builder, "Index", "", 100), 'utf-8'))

    if not nextpages[0]:
        print(f"""
 No favorite artists in {rulefile}! Add artist ID and their name per line please.

 + To add new artists, find their ID, then append each with their name, please do not backspace or continue number after ID. E.G.
 | 312424/Adam Wan
 | # Insert a slash to use ending as folder E.G. \\Adam Wan\\ for Zaush.
 |
 | fanbox
 | 1092867.b@commission
 | # Appended names are for you to identify, they can be renamed (please also make your changes symmetrical to existing folders).
 + # Artists from different paysites in rule file can be grouped by paysite name headings ("Fanbox", "Fantia", "Patreon").
     Without them, {batchfile} will assume everyone is from Patreon.""")
    else:
        if not newfilen[0]:
            print(f"""\n Today download result HTML "{htmlfile}" {"updated with scan result" if Patrol else "will not be made at this time"}. There are 0 new pictures.""")
        elif newfilen[0] <= 256:
            print(f"""\n Today download result HTML "{htmlfile}" updated! You can view {newfilen[0]} new picture(s) in browser.""")
        else:
            print(f"""\n Today download result HTML "{htmlfile}" updated! It might be hard for browser to handle {newfilen[0]} new pictures!""")
    title(status() + batchfile)



def unrecognized(k):
    echo("", 1)
    echo(f"Keypress {k} unrecognized", 0, 1)
    if not busy[0]:
        ready_input()

def pressed(k, s=True):
    echo("", 1)
    k[0] = s
    if not busy[0]:
        ready_input()

def keylistener():
    while True:
        el = choice("abcdefghijklmnopqrstuvwxyz0123456789")
        if el == 1:
            pressed(Keypress_A)
        elif el == 2:
            unrecognized("B")
        elif el == 3:
            pressed(Keypress_C)
        elif el == 4:
            unrecognized("D")
        elif el == 5:
            unrecognized("E")
        elif el == 6:
            pressed(Keypress_F)
        elif el == 7:
            unrecognized("G")
        elif el == 8:
            unrecognized("H")
        elif el == 9:
            unrecognized("I")
        elif el == 10:
            unrecognized("J")
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
            unrecognized("M")
        elif el == 14:
            unrecognized("N")
        elif el == 15:
            unrecognized("O")
        elif el == 16:
            unrecognized("P")
        elif el == 17:
            pressed(Keypress_A, False)
        elif el == 18:
            pressed(Keypress_R)
        elif el == 19:
            pressed(Keypress_S)
        elif el == 20:
            if ticks:
                echo(f"""COOLDOWN {"DISABLED" if cooldown[0] else "ENABLED"}""", 1, 1)
            else:
                echo(f"""Timer not enabled, please add "#-# seconds rarity 100%" in {rulefile}, add another timer to manipulate rarity.""", 1, 1)
            cooldown[0] = False if cooldown[0] else True
            if not busy[0]:
                ready_input()
        elif el == 21:
            unrecognized("U")
        elif el == 22:
            unrecognized("V")
        elif el == 23:
            unrecognized("W")
        elif el == 24:
            echo(f"""SET ALL ERROR DOWNLOAD REQUESTS TO: {"SKIP" if Keypress_X[0] else "RETRY"}""", 1, 1)
            Keypress_X[0] = False if Keypress_X[0] else True
            Keypress_A[0] = True
            if not busy[0]:
                ready_input()
        elif el == 25:
            unrecognized("Y")
        elif el == 26:
            pressed(Keypress_CtrlC)
        elif 0 <= (n := min(el-27, 8)) < 9:
            echo(f"""MAX PARALLEL DOWNLOAD SLOT: {n} {"(pause)" if not n else ""}""", 1, 1)
            dlslot[0] = n
            if not busy[0]:
                ready_input()
        else:
            pressed(Keypress_CtrlC)
t = Thread(target=keylistener)
t.daemon = True
t.start()
print("""
 Key listener:
  > Press X to enable or disable indefinite retry on error downloading files (for this session).
  > Press S to skip next error once during downloading files.
  > Press T to enable or disable cooldown during errors (reduce server strain).
  > Press K to view cookies.
  > Press 1 to 8 to set max parallel download of 8 available slots, 0 to pause.
  > Press Z or CtrlC to break and reconnect of the ongoing downloads or to end timer instantly.""")



echo(mainmenu(), 0, 1)
ready_input()
while True:
    if run_input[2]:
        busy[0] = True
        readfile()
        run_input[2] = False
        busy[0] = False
        print()
        ready_input()
    try:
        time.sleep(0.1)
    except KeyboardInterrupt:
        echo(skull(), 0, 1)
        choice(bg="4c")



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
