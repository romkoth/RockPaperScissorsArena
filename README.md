# RockPaperScissorsArena

Arena game for AO the computer project

3 steps to start playing:

1. aos> RockPaperScissorsArena = "u_duaUIyjq9Hze3NLN335-4DwxMdHM6mb_GHwoKyrGk" // registering game process id
2. Send({ Target = RockPaperScissorsArena, Action = "Register" })  // register for a game
3. Send({ Target = RockPaperScissorsArena, Action = "Choice", Choice = "paper|rock|scissors", Player = ao.id }) // make your choice and wait for others

Note:
If you are hosting this game in your won process you have to "load" it and schedule cron job.
1. aos> .load /path/to/file
2. ao.id --cron 1-minute   (this command will update game state very minute)
