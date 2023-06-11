@echo off && goto loaded

import os, sys, time, hashlib, shutil
from datetime import datetime, timedelta
from threading import Thread
from urllib import parse

batchfile = os.path.basename(__file__)
batchname = os.path.splitext(batchfile)[0]
batchdir = os.path.dirname(os.path.realpath(__file__))
filelist = []
pythondir = ""

if len(sys.argv) > 3:
    filelist = list(filter(None, sys.argv[1].split("//")))
    pythondir = sys.argv[2].replace("\\\\", "\\").replace("\\", "/")
    batchdir = sys.argv[3].replace("\\\\", "\\").replace("\\", "/") # grabs "start in" argument
if "/" in batchdir and not batchdir.endswith("/"):
    batchdir += "/"
os.chdir(batchdir)

editor = "C:\\Program Files Two\\Notepad++\\notepad++.exe"
overrall = [False]
textfile = ['.txt', '.bat', '.reg', '.html', '.cd', '.plist']
Keypress = [False]*27



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
                echo(f"{str(i)}{choices[el-1].upper()}", 0, 2)
                return el
    else:
        return sys.stdin.readline().replace("\n", "")



argslist = ['expensive', 'expensivebg', 'loaded', 'loadedbg']
regfile = batchname + ".reg"
if not filelist:
    batchdirx = batchdir.replace("/", "\\\\") + "\\\\"
    print(f"""
 + You must launch me from context menu. I can create regfile to add new items in context menu.
 + And when launching from context menu, it'll expect this batch file to be in same name and place.
 + If I moved to elsewhere, come to me to recreate regfile to update items in context menu with my new location.

(C)reate regfile now: """)
    if choice("c") == 1:
        with open(regfile, 'wb') as f:
            f.write(bytes(f"""Windows Registry Editor Version 5.00

;Ferchel
[HKEY_CLASSES_ROOT\Directory\Background\shell\\ferchel]
@="&{batchname}"
[HKEY_CLASSES_ROOT\Directory\Background\shell\\ferchel_expensive]
@="{batchname} (expensive)"

[HKEY_CLASSES_ROOT\Directory\Background\shell\\ferchel\Command]
@="cmd.exe /c \\"{batchdirx}{batchfile}\\" loadedbg"
[HKEY_CLASSES_ROOT\Directory\Background\shell\\ferchel_expensive\Command]
@="cmd.exe /c \\"{batchdirx}{batchfile}\\" expensivebg"

[HKEY_CLASSES_ROOT\*\shell\\ferchel]
@="&{batchname}"
[HKEY_CLASSES_ROOT\*\shell\\ferchel_expensive]
@="{batchname} (expensive)"

[HKEY_CLASSES_ROOT\*\shell\\ferchel\command]
@="{batchdirx}{batchfile} \\"%1\\" \\"loaded\\""
[HKEY_CLASSES_ROOT\*\shell\\ferchel_expensive\command]
@="{batchdirx}{batchfile} \\"%1\\" \\"expensive\\""

[HKEY_CLASSES_ROOT\Directory\shell\\ferchel]
@="&{batchname}"
[HKEY_CLASSES_ROOT\Directory\shell\\ferchel_expensive]
@="{batchname} (expensive)"

[HKEY_CLASSES_ROOT\Directory\shell\\ferchel\command]
@="{batchdirx}{batchfile} \\"%1\\" \\"loaded\\""
[HKEY_CLASSES_ROOT\Directory\shell\\ferchel_expensive\command]
@="{batchdirx}{batchfile} \\"%1\\" \\"expensive\\""
""", 'utf-8'))
    sys.exit()
elif filelist[-1] in tuple(argslist):
    expensive = filelist[-1]
    filelist.remove(filelist[-1])
else:
    expensive = "loaded"



def createdate(datefile, lastdate):
    if lastdate:
        new_datefile = datetime.strptime(lastdate, "%Y-%m-%d %H:%M:%S") + timedelta(minutes=1)
        new_datefile = datetime.strftime(new_datefile, "%m-%d-%Y %H.%M.00")
    print("""
================================================================================
                    (P)roceed to update datefile now""")
    if lastdate:
        print(f"               Or dir's (L)atest date: {new_datefile}" )
    el = choice("pl" if lastdate else "p")
    if not el in [1, 2]:
        sys.exit()
    if el == 1:
        new_datefile = str(datetime.now().replace(microsecond=0))
        new_datefile = datetime.strptime(new_datefile, "%Y-%m-%d %H:%M:%S")
        new_datefile = datetime.strftime(new_datefile, "%m-%d-%Y %H.%M.00")
    buf = ""
    print("Now working in top directory . . .")
    for file in next(os.walk('.'))[2]:
        size = 0
        if file == new_datefile or file == datefile:
            continue
        size = os.path.getsize(file)
        size = ' '.join(f'{size:012}'[i:i+3] for i in range(0, 12, 3))
        buf += f"{size}    {file}\n"
    for folder in next(os.walk('.'))[1]:
        if folder.endswith(" Trash"):
            continue
        print(f"""Now working in subdirectory \\{folder}\\ . . .""")
        try:
            itemcount = len(os.listdir(folder))
            if itemcount < 1250:
                isbig = "   "
            elif itemcount < 1500:
                isbig = " + "
            elif itemcount < 1750:
                isbig = "+ +"
            else:
                isbig = "+++"
        except:
            isbig = " ? "
        try:
            size = 0
            for dirpath, folders, files in os.walk(folder):
                for file in files:
                    filepath = os.path.join(dirpath, file)
                    size += os.path.getsize(filepath)
            size = ' '.join(f'{size:012}'[i:i+3] for i in range(0, 12, 3))
        except:
            size = "??? ??? ??? ???"
        buf += f"{size}{isbig}\\{folder}\\\n"
    try:
        with open(new_datefile, 'wb') as f:
            buf = '\n'.join(sorted(buf.splitlines(), reverse=True))
            f.write(bytes(buf, 'utf-8'))
    except:
        print("\n This directory is write protected.")
    if datefile and not datefile == new_datefile:
        os.remove(datefile)
    print("\n Datefile updated")



def get_datefile():
    # Looking for 01-01-2000 through 12-31-2060 with .00 as extension, pick last item, hopefully a datefile.
    datefile = ""
    for file in next(os.walk('.'))[2]:
        if not file[0:10].replace('-', '').isnumeric():
            continue
        if file[0].isalpha():
            break
        if not 1 <= int(file[0:1]) <= 12 and not 1 <= int(file[3:4]) <= 31 and not 2000 <= int(file[6:10]) <= 2060:
            continue
        if not file.endswith(".00"):
            continue
        datefile = file
    return datefile



def ferchel():
    datefile = get_datefile()
    difference = ""
    if not datefile:
        print("No old date!")
        createdate(datefile, "")
    else:
        folders = []
        newmaster = []
        oldmaster = []
        scanned = []
        unscanned = []
        exempted = []
        lastdate = ""

        with open(datefile, 'r', encoding='utf-8') as f:
            masterread = f.read().splitlines()
        for line in masterread:
            if "\\" in line:
                oldmaster += [line[18:]]
            else:
                oldmaster += [line[19:]]

        for folder in next(os.walk('.'))[1]:
            if folder.endswith(" Trash"):
                exempted += [folder]
            else:
                folders += [folder]
                newmaster += ["\\" + folder + "\\"]
        newfolder = set(newmaster).difference(oldmaster)

        for file in next(os.walk('.'))[2]:
            if file == datefile:
                continue
            newmaster += [file]
        deleted = set(oldmaster).difference(newmaster)

        print(f"Loading old date successfully: {datefile}\n")
        date = datetime.strptime(datefile, "%m-%d-%Y %H.%M.%S")
        date = datetime.strftime(date, "%Y-%m-%d %H:%M:00")
        print("===================================Updates======================================")
        print(" - - Folders - -")
        if expensive == "expensivebg":
            for folder in folders:
                New = 0
                for root, subfolder, files in os.walk(folder):
                    for file in files:
                        if (ld := str(datetime.fromtimestamp(os.path.getmtime(root + "/" + file)).replace(microsecond=0))) > date:
                            if ld > lastdate:
                                lastdate = ld
                            New += 1
                if New:
                    print(f"+ \\{folder}\\ ({New} new files)")
                elif (ld := str(datetime.fromtimestamp(os.path.getmtime(folder)).replace(microsecond=0))) > date:
                    if ld > lastdate:
                        lastdate = ld
                    scanned += [folder]
        else:
            for folder in folders:
                if (ld := str(datetime.fromtimestamp(os.path.getmtime(folder)).replace(microsecond=0))) > date:
                    if ld > lastdate:
                        lastdate = ld
                    scanned += [folder]
                else:
                    unscanned += [folder]
        for e in scanned:
            print(f"+ \\{e}\\")
        if exempted:
            print("\nExempted from scan")
            for e in exempted:
                print(f"- \\{e}\\")
        if unscanned:
            print("\nConsider run Ferchel expensive for updated folder by edited files")
            for e in unscanned:
                print(f"? \\{e}\\")



        print("\n - - Files - -")
        for file in next(os.walk('.'))[2]:
            if not file == datefile and (ld := str(datetime.fromtimestamp(os.path.getmtime(file)).replace(microsecond=0))) > date:
                if ld > lastdate:
                    lastdate = ld
                print(file)



        print("\n - - Deleted/renamed - -")
        if deleted:
            print('\n'.join(deleted))

        print("\n - - New/renamed - -")
        if newfolder:
            print('\n'.join(newfolder))

        createdate(datefile, lastdate)
    sys.exit()



def overwrite(slavefile, masterfile):
    if os.path.basename(masterfile) == "desktop.ini":
        os.system(f"attrib -s -h \"{masterfile}\"")
    try:
        with open(slavefile, 'rb') as fsrc:
            with open(masterfile, 'wb') as fdst:
                while True:
                    buffer = fsrc.read(16*1024)
                    if not buffer:
                        break
                    fdst.write(buffer)
        os.utime(masterfile, (os.path.getatime(slavefile), os.path.getmtime(slavefile)))
    except:
        # raise
        print("Write protected or in use (by COM surrogate probably).\n\nTry again!")
        sys.exit()
    if os.path.basename(masterfile) == "desktop.ini":
        os.system(f"attrib +s +h \"{masterfile}\"")



def remainders(masterfile, slavefile, m, s):
    pos = 0
    EOL = True
    sEOL = len(s)

    for line in m:
        line = line.decode("utf-8")
        if sEOL > pos:
            line2 = s[pos].decode("utf-8")
        else:
            line2 = "(end)"
        pos += 1
        if not line == line2:
            buffer = f"""First difference in line {pos}:

featuring: {line}
reference: {line2}"""
            EOL = False
            break

    if EOL:
        if sEOL > pos:
            line2 = s[pos].decode("utf-8")
            pos += 1
            buffer = f"""First difference in line {pos}:

featuring: (end)
reference: {line2}"""
        else:
            buffer = f"Please fix the carriage returns (\\r\\n vs \\n difference)."

    if edit[0]:
        os.system(f"""start "" "{editor}" "{masterfile}" -n{pos}""")
        os.system(f"""start "" "{editor}" "{slavefile}" -n{pos}""")
        edit[0] = False
    echo(buffer, 0, 2)
    el = input(f"""(E)dit to open these in text editor, "over" (reverse: "revo") or "all" to overwrite/all, re(L)oad: """, ["E", "Over", "Revo", "All", "L"])
    if el == 1:
        edit[0] = True
    elif el == 2:
        overwrite(slavefile, masterfile)
    elif el == 3:
        overwrite(masterfile, slavefile)
    elif el == 4:
        overwrite(slavefile, masterfile)
        overrall[0] = True
        print("\n Overwriting all the differences . . .")



edit = [False, False]
def compute(masterfile, slavefile):
    while True:
        timestamp = [os.path.getmtime(masterfile), os.path.getmtime(slavefile)]
        if not expensive == "expensive" and timestamp[0] == timestamp[1]:
            edit[0] = False
            return

        with open(masterfile, 'rb') as f:
            m = f.read()
        with open(slavefile, 'rb') as f:
            s = f.read()
        md5hash = [hashlib.md5(m).hexdigest(), hashlib.md5(s).hexdigest()]

        if md5hash[0] == md5hash[1]:
            if not timestamp[0] == timestamp[1]:
                if not Keypress[1] and not Keypress[14]:
                    title(masterfile.replace("/", "\\"))
                    os.system("cls")
                    echo(f"{tcolorx}{cls}md5: {md5hash[0]} last modification: {timestamp[0]}\nmd5: {md5hash[1]} last modification: {timestamp[1]}", 0, 2)
                    Keypress[input("(U)pdate newer identical file with oldest date, (A)lways (N)one (S)kip: ", "abcdefghijklmnopqrstuvwxyz0123456789")] = True
                if not Keypress[14]:
                    if Keypress[1] or Keypress[21]:
                        old = [masterfile, slavefile] if timestamp[0] < timestamp[1] else [slavefile, masterfile]
                        os.utime(old[1], (os.path.getatime(old[0]), os.path.getmtime(old[0])))
            edit[0] = False
            return
        elif overrall[0]:
            overwrite(slavefile, masterfile)
            edit[0] = False
            return
        elif masterfile.lower().endswith(tuple(textfile)) and slavefile.lower().endswith(tuple(textfile)):
            title(masterfile.replace("/", "\\"))
            os.system("cls")
            echo(f"{tcolorx}{cls}")
            remainders(masterfile, slavefile, m.splitlines(), s.splitlines())
        else:
            title(masterfile.replace("/", "\\"))
            os.system("cls")
            echo(f"{tcolorx}{cls}md5: {md5hash[0]}\nmd5: {md5hash[1]}", 0, 2)
            if os.path.basename(masterfile) == os.path.basename(slave):
                el = input("""Files of same name have different MD5. Type "over" (reverse: "revo") or "all" to overwrite/all, re(L)oad: """, ["Over", "Revo", "All", "L"])
            else:
                el = input("""They got different MD5 hashes. Type "over" (reverse: "revo") or "all" to overwrite/all, re(L)oad: """, ["Over", "Revo", "All", "L"])
            if el == 1:
                overwrite(slavefile, masterfile)
            elif el == 2:
                overwrite(masterfile, slavefile)
            elif el == 3:
                overwrite(slavefile, masterfile)
                overrall[0] = True
                print("\n Overwriting all the differences . . .")
        if not os.path.exists(masterfile) or not os.path.exists(slavefile):
            edit[0] = False
            return



def patrol(master, slave):
    for file in next(os.walk(master))[2]:
        compute(f"{master}/{file}", f"{slave}/{file}")



def getdiff(master, slave):
    diffm = [x for x in os.listdir(master) if not x.endswith(" Trash")]
    diffs = [x for x in os.listdir(slave) if not x.endswith(" Trash")]
    return sorted(set(diffm).difference(diffs)), sorted(set(diffs).difference(diffm))



if expensive == "loadedbg" or expensive == "expensivebg":
    ferchel()
master = filelist[0]
print(f"""Loading featuring {"folder" if os.path.isdir(master) else "file"} successful: {master}""")



while True:
    slave = parse.unquote(input(f"""Drag'n'drop the reference {"folder and hit Enter" if os.path.isdir(master) else "file and hit Enter (or enter nothing to compute MD5)"}: """).replace("\"", "").replace("file:///", ""))
    if not slave and not os.path.isdir(master):
        with open(master, 'rb') as f:
            masterread = f.read()
        md5hash = hashlib.md5(masterread).hexdigest()
        print("\nmd5:" + md5hash)
        sys.exit()
    elif not os.path.exists(slave):
        choice(bg=True)
    elif os.path.isdir(master) != os.path.isdir(slave):
        choice(bg=True)
        print("\n Dragged file vs folder type mismatch . . . TRY AGAIN!\n")
    else:
        break



# Basic file vs file comparison, else directory comparison
relative = ""
if not os.path.isdir(master):
    compute(master, slave)
    print("\nCongrats! Both have same MD5 hashes.")
else:
    trashdir = f"{master} Trash/"



    # Top directory and instant operation
    datefile_ts = 0
    timestamp = 0
    while True:
        os.system("cls")
        echo(f"{tcolorx}{cls}Now working in top directory . . .")
        diff_del, diff_add = getdiff(master, slave)
        buffer = f"\n\nI'll take these files to {master} Trash\\: "
        if diff_del:
            for x in diff_del:
                buffer += f"\n{master}\\{x}"
        else:
            buffer += f"\nNothing! {master} Trash\ will not be created at this time."
        buffer += f"\n\nI'll copy these new files to {master}\\:"
        if diff_add:
            for x in diff_add:
                buffer += f"\n{slave}\\{x}"
            if not datefile_ts:
                timestamp = os.path.getmtime(master)
                if date := get_datefile():
                    datefile_ts = datetime.strptime(date, "%m-%d-%Y %H.%M.%S").timestamp()
                if datefile_ts:
                    if timestamp > datefile_ts:
                        buffer += f"""

Folder's last modification is {tcoloro}newer{tcolorx} than datefile: these new files may be {tcoloro}deleted previously{tcolorx} by this folder.
Delete from another folder to proceed with remaining new files, to recover and whatnot."""
                    else:
                        buffer += f"""

Folder's last modification is {tcolorg}older{tcolorx} than datefile: these new files are {tcolorg}new{tcolorx} to this folder."""
                else:
                    buffer += f"""

No old date! Datefile is used as "fuse" toward new files, as way to autoconfirm of new files for this folder,
whether should another folder have those deleted too already or not."""
        else:
            buffer += "\nNothing!"
        if diff_del or diff_add:
            echo(buffer, 0, 2)
            el = input(f"""Type "del" to delete instead (no \\.. Trash\\ creation), re(F)resh, (P)roceed: """, ["Del", "F", "P"])
            if not el:
                kill(0)
            elif el == 2:
                continue
            diff_del, diff_add = getdiff(master, slave)
            print("\n Working . . .")
            if diff_del and el == 3 and not os.path.exists(trashdir):
                os.makedirs(trashdir)
            for file in diff_del:
                masterfile = f"{master}/{file}"
                if el == 1 and os.path.exists(masterfile):
                    if os.path.isdir(masterfile):
                        shutil.rmtree(masterfile)
                    else:
                        os.remove(masterfile)
                elif os.path.exists(masterfile):
                    if os.path.exists(trashdir + file):
                        print(f"\nSome files in {master} Trash\\ got same file names. Name conflicting files will be taken to MD5 comparison test (this CLI will be stuck in there until they're same or deleted by you).")
                        compute(trashdir + file, masterfile)
                        if os.path.exists(masterfile):
                            os.remove(masterfile)
                    else:
                        os.rename(masterfile, trashdir + file)
            for file in diff_add:
                if not os.path.isdir(f"{slave}/{file}"):
                    overwrite(f"{slave}/{file}", f"{master}/{file}")
            for file in diff_add:
                if os.path.isdir(f"{slave}/{file}"):
                    shutil.copytree(f"{slave}/{file}", f"{master}/{file}")
        break
    print("Now patrolling files at top directory to catch any differences . . . kill this CLI to cancel.")
    patrol(master, slave)



    # Subdirectories
    while True:
        title(batchfile)
        os.system("cls")
        echo(f"""{tcolorx}{cls}
 Top directories are (now) congruent!
 Top directory files have same MD5 hashes!

Quick look through subdirectories . . .
""")
        perfection = True
        for subfolder in os.listdir(master):
            if subfolder.endswith(" Trash") or not os.path.isdir(f"{master}/{subfolder}"):
                continue
            folderdiff = 0
            filediff = 0
            for root, folders, files in os.walk(f"{slave}/{subfolder}"):
                relative = os.path.relpath(root, slave) + "/"
                for folder in folders:
                    if not os.path.exists(f"{master}/{relative}{folder}"):
                        folderdiff += 1
                for file in files:
                    if not os.path.exists(f"{master}/{relative}{file}"):
                        filediff += 1
            for root, folders, files in os.walk(f"{master}/{subfolder}"):
                relative = os.path.relpath(root, master) + "/"
                for folder in folders:
                    if not os.path.exists(f"{slave}/{relative}{folder}"):
                        folderdiff += 1
                for file in files:
                    if not os.path.exists(f"{slave}/{relative}{file}"):
                        filediff += 1
            if not filediff == 0 or not folderdiff == 0:
                print(f""" \{subfolder}\ ({filediff} files and {folderdiff} folders difference)""")
                perfection = False
        if perfection == True:
            print(" Subdirectories are (now) congruent!")
            break
        else:
            input(f"\nReplace them yourself/Run {batchname} on each. Enter to refresh, kill this CLI to quit: ")



    # Instant operation on subdirectories is forbidden, patrol only.
    print("\nNow patrolling files at subdirectories to catch any differences . . . kill this CLI to finish.")
    for subfolder in next(os.walk(master))[1]:
        if subfolder.endswith(" Trash") or not os.path.isdir(f"{master}/{subfolder}"):
            continue
        for root, folders, files in os.walk(f"{master}/{subfolder}"):
            relative = os.path.relpath(root, master) + "/"
            for folder in folders:
                patrol(f"{master}/{relative}{folder}", f"{slave}/{relative}{folder}")
            for file in files:
                compute(f"{master}/{relative}{file}", f"{slave}/{relative}{file}")
    print("\n Everything is identical!")
title(batchfile)



"""
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
if not "!TXT!"=="" for /f "delims=" %%i in ('findstr /b /i "Python = " "!TXT!"') do set string=%%i&& set string=!string:~9!&& goto check
:check
chcp 437>nul
if not "!string!"=="" (set pythondir=!string!)
set x=Python 3.10
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
python.exe -x "!batchfile!" "!filelist!" "!pythondir!" "!batchdir!"
set filelist=
color %stopcolor%
echo.
echo Restart CLI? Press any key to continue . . .
pause >nul
goto start
"""
