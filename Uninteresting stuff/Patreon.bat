@echo off && goto loaded

import os, sys, ssl, socket, socks, time, json
from datetime import datetime
from http import cookiejar
from http.server import SimpleHTTPRequestHandler, HTTPServer
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

busy = [False]
cooldown = [False]
dlslot = [8]
echothreadn = []
error = [[]]
htmlname = batchfile
newfilen = [0]
Keypress_flush = [False]
Keypress_prompt = [False]
Keypress_A = [False]
Keypress_C = [False]
Keypress_F = [False]
Keypress_N = [False]
Keypress_S = [False]
Keypress_X = [False]
Keypress_CtrlC = [False]
retries = [0]
sf = [0]

# Probably useless settings
collisionisreal = False
# Please also delete ender files to take effect with older posts.
editisreal = False
# If you want to download possible edited pictures. Most of the time it's just edit of a text post.
buildthumbnail = False
# True if you want to serve pages efficiently. It'll take a while to build new thumbnails from large collection.
favoriteispledged = False
# All your favorites are your "pledges", used for when some creators have paid contents still available to you on Patreon for a month.
Kemonoparty = False



def ansi_color(b=False, f="3"):
    if not b:
        return "\033[0m"
    c = [b, f]
    n = 0
    for d in [4, 3]:
        c[n] = (f"{d}8;2;" + ";".join(str(int(x, 16)) for x in [f'{c[n]:06}'[i:i+2] for i in range(0, 6, 2)])) if len(c[n]) == 6 else f"{d if d == 4 else 9}{c[n]}"
        n += 1
    return f"\033[{c[0]};{c[1]}m"



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
    os.system("cat /dev/location > /dev/null &")
title(batchfile)
sys.stdout.write("Non-ANSI-compliant Command Prompt/Terminal (expect lot of visual glitches): Upgrade to Windows 10 if you're on Windows.")


def mainmenu():
    print("""
 Delete the ender file if:
  > You need files that was rejected by your filter list in the past.
  > The deleted files you want them back.
""")
def ready_input():
    sys.stdout.write(f"Ready to (L)oad your favorite artists from {textfile}: ")
    sys.stdout.flush()
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
def help():
    print(f"""
 + Find their ID, then append each with their name, please do not backspace or continue number after ID:
 | 312424/Adam Wan
 |   Insert a slash to use ending as folder E.G. \\Adam Wan\\ for Zaush.
 |
 | Artists from different paysites in rule file are separated by paysite names ("Fanbox", "Fantia", "Patreon"):
 | 312424.zaush
 |
 | fanbox
 + 1092867.b@commission""")



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



if not os.path.exists(rulefile):
    open(rulefile, 'w').close()
if os.path.getsize(rulefile) < 1:
    rules = ["- - - - Spoofer - - - -", "Mozilla/5.0 for http"]
else:
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
    return f"""
https://www.fanbox.cc for https://api.fanbox.cc

# Appended names are for you to identify, they can be renamed - But please do not backspace or continue number after ID.
# These are also folder names - Please make your changes symmetrical to existing folders.
# Inserting a slash in creator name will split and use the latter as folder name.
# Artists from different paysites are separated by paysite names ("Fanbox", "Fantia", "Patreon"). Without paysite name, {batchfile} will assume everyone is from Patreon.

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

# Per-creator filter how-to:
# Create mediocre.txt in creator folder to blacklist matching pattern, this will incorporate with global filters (here).
# Create magnificent.txt in creator folder to whitelist matching pattern, this will override global filters but not mediocre.txt. While mediocre.txt is king, global filters will still be overridden by this.
# Write "{rulefile}" in magnificent.txt to incorporate with global filters, adding flexibility. Illustrated example:

#                           global's !.zip = all but .zip
# mag's .zip              + global's !.zip = .zip only
# mag's .zip + "{rulefile}" + global's !.zip = all

# Filters will be case insensitive.
# The beginning and ending of a line will act like wildcard. The asterisk (*) will be literal.
# Ending wildcards will be disabled if there's a period at the beginning, to avoid matching pattern of a extension name in file names.
"""



comment = ""
offset = 0
settings = ["Launch HTML server = No", "Show mediocre = No", "Patrol mediocre = No", "Python = " + pythondir, "Proxy = socks5://"]
for setting in settings:
    if not rules[offset].replace(" ", "").startswith(setting.replace(" ", "").split("=")[0]):
        if offset == 0 and not "#" in "".join(rules):
            comment = new_comment()
            rules = tidy(offset, setting, comment=comment)
        else:
            rules = tidy(offset, setting)
        print(f"""Added new setting "{setting}" to {rulefile}!""")
    offset += 1
if comment:
    print(f"\n New comments (# comment) and download filters were added to {rulefile}.\n You may want to check/edit there then restart CLI before I download artpieces with filters and settings.")
    sys.exit()



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



# Loading referer, sort, and custom dir rules, and global file rejection by file types from rulefile
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
mag = []
med = []
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
    elif rule == "favoriteispledged":
        favoriteispledged = True
    elif rule == "Kemono.party":
        Kemonoparty = True
    elif rule.startswith('bgcolor '):
        bgcolor = rule.replace("bgcolor ", "")
    elif rule.startswith('fgcolor '):
        fgcolor = rule.replace("fgcolor ", "")
    elif rule.startswith('.'):
        mag += [rule]
    elif rule.startswith('!.'):
        med += [rule.replace("!.", ".", 1)]
    elif rule.startswith("\\"):
        dir = rule.split("\\", 1)[1]
        if dir.endswith("\\"):
            sorter.update({dir: [False]})
        else:
            dir = dir.rsplit("\\", 1)
            sorter.update({dir[0] + "\\": [False, dir[1]]})
    elif rule.startswith("!\\"):
        dir = rule.split("!\\", 1)[1]
        if dir.endswith("\\"):
            sorter.update({dir: [True]})
        else:
            dir = dir.rsplit("\\", 1)
            sorter.update({dir[0] + "\\": [True, dir[1]]})
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
    directories = [batchname]
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
if Patrol or buildthumbnail:
    from PIL import Image
    Image.MAX_IMAGE_PIXELS = 400000000
    import subprocess



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
    Keypress_flush[0] = False
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
                    Keypress_flush[0] = True
                else:
                    title(status() + batchname)
                    sys.stdout.write(f"{stderr} (R)etry? (A)lways (N)ext defuse antibot with (F)irefox: ")
                    sys.stdout.flush()
                    while True:
                        if Keypress_flush[0] or Keypress_A[0]:
                            Keypress_prompt[0] = False
                            break
                        if Keypress_N[0]:
                            Keypress_prompt[0] = False
                            Keypress_N[0] = False
                            return
                        if Keypress_F[0]:
                            Keypress_F[0] = False
                            return 2
                        time.sleep(0.1)
            else:
                echo(f"{retries[0]} retries (S)kip one, wait it out, or press X to quit trying . . . ")
            time.sleep(0.5)
            title(status() + batchname)
            retries[0] += 1
            Keypress_prompt[0] = False
            return True
        elif Keypress_flush[0]:
            return True
        time.sleep(0.5)



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
    mediocre, magnificent, magplus = rejlist
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
    if not rejected and magplus:
        rejected = check(filename, magnificent, majestic=True)
        if rejected and mag:
            rejected = check(filename, mag, majestic=True)
        elif rejected and med:
            origin = rulefile
            rejected = check(filename, med)
        else:
            rejected = ""
    elif not rejected and magnificent:
        rejected = check(filename, magnificent, majestic=True)
    elif not rejected and mag:
        rejected = check(filename, mag, majestic=True)
    elif not rejected and med:
        origin = rulefile
        rejected = check(filename, med)
    if rejected and Showpattern:
        if rejected in filename.lower():
            print(f"{tcolor}{origin:>18}: {dir}{filename.lower().replace(rejected, tcolorr + rejected + tcolor)}{tcolorx}")
        else:
            print(f"{tcolor}  Not in whitelist: {dir}{tcolorb}{filename}{tcolorx}")
    return rejected



def ren(filename, append):
    return append.join(os.path.splitext(filename) if filename.count(".") > 1 else [filename, ""])



def get_cd(file, rejlist, makedirs=False, preview=False, subdir=""):
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
        tdir = "\\" + dir.replace("/", "\\")
        if isrej(todisk, rejlist):
            link = ""
        elif not preview and not os.path.exists(dir):
            if makedirs or [ast(x) for x in exempt if ast(x) == dir.replace("/", "\\")]:
                try:
                    os.makedirs(dir)
                except:
                    kill(f"Can't make folder {tdir} because there's a file using that name, I must exit!")
            else:
                print(f" Error downloading (dir): {link}")
                error[0] += [todisk]
                link = ""
    elif not preview:
        dir = subdir + x[0] + "/" if len(x := todisk.rsplit("/", 1)) == 2 else subdir
        tdir = "\\" + dir.replace("/", "\\")
        if isrej(todisk, rejlist):
            link = ""
    if not preview:
        if makedirs and not os.path.exists(dir):
            try:
                os.makedirs(dir)
            except:
                kill(f"Can't make folder {tdir} because there's a file using that name, I must exit!")
        file.update({"name":todisk, "edited":file["edited"]})
    return [link, todisk, file["edited"]]



def downloadtodisk(fromhtml, paysite=False, makedirs=False):
    rejlist = fromhtml["m"]
    filelist = []
    filelisthtml = []
    fromhtml_pm = fromhtml["paysite" if paysite else "mirror"]
    htmlpart = fromhtml_pm["partition"]
    htmlname = fromhtml["htmlname"]
    for key in htmlpart.keys():
        for file in htmlpart[key]["files"]:
            if not file["name"]:
                print(f""" I don't have a scraper for {file["link"]}""")
            else:
                if (x := get_cd(file, rejlist, makedirs, subdir=f"{batchname}/{htmlname}/") + [key])[0]:
                    filelist += [x]
        for array in htmlpart[key]["html"]:
            if len(array) == 2 and array[1]:
                if not array[1]["name"]:
                    print(f""" I don't have a scraper for {array[1]["link"]}""")
                else:
                    if (x := get_cd(array[1], rejlist, makedirs, subdir=f"{batchname}/{htmlname}/") + [key])[0]:
                        filelisthtml += [x]
    if fromhtml["inlinefirst"]:
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
        print("\n Add following dirs as new rules (preferably only for those intentional) to allow auto-create dirs.")

    if not filelist:
        if fromhtml["makehtml"]:
            tohtml(batchname + "/" + htmlname + "/", htmlname, fromhtml_pm, [], rejlist)
        else:
            print("Filelist is empty!")
        error[0] = []
        return
    html = []
    log = []
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
    ender = ""
    enderread = []
    last_id = 0
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
        part_id = filename.rsplit("/", 1)[-1].split(".", 1)[0]

        if not new_ender:
            new_ender = os.path.splitext(filename)[0] + ".ender"
        if line := [x for x in enderread if part_id in x]:
            if not onserver or isrej(filename, rejlist):
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
                        last_id = part_id
                        print(f"  Edited on server: {ondisk}")
                        continue
                if not part_id == last_id:
                    last_id = part_id
                    new_enderread.remove(line[0])
                    new_enderread.add(f"{part_id} {edited}")
            else:
                continue
        elif int(edited) > 0:
            new_enderread.add(f"{part_id} {edited}")
        else:
            new_enderread.add(f"{part_id}")



        if not onserver or isrej(filename, rejlist):
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
        print("You've got everything from this creator at tier you pledged to!")
    elif ender:
        print(f"""Ender file tripped.{" Nothing new to download." if not newfile else ""}{" There are failed downloads I will try again later." if error[0] else ""}""")
        if newfile and ender:
            os.remove(f"{batchname}/{htmlname}/{ender}")
            ender = ""
    if not ender:
        with open(f"{batchname}/{htmlname}/{new_ender}", 'w') as f:
            f.write("\n".join(new_enderread))
        if os.path.exists(f"{batchname}/{htmlname}.html"):
            os.remove(f"{batchname}/{htmlname}.html")
    if not (x := os.path.exists(f"{batchname}/{htmlname}.html")) or Patrol:
        orphfiles = []
        for file in next(os.walk(f"{batchname}/{htmlname}/"))[2]:
            if not file.endswith(tuple(specialfile)):
                orphfiles += [file]
        if not x:
            tohtml(batchname + "/" + htmlname + "/", htmlname, fromhtml_pm, set(orphfiles).difference(x[1].rsplit("/", 1)[-1] for x in filelist), rejlist)
        if Patrol:
            print()
            total = len(orphfiles)
            patrolthreadn = 0
            for file in orphfiles:
                patrolthreadn += 1
                patrol.put((patrolthreadn, folder, rejlist, total, file, log))
            patrol.join()
            print(" PATROL MEDIOCRE: 100%")
    error[0] = []

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



def new_html(builder, htmlname, listurls, imgsize=200, css="style.css"):
    if not listurls:
        listurls = "Maybe in another page."
    return """<!DOCTYPE html>
<html>
<meta charset="utf-8"/>
""" + f"<title>{htmlname}</title>" + """
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
var slideIndex = 1;
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
""" + f"""<link rel="stylesheet" type="text/css" href="{css}">""" + """
<style>
html,body{background-color:#10100c; color:#088 /*cb7*/; font-family:consolas, courier; font-size:14px;}
a{color:#dc8 /*efdfa8*/;}
a:visited{color:#cccccc;}
.aqua{background-color:#006666; color:#33ffff; border:1px solid #22cccc;}
.carbon, .files, .time{background-color:#10100c /*07300f*/; border:3px solid #6a6a66 /*192*/; border-radius:12px;}
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
.cell{overflow:auto; width:calc(100% - 28px); display:inline-block; vertical-align:text-top;}
h2{margin:4px;}
.postMessage{white-space:pre-wrap;}
</style>
<body>
<div style="display:block; height:20px;"></div><div class="container" style="display:none;">
<button class="closebtn" onclick="this.parentElement.style.display='none'">&times;</button>""" + f"""<div class="mySlides">{listurls}</div>
<img id="expandedImg">
</div>
<div style="display:block; height:10px;"></div><div style="background:#0c0c0c; height:20px; border-radius: 0 0 12px 0; position:fixed; padding:6px; top:0px; z-index:1;">
<button class="next" onclick="showDivs(slideIndex = 1)">Links in this HTML</button>
<button class="next" onclick="resizeImg('{imgsize}px')">1x</button>
<button class="next" onclick="resizeImg('{imgsize*2}px')">2x</button>
<button class="next" onclick="resizeImg('{imgsize*4}px')">4x</button>
<button class="next" onclick="resizeImg('auto')">1:1</button>
<button class="next" onclick="resizeCell('calc(100% - 28px)')">&nbsp;.&nbsp;</button>
<button class="next" onclick="resizeCell('calc(50% - 32px)')">. .</button>
<button class="next" onclick="resizeCell('calc(33.33% - 34px)')">...</button>
<button class="next" onclick="resizeCell('calc(25% - 34px)')">....</button>
<button id="fi" class="next" onclick="preview(this, 'Preview [ ]', 'Preview 1:1')">Preview</button>
<button id="ge" class="next" onclick="previewg(this, 'vs left', 'vs left <', 'vs left >', 'Find Edge')">Original</button>
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



def tohtml(subdir, htmlname, fromhtml, orphfiles, rejlist):
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
    orphid = iter(relics.keys())
    part = {}
    for id in new_relics.keys():
        if not id in relics:
            part.update({id:new_relics[id]})
            continue
        for idx in orphid:
            if not id == idx:
                part.update({idx:relics[idx]})
            else:
                break
        if not relics[id]["html"] or not relics[id]["keywords"] == new_relics[id]["keywords"]:
            part.update({id:new_relics[id]})
        else:
            part.update({id:relics[id]})
    with open(partfile, 'w') as f:
        f.write(json.dumps(part))
    buffer = partfile.replace("/", "\\")
    print(f" File {gallery_is}: {buffer}")



    for file in orphfiles:
        if file.endswith(tuple(specialfile)) or file.startswith("icon"):
            continue
        id = file.split(".", 1)[0]
        if not id in part.keys():
            id = "0"
        if "orphfiles" in part[id]:
            part[id]["orphfiles"] += [file]
        else:
            part[id]["orphfiles"] = [file]
    if buildthumbnail:
        echo("Building thumbnails . . .")



    for id in part.keys():
        keywords = part[id]["keywords"]
        if id == "0":
            if "orphfiles" in part[id]:
                title = "Unsorted"
                content = "No matching partition found for this files. Either partition IDs are not assigned properly in file names or they're just really orphans.\n"
            else:
                continue
        else:
            title = f"<h2>{keywords[0]}</h2>" if keywords and keywords[0] else f"""<h2 style="color:#666;">ꍯ Part {id} ꍯ</h2>"""
            content = ""
        new_container = False
        end_container = False
        builder += """<div class="cell">\n"""
        if len(keywords) > 1:
            time = keywords[1] if keywords[1] else "No timestamp"
            keywords = ", ".join(x for x in keywords[2:]) if len(keywords) > 2 else "None"
            builder += f"""<div class="time" id="{id}" style="float:right;">Part {id} ꍯ {time}<sup><span style="font-size:80%;">UTC</span></sup>\nKeywords: {keywords}</div>\n"""
        builder += title
        if part[id]["files"]:
            builder += "<div class=\"files\">\n"
            for file in part[id]["files"]:
                builder += container(subdir + file, rejlist, 1)
            builder += "</div>\n"
        if "orphfiles" in part[id]:
            builder += "<div class=\"edits\">\n"
            for file in part[id]["orphfiles"]:
                # os.rename(subdir + file, subdir + "Orphaned files/" + file)
                builder += container(subdir + file, rejlist, 1)
            builder += "<br><br>orphaned file(s)\n</div>\n"
        if html := part[id]["html"]:
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
                listurls += f"""# From <a href="#{id}">#{id}</a> :: {part[id]["keywords"][0]}<br>{links}\n"""
            builder += f"{content}</div>\n"
        elif not part[id]["files"]:
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
    creators = api["data"]
    for creator in creators:
        pledges += [creator["relationships"]["creator"]["data"]["id"]]
    resp, err = fetch("https://www.patreon.com/api/stream?include=user.null&fields[post]=&fields[user]=")
    api = json.loads(resp.read().decode("utf-8"))
    if not "included" in api:
        kill(0, "You haven't pledged to any creators on Patreon!", r="Patreon cookie")
    for creator in api["included"]:
       pledges += [creator["id"]]
    pledges = list(dict.fromkeys(pledges))
    if not pledges and not favoriteispledged:
        kill(0, "You haven't pledged to any creators on Patreon!", r="Patreon cookie")
if Fanboxcookie:
    referers.update({"https://api.fanbox.cc/":"https://www.fanbox.cc"})
    print("Checking your pledges on Fanbox . . .")
    resp, err = fetch("https://api.fanbox.cc/plan.listSupporting")
    try:
        api = json.loads(resp.read().decode('utf-8'))
    except:
        kill(0, f"Fanbox cookie may be outdated ({err}).", r="Fanbox cookie")
    creators = api["body"]
    if not creators and not favoriteispledged:
        kill(0, "You haven't pledged to any artists on Fanbox!", r="Fanbox cookie")
    else:
        for creator in creators:
            pledges += [creator["user"]["userId"]]
if Fantiacookie:
    print("Checking your pledges on Fantia . . .")
    resp, err = fetch("https://fantia.jp/mypage/users/plans")
    try:
        html = resp.read().decode('utf-8')
    except:
        kill(0, f"Fantia cookie may be outdated ({err}).", r="Fantia cookie")
    if not html:
        kill(0, "You haven't pledged to any artists on Fantia!", r="Fantia cookie")



def new_part():
    return {"page":"", "campaign_id":None, "icons":[], "partition":{}}

def fanbox_avatars(threadn, htmlname, CREATOR_ID):
    api = json.loads(get(f"https://api.fanbox.cc/creator.get?userId={CREATOR_ID}", stderr=f"Broken API on Fanbox for {htmlname}", threadn=threadn).decode('utf-8'))
    if obj := api["body"]:
        return {"page":{"link":f"""https://{obj["creatorId"]}.fanbox.cc/""", "name":obj["user"]["name"]}, "icons":[{"link":obj["user"]["iconUrl"], "name":"avatar.png", "edited":0}, {"link":obj["coverImageUrl"], "name":"cover.png", "edited":0}]}

def fantia_avatars(threadn, htmlname, CREATOR_ID):
    api = json.loads(get("https://fantia.jp/api/v1/fanclubs/" + CREATOR_ID, stderr=f"Broken API on Fantia for {htmlname}", threadn=threadn).decode('utf-8'))
    if obj := api["fanclub"]:
        return {"page":{"link":f"https://fantia.jp/fanclubs/{CREATOR_ID}", "name":obj["fanclub_name_with_creator_name"]}, "icons":[{"link":obj["icon"]["original"], "name":"avatar.png", "edited":0}, {"link":obj["cover"]["original"], "name":"cover.png", "edited":0}]}

def patreon_avatars(threadn, htmlname, CREATOR_ID):
    if not (data := get("https://www.patreon.com/api/user/" + CREATOR_ID, utf8=True, stderr=f"Broken API on Patreon while fetching profile for {htmlname}\n > Or failed at Patreon's aggressive anti-bot detection\n > To pass: provide your browser's user-agent string and cookie value for __cf_bm\n\n", threadn=threadn)).isdigit():
        api = json.loads(data)
        if obj := api["included"][0]["attributes"]:
            return {"page":{"link":api["data"]["attributes"]["url"], "name":api["data"]["attributes"]["vanity"]}, "campaign_id":api["data"]["relationships"]["campaign"]["data"]["id"], "icons":[{"link":obj["avatar_photo_url"], "name":"avatar.png", "edited":0}, {"link":obj["cover_photo_url"], "name":"cover.png", "edited":0}]}



def fanbox_assets(threadn, htmlname, CREATOR_ID):
    fromhtml = new_part()
    fromhtml.update(fanbox_avatars(threadn, htmlname, CREATOR_ID))
    url = f"https://api.fanbox.cc/post.listCreator?userId={CREATOR_ID}&limit=10"
    while True:
        api = get(url, stderr=f"Broken API on Fanbox for {htmlname}", threadn=threadn)
        if not api:
            return fromhtml
        api = json.loads(api.decode('utf-8'))
        for next_obj in api["body"]["items"]:
            id = next_obj["id"]
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
                        html += [["<p>", {"link":url, "name":id + "." + url.rsplit("/", 1)[1], "edited":edited}]]
                filelist = []
            files = []
            for file in filelist:
                url = file["originalUrl"]
                files += [{"link":url, "name":id + "." + url.rsplit("/", 1)[1], "edited":edited}]
            fromhtml["partition"].update({id:{"keywords":keywords, "html":html, "files":files}})
        if api["body"]["nextUrl"]:
            url = api["body"]["nextUrl"]
        else:
            break
    return fromhtml



def fantia_assets(threadn, htmlname, CREATOR_ID):
    fromhtml = new_part()
    fromhtml.update(fantia_avatars(threadn, htmlname, CREATOR_ID))
    page = 1
    while True:
        html = get(f'https://fantia.jp/fanclubs/{CREATOR_ID}/posts?page={page}', stderr=f"Error getting new page for {htmlname} on Fantia", threadn=threadn).decode("utf-8")
        html = html.replace("\n", "").replace("<div class=\"post-meta\">", "\n").replace(u"\u2028"," ").splitlines()
        for part in html[1:]:
            key = part.split("href=\"/posts/", 1)[1].split("\"", 1)[0]
            assets = get("https://fantia.jp/posts/" + key, stderr=f"Error getting new page for {htmlname} on Fantia", threadn=threadn).decode("utf-8")
        page += 1
    return fromhtml

    print(f"Yiff.party's dead, Jim.")
    html = get('https://yiff.party/fantia/' + CREATOR_ID, stderr=f"Error getting new page for {htmlname} on Fantia", threadn=threadn).decode("utf-8")
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



def kp_fanbox_assets(threadn, htmlname, CREATOR_ID):
    fromhtml = new_part()
    page = 0
    while True:
        api = get(f"https://kemono.party/api/fanbox/user/{CREATOR_ID}?o={page*25}", stderr=f"Broken API on kemono.party for {htmlname}", threadn=threadn)
        if not api:
            return fromhtml
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



def kp_fantia_assets(threadn, htmlname, CREATOR_ID):
    fromhtml = new_part()
    page = 0
    while True:
        api = get(f"https://kemono.party/api/fantia/user/{CREATOR_ID}?o={page*25}", stderr=f"Broken API on kemono.party for {htmlname}", threadn=threadn)
        if not api:
            return fromhtml
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



def kp_patreon_assets(threadn, htmlname, CREATOR_ID):
    fromhtml = new_part()
    if Patreoncookie and (data := patreon_avatars(threadn, htmlname, CREATOR_ID)):
        fromhtml.update(data)
    page = 0
    while True:
        api = get(f"https://kemono.party/api/patreon/user/{CREATOR_ID}?o={page*25}", stderr=f"Broken API on kemono.party for {htmlname}", threadn=threadn)
        if not api:
            return fromhtml
        if not (api := json.loads(api.decode('utf-8'))):
            break
        for asset in api:
            key = asset["id"]
            keywords = [asset["title"] + datetime.strptime(asset["published"], "%a, %d %b %Y %H:%M:%S GMT").isoformat(" ")]
            # desired result is "YYYY-MM-DD HH:MM:SS"
            edited = keywords[1].split(" ", 1)[0].replace("-", "")
            files = []
            if file := asset["file"]:
                files += [{"link":"https://kemono.party" + file["path"], "name":saint(key + "." + file["name"]), "edited":edited}]
            if attachments := asset["attachments"]:
                for file in attachments:
                    files += [{"link":"https://kemono.party" + file["path"], "name":saint(key + "." + file["name"]), "edited":edited}]
            html = []
            embed = ""
            if asset["embed"]:
                url = asset["embed"]["url"]
                embed = f"""<p><a href="{url}">{url}</a></p>"""
            if asset["content"]:
                asset = ["", asset["content"]]
                while True:
                    asset = asset[1].split("<img data-media-id=\"", 1)
                    if len(asset) == 2:
                        image, asset[1] = asset[1].split(">", 1)
                        name, url = image.split("\" src=\"")
                        url = url.split("\"", 1)[0]
                        try:
                            ext = url.rsplit("/", 1)[1].split("?")[0].split(".")[1]
                            name = f"""{key}.{name}.{ext}"""
                        except:
                            name = url
                        html += [[asset[0], {"link":"https://kemono.party" + url, "name":saint(name), "edited":edited}]]
                    else:
                        break
                html += [[asset[0] + embed]]
            fromhtml["partition"].update({key:{"keywords":keywords, "html":html, "files":files}})
        page += 1
    #for k in fromhtml["partition"].keys():
    #    print(fromhtml["partition"][k])
    #input()
    return fromhtml



def patreon_assets(threadn, htmlname, CREATOR_ID):
    fromhtml = new_part()
    if data := patreon_avatars(threadn, htmlname, CREATOR_ID):
        fromhtml.update(data)
    else:
        return
    url = "https://www.patreon.com/api/posts?include=attachments%2Cimages.null%2Caudio.null&fields[post]=content%2Ccurrent_user_can_view%2Cedited_at%2Cembed%2Cpost_file%2Cpost_type%2Ctitle&fields[media]=download_url%2Cfile_name%2Cowner_id&sort=-published_at&filter[campaign_id]=" + fromhtml["campaign_id"]
    while True:
        api = get(url, stderr=f"Broken API on Patreon while fetching posts for {htmlname}\n > Or failed at Patreon's aggressive anti-bot detection\n > To pass: provide your browser's user-agent string and cookie values for __cf_bm and __cfuid\n\n", threadn=threadn)
        if not api:
            return fromhtml
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
                html += [[next_obj[0] + embed]]
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
        threadn, master, CREATOR_ID, htmlname, HOME = artworks.get()
        mirror_assets = []
        paysite_assets = []
        if Kemonoparty:
            if HOME == "Fanbox":
                mirror_assets = kp_fanbox_assets(threadn, htmlname, CREATOR_ID)
            elif HOME == "Fantia":
                mirror_assets = kp_fantia_assets(threadn, htmlname, CREATOR_ID)
            elif HOME == "Patreon":
                mirror_assets = kp_patreon_assets(threadn, htmlname, CREATOR_ID)
            print(f"Fetched new data for {htmlname}")
        if CREATOR_ID in pledges:
            if HOME == "Fanbox":
                paysite_assets = fanbox_assets(threadn, htmlname, CREATOR_ID)
            elif HOME == "Fantia":
                paysite_assets = fantia_assets(threadn, htmlname, CREATOR_ID)
            elif HOME == "Patreon":
                paysite_assets = patreon_assets(threadn, htmlname, CREATOR_ID)
            print(f"Fetched new data for {htmlname} ({HOME})")
        master.update({HOME + CREATOR_ID: {"htmlname":htmlname, "m":[[], [], False], "inlinefirst": False, "mirror": mirror_assets, "paysite": paysite_assets}})
        fromhtml = master[HOME + CREATOR_ID]
        if os.path.exists(f"{batchname}/{htmlname}/mediocre.txt"):
            with open(f"{batchname}/{htmlname}/mediocre.txt", 'r', encoding='utf-8') as f:
                fromhtml["m"][0] = f.read().splitlines()
        if os.path.exists(f"{batchname}/{htmlname}/magnificent.txt"):
            with open(f"{batchname}/{htmlname}/magnificent.txt", 'r', encoding='utf-8') as f:
                fromhtml["m"][1] = f.read().splitlines()
        if rulefile in fromhtml["m"][1]:
            fromhtml["m"][2] = True
        echothreadn.remove(threadn)
        artworks.task_done()



artworks = Queue()
for i in range(8):
    t = Thread(target=get_assets, args=(artworks,))
    t.daemon = True
    t.start()



htmldata = [[]]
run_input = ["", "", False]

def readfile():
    print(f"Reading {textfile} . . .")
    with open(textfile, 'r', encoding="utf-8") as f:
        textread = f.read().splitlines()
    HTMLLIST = []
    NEXTHTML = []
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
            HTMLLIST += [NEXTHTML]
            NEXTHTML = []
        elif line == "end":
            break
        if not line[0].isdigit() or " seconds rarity " in line[0]:
            continue
        CREATOR_ID = ""
        for d in line:
            if d.isdigit():
                CREATOR_ID += d
            else:
                break
        if not line.replace(CREATOR_ID, ""):
            print(f"\nPlease append name (any name) to {CREATOR_ID} e.g. {CREATOR_ID}.name or {CREATOR_ID}name in {rulefile} then try again.\nThe name must not start with number!")
            return
        line = line.replace("\\", "/").rsplit("/", 1)[-1]
        NEXTHTML += [[line, CREATOR_ID, HOME]]
    HTMLLIST += [NEXTHTML]



    resume = False
    htmldata[0] = []
    for NEXTHTML in HTMLLIST:
        if resume:
            print("\n Resuming next favorites")
        else:
            resume = True
        master = {}
        queued = []
        threadn = 0



        for htmlname, CREATOR_ID, HOME in NEXTHTML:
            if favoriteispledged:
                pledges += [CREATOR_ID]
            if HOME + CREATOR_ID in queued:
                continue
            queued += [HOME + CREATOR_ID]
            threadn += 1
            echothreadn.append(threadn)
            artworks.put((threadn, master, CREATOR_ID, htmlname, HOME))
        htmlname = batchfile
        try:
            artworks.join()
        except KeyboardInterrupt:
            pass



        for htmlname, CREATOR_ID, HOME in NEXTHTML:
            fromhtml = master[HOME + CREATOR_ID]
            if not os.path.exists(f"{batchname}/{htmlname}/"):
                os.makedirs(f"{batchname}/{htmlname}/")
            if fromhtml["mirror"]:
                print(f"\n - - - - {htmlname} - - - -")
                title(status() + htmlname)
                htmldata[0] += [f"<p>- - - - {htmlname} - - - -</p>"]
                downloadtodisk(fromhtml)
            if fromhtml["paysite"]:
                print(f"\n - - - - {htmlname} (only on {HOME}) - - - -")
                title(f"{status()}{htmlname} (only on {HOME})")
                htmldata[0] += [f"<p>- - - - {htmlname} (only on {HOME}) - - - -</p>"]
                downloadtodisk(fromhtml, paysite=True)



    if newfilen[0] or not os.path.exists(htmlfile) or Patrol:
        with open(htmlfile, 'wb') as f:
            f.write(bytes(new_html("\n".join(htmldata[0]), "Today download result", "", css=batchname + "/" + "style.css"), 'utf-8'))
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



    if not HTMLLIST[0]:
        print(f"\n No creator list in rule file ({rulefile})! Add creator's ID per line please.")
        help()
    else:
        if not newfilen[0]:
            print(f"""\n Today download result HTML "{htmlfile}" {"updated with scan result" if Patrol else "will not be made at this time"}. There are 0 new pictures.""")
        elif newfilen[0] <= 256:
            print(f"""\n Today download result HTML "{htmlfile}" updated! You can view {newfilen[0]} new picture(s) in browser.""")
        else:
            print(f"""\n Today download result HTML "{htmlfile}" updated! It might be hard for browser to handle {newfilen[0]} new pictures!""")
    title(status() + batchfile)



def keylistener():
    while True:
        el = choice("abcdefghijklmnopqrstuvwxyz0123456789")
        if el == 1:
            echo("", 1)
            Keypress_A[0] = True
            if not busy[0]:
                ready_input()
        elif el == 2:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo("Keypress B unrecognized", 0, 1)
            ready_input()
        elif el == 3:
            echo("", 1)
            Keypress_C[0] = True
            if not busy[0]:
                ready_input()
        elif el == 4:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo("Keypress D unrecognized", 0, 1)
            ready_input()
        elif el == 5:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo("Keypress E unrecognized", 0, 1)
            ready_input()
        elif el == 6:
            Keypress_F[0] = True
            if not busy[0]:
                ready_input()
        elif el == 7:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo("Keypress G unrecognized", 0, 1)
            ready_input()
        elif el == 8:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo("Keypress H unrecognized", 0, 1)
            ready_input()
        elif el == 9:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo("Keypress I unrecognized", 0, 1)
            ready_input()
        elif el == 10:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo("Keypress J unrecognized", 0, 1)
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
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo("Keypress M unrecognized", 0, 1)
            ready_input()
        elif el == 14:
            echo("", 1)
            Keypress_N[0] = True
            if not busy[0]:
                ready_input()
        elif el == 15:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo("Keypress O unrecognized", 0, 1)
            ready_input()
        elif el == 16:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo("Keypress P unrecognized", 0, 1)
            ready_input()
        elif el == 17:
            echo("", 1)
            Keypress_A[0] = False
            if not busy[0]:
                ready_input()
        elif el == 18:
            echo("", 1)
            Keypress_flush[0] = True
            if not busy[0]:
                ready_input()
        elif el == 19:
            echo("", 1)
            Keypress_S[0] = True
            if not busy[0]:
                ready_input()
        elif el == 20:
            if ticks:
                echo(f"""COOLDOWN {"DISABLED" if cooldown[0] else "ENABLED"}""", 1, 1)
            else:
                echo(f"""Timer not enabled, please add "#-# seconds rarity 100%" in {rulefile}, add another timer to manipulate rarity.""", 1, 1)
            cooldown[0] = False if cooldown[0] else True
            if not busy[0]:
                ready_input()
        elif el == 21:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo("Keypress U unrecognized", 0, 1)
            ready_input()
        elif el == 22:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo("Keypress V unrecognized", 0, 1)
            ready_input()
        elif el == 23:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo("Keypress W unrecognized", 0, 1)
            ready_input()
        elif el == 24:
            echo(f"""SET ALL ERROR DOWNLOAD REQUESTS TO: {"SKIP" if Keypress_X[0] else "RETRY"}""", 1, 1)
            Keypress_X[0] = False if Keypress_X[0] else True
            Keypress_A[0] = True
            if not busy[0]:
                ready_input()
        elif el == 25:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo("Keypress Y unrecognized", 0, 1)
            ready_input()
        elif el == 26:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            echo("Keypress Z unrecognized", 0, 1)
            ready_input()
        elif 0 <= (n := min(el-27, 8)) < 9:
            echo(f"""MAX PARALLEL DOWNLOAD SLOT: {n} {"(pause)" if not n else ""}""", 1, 1)
            dlslot[0] = n
            if not busy[0]:
                ready_input()
        else:
            Keypress_CtrlC[0] = True
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
  > Press Ctrl + C to break and reconnect of the ongoing downloads or to end timer instantly.""")



mainmenu()
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
        echo("Ctrl + C")
        skull()
        ready_input()



"""
::MacOS - Install Python 3 then open Terminal and enter:
open /Applications/Python\ 3.10/Install\ Certificates.command
sudo python3 -m pip install --upgrade pip
sudo python3 -m pip install Pillow
sudo python3 -m pip install PySocks
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

if exist Lib\site-packages\PIL (echo.) else (goto install)
if exist Lib\site-packages\socks.py (goto start) else (echo.)

:install
echo  Hold on . . . I need to install the missing packages.
if exist "Scripts\pip.exe" (echo.) else (color %stopcolor% && echo  PIP.exe doesn't seem to exist . . . Please install Python properly^^! I must exit^^! && pause>nul && exit)
python -m pip install --upgrade pip
Scripts\pip.exe install Pillow
Scripts\pip.exe install PySocks
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