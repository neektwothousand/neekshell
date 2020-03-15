# neekshell-telegrambot
I'm a newbie to shell scripting and I made this bot for fun, feel free to criticize

This bot needs a web server to set a webhook pointing on neekshell-webhook.php, to execute the script on request.<br />Example with current code: [@neekshellbot](https://t.me/neekshellbot)

Utilities used:
  - GNU Wget, sed, and various coreutils
  - jq (https://stedolan.github.io/jq/)
  - googler (https://github.com/jarun/googler)

# commands

!d[number] (dice)<br />
!fortune (fortune cookie)<br />
!owoifer (on reply)<br />
!sed [regexp] (on reply)<br />
!forward [usertag] (in private, on reply)<br />
!tag [[@username] (new tag text)] (in private)<br />
!ping

administrative commands:

!bin [system command]<br />
!setadmin @username<br />
!deladmin @username<br />
!bang (on reply to mute)

inline mode:

d[number] (dice)<br />
[system command] bin (administrative)<br />
tag [[@username] (new tag text)]<br />
search [text to search on google]<br />
gel [gelbooru tag]<br />
xbgif [xbooru gif tag]

# enable administrative commands
To use administrative commands you need a text file named `neekshelladmins` inside `neekshellbot` folder with a list of admin IDs, like: [neekshelladmins.example](https://github.com/neektwothousand/neekshell-telegrambot/blob/master/neekshellbot/neekshelladmins.example)
