# Schande

Download and serve files, you define how are they downloaded and sorted!

```
              ______
           .-"______"-.
          / |https://| \
         |' |x HT*ML | '|
    /\   | )|x A>P>I |( |
  _ \/   |/ |________| \|
 \_\/    (_ \   ^^   / _)   .-==/~\
---,---,---|-Download-|---,\'-' {{~}
           \          /     '-==\}/
            '--------'
```

1. Any good OS with Python 3 installed will work.
    - iOS/iPadOS: get iSH Shell app from [AppStore](https://apps.apple.com/us/app/ish-shell/id1436902243)
        - Pirates: Get the latest x86 Miniroot 3.17 from https://alpinelinux.org/releases/ import into iSH Shell by cogwheel icon > Filesystems > Import 
        - All: Then enter `apk add py3-pip` and then `mount -t ios . /mnt` and select your favorite location for Schande.bat.
    - MacOS need one more step after installing Python: open Terminal and enter `open /Applications/Python\ 3.9/Install\ Certificates.command`

2. Save <a href="https://github.com/Rukario/Schande/raw/main/Schande.bat">Schande.bat</a> to your favorite location where you want to download files to, change the file extension back to `.bat` if it's in something else.
    - iOS: Files app > ellipsis icon > View Options > Show All Filename Extensions
    - Windows: File explorer > View > Show > File name extensions
    - Other OS: YMMV

3. Follow one for your system:
    - Windows: Double click on it and read the CLI message.
    - Linux/MacOS (Terminal): `python3 -x /drag/n/drop/Schande.bat`
    - iOS/iPadOS (iSH Shell app): `(cat /dev/location > /dev/null &); python3 -x /mnt/Schande.bat`

4. Schande.bat on first run will create a new file: Schande.cd, open it in your favorite text editor to edit rules, refer to the premade Schande.cd for inspiration.

5.
    - Paranoids: h(E)lp
    - Braves: (I)nput
    - Pirates: open torrent (M)anager
    - Leave it in background for HTML server if enabled

Here's some other uninteresting stuff

  - <a href="https://github.com/Rukario/Schande/raw/main/Uninteresting%20stuff/Ferchel.bat">Ferchel.bat</a> - Filelist snapshot and compare folders for manual "incremental backup"/folder-merging-esque. Supports UTF-8 files file-merging-esque with helps of a certain text editor.
  - <a href="https://github.com/Rukario/Schande/raw/main/Uninteresting%20stuff/APNG%20Maker.html">APNG Maker.html</a> - APNG production (<a href="https://rukario.github.io/Schande/Uninteresting%20stuff/APNG%20Maker.html">demo</a>)
  - <a href="https://github.com/Rukario/Schande/raw/main/Uninteresting%20stuff/Color%20Gallery.html">Color Gallery.html</a> - WIP BD color finder (<a href="https://rukario.github.io/Schande/Uninteresting%20stuff/Color%20Gallery.html">demo</a>)
  - <a href="https://github.com/Rukario/Schande/raw/main/Uninteresting%20stuff/starfield.html">starfield.html</a> - Flying Windows / starfield Windows 95 screensaver replication in JavaScript (<a href="https://rukario.github.io/Schande/Uninteresting%20stuff/starfield.html">demo</a>, right-click in demo for different stars)
  - <a href="https://github.com/Rukario/Schande/raw/main/Uninteresting%20stuff/New%20Text.html">New Text.html</a> - A good UTF-8 text editor for neglected OS but has good browser (<a href="https://rukario.github.io/Schande/Uninteresting%20stuff/New%20Text.html">demo</a> | <a href="https://rukario.github.io/Schande/Uninteresting%20stuff/New%20Text.html?🦦">easter egg</a>), collaborate with New Text and Save Text for iOS Shortcuts app

New Text - https://www.icloud.com/shortcuts/4a4a4580207540e5a4865c4d7c9781ae

- Open directly from Shortcuts screen for a prompt to save the demo HTML to Files app for offline use.

- Create and edit text files as you would with a text editor! There are inline calculator and several text manipulation tools you should try. Bookmark the text editor UI to your Favorite screen for a faster access.

- Choose New Text from share sheet on another page to view its source.

Save Text - https://www.icloud.com/shortcuts/b7023779316f492facc3b594d7f665a4

- Choose from share sheet on the text editor to save your precious document on iCloud/Ask where to save.
