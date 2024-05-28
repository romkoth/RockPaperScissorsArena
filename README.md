# RockPaperScissorsArena

Arena game for AO the computer project

3 steps to start playing:
1. aos> RockPaperScissorsArena = "u_duaUIyjq9Hze3NLN335-4DwxMdHM6mb_GHwoKyrGk" // registering game process id
2. Send({ Target = RockPaperScissorsArena, Action = "Register" })  // register for a game
3. Send({ Target = RockPaperScissorsArena, Action = "Choice", Choice = "paper|rock|scissors", Player = ao.id }) // make your choice and wait for others
