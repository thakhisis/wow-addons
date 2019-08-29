FMR 3.0b
16 Nov 2008


**** INTODUCTION ****

FMR is a looting system made my Frujin for Ace of Spades guild on Zenedar-EU server. It is designed to be very easy to use and maintain. The FMR system allows fair distribution of loot but also it stimulates friendship, sharing spirit and teamplay. The system basically collects players rolls and modifies them according their raid activity and loot history. The addon allows guild leaders and guild members to have real-time view of their luck points in a simple and easy to use interface. 



**** HOW IT WORKS ****

For every memeber in the guild there is assigned number called Luck Points (or simply LP). When loot have to be distributed, the ML initiates a FMR roll. Everyone who are eligible (depends on current guild' loot restrictions if any) are rolling just like in usual cases byt typing /roll in chat line. The FMR addon collects the rolls and modifies them by adding LP to the rolls. Then those who rolled are sorted by final score. Final score is calculated like:

Final Score = Real Roll + Luck Points. 

For example if player rolled 56 and if he had 40 LP currently, his final score will be 96! The player with highest final score wins the FMR roll. 

Then the Master Looter gives the item to the winner and marks him as a winner in the FMR addon. The winner will automatically loose 50 luck points and everyone else in the raid will earn 1 luck point. So, in brief, dring the guild raid, every winner is looing 50 LP and everyone else is earning 1 LP. There are features that allows Raid Leader to reward (or even penalise) with additional LP the raid according to its performace. The luck points are kept automatically in the boundaries (0 - 200). That means that noone can have more than 200 LP and noone will have less than 0 LP. 



**** DATABASE ****

The FMR addon is using guild rosters' officer note to keep data for every player. Therefore it must be kept free and clean. After installation and initial set-up, you can see data stored in the officer notes of all members which looks like:

<FMR/160606,22:11:23/89>

The meaning of this is:

FMR - FMR data header
160606,22:11:23  - timestamp (time of last update), i.e. how old is this data (in the example it is 16 June 2006, 22hour 11min 23sec)
89 - current LP for the player

The symbols < > and / are used to separate the data fields

Note, that the ADDON automatically enters this data and handles it. It is important for it to stay in right format, as the addon is using officers notes to synchronize information amongst guild members. Manually editing the data is possible if officers knows what they are exacly doing :) 



**** SYNCHRONIZATION ****

Synchronization is automatic. It is based on timestamps of different players data. For example when Master Looter assigns item to one of the raid members, all LP changes are updated on his comuter immediately. Then the addon finds that his data is newer than that on the server and starts uploading the data into officer notes of affected players. When the new data is uploaded, the addon on other players' machines finds out that the information in officer notes is newer than theirs own and automatically downloads it. Well, this is the simplest explanation. The real one is .. well .. too imba for this file :) Most important is that the synchronization is not instant. It can take some minutes (rarely longer than 4-5) until everyone get's the new data. 



**** REQUIRED GUILD SETUP ****

For the addon to work properly, the addon counts on several requirements to be met:

1) All officer notes are initially empty (you can try setting up the system without clearing officer notes first, normaly this works, but errors are possible).
2) Only Guild Master and Next rank below him (normaly officers) have right to change officer notes.
3) All guild members are allowed to view officer notes



**** INSTALLATION ****

Unzip and them place in the addons folder of your World of Warcraft. Just like with all other addons. :) Type "/fmr options" to show options window. You can adjust minimap button from there and turn off the "extended-spam-like-notifications".



**** GETTING READY TO USE ****

Only Guild Master can "setup" the system for the guild. To do so, follow those steps (you are guild master, don't you?!):

1. Before installation clear officer notes for all players (prefferably). 
2. Install the addon just like any other addon. (if u don't know how to do this - better abandon FMR and look for something else)
3. Start the game
4. Set up the initial Luck Points with wich everyone should start (practice shows that the best initial number is 50 LP). To do so type in chat line "/fmr init 50". if your guild has hundreds of members you can get disconnected by the server one or few times. Try getting in low populated area before doins so (Dun Morogh is okay). This happens very rarely but it is still possible.
5. You are ready ... hic!



**** HOW TO USE ****

Unsing of addon is very easy (that was the main feature we wanted to have with it). The addon works in two modes depending if you are master looter or not. 

1) Features for Everyone

You can left click on small Ace of Spades button on the minimap to open the standings window. It shows how much luck points everyone currently have. Keep in mind that synchronizing can take some minutes, so do not panic if you do not see immediate change if your luck points after looting or so. You can click on column titles (name, luck, days off) to sort out the standings list by different values (by name, by luck points, by class, by days off, etc.). Experiment with this and you will get it in few minutes. Right clicking on Ace button on the minimap will bring up the options window. 

There is a button at bottom of the standings window that toggles the list in the standings between "guild view" and "raid view". 

2) Features for Master Looters

FMR Master Looter can be only Guild Master or Officers. To be eligible to make FMR rolls, they must have the rights to change officer notes from the guild roster options window. In the raid only one can be Master Looter (ML). When you are selected as ML and IF you are Guild Master or officer you will see additional button next to "Show raid" that is has text "Loot". By clicking on this button you can initiate FRM roll. For more information on how to make FRM rolls see below. Also ML is eligible for using slash command "/fmr raid" which opens raid rewarding window. From this window you can reward the entire raid with some LP or even penalize it depending on its performance. It is tool to use, depending on whatever rules your guilds have.  



**** LOOTING PROCEDURE ****

Looting procedure is very easy to follow:

1) You are assigned as Master Looter in the raid (you must be guild master or officer AND have the rights to change officer notes)
2) Raid kills boss (let's say Lucifron)
3) Open FMR addon (by clicking on Ace button on minimap)
4) Opens boss' corpse and now you have loot window opened
5) Shift+click on an item in ML window (this will paste the link to the item in the raid chat for example)
6) Say who can roll on this item (if you have any restrictions at all)
7) Click on "Loot" button in FMR addon. As a result two things will happen. A small window called "Current Roll" will open next to FMR standings and a chat message will automatically be sent to raid chat tellin players to START ROLLING.
8) Wait for players to roll. Every roll is shown in the "Current Roll" window of FMR. Left column is final score (see above) and right column is real roll.
9) When there are no more players who wants to roll click on "End" button in "Current Roll" window.
10) Roll window will close automatically and two things will happen: FMR will send the roll outcome list in the raid chat and another small window will open for the winner. This small window contains only one button "Win Item".
11) Click on 'Win Item" button in the small "players' window". This will cause him to loose 50 LP and the rest of the raid to earn 1 LP.
12) Give the item to the winner. DONE! ... repeat steps 5)-11) for next items if needed.


This is the basic loot procedure and it is very easy to follow. Here are some addional things you must know:

a) All rolls before clicking on "Loot" button and all rolls after clicking on "End" button are ignored.
b) Only first roll is counted, any sunsequent rolls are ignored
c) If there is a tie (i.e. on top of the rolls are two or more players with same final score) the addon allows you to "Solve Tie" by clikcing on the button in Roll window. If you do so, the addon will ask all who ended up with same score on top to roll again.
d) You can manually force winners for the roll by clicking on their name in the roll window. The name will turn green and the addon will report that winner has been "forced". To remove forced winner, click on his name again. Imagine that Gurgore Ripper dagger drops and all rogues are rolling. But imagine that by mistake on of the priests rolls too and he get's on top of the FMR roll because he has a lot of LP. Then you simply click on the name of the rogue with highest score to "force" him to be the winner, ignoring that priests' accidental roll. Very useful .. hic!
e) Remeber! Winning the roll doesn't do the LP loss and earning! It is clicking on "Win Item" button in players' window that does! You can invoke the player's window manually without a roll by clicking on player name in the standings window. For the "Win Button" to be enable, you must be Master Looter, eligible for FMR rolls (guild master or officer with according rights) and the player selected must be in your raid. 
f) Everytime you click on "Win Item" button, the raid will receive notifications in raid chat
g) Cheating the system is not possible, cheating with rolls is not possible as well!



**** KNOWN ISSUES ****

None so far, but I bet there are some :) 


**** HISTORY ****
3.0b-classic

Version information and interface API version edited by thakhisis on Golemagg to match WoW classic.

3.0b

The stupid thing did not work since quite a while ;) So, fixed ... and works with 3.0.3 patch.

2.01

Fixed few bugs (thanks Tussak) and changed shaman color to the proper one. 

2.00

FMR is now compatible with the latest 2.0 patch. I.e. its Burning Crusade ready :) 

0.98

Now FMR roll can be initiated directly from standart master loot menu. Few minor bugs were fixed. After granting item to a player (with "Win item" button) the addon reports real LP spent instead of just 50. If you have ClassLoot by Ony addon installed the FMR addon will benefit and automatically anounce best class(es) to roll for a given item. overall - not a big changes. :) 

0.97b 

Now one more rank below guild master can use the addon.

0.97a 

First public version. No known issues. Let's test this baby ...


**** CONTACT ****

www.wowaces.com

**** THANKS TO ****

I want to thanks to my friends in Ace of Spades for helping me to make this system and the addon. I also want to thank you guys for being such a nice people to play with! 

*******************

Truly Yoursh ... hic!, 
Frujin

