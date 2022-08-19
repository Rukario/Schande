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
Any good OS with Python 3 installed will work. iOS/iPadOS: get iSH Shell app from https://apps.apple.com/us/app/ish-shell/id1436902243 then enter `apk add py3-pip` and then `mount -t ios . /mnt` and select your favorite location for Schande.bat. MacOS need one more step after installing Python: open Terminal and enter `open /Applications/Python\ 3.9/Install\ Certificates.command`

1. Save <a href="https://github.com/Rukario/Schande/raw/main/Schande.bat">Schande.bat</a> to your favorite location where you want to download files to, change the file extension back to .bat if it's in something else.
    - iOS isn't showing file extensions and has no normal means to change it on iOS. It can be renamed back to Schande.bat by executing this command on iSH: `mv /mnt/Schande.bat.txt /mnt/Schande.bat`

2. Follow one for your system:
    - Windows: Double click on it and read the CLI message.
    - Linux/MacOS (Terminal): `python3 -x /drag/n/drop/Schande.bat`
    - iOS/iPadOS (iSH Shell app): `python3 -x /mnt/Schande.bat`

3. Schande.bat on first run will create a new file: Schande.cd, open it in your favorite text editor to edit rules, refer to the premade Schande.cd for inspiration.

4.
    - Paranoids: h(E)lp
    - Braves: (I)nput
    - Pirates: open torrent (M)anager
      - Torrent capabilities via Transmission-daemon for the neglected OS (iOS/iPadOS) and whatnot.
    - Leave it in background for HTML server if enabled

Here's some other uninteresting stuff

  - <a href="https://github.com/Rukario/Schande/raw/main/Uninteresting%20stuff/Fuchsatchi.bat">Fuchsatchi.bat</a> - Download and serve files from Patreon, Fantia, Fanbox, Kemono
  - <a href="https://github.com/Rukario/Schande/raw/main/Uninteresting%20stuff/Ferchel.bat">Ferchel.bat</a> - Filelist snapshot and compare folders for a manual "incremental backup"/folder-merging-esque and file-merging-esque with collaborative help of a certain text editor, to make copies round up between PC and iOS/iPadOS storage (through iTunes saving selected folders to a temporary space) quite a bit more manageable!
  - <a href="https://github.com/Rukario/Schande/raw/main/Uninteresting%20stuff/APNG%20Maker.html">APNG Maker.html</a> - APNG production (<a href="https://rukario.github.io/Schande/Uninteresting%20stuff/APNG%20Maker.html">demo</a>)
  - <a href="https://github.com/Rukario/Schande/raw/main/Uninteresting%20stuff/New%20Text.html">New Text.html</a> - A good UTF-8 text editor for neglected OS but has good browser (<a href="https://rukario.github.io/Schande/Uninteresting%20stuff/New%20Text.html">demo</a>), collaborate with Shortcuts app for a proper experience, starting point here: http://redd.it/westw3
