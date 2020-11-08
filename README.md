# neekshell-telegrambot
I'm a newbie to shell scripting and I made this bot for fun, feel free to criticize

This bot needs a web server to set a webhook pointing on neekshell-webhook.php, to execute the script on request.<br />Example with current code: [@neekshellbot](https://t.me/neekshellbot)

Utilities used:
  - GNU sed, and various coreutils
  - cURL
  - fortune-mod (https://github.com/shlomif/fortune-mod)
  - jshon (http://kmkeen.com/jshon/index.html)
  - searx (https://github.com/asciimoo/searx)

# commands

!d[number] (dice)<br />
!fortune (fortune cookie)<br />
!owoifer (on reply)<br />
!jpg (on reply, compress media)<br />
!nfry (on reply, fry video/gif)<br />
!wide (on reply)<br>
!hf (random hentai)<br />
!sed [regexp] (on reply)<br />
!forward [usertag] (in private, on reply)<br />
!tag [[@username] (new tag text)] (in private)<br />
!cpustat (displays % of current cpu usage)<br />
!stats (displays number of groups and users)<br />
!neofetch (displays general system info)<br />
!ping<br />
!top+ (gets a top 10 highscores)<br />
!my+ (gets your score)<br />
respect+ (on reply to give a point with audio)<br />
\+ (on reply to give a point)

administrative commands:

!bin [system command]<br />
!explorer [directory] (browse directories and download files)<br />
!setadmin @username<br />
!deladmin @username<br />
!denylist @username<br />
!allowlist @username (delete ID from denylist)<br />
!nomedia (disable media messages)<br />
!silence (disable messages)<br />
!bang (on reply to mute)<br >
!broadcast [message or reply] (broadcast to all groups)<br >
!exit (leave chat)

inline mode:

d[number] (dice)<br />
fortune (fortune cookie)<br />
[system command] bin (administrative)<br />
tag [[@username] (new tag text)]<br />
search [text to search on searx]<br />
[g/x/r34/real/e621]b [booru pic tag]<br />
[g/x/r34/real/e621]bgif [booru gif tag]<br />
joinchat (sends an invite button to a botchat)

chat mode (in private):

!chat create (creates a chat with your ID)<br />
!chat delete (deletes your chat)<br />
!chat join (lists existing chats to join)<br />
!chat leave (lists existing chats to leave)<br />
!chat users (prints number of active users)<br />
!chat list (prints a complete list with chat ids and active users for each chat)

# enable administrative commands
To use administrative commands you need a text file named `neekshelladmins` inside `neekshellbot` folder with a list of admin IDs, like: [neekshelladmins.example](https://gitlab.com/craftmallus/neekshell-telegrambot/-/blob/master/neekshelladmins.example)

# denylist and allowlist
To deny access to a user you need to be a bot admin and denylist an ID using !denylist @username
