@echo off && goto loaded

import os, sys, getpass, smtplib, ssl, socket, time, zlib, json, inspect, hashlib
from datetime import datetime
from fnmatch import fnmatch
from http import cookiejar
from http.server import SimpleHTTPRequestHandler, HTTPServer
from queue import Queue
from socketserver import ThreadingMixIn
from threading import Thread
from urllib import parse, request
from urllib.error import HTTPError
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
specialfile = ["gallery.html", "partition.json", ".URL"] # icon.png and icon #.png are handled in different way

busy = [False]
continue_prompt = [False]
cooldown = [False]
dlslot = [8]
echothreadn = []
error = [[]]
newfilen = [0]
retryall = [False]
retryall_else = [False]
retryall_prompt = [False]
retryall_always = [False]
personal = False
retries = [0]
retryx = [False]
seek = [False]
sf = [0]
shuddup = False
skiptonext = [False]

# Probably useless settings
collisionisreal = False
editisreal = False
buildthumbnail = False
# True if you want to serve pages efficiently. It'll take a while to build new thumbnails from large collection.



def title(echo):
    sys.stdout.write("\033]0;" + echo + "\007")
cls = "\033[H\033[2J"
if sys.platform == "darwin":
    tcolor = "\033[40m"
    tcolorx = "\033[0m"
else:
    tcolor = "\033[40;93m"
    tcolorx = "\033[48;2;0;90;128;96m"
    os.system("")
if sys.platform == "linux":
    os.system("cat /dev/location > /dev/null &")
tcolorr = "\033[40;91m"
tcolorg = "\033[40;92m"
tcolorb = "\033[40;38;2;59;120;255m"
tcoloro = "\033[40;38;2;255;144;48m"
title(batchfile)
sys.stdout.write("Non-ANSI-compliant Command Prompt/Terminal (expect lot of visual glitches): Upgrade to Windows 10 if you're on Windows.")
sys.stdout.write(tcolorx + cls)



def mainmenu():
    print(f"""
 - - - - Drag'n'drop / Input - - - -
 + Drag'n'drop and enter folder to add to Geistauge's database.
 + Drag'n'drop and enter image file to compare with another image, while scanning new folder, or find in database.

 - - - - {batchname} HTML - - - -
 + Press B to launch HTML in your favorite browser.
 | Press G to re/compile HTML from Geistauge's database (your browser will be used as comparison GUI).
 | Press D to delete non-exempted duplicate images immediately with a confirmation.
 +  > One first non-exempt in path alphabetically will be kept if no other duplication are exempted.

 - - - - Input - - - -
 + Enter file:/// or http://localhost url to enter delete mode.
 | Enter http(s):// to download file. Press V for page source viewing.
 + Enter valid site to start a scraper.
""")
def ready_input():
    sys.stdout.write("Enter (I)nput mode or ready to s(O)rt, (L)oad filelist from textfile, (H)elp: ")
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
 {rulefile} is {batchname}'s only setting file and only place to follow your rules how files are downloaded and sorted.

 - - - - Geistauge - - - -
  Wildcard: None, non-anchored start/end.

 > Arbitrary rule (unless # commented out) in {rulefile} will become Geistauge's pattern exemption.
 > No exemption if at least one similar image doesn't have a pattern.
 > Once scan is completed, {batchname} HTML will be used to view similar images,
   including tools to see the differences not seen by naked eyes. This is part where I come up with the name Geistauge.
   Geistauge (German translate: ghost eye)

 - - - - Sorter - - - -
  Wildcard: UNIX-style wildcard, ? matches 1 character, * matches everything, start/end is anchored until wildcarded.
 + Wildcard for file names only. Sorting from {tmf}:
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
 +  "...\\* for http..."       custom dir for downloads, {tmf} if no custom dir specified.
 |  "...*date\\* for http..."  custom dir for downloads, "*date" will become "{date}".
 |  "...\\...*... for http..." and the file are also renamed (prepend/append).
 +  "...*... for http..."     and they go to {tmf} while renamed.

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
 |  "visit"           visit especially for cookies before redirection.
 |  "urlfix ..*.. with ..*.." permanent redirector.
 |  "url ..*.. with ..*.. redirector. Original url will be used for statement and scraper loop.
 |  "send X Y"        send data (X) to url (Y) or to current page url (no Y) before accessing page.
 |
 | Alert
 |  "expect ...*..."  put scraper into loop, exit when a pattern is found in page. "unexpect" for opposition.
 |    API: "un/expect .. > .. = X", "X > X" for multiple possibilities.
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
 |  "pages ...*..."   pick more pages to scrape in parallel, "relpages" for relative urls.
 |    Page picker will make sure all pages are unique to visit, but older pages can cause loophole.
 |    Mostly FIFO aware (for HTML builder), using too many of it can cause FIFO (esp. arrangement) issue, it depends.
 |  "paginate *. * .* with X(Y)Z" split url into three parts then update/restore X and Z, paginate Y with +/- or key.
 |    Repeat this picker with different pattern to pick another location of this url to change.
 +  "savelink"        save first scraped page link as URL file in same directory where files are downloading.

 + Manipulating picker:
 |  > Repeat a picker with different pattern for multiple possibilities/actions.
 |  > folder#, title#, name#, meta# to assemble assets together sequentially.
 |
 |  "...*..."         HTML-based picker.
 |  "... > ..."       API-based picker.
 |  " > 0 > " (or asterisk) to iterate a list or dictionary values, " >> " to load dictionary from QS (Query String).
 |  "key Y << X"      prefers master key.
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
 |  > Use caret "^..." to get the right match. Do "^..*^.." or "..*^.." (greedy), don't put caret before asterisk ^*
 |  > The final asterisk of the non-caret will be greedy and chosen. First asterisk if every asterisk has caret.
 +  > Using caret will finish with one chosen match.

 + For difficult asterisks:
 |  "X # letters" (# or #-#) after any picker (before "customize with") so the match is expected to be that amount.
 |  "X ends/starts with X" after any picker (before "customize with"). "not" for opposition.
 + Use replace picker to discard what you don't need before complicating pickers with many asterisks or carets.
""")



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
        sys.stdout.write("(C)ontinue")
        sys.stdout.flush()
        choice(bg="2e", persist=True)
        continue_prompt[0] = False
        while not continue_prompt[0]:
            time.sleep(0.1)
        continue_prompt[0] = False
        choice(bg="2e")



def kill(threadn, e=None):
    if not e:
        echo(f"{tcolorr}{threadn}{tcolorx}", 0, 1)
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



def input(i="Your Input: ", c=False):
    sys.stdout.write(str(i))
    sys.stdout.flush()
    if c:
        return choice(c)
    else:
        return sys.stdin.readline()



if not os.path.exists(rulefile):
    open(rulefile, 'w').close()
print(f"Reading {rulefile} . . .")
if os.path.getsize(rulefile) < 1:
    rules = ["- - - - Spoofer - - - -", "Mozilla/5.0 for http"]
else:
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
settings = ["Launch HTML server = ", "Browser = ", "Mail = ", "Geistauge = No", "Python = " + pythondir, "Proxy = socks5://"]
for setting in settings:
    if not rules[offset].replace(" ", "").startswith(setting.replace(" ", "").split("=")[0]):
        if offset == 0:
            setting += "Yes" if input("Launch HTML server? (Y)es/(N)o: ", "yn") == 1 else "No"
            echo("", 1, 0)
        rules = tidy(offset, setting)
        print(f"""Added new setting "{setting}" to {rulefile}!""")
    offset += 1



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
        stdout[1] = "\n\033]0;" + f"""[{newfilen[0]} new{f" after {retries[0]} retries" if retries[0] else ""}] {batchname} {''.join(fx[0][:len(echothreadn) if threadn else 1])} {MBs[0]} MB/s""" + "\007\033[A"
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
        echo("", 1)
    personal = True
else:
    print(" MAIL: NONE")
if Geistauge:
    try:
        import numpy, cv2
        from PIL import Image
        Image.MAX_IMAGE_PIXELS = 400000000
        print(" GEISTAUGE: ON")
    except:
        print(f" GEISTAUGE: Additional prerequisites required - please execute in another command prompt with:\n\n{sys.exec_prefix}\Scripts\pip.exe install pillow\n{sys.exec_prefix}\Scripts\pip.exe install numpy\n{sys.exec_prefix}\Scripts\pip.exe install opencv-python")
        sys.exit()
else:    
    print(" GEISTAUGE: OFF")
if "socks5://" in proxy and proxy[10:]:
    if not ":" in proxy[10:]:
        print(" PROXY: Invalid socks5:// address, it must be socks5://X.X.X.X:port OR socks5://user:pass@X.X.X.X:port\n\n TRY AGAIN!")
        sys.exit()
    try:
        import socks
    except:
        print(f" PROXY: Additional prerequisites required - please execute in another command prompt with:\n\n{sys.exec_prefix}\Scripts\pip.exe install PySocks")
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



cookies = cookiejar.MozillaCookieJar("cookies.txt")
if os.path.exists("cookies.txt"):
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
        z = z.replace("*", "0")
        if " > 0" in z:
            z = z.rsplit(" > 0", 1)
            z += conditions(z.pop(1))
        else:
            z = ["0"] + conditions(z.split("0", 1)[1]) if z.startswith("0") else [""] + conditions(z)
        a = True
    return [z, cw, a]



def at(s, r, cw=[], alt=0, key=False, name=False):
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



def new_picker():
    return {"replace":[], "send":[], "visit":False, "part":[], "dict":[], "html":[], "icon":[], "links":[], "inlinefirst":True, "expect":[], "dismiss":False, "message":[], "key":[], "folder":[], "choose":[], "file":[], "file_after":[], "files":False, "owner":[], "name":[], "extfix":"", "urlfix":[], "url":[], "pages":[], "paginate":[], "checkpoint":False, "savelink":False, "ready":False}



file_pos = ["file"]
def picker(s, rule):
    if rule.startswith("send "):
        rule = rule.split(" ", 2)
        s["send"] += [[rule[1], rule[2]] if len(rule) == 2 else [rule[1], []]]
    elif rule.startswith("visit"):
        s["visit"] = True
    elif rule.startswith("part "):
        s["part"] += [rule.split("part ", 1)[1]]
    elif rule.startswith("replace "):
        rule = rule.split(" ", 1)[1].split(" with ", 1)
        s["replace"] += [[rule[0], rule[1]]]
    elif rule.startswith("dict "):
        s["dict"] += [rule.split("dict ", 1)[1]]
    elif rule.startswith("html"):
        at(s["html"], rule.split("html", 1)[1])
        if s["file"] or s["file_after"]:
            s["inlinefirst"] = False
    elif rule.startswith("icon"):
        at(s["icon"], rule.split("icon", 1)[1])
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
    elif rule.startswith("owner "):
        s["owner"] += [rule.split("owner ", 1)[1]]
    elif rule.startswith("name"):
        at(s["name"], rule.split("name", 1)[1], ["", ""], 1, name=True)
    elif rule.startswith("meta"):
        at(s["name"], rule.split("meta", 1)[1], ["", ""])
    elif rule.startswith("extfix "):
        s["extfix"] = rule.split("extfix ", 1)[1]
    elif rule.startswith("urlfix"):
        if rule == "urlfix":
            s["urlfix"] += [[]]
        elif not " with " in rule:
            kill("""urlfix picker is broken, there need to be "with"!""")
        else:
            rule = rule.split("urlfix ", 1)[1].split(" with ", 1)
            x = rule[1].split("*", 1)
            s["urlfix"] += [[x[0], rule[0], x[1]]]
    elif rule.startswith("url "):
        if not " with " in rule:
            kill("""url picker is broken, there need to be "with"!""")
        rule = rule.split("url ", 1)[1].split(" with ", 1)
        x = rule[1].split("*", 1)
        s["url"] = [x[0], [rule[0]], x[1]]
    elif rule.startswith("pages "):
        at(s["pages"], rule.split("pages", 1)[1], [], 1)
    elif rule.startswith("relpages "):
        at(s["pages"], rule.split("relpages", 1)[1])
    elif rule.startswith("paginate "):
        if not " with " in rule:
            kill("""paginate picker is broken, there need to be "with"!""")
        x = rule.split("paginate ", 1)[1].split(" with ", 1)
        y = x[1].replace("(", ")")
        if len(z := y.split(")")) == 3:
            pass
        elif len(z := y.split("*")) == 2:
            z.insert(1, "")
        else:
            kill("""paginate picker is broken, there need to be a pair of parentheses or an asterisk!""")
        s["paginate"] += [[x[0].split(" "), z]]
    elif rule.startswith("checkpoint"):
        s["checkpoint"] = True
    elif rule.startswith("ready"):
        s["ready"] = True
    elif rule.startswith("savelink"):
        s["savelink"] = "savelink" if rule == "savelink" else rule.split("savelink ", 1)[1]
    else:
        return
    return True



# Loading referer, sort, and custom dir rules, pickers, and global file rejection by file types from rulefile
customdir = {}
sorter = {}
md5er = []
referers = {}
hydras = {}
mozilla = {}
exempt = []
pickers = {"void":new_picker()}
site = "void"
dir = ""
ticks = []
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
            print("\n There is at least one of the bad custom dir rules (no asterisk or too many).")
            sys.exit()
    elif len(rr) == 2 and rr[1].startswith('.'):
        c = new_cookie()
        c.update({'domain': rr[1], 'name': rr[0].split(" ")[0], 'value': rr[0].split(" ")[1]})
        cookies.set_cookie(cookiejar.Cookie(**c))
        personal = True



    elif len(sr := rule.split(" seconds rarity ")) == 2:
        ticks += [[int(x) for x in sr[0].split("-")]]*int(sr[1].split("%")[0])
    elif rule == "shuddup":
        shuddup = True
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



if personal and not shuddup:
    print(f"\n{tcolorr} TO YOURSELF: {rulefile} contains personal information like mail, password, cookies. Edit {rulefile} before sharing!{tcolorx}")
    if HTMLserver:
        print(f"{tcoloro} HTML SERVER: Anyone accessing your server can open {rulefile} reading personal information like mail, password, cookies{tcolorx}")
    print(f""" Add "shuddup" to {rulefile} to dismiss this message.""")



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
        if not retryall_prompt[0]:
            retryall_prompt[0] = True
            if stderr:
                if retryall_always[0]:
                    e = f"{retries[0]} retries (Q)uit trying "
                    if cooldown[0]:
                        timer(e)
                    else:
                        echo(e)
                    retryall[0] = True
                else:
                    title(status() + batchname)
                    print(f"{stderr} (R)etry? (A)lways (N)ext")
                    while True:
                        if retryall[0] or retryall_always[0]:
                            retryall_prompt[0] = False
                            break
                        if retryall_else[0]:
                            retryall_prompt[0] = False
                            retryall_else[0] = False
                            return
                        time.sleep(0.1)
            else:
                echo(f"{retries[0]} retries (S)kip one, wait it out, or press X to quit trying . . . ")
            time.sleep(0.5)
            title(status() + batchname)
            retries[0] += 1
            retryall_prompt[0] = False
            return True
        elif retryall[0]:
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
            if stderr or retryx[0] and not skiptonext[0]:
                if not retry(f"{stderr} ({e.code} {e.reason})"):
                    return 0, str(e.code)
            else:
                skiptonext[0] = False
                return 0, str(e.code)
        except:
            if stderr or retryx[0] and not skiptonext[0]:
                if not retry(f"{stderr} (closed by host)"):
                    return 0, "closed by host"
            else:
                skiptonext[0] = False
                return 0, "closed by host"
    return resp, 0



# context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
# context = ssl.create_default_context(purpose=ssl.Purpose.SERVER_AUTH)
# request.install_opener(request.build_opener(request.HTTPSHandler(context=context)))
request.install_opener(request.build_opener(request.HTTPCookieProcessor(cookies)))
# cookies.save()

def get(url, todisk="", utf8=False, conflict=[[], []], context=None, headonly=False, stderr="", threadn=0):
    dl = 0
    if todisk:
        echo(threadn, f"{threadn:>3} Downloading 0 / 0 MB {url}", clamp='█')
        if os.path.exists(todisk + ".part"):
            dl = os.path.getsize(todisk + ".part")
    else:
        echo(threadn, "0 MB")
    skiptonext[0] = False
    seek[0] = False
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
                if seek[0]:
                    resp, err = fetch(url, context, stderr, dl, threadn)
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
            if seek[0]:
                resp, err = fetch(url, context, stderr, dl, threadn)
                if resp.status == 200:
                    data = b''
                    dl = 0
                seek[0] = False



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
                html.append("<a href=\"" + todisk.replace("#", "%23") + "\"><img src=\"" + todisk.replace("#", "%23") + "\" height=200px></a>")
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



def get_cd(file, makedirs=False, preview=False):
    link = file["link"] if preview else file.pop("link")
    todisk = mf + file["name"].replace("\\", "/")
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
        dir = todisk.rsplit("/", 1)[0] + "/"
        tdir = "\\" + dir.replace("/", "\\")
        if not preview and not os.path.exists(dir):
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
        dir = todisk.rsplit("/", 1)[0] + "/"
        tdir = "\\" + dir.replace("/", "\\")
        if not os.path.exists(mf):
            try:
                os.makedirs(mf)
            except:
                kill(f"Can't make folder {tdir} because there's a file using that name, I must exit!")
    if not preview:
        if makedirs and not os.path.exists(dir):
            try:
                os.makedirs(dir)
            except:
                kill(f"Can't make folder {tdir} because there's a file using that name, I must exit!")
        file.update({"name":todisk, "edited":file["edited"]})
    return [link, todisk, file["edited"]]



def downloadtodisk(fromhtml, makedirs=False):
    filelist = []
    filelisthtml = []
    htmlpart = fromhtml["partition"]
    for key in htmlpart.keys():
        for file in htmlpart[key]["files"]:
            if not file["name"]:
                print(f""" I don't have a scraper for {file["link"]}""")
            else:
                if (x := get_cd(file, makedirs) + [key])[0]:
                    filelist += [x]
        for html in htmlpart[key]["html"]:
            if len(html) == 2 and html[1]:
                if not html[1]["name"]:
                    print(f""" I don't have a scraper for {html[1]["link"]}""")
                else:
                    if (x := get_cd(html[1], makedirs) + [key])[0]:
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
            tohtml(get_cd({"link":fromhtml["page"], "name":fromhtml["folder"], "edited":0}, makedirs)[1], fromhtml, [])
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
    try:
        download.join()
    except KeyboardInterrupt:
        pass
    title(status() + batchfile)

    if len(htmlpart) > 1 or htmlpart["0"]["html"]:
        newfile = False if lastfilen == newfilen[0] else True
        if error[0]:
            for x in error[0]:
                htmlpart.pop(os.path.basename(x).split(".", 1)[0], None)
        if not newfile:
            sys.stdout.write(" Nothing new to download.")
        if error[0]:
            sys.stdout.write(" There are failed downloads I will try again later.\n")
        elif not newfile:
            sys.stdout.write("\n")
        for dir in htmldirs.keys():
            if not (x := os.path.exists(dir + "gallery.html")) or newfile:
                orphfiles = []
                for file in next(os.walk(dir))[2]:
                    if not file.endswith(tuple(specialfile)) and not file.startswith("icon"):
                        orphfiles += [file]
                tohtml(dir, fromhtml, set(orphfiles).difference([x[1].rsplit("/", 1)[-1] for x in filelist]))
    for dir in htmldirs.keys():
        if x := fromhtml["page"]:
            file = dir + x["name"] + ".URL"
            if not os.path.exists(file):
                with open(file, 'w') as f:
                    f.write(f"""[InternetShortcut]
URL={x["link"]}""")
                x = "\\" + file.replace("/", "\\")
                print(f" File created: {x}")
    error[0] = []



def carrot(array, z, cw, new, my_conditions):
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
                update_array[0] = y[1]
                a = ii[1] if ii else y[0]
                if cw:
                    p = cw[0] + p + cw[1]
            new += [[a, p]]
            return True, update_array



def carrots(arrays, x, cw=[], any=True):
    update_array = []
    x, my_conditions = conditions(x)
    new = []
    for array in arrays:
        while True:
            update_array = carrot(array, x, cw, new, my_conditions)
            if not update_array:
                break
            array = update_array[1]
            if not any:
                break
        new += [array]
    arrays = new
    return arrays



def linear(d, z):
    dt = []
    for x in z[1]:
        dc = d
        if not x[0]:
            continue
        elif x[0] == "0" or isinstance(x[0], int):
            dt += [x[0]]
            continue
        for y in x[0].split(" > "):
            y = y.split(" >> ")
            if not y[0]:
                continue
            if dc and y[0] in dc:
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
        dc = str(dc)
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



def branch(d, z):
    ds = []
    for k in z[0][0].split(" > "):
        x = k.split(" >> ")
        if not x[0]:
            if len(z[0]) >= 2:
                if isinstance(d, list):
                    for x in d:
                        ds += branch(x, [z[0][1:]] + z[1:])
                elif isinstance(d, dict):
                    for x in d.values():
                        ds += branch(x, [z[0][1:]] + z[1:])
                return ds
            else:
                continue
        elif x[0] in d:
            d = d[x[0]]
            if len(x) == 2:
                d = json.loads(d)
                if x[1] in d:
                    d = d[x[1]]
                else:
                    return ds
        else:
            return ds
    t = type(d).__name__
    if len(z[0]) == 1:
        if not t == "list" and not t == "dict":
            return ds
        if z[0][0]:
            dx = []
            if t == "list":
                for dc in d:
                    if dt := linear(dc, z):
                        if len(z) > 2:
                            dx += [dt + b for b in branch(dc, [splitos(z[2])] + z[3:])]
                        else:
                            dx += [dt]
            elif t == "dict":
                for x in d.values():
                    if dt := linear(x, z):
                        dx += [dt]
            return dx
        else:
            if dt := linear(d, z):
                if len(z) > 2:
                    return [dt + b for b in branch(d, [splitos(z[2])] + z[3:])]
                else:
                    return [dt]
    else:
        if t == "list":
            for x in d:
                ds += branch(x, [z[0][1:]] + z[1:])
        elif t == "dict":
            for x in d.values():
                ds += branch(x, [z[0][1:]] + z[1:])
    return ds



def splitos(z):
    z = z.split(" > 0")
    return z[0].split("0", 1) + z[1:]

def tree(d, z):
    # tree(dictionary, [branching keys, [[linear keys, choose, conditions, customize with, stderr and kill], [linear keys, 0 accept any, 0 no conditions, 0 no customization, 0 continue without]]])
    for x in z[1::2]:
        if not x[0][0]:
            print(f"{tcolorr} Can't have > 0 for last.{tcolorx}")
    z[0] = splitos(z[0])
    # if len(z[0]) >= 2 and not z[0][-1]: z[0] += [""]
    return branch(d, z)



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



def carrot_files(html, htmlpart, key, pick, is_abs, folder, after=False):
    url = ""
    name_err = True
    update_html = []
    for array in html:
        update_array = [array[0], array[1]]
        if after:
            if not update_array[0]:
                update_html += [update_array]
                continue
            url = array[1]
        if url:
            if not is_abs:
                url = page + url
            name = ""
            for x in pick["name"]:
                name_err = True
                for z, cw, a in x[1:]:
                    cw = ast(f"{cw[0]}*{cw[1]}", key).rsplit("*", 1)
                    if a:
                        continue
                    if not z:
                        name_err = False
                    elif x[0]["alt"]:
                        if len(n := carrots([[update_array[0], ""]], z, cw)) >= 2:
                            name += n[-2 if after else 0][1]
                            name_err = False
                            # Developer note: Could be better
                            update_array[0] = n[0][0] + n[1][0]
                            break
                    else:
                        if len(n := carrots([[url, ""]], z, cw, False)) == 2:
                            name += n[-2][1]
                            name_err = False
                            break
                if name_err:
                    kill(0, "there's no name asset found in HTML for this file.")
            if e := pick["extfix"]:
                if len(ext := carrots([[url, ""]], e, [".", ""], False)) == 2 and not name.endswith(ext := ext[-2][1]):
                    name += ext
            if after:
                url = array[1]
            update_html += [[update_array[0], {"link":url, "name":saint(folder + parse.unquote(name)), "edited":htmlpart[key]["keywords"][1] if key in htmlpart and len(htmlpart[key]["keywords"]) > 1 else "0"}]]
        else:
            update_html += [[update_array[0], '']]
        url = array[1]
    return update_html, name_err



def tree_files(db, k, f, cw, pick, htmlpart, folder, filelist, pos):
    master_key = ["", [["0"]]]
    file = f[0]
    if not k:
        key = [["0"]]
    else:
        key = [[k[1][1], 0, 0, 0, 0]]
        if k[0][0]:
            if len(z := k[1][0].split(k[0][0] if k[0][0].startswith("0") else k[0][0] + " > 0", 1)) == 2:
                file = z[1]
                master_key = [k[0][0], [[k[0][1], 0, 0, 0, 0]]]
        elif k[0][1]:
            master_key = ["", [[k[0][1], 0, 0, 0, 0]]]



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
            linear_name += [[z[1], 0, 0, cwf, stderr]]
        else:
            x = tree(db, [z[0], [[z[1], 0, 0, cwf, stderr]]])
            off_branch_name += [x[0][0]] if x else []
    files = tree(db, master_key + [file, key + [[c[0], c[1], 0, 0, 0], [f[1], 0, f[2], cw, 0]] + linear_name])
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
        m = []
        for x in meta:
            for y, cwf in x:
                if len(c := carrots([[file[2], ""]], y, cwf, False)) == 2 and c[-2][1]:
                    m += [c[-2][1]]
                    break
        name = "".join([x if not x == 1 else m.pop(0) if m else "" for x in file[3:]] + off_branch_name)
        if e := pick["extfix"]:
            if len(ext := carrots([[file[2], ""]], e, [".", ""], False)) == 2 and not name.endswith(ext := ext[-2][1]):
                name += ext
        filelist += [[f_key, {"link":file[2], "name":saint(folder + name), "edited":htmlpart[f_key]["keywords"][1] if f_key in htmlpart and len(htmlpart[f_key]["keywords"]) > 1 else "0"}]]



def pick_files(threadn, data, db, part, htmlpart, pick, pickf, folder, filelist, pos, after):
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
                    html, name_err = carrot_files(carrots([p], z, cw, pick["files"]), htmlpart, key, pick, y[0]["alt"], folder, after)
                    for h in html:
                        if not h[1]:
                            continue
                        filelist += [[key, h[1]]]
            if not pick["files"] and not name_err:
                break
    return pos



def rp(x, p):
    for r in p:
        x = "".join(y[0] + y[1] for y in carrots([[x, ""]], r[0], r[1].split("*", 1)))
    return x



def get_data(threadn, page, url, pick):
    data = ""
    if not pick["ready"]:
        echo(f" Visiting {page}", 0, 1)
    if pick["visit"]:
        fetch(page, stderr="Error visiting the page to visit")
    if pick["send"]:
        for x in pick["send"]:
            post = x[1] if x[1] else url
            data = fetch(post, stderr="Error sending data", data=str(x[0]).encode('utf-8'))
        if not data:
            print(f" Error visiting {page}")
            return
        data = data.read()
    if not data and (data := get(url if url else page, utf8=True, stderr="Update cookie or referer if these are required to view", threadn=threadn)) and not data.isdigit():
        if len(data) < 4:
            return
    else:
        print(f" Error visiting {page}")
        return
    title(batchfile + monitor())
    data = ''.join([x.strip() for x in data.splitlines()])
    if pick["part"]:
        part = []
        for z in pick["part"]:
            part += [[x[1], ""] for x in carrots([[data, ""]], z)]
    else:
        part = [[data, ""]]
    if not pick["html"]:
        for p in part:
            p[0] = rp(p[0], pick["replace"])
    return data, part



def pick_in_page(scraper):
    while True:
        data = ""
        url = ""
        threadn, pick, start, page, more_pages, fromhtml = scraper.get()
        htmlpart = fromhtml["partition"][threadn]
        folder = fromhtml["folder"]
        pg[0] += 1
        if x := pick["url"]:
            redir = ""
            for y in x[1]:
                if len(c := carrots([[page, ""]], y, [], False)) == 2:
                    redir = x[0] + c[-2][1] + x[2]
                    break
            if not redir:
                print(f" Error creating a redirected url for {page}")
                break
            url = redir
        if x := pick["urlfix"]:
            redir = ""
            for y in x:
                if not y:
                    redir = page
                    break
                if len(c := carrots([[page, ""]], y[1], [], False)) == 2:
                    redir = y[0] + c[-2][1] + y[2]
                    break
            if not redir:
                print(f" Error fixing url for permanent redirection from {page}")
                break
            page = redir
        db = ""
        if pick["dict"]:
            if not data and (x := get_data(threadn, page, url, pick)):
                data, part = x
            for y in pick["dict"]:
                if len(c := carrots(part, y)) == 2:
                    data = c[0][1]
        if pick["expect"]:
            if not data and (x := get_data(threadn, page, url, pick)):
                data, part = x
            pos = 0
            for y in pick["expect"]:
                for z, cw, a in y[1:]:
                    if a:
                        if not db:
                            db = opendb(data)
                        pos += 1
                        c = z[1].rsplit(" = ", 1)
                        result = tree(db, [z[0], [[c[0], c[1].split(" > "), 0, 0, 0, 0]]])
                    else:
                        result = True if [x[1] for x in carrots(part, z, [], False)][0] else False
                    if y[0]["alt"] and result:
                        if not pick["dismiss"] and Browser:
                            os.system(f"""start "" "{Browser}" "{page}" """)
                        alert(page, pick["message"][pos-1] if pick["message"] and len(pick["message"]) >= pos else "As expected", pick["dismiss"])
                    elif not y[0]["alt"] and not result:
                        if not pick["dismiss"] and Browser:
                            os.system(f"""start "" "{Browser}" "{page}" """)
                        alert(page, pick["message"][pos-1] if pick["message"] and len(pick["message"]) >= pos else "Not any longer", pick["dismiss"])
                    else:
                        more_pages += [[start, page]]
                        timer("Not quite as expected! ", False)
        if not folder:
            if pick["folder"]:
                if not data and (x := get_data(threadn, page, url, pick)):
                    data, part = x
                for y in pick["folder"]:
                    name_err = True
                    for z, cw, a in y[1:]:
                        if a:
                            if not db:
                                db = opendb(data)
                            for d in tree(db, [z[0], [[z[1], 0, 0, 0, 0]]]):
                                folder += d[0]
                                name_err = False
                        elif y[0]["alt"]:
                            if x := [x[1] for x in carrots(part, z, cw, False) if x[1]]:
                                folder += x[0]
                                name_err = False
                                break
                        else:
                            if len(x := carrots([[page, ""]], z, cw, False)) == 2:
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
            if x := pick["savelink"]:
                fromhtml["page"] = {"link":page, "name":saint(x), "edited":0}
        if pick["pages"]:
            if not data and (x := get_data(threadn, page, url, pick)):
                data, part = x
            for y in pick["pages"]:
                for z, cw, a in y[1:]:
                    if a:
                        if not db:
                            db = opendb(data)
                        pages = tree(db, [z[0], [[z[1], 0, 0, 0, 0]]])
                        if pages and not pages[0][0] == "None":
                            for p in pages:
                                if not p[0] == page and not page + p[0] == page:
                                    px = p[0] if y[0]["alt"] else page + p[0]
                                    more_pages += [[start, px]]
                                    if pick["checkpoint"]:
                                        print(f"Checkpoint: {px}\n")
                    else:
                        for p in [x[1] for x in carrots(part, z, cw) if x[1]]:
                            if not p == page and not page + p == page:
                                px = p if y[0]["alt"] else page + p
                                more_pages += [[start, px]]
                                if pick["checkpoint"]:
                                    print(f"Checkpoint: {px}\n")
        if pick["paginate"]:
            new = page
            for y in pick["paginate"]:
                l = carrots([[new, ""]], y[0][0])[0][1] if len(y[0]) > 1 else ""
                l_fix = y[1][0]
                x = carrots([[new, ""]], y[0][1 if len(y[0]) > 1 else 0])[0][1]
                if (p := y[1][1])[1:].isdigit():
                    x = int(x) + int(p)
                elif y[1][1]:
                    p, _, a = peanut(y[1][1], [], False)
                    if a:
                        if not data and (x := get_data(threadn, page, url, pick)):
                            data, part = x
                        if not db:
                            db = opendb(data)
                        x = tree(db, [p[0], [[p[1], 0, 0, 0, 0]]])[-1][0]
                r_fix = y[1][2]
                r = carrots([[new, ""]], y[0][2])[0][1] if len(y[0]) == 3 else ""
                new = f"{l}{l_fix}{x}{r_fix}{r}"
            more_pages += [[start, new]]
        filelist_html = []
        if pick["html"]:
            if not data and (x := get_data(threadn, page, url, pick)):
                data, part = x
            fromhtml["makehtml"] = True
            k_html = []
            if pick["key"] and pick["key"][0]:
                kx = pick["key"][0]
            else:
                kx = [0, 0]
            pos = 0
            for y in pick["html"]:
                for z, cw, a in y[1:]:
                    if a:
                        if not db:
                            db = opendb(data)
                        for k in kx[1:]:
                            master_key = ["", [["0"]]]
                            if not k:
                                key = [["0"]]
                            else:
                                html =  z[0]
                                if html == k[1][0]:
                                    key = [[k[1][1], 0, 0, 0, 0]]
                                else:
                                    continue
                                if k[0][0]:
                                    if len(x := k[1][0].split(k[0][0] if k[0][0].startswith("0") else k[0][0] + " > 0", 1)) == 2:
                                        html = x[1]
                                        master_key = [k[0][0], [[k[0][1], 0, 0, 0, 0]]]
                                elif k[0][1]:
                                    master_key = ["", [[k[0][1], 0, 0, 0, 0]]]
                            for html in tree(db, master_key + [html, key + [[z[1], 0, 0, cw, 0]]]):
                                if pos == 1 or pos == 5:
                                    html[2] = html[2] + "\n"
                                if pos > 3:
                                    html[2] = hyperlink(html[2])
                                html[2] = rp(html[2], pick["replace"])
                                k_html += [[html[1 if html[0] == "0" else 0], [[html[2], ""]]]]
                    else:
                        new_part = []
                        for p in part:
                            key = "0"
                            for k in kx[1:]:
                                if len(d := carrots([[p[0], ""]], k[1], [], False)) == 2:
                                    key = d[0][1]
                                    break
                            c = carrots([[p[0], ""]], z, cw, False)
                            k_html += [[key, [[rp(c[0][1], pick["replace"]), ""]]]]
                            new_part += [["".join(x[0] for x in c), ""]]
                        part = new_part
                pos += 1
            for k, html in k_html:
                if not k in htmlpart:
                    htmlpart.update(new_p(k))
                after = False
                for x in [pick["file"], pick["file_after"]]:
                    for y in x:
                        for z, cw, a in y[1:]:
                            if a:
                                continue
                            html = carrot_files(carrots(html, z, cw, pick["files"]), htmlpart, k, pick, y[0]["alt"], folder, after)[0]
                            new_html = []
                            for h in html:
                                new_html += [[h[0], ""], ["", h[1]]] if h[1] else [h] # Overkill?
                                if not pick["ready"]: filelist_html += [h[1]] if h[1] else []
                            html = new_html
                    after = True
                htmlpart[k]["html"] += html
            keywords = {}
            pos = 0
            for y in pick["key"][1:]:
                for z in y[1:]:
                    z, cw, a = z[1:]
                    if a:
                        if not db:
                            db = opendb(data)
                        for k in kx[1:]:
                            if not k:
                                key = [["0", 0, 0, 0, 0]]
                            else:
                                if z[0] == k[1][0]:
                                    key = [[k[1][1], 0, 0, 0, 0]]
                                else:
                                    continue
                            for d in tree(db, [z[0], [[z[1], 0, 0, 0, 0]] + key]):
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
                            for k in kx[1:]:
                                if len(d := carrots([[p[0], ""]], k[1], [], False)) == 2:
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
        if pick["icon"]:
            if not data and (x := get_data(threadn, page, url, pick)):
                data, part = x
            pos = 0
            for y in pick["icon"]:
                if len(fromhtml["icons"]) < pos + 1:
                    for z, _, a in y[1:]:
                        if a:
                            if not db:
                                db = opendb(data)
                            url = tree(db, [z[0], [[z[1], 0, 0, 0, 0]]])[0][0]
                            ext = ""
                            for x in imagefile:
                                if x in url:
                                    ext = x
                            fromhtml["icons"] += [{"link":url, "name":f"""icon{" " + str(pos) if pos else ""}{ext}""", "edited":0}]
                        else:
                            if len(c := carrots(part, z, [], False)) == 2:
                                url = c[0][1]
                                ext = ""
                                for x in imagefile:
                                    if x in url:
                                        ext = x
                                fromhtml["icons"] += [{"link":url, "name":f"""icon{" " + str(pos) if pos else ""}{ext}""", "edited":0}]
                pos += 1
        if pick["file"] or pick["file_after"]:
            if not data and (x := get_data(threadn, page, url, pick)):
                data, part = x
            pos = 0
            filelist = []
            if pick["file"]:
                pos = pick_files(threadn, data, db, part, htmlpart, pick, pick["file"], folder, filelist, pos, False)
            if pick["file_after"]:
                pos = pick_files(threadn, data, db, part, htmlpart, pick, pick["file_after"], folder, filelist, pos, True)
            for file in filelist:
                k = file[0]
                if not k in htmlpart:
                    htmlpart.update(new_p(k))
                htmlpart[k].update({"files":[file[1]] + htmlpart[k]["files"]})
            if not pick["ready"]:
                stdout = ""
                x = ""
                for file in filelist:
                    x = get_cd(file[1], preview=True)
                    stdout += tcolorb + x[0] + tcolorr + " -> " + tcolorg + x[1].replace("/", "\\") + "\n"
                for file in filelist_html:
                    x = get_cd(file, preview=True)
                    stdout += tcolorb + x[0] + tcolorr + " -> " + tcolorg + x[1].replace("/", "\\") + "\n"
                if not x:
                    stdout += f"{tcolorr} No files found in this page (?) Check pattern, add more file pickers, using cookies can make a difference." + "\n"
                echo(stdout + tcolorx)
        if not pick["ready"]:
            fromhtml["ready"] = False
        echothreadn.remove(threadn)
        scraper.task_done()
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
    return {"ready":True, "page":"", "folder":"", "makehtml":False, "icons":[], "inlinefirst":True, "partition":new}



def scrape(startpages):
    shelf = {}
    threadn = 0
    pages = [["", x] for x in startpages]
    visited = set()
    while True:
        more_pages = []
        for start, page in pages:
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
                fromhtml["inlinefirst"] = pick["inlinefirst"]
            else:
                fromhtml = shelf[start]
                fromhtml["partition"].update({threadn:new_p("0")})
            scraper.put((threadn, pick, start, page, more_pages, fromhtml))
        try:
            scraper.join()
        except KeyboardInterrupt:
            pass # Ctrl + C
        seen = set()
        more_pages = [x for x in more_pages if not x[1] in seen and not seen.add(x[1])]
        for start, page in more_pages:
            if page in visited and not visited.add(page):
                print(f"{tcolorr}Already visited {page} loophole warning{tcolorx}")
                # more_pages.remove(page)
        if not more_pages:
            break
        pages = more_pages
    title(status() + batchfile)

    for p in shelf.keys():
        if shelf[p]["partition"]:
            sort_part = {}
            threadn = list(shelf[p]["partition"].keys())
            threadn.sort()
            for t in threadn:
                sort_part.update(shelf[p]["partition"][t])
            shelf[p]["partition"] = sort_part
            if not shelf[p]["ready"]:
                htmlpart = shelf[p]["partition"]
                if shelf[p]["makehtml"]:
                    stdout = f"\n Then create " + tcolorg + shelf[p]["folder"] + "gallery.html" + tcolorx + " with\n"
                    if x := shelf[p]["icons"]:
                        stdout += f"""{tcolorg}█{"█ █".join([i["name"] for i in x])}█\n"""
                    if x := shelf[p]["page"]:
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
                    echo(stdout + tcolorx)
                echo(f""" ({tcolorb}Download file {tcolorr}-> {tcolorg}to disk{tcolorx}) - Add scraper instruction "ready" in {rulefile} to stop previews for this site (C)ontinue """, 0, 1)
                continue_prompt[0] = False
                while not continue_prompt[0]:
                    time.sleep(0.1)
                continue_prompt[0] = False
            downloadtodisk(shelf[p], makedirs=True)
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



def container(dir, ondisk):
    if ondisk.lower().endswith(tuple(videofile)):
        data = f"""<div class="frame"><video height="200" autoplay><source src="{ondisk.replace("#", "%23")}"></video><div class="sources">{ondisk}</div></div>\n"""
    elif ondisk.lower().endswith(tuple(imagefile)):
        if buildthumbnail:
            thumb = "Thumbnails/" + ren(ondisk, "_small")[1]
            if not os.path.exists(dir + thumb):
                try:
                    img = Image.open(dir + ondisk)
                    w, h = img.size
                    if h > 200:
                        img.resize((int(w*(200/h)), 200), Image.ANTIALIAS).save(dir + thumb, subsampling=0, quality=100)
                    else:
                        img.save(dir + thumb)
                except:
                    pass
        else:
            thumb = ondisk
        data = f"""<div class="frame"><a class="fileThumb" href="{ondisk.replace("#", "%23")}"><img class="lazy" data-src="{thumb.replace("#", "%23")}"></a><div class="sources">{ondisk}</div></div>\n"""
    elif os.path.exists(dir + ondisk):
        data = f"""<a href=\"{ondisk.replace("#", "%23")}"><div class="aqua" style="height:174px; width:126px;">{ondisk}</div></a>\n"""
        if os.path.exists(dir + ondisk.rsplit(".", 1)[0] + "/"):
            data += f"""<a href="{ondisk.rsplit(".", 1)[0].replace("#", "%23")}"><div class="aqua" style="height:174px;"><i class="aqua" style="border-width:0 3px 3px 0; padding:3px; -webkit-transform: rotate(-45deg); margin-top:82px;"></i></div></a>\n"""
    else:
        data = f"""<a href=\"{ondisk.replace("#", "%23")}"><div style="display:inline-block; vertical-align:top; border:1px solid #b2b2b2; border-top:1px solid #4c4c4c; border-left:1px solid #4c4c4c; padding:12px; height:174px; width:126px; word-wrap: break-word;">☠️</div></a>\n"""
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
<style>
html,body{background-color:#10100c; color:#088 /*cb7*/; font-family:consolas, courier; font-size:14px;}
a{color:#dc8 /*efdfa8*/;}
a:visited{color:#cccccc;}
.aqua{background-color:#006666; color:#33ffff; border:1px solid #22cccc;}
.aquatext{color:#22cccc}
.carbon, .files, .time{background-color:#10100c; border:3px solid #6a6a66; border-radius:12px;}
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
.cell{overflow:auto; width:calc(100% - 20px); display:inline-block; vertical-align:text-top;}
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
<button class="next" onclick="resizeCell('calc(100% - 20px)')">&nbsp;.&nbsp;</button>
<button class="next" onclick="resizeCell('calc(50% - 32px)')">. .</button>
<button class="next" onclick="resizeCell('calc(33% - 28px)')">...</button>
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



def tohtml(dir, fromhtml, orphfiles):
    tdir = "\\" + dir.replace("/", "\\")
    builder = ""
    listurls = ""
    htmlpart = fromhtml["partition"]
    new_relics = htmlpart.copy()



    for icon in fromhtml["icons"]:
        todisk = dir + icon["name"]
        if not os.path.exists(todisk):
            if not (err := get(icon["link"], todisk)) == 1:
                echo(f""" Error downloading ({err}): {icon["link"]}""", 0, 1)
        builder += f"""<img src="{icon["name"]}" height="100px">\n"""
    if x := fromhtml["page"]:
        builder += f"""<h2><a href="{x["link"]}">{x["name"]}</a></h2>"""



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



    partfile = dir + "partition.json"
    gallery_is = "updated"
    if not os.path.exists(partfile):
        gallery_is = "created"
        with open(partfile, 'w') as f:
            f.write(json.dumps(new_relics))
    print(f" File {gallery_is}: {tdir}partition.json")
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
        if not relics[id]["html"] or relics[id]["keywords"] < new_relics[id]["keywords"]:
            part.update({id:new_relics[id]})
        else:
            part.update({id:relics[id]})
    with open(partfile, 'w') as f:
        f.write(json.dumps(part))



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
        if not os.path.exists(dir + "Thumbnails/"):
            os.makedirs(dir + "Thumbnails/")
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
            builder += f"""<div class="time" id="{id}" style="float:right;">Part {id} ꍯ {time}\nKeywords: {keywords}</div>\n"""
        builder += title
        files = [x for x in part[id]["files"]]
        if files:
            builder += "<div class=\"files\">\n"
            for file in files:
                builder += container(dir, file)
            builder += "</div>\n"
        if "orphfiles" in part[id]:
            builder += "<div class=\"edits\">\n"
            for file in part[id]["orphfiles"]:
                # os.rename(dir + file, dir + "Orphaned files/" + file)
                builder += container(dir, file)
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
                        content += f"""{array[0]}{container(dir, array[1]["name"])}"""
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
                listurls += f"""# From <a href="#{id}">#{id}</a> :: {title}<br>{links}\n"""
            builder += f"{content}</div>\n"
        elif not files:
            builder += "<div class=\"edits\">Rebuild HTML with a different login/tier may be required to view</div>\n"
        builder += "</div>\n\n"
    with open(dir + "gallery.html", 'wb') as f:
        f.write(bytes(new_html(builder, batchname, listurls), "utf-8"))
    print(f" File {gallery_is}: {tdir}gallery.html ")



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
        return
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
            return
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



def finish_sort():
    if not os.path.exists(mf):
        choice(bg=True)
        print(f" {tmf} doesn't exist! Nothing to sort.")
        return
    mover = {}
    for file in next(os.walk(mf))[2]:
        for n in md5er:
            if len(c := carrots([[file,""]], n, [], False)) == 2 and not c[0][0] and not c[-1][0]:
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
        print(f" Nothing to sort! Check and add or update pattern if there are files in {tmf} needed to be sorted.")
        return
    sys.stdout.write(f" ({tcolorb}From directory {tcolorr}-> {tcolorg}to a more deserving directory{tcolorx}) {tcd} for non-existent directories - (C)ontinue ")
    sys.stdout.flush()
    if not choice("c") == 1:
        kill(0)
    for file, dir in mover.items():
        if os.path.exists(dir + file):
            print(f"""I want to (D)elete source file because destination file already exists:
     source:      {mf}{file}
     destination: {dir}{file}""")
            if not choice("d") == 1:
                kill(0)
            os.remove(mf + file)
        elif os.path.exists(dir):
            os.rename(mf + file, dir + file)
        else:
            if not os.path.exists(cd):
                os.makedirs(cd)
            if not os.path.exists(cd + file):
                os.rename(mf + file, cd + file)
            else:
                print(f"""I want to (D)elete source file because destination file already exists:
     source:      {mf}{file}
     destination: {cd}{file}""")
                if not choice("d") == 1:
                    kill(0)
                os.remove(mf + file)



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



run_input = ["", "", False]
def read_input(m):
    if not m:
        return
    if any(word for word in pickers.keys() if m.startswith(word)):
        run_input[0] = m
        return True
    elif m.startswith("http") and not m.startswith("http://localhost"):
        if m.endswith("/"):
            choice(bg=True)
            print(" I don't have a scraper for that!")
        else:
            run_input[1] = m
        return True
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
    print()
    ready_input()
    return True



def readfile():
    if not os.path.exists(textfile):
        open(textfile, 'w').close()
    print(f"Reading {textfile} . . .")
    with open(textfile, 'r', encoding="utf-8") as f:
        textread = f.read().splitlines()
    pages = []
    nextpages = []
    fromhtml = new_part()
    for line in textread:
        if not line or line.startswith("#"):
            continue
        elif line == "then":
            nextpages += [pages]
            pages = []
            continue
        elif line == "end":
            break
        elif not line.startswith("http"):
            continue
        if any(word for word in pickers.keys() if line.startswith(word)):
            pages += [line]
        else:
            name = parse.unquote(line.split("/")[-1])
            fromhtml["partition"]["0"]["files"] += [{"link":line, "name":saint(name), "edited":0}]
    nextpages += [pages]
    if fromhtml["partition"]["0"]["files"]:
        downloadtodisk(fromhtml)
    elif nextpages:
        resume = False
        for pages in nextpages:
            if resume:
                print(f"\n Resuming next lines from {textfile}")
            else:
                resume = True
            scrape(pages)
    else:
        print(f" No urls in {textfile}!")



savepage = [{}]
def source_view():
    if busy[0]:
        echo("Please wait for another operation to finish", 1, 1)
        return
    while True:
        m = input("Enter URL to view source, append URL with key > s > to read it as dictionary, enter nothing to exit: ").rstrip()
        if m.startswith("http"):
            m = m.split(" ", 1)
            if not m[0] in savepage[0]:
                data = get(m[0], utf8=True)
                savepage[0] = {m[0]:data, "part":[]}
            else:
                data = savepage[0][m[0]]
            if not data.isdigit():
                if len(m) == 2:
                    z, _, a = peanut(m[1], [], False)
                    if a:
                        if x := tree(opendb(data), [z[0], [[z[1], 0, 0, 0, 0]]]):
                            for y in x:
                                print(syntax(y[0], True))
                                savepage[0]["part"] += [y[0]]
                        else:
                            print(f"{tcolorr}Last few keys doesn't exist, try again.{tcolorx}\n")
                    else:
                        part = []
                        for x in carrots([[data, ""]], z):
                            print(x[1])
                            savepage[0]["part"] += [x[1]]
                else:
                    data = ''.join([s.strip() if s.strip() else "" for s in data.splitlines()])
                    print(syntax(data))
                    print()
            else:
                print("Error or dead (update cookie or referer if these are required to view)\n")
        elif not m:
            echo("", 1)
            echo("", 1)
            break
        else:
            z, _, a = peanut(m, [], False)
            part = savepage[0]["part"]
            savepage[0]["part"] = []
            for data in part:
                if a:
                    if x := tree(opendb(data), [z[0], [[z[1], 0, 0, 0, 0]]]):
                        for y in x:
                            print(syntax(y[0], True))
                            savepage[0]["part"] += [y[0]]
                    else:
                        print(f"{tcolorr}Last few keys doesn't exist, try again.{tcolorx}\n")
                else:
                    for x in carrots([[data, ""]], z):
                        print(x[1])
                        savepage[0]["part"] += [x[1]]
    ready_input()



def keylistener():
    while True:
        el = choice("abcdghiklnoqrstvx0123456789")
        if el == 1:
            echo("", 1)
            retryall_always[0] = True
            if not busy[0]:
                ready_input()
        elif el == 2:
            if not Browser:
                choice(bg=True)
                print(f""" No browser selected! Please check the "Browser =" setting in {rulefile}""")
            elif HTMLserver:
                os.system(f"""start "" "{Browser}" "http://localhost:8886/{batchname} 1.html" """)
            else:
                os.system(f"""start "" "{Browser}" "{batchdir}{batchname} 1.html" """)
            print("""
 Browser key listener (Not here!):
  > W - Edge detect
  > A - Geistauge: compare to left
  > S - Geistauge: bright both
  > D - Geistauge: compare to right (this)
  > Shift - Fit image to screen
 Enable preview from toolbar then mouse-over an image while holding a key to see effects.

 "Edge detect" and "Geistauge" are canvas features and they require Cross-Origin Resource Sharing (CORS)
 (Google it but tl;dr: Try HTML server)
""")
            if not busy[0]:
                ready_input()
        elif el == 3:
            echo("", 1)
            continue_prompt[0] = True
            if not busy[0]:
                ready_input()
        elif el == 4:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            if not Geistauge:
                choice(bg=True)
                print(" GEISTAUGE: Maybe not.")
            else:
                choice(bg="4c")
                if input("Drag'n'drop and enter my SAV file: ").rstrip().replace("\"", "").replace("\\", "/") == f"{batchdir}{sav}":
                    skull()
                    tohtml_g(delete=True)
            ready_input()
        elif el == 5:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            if not Geistauge:
                choice(bg=True)
                print(" GEISTAUGE: Maybe not.")
            else:
                tohtml_g()
            ready_input()
        elif el == 6:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            sys.stdout.write("Open (H)elp unless you mean (I)nput mode for (HTTP...): ")
            sys.stdout.flush()
            el = choice("hvi")
            if el == 1:
                help()
                ready_input()
            elif el == 2:
                source_view()
            elif el == 3:
                if not read_input(input("Enter input, enter nothing to cancel: ").rstrip().replace("\"", "")):
                    echo("", 1, 0)
                    echo("", 1, 0)
                    echo("", 1, 0)
                    ready_input()
        elif el == 7:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            if not read_input(input("Enter input, enter nothing to cancel: ").rstrip().replace("\"", "")):
                echo("", 1, 0)
                echo("", 1, 0)
                ready_input()
        elif el == 8:
            c = False
            for c in cookies:
                echo(str(c), 1, 2)
            if not c:
                echo("No cookies!", 1, 1)
            if not busy[0]:
                ready_input()
        elif el == 9:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            run_input[2] = True
        elif el == 10:
            echo("", 1)
            retryall_else[0] = True
            if not busy[0]:
                ready_input()
        elif el == 11:
            if busy[0]:
                echo("Please wait for another operation to finish", 1, 1)
                continue
            finish_sort()
            ready_input()
        elif el == 12:
            echo("", 1)
            retryall_always[0] = False
            if not busy[0]:
                ready_input()
        elif el == 13:
            echo("", 1)
            retryall[0] = True
            if not busy[0]:
                ready_input()
        elif el == 14:
            echo("", 1)
            skiptonext[0] = True
            if not busy[0]:
                ready_input()
        elif el == 15:
            if ticks:
                echo(f"""COOLDOWN {"DISABLED" if cooldown[0] else "ENABLED"}""", 1, 1)
            else:
                echo(f"""Timer not enabled, please add "#-# seconds rarity 100%" in {rulefile}, add another timer to manipulate rarity.""", 1, 1)
            cooldown[0] = False if cooldown[0] else True
            if not busy[0]:
                ready_input()
        elif el == 16:
            source_view()
        elif el == 17:
            echo(f"""SET ALL ERROR DOWNLOAD REQUESTS TO: {"SKIP" if retryx[0] else "RETRY"}""", 1, 1)
            retryx[0] = False if retryx[0] else True
            retryall_always[0] = True
            if not busy[0]:
                ready_input()
        elif 0 <= (n := min(el-18, 8)) < 9:
            echo(f"""MAX PARALLEL DOWNLOAD SLOT: {n} {"(pause)" if not n else ""}""", 1, 1)
            dlslot[0] = n
            if not busy[0]:
                ready_input()
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
  > Press K to view cookies.
  > Press 1 to 8 to set max parallel download of 8 available slots, 0 to pause.
  > Press Ctrl + C to break and reconnect of the ongoing downloads or to end timer instantly.""")



busy[0] = True
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
busy[0] = False



mainmenu()
ready_input()
while True:
    if run_input[0]:
        busy[0] = True
        scrape([run_input[0]])
        run_input[0] = ""
        busy[0] = False
        print()
        ready_input()
    if run_input[1]:
        busy[0] = True
        x = new_part()
        x["partition"]["0"]["files"] = [{"link":run_input[1], "name":saint(parse.unquote(run_input[1].split("/")[-1])), "edited":0}]
        downloadtodisk(x)
        run_input[1] = ""
        busy[0] = False
        print()
        ready_input()
    if run_input[2]:
        readfile()
        run_input[2] = False
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
open /Applications/Python\ 3.9/Install\ Certificates.command
sudo python3 -m pip install --upgrade pip
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
if exist "!txtfilex!" for /f "delims=" %%i in ('findstr /b /i "Python = " "!txtfilex!"') do set string=%%i&& set string=!string:~9!&&goto check
:check
chcp 437>nul
if not "!string!"=="" (set pythondir=!string!)
set x=Python 3.9
set cute=!x:.=!
set cute=!cute: =!
set pythondirx=!pythondir!!x: 3.=3!
if exist "!pythondirx!\python.exe" (cd /d "!pythondirx!" && color %color%) else (color %stopcolor%
echo.
if "!string!"=="" (echo  I can't seem to find \!x: 3.=3!\python.exe^^! Install !x! in default location please, or edit this batch file.&&echo.&&echo  Download the latest !x!.x from https://www.python.org/downloads/) else (echo  Please fix path to \!x: 3.=3!\python.exe in "Python =" setting in !txtfile!)
echo.
echo  I must exit^^!
pause%>nul
exit)
set pythondir=!pythondir:\=\\!

if exist Lib\site-packages\ (goto start) else (goto install)
if exist Lib\site-packages\ (echo.) else (echo.)

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
