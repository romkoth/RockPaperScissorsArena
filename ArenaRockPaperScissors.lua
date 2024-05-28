-- Set the Game ID (ensure this is the ID of your game process)
RockPaperScissorsArena = "u_duaUIyjq9Hze3NLN335-4DwxMdHM6mb_GHwoKyrGk"

-- Initialize game data structures
users = {}
messages = {}
waiting_queue = {}
waiting_start_time = nil
waiting_duration = 60  -- 1 minute in seconds
Listeners = {}
GameMode = "Not-Started"
StateChangeTime = nil
Now = nil

-- Function to register users
function register_user(Msg)
    local username = Msg.From
    if users[username] == nil then
        users[username] = {tokens = 0}
        announce("New Player Registered", username .. " has joined the game.")
    else
        announce("Player Already Registered", username .. " is already in the game.")
    end

    -- Add to listeners if not already in the list
    local alreadyListening = false
    for _, listener in ipairs(Listeners) do
        if listener == username then
            alreadyListening = true
            break
        end
    end
    if not alreadyListening then
        table.insert(Listeners, username)
    end

    -- Provide instructions to the user
    local instructions = "Hello! To play, choose one of the following: rock, paper, or scissors.\nSend your choice using: Send({ Target = '" .. RockPaperScissorsArena .. "', Action = 'Choice', Choice = 'rock|paper|scissors', Player = '" .. username .. "' })"
    ao.send({
        Target = username,
        Action = "Message",
        Content = instructions
    })
end

-- Function to handle user choices
function handle_choice(Msg)
    local username = Msg.Player
    local choice = Msg.Choice
    if users[username] then
        messages[username] = choice
        table.insert(waiting_queue, username)
        announce("Player Choice", username .. " has chosen " .. choice)
        -- Start the waiting timer if not already started
        if waiting_start_time == nil then
            waiting_start_time = os.time()
        end
    else
        announce("Unregistered Player Choice", username .. " is not registered.")
    end
end


-- Starts the waiting period for players to submit their choices.
function startWaitingPeriod()
    GameMode = "Waiting"
    StateChangeTime = Now + waiting_duration
    announce("Started-Waiting-Period", "The game is about to begin! Submit your choice: rock, paper, or scissors.")
    print('Starting Waiting Period')
end

-- Processes the game if there are enough choices.
function startGamePeriod()
    if #waiting_queue < 1 then
        announce("Not-Enough-Choices", "Not enough choices submitted! Restarting...")
        startWaitingPeriod()
        return
    end

    GameMode = "Playing"
    StateChangeTime = Now + waiting_duration  -- Assuming game time is the same as waiting duration for simplicity
    announce("Started-Game", "The game has started. Processing choices...")
    process_matches()
end

-- Processes the matches
function process_matches()
    -- Count choices
    local counts = {rock = 0, paper = 0, scissors = 0}
    for _, player in ipairs(waiting_queue) do
        local choice = messages[player]
        counts[choice] = counts[choice] + 1
    end

    -- Determine the winning choice
    local winner
    if (counts.rock > 0 and counts.scissors > 0 and counts.paper == 0) then
        winner = "rock"
    elseif (counts.paper > 0 and counts.rock > 0 and counts.scissors == 0) then
        winner = "paper"
    elseif (counts.scissors > 0 and counts.paper > 0 and counts.rock == 0) then
        winner = "scissors"
    else
        winner = "draw"
    end

    -- Reward winners and notify players
    for _, player in ipairs(waiting_queue) do
        local choice = messages[player]
        if winner == "draw" then
            announce("Match Result", player .. ": It's a draw! No tokens awarded.")
        elseif choice == winner then
            users[player].tokens = users[player].tokens + 1
            announce("Match Result", player .. ": You win! You now have " .. users[player].tokens .. " tokens.")
        else
            announce("Match Result", player .. ": You lose! The winning choice was " .. winner .. ".")
        end
    end

    -- Clear messages and waiting queue for the next round
    messages = {}
    waiting_queue = {}
    waiting_start_time = nil
    startWaitingPeriod()
end

-- Handles the periodic checks and game state transitions.
function gameTick()
    print("gameTick triggered")
    if GameMode == "Not-Started" then
        startWaitingPeriod()
    elseif GameMode == "Waiting" then
        print("GameMode = Waiting Now: ".. Now .. " StateChangeTime: " .. StateChangeTime .." check")
        if Now >= StateChangeTime then
            startGamePeriod()
        end
    elseif GameMode == "Playing" then
        print("GameMode = Playing Now: ".. Now .. " StateChangeTime: " .. StateChangeTime .." check")
        if Now >= StateChangeTime then
            process_matches()
        end
    end
end

-- Handler for periodic checks and game state transitions
Handlers.add(
  "CronTick", 
  Handlers.utils.hasMatchingTag("Action", "Cron"), -- handler pattern to identify cron message
  function (Msg) -- handler task to execute on cron message
    print("CronTick Handler received:", Msg)
    Now = Msg.Timestamp  -- Update the current time with the timestamp from the message
    gameTick()
  end
)

-- Handler for players registration
Handlers.add("Register", Handlers.utils.hasMatchingTag("Action", "Register"), function(Msg)
    print("Register Handler received:", Msg)
    register_user(Msg)
end)

-- Handler for players choices
Handlers.add("Choice", Handlers.utils.hasMatchingTag("Action", "Choice"), function(Msg)
    print("Choice Handler received:", Msg)
    handle_choice(Msg)
end)

-- Sends a state change announcement to all registered listeners.
function announce(event, description)
    for ix, address in pairs(Listeners) do
        ao.send({
            Target = address,
            Action = "Announcement",
            Event = event,
            Data = description
        })
    end
    return print("Announcement: " .. event .. " " .. description)
end


