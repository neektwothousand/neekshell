# neekshell-telegrambot

This bot needs a web server to set a webhook pointing on webhook.php, to execute the script on request.<br />Example with current code: [@neekshellbot](https://t.me/neekshellbot)

Utilities used:
  - GNU sed, and various coreutils<br />
  - cURL<br />
  - jshon (http://kmkeen.com/jshon/index.html)

PowerShell version by adamantinum: https://github.com/adamantinum/PSTelegramBot

# commands
### these commands are available through scripts under custom_commands/ directory

!d[number] (dice)<br />
!fortune (fortune cookie)<br />
!owoifer (on reply)<br />
!jpg (on reply, compress media)<br />
!hf (random hentai)<br />
!sed [regexp] (on reply)<br />
!tag [[@username] (new tag text)] (in private)<br />
!stats (displays number of groups and users)<br />
!neofetch (displays general system info)<br />
!reddit [sub] (gets a random reddit post)<br />
!deemix (downloads a song from deezer)<br />
!insta [instagram_username] (scrapes pics and vids from instagram)<br />
!ping<br />
!me [text]<br />
!gayscale (on reply too)<br />
!top [+|gs] (gets a top 10 highscores)<br />
!my [+|gs] (gets your score)<br />
\+ (on reply to give a point)

administrative commands:

!bin [system command]<br />
!explorer [directory] (browse directories and download files)<br />
!db [chats/get (on reply)]<br />
!setadmin @username<br />
!deladmin @username<br />
!nomedia (disable media messages)<br />
!silence (disable messages)<br />
!broadcast [message or reply] (broadcast to all groups)<br />
!delete (delete messages on reply)<br />
!exit (leave chat)

inline mode:

[any text] (converts as owoifier command)<br>
d[number] (dice)<br />
fortune (fortune cookie)<br />
figlet [text]<br />
jafw [text]<br />
[system command] bin (administrative)<br />
search [text to search on searx]<br />
[g/s/e621]b [booru pic tag]

chat mode (in private):

!chat create (creates a chat with your ID)<br />
!chat delete (deletes your chat)<br />
!chat join (lists existing chats to join)<br />
!chat leave (lists existing chats to leave)<br />
!chat users (prints number of active users)<br />
!chat list (prints a complete list with chat ids and active users for each chat)

# enable administrative commands
To use administrative commands you need a text file named `admins` with a list of admin IDs
