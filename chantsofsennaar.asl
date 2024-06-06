state("Chants Of Sennaar", "v.1.0.0.9")
{
}

startup
{
    // Load the asl-help script and settings
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Chants of Sennaar";
    vars.Helper.Settings.CreateFromXml("Components/chantsofsennaar.Settings.xml");
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        vars.Helper["cursorOff"] = mono.Make<bool>("GameController", "staticInstance", "inputsController", "cursorOff");

        vars.Helper["titleScreenPtr"] = mono.Make<ulong>("GameController", "staticInstance", "placeController", "titleScreen");
        vars.Helper["currentPlacePtr"] = mono.Make<ulong>("GameController", "staticInstance", "placeController", "currentPlace");
        vars.Helper["currentGameSaveId"] = mono.Make<int>("GameController", "staticInstance", "placeController", "currentGameSaveId");

        vars.Helper["gameSave1LevelId"] = mono.Make<int>("GameController", "staticInstance", "placeController", "gameSaves", 0x20, "currentPlaceId", "level");
        vars.Helper["gameSave1PlaceId"] = mono.Make<int>("GameController", "staticInstance", "placeController", "gameSaves", 0x20, "currentPlaceId", "id");
        vars.Helper["gameSave1PortalId"] = mono.Make<int>("GameController", "staticInstance", "placeController", "gameSaves", 0x20, "currentPortalId");

        vars.Helper["gameSave2LevelId"] = mono.Make<int>("GameController", "staticInstance", "placeController", "gameSaves", 0x28, "currentPlaceId", "level");
        vars.Helper["gameSave2PlaceId"] = mono.Make<int>("GameController", "staticInstance", "placeController", "gameSaves", 0x28, "currentPlaceId", "id");
        vars.Helper["gameSave2PortalId"] = mono.Make<int>("GameController", "staticInstance", "placeController", "gameSaves", 0x28, "currentPortalId");

        vars.Helper["gameSave3LevelId"] = mono.Make<int>("GameController", "staticInstance", "placeController", "gameSaves", 0x30, "currentPlaceId", "level");
        vars.Helper["gameSave3PlaceId"] = mono.Make<int>("GameController", "staticInstance", "placeController", "gameSaves", 0x30, "currentPlaceId", "id");
        vars.Helper["gameSave3PortalId"] = mono.Make<int>("GameController", "staticInstance", "placeController", "gameSaves", 0x30, "currentPortalId");

        // lastMovementDirection is a nested Vector3, but we only need the X coordinate to see if player has moved after intro cutscene.
        vars.Helper["playerLastMovementDirectionX"] = mono.Make<float>("GameController", "staticInstance", "playerController", "playerMove", "lastMovementDirection");
        vars.Helper["canPlayerRun"] = mono.Make<bool>("GameController", "staticInstance", "playerController", "playerMove", "canRun");

        vars.Helper["inventoryState"] = mono.Make<int>("GameController", "staticInstance", "inventory", "state");
        vars.Helper["isInventoryNeedOpen"] = mono.Make<bool>("GameController", "staticInstance", "inventory", "needOpen");
        // Gets the number of lines solved in the linking terminal.
        vars.Helper["terminalLinkUIProgress"] = mono.Make<int>("GameController", "staticInstance", "uiController", "terminalUI", "terminalLinkUI", "overed");

        return true;
    });

    // Gets the last DateTime that player was on the title screen.
    vars.lastDateTimeOnTitleScreen = null;

    // Gets whether the player went from the title screen to the first cutscene.
    vars.isTitleScreenToNewSave = false;

    // Gets whether the inventory *needs* to be forced open.
    vars.isInventoryForcedOpenNeeded = false;

    // Gets whether the inventory is *actually* forced open.
    // The split block should check this variable to see if an item is picked up.
    vars.isInventoryForcedOpen = false;

    /* Variables for old place */
    vars.oldLevelId = -1;
    vars.oldPlaceId = -1;

    /* Variables for current place */
    vars.currentLevelId = -1;
    vars.currentPlaceId = -1;
    vars.currentPortalId = -1;

    // Function checks if we should split, based on desired old and current place ids, and provided setting names.
    // We use vars.splitDict to ensure we don't split again.
    vars.splitDict = new Dictionary<string, bool>();
    vars.checkSplit = (Func<int?, int?, string, string, bool>)((oldPlaceId, currentPlaceId, settingName1, settingName2) =>
    {
        var key1 = string.IsNullOrEmpty(settingName1) ? string.Empty : settingName1;
        var key2 = string.IsNullOrEmpty(settingName2) ? string.Empty : settingName2;
        var key = key1 + "||" + key2;
        if(!vars.splitDict.ContainsKey(key))
        {
            vars.splitDict[key] = false;
        }

        var checkOldPlaceId = oldPlaceId == null ? true : vars.oldPlaceId == oldPlaceId;
        var checkCurrentPlaceId = currentPlaceId == null ? true : vars.currentPlaceId == currentPlaceId;
        var checkPlaceIds = checkOldPlaceId && checkCurrentPlaceId;

        var checkSetting1 = string.IsNullOrEmpty(settingName1) ? false : settings[settingName1];
        var checkSetting2 = string.IsNullOrEmpty(settingName2) ? false : settings[settingName2];
        var checkSettings = checkSetting1 || checkSetting2;

        var shouldSplit = checkPlaceIds && checkSettings && !vars.splitDict[key];
        if (shouldSplit)
        {
            vars.splitDict[key] = true;
        }

        return shouldSplit;
    });
}

update
{
    // Determine save slot based on setting, and populate vars with old and current level/place ids.
    if (current.currentGameSaveId == 0)
    {
        vars.oldLevelId = old.gameSave1LevelId;
        vars.oldPlaceId = old.gameSave1PlaceId;
        vars.currentLevelId = current.gameSave1LevelId;
        vars.currentPlaceId = current.gameSave1PlaceId;
        vars.currentPortalId = current.gameSave1PortalId;
    }
    else if (current.currentGameSaveId == 1)
    {
        vars.oldLevelId = old.gameSave2LevelId;
        vars.oldPlaceId = old.gameSave2PlaceId;
        vars.currentLevelId = current.gameSave2LevelId;
        vars.currentPlaceId = current.gameSave2PlaceId;
        vars.currentPortalId = current.gameSave2PortalId;
    }
    else if (current.currentGameSaveId == 2)
    {
        vars.oldLevelId = old.gameSave3LevelId;
        vars.oldPlaceId = old.gameSave3PlaceId;
        vars.currentLevelId = current.gameSave3LevelId;
        vars.currentPlaceId = current.gameSave3PlaceId;
        vars.currentPortalId = current.gameSave3PortalId;
    }
    else
    {
        // No save slot has been selected yet.
        // print("No save slot selected yet, exiting early.");
        return false;
    }

    /* The next section checks if inventory needs to be forced open, so we can split when the inventory is actually open. */
    var isInventoryStateOpen = current.inventoryState == 5;

    // Check if inventory was forced open.
    if (vars.isInventoryForcedOpen)
    {
        // Value should only be true for one tick so we split once.
        vars.isInventoryForcedOpen = false;
    }
    // Check if inventory needs to be forced open and is finally open.
    else if (vars.isInventoryForcedOpenNeeded && isInventoryStateOpen)
    {
        vars.isInventoryForcedOpen = true;
        vars.isInventoryForcedOpenNeeded = false;

        return;
    }
    // Check if inventory needs to be forced open.
    else if (!old.isInventoryNeedOpen && current.isInventoryNeedOpen)
    {
        vars.isInventoryForcedOpenNeeded = true;
    }
}

reset
{
    // Check if player is on title screen.
    return current.currentPlacePtr == current.titleScreenPtr;
}

onReset
{
    // Reset vars.
    vars.lastDateTimeOnTitleScreen = null;
    vars.isTitleScreenToNewSave = false;
    vars.isInventoryForcedOpenNeeded = false;
    vars.isInventoryForcedOpen = false;
    vars.isCanteenTimerTriggered = false;

    vars.splitDict = new Dictionary<string, bool>();
}

start
{
    // Check if player is on title screen.
    if (current.currentPlacePtr == current.titleScreenPtr)
    {
        // Store current time and exit early.
        vars.lastDateTimeOnTitleScreen = DateTime.Now;
        vars.isTitleScreenToNewSave = false;
        return false;
    }

    // Check if script started while not on the title screen.
    if (vars.lastDateTimeOnTitleScreen == null)
    {
        return false;
    }

    // Check if player moved from title screen to first cutscene.
    if (vars.isTitleScreenToNewSave)
    {
        /** 
         * Start timer when player's last movement direction changed.
         * Checking `isMoving` or `canRun` doesn't work if player uses controller and keeps moving stick after hitting "New Game".
         * Checking `run` doesn't work if player uses mouse and clicks close to character so they walk. */
        return current.playerLastMovementDirectionX != 0;
    }

    // Otherwise, check if player moved from title screen to first room's intro cutscene.
    var isFreshFirstRoom = vars.currentLevelId == 0 && vars.currentPlaceId == 0 /*&& vars.currentPortalId == 0*/;  // Portal id is 0 from a new save, and 1 otherwise (e.g. go into next room and back, then save).
    var isNoLongerOnTitleScreen = DateTime.Now.Subtract(vars.lastDateTimeOnTitleScreen).TotalSeconds > 1;  // Leniency needed when resetting to title screen.
    var inCutscene = current.cursorOff;  // Cursor is off during a cutscene, even when using controller.
    if (isFreshFirstRoom && isNoLongerOnTitleScreen && inCutscene)
    {
        vars.isTitleScreenToNewSave = true;
    }
}

onStart
{
    // Reset vars.
    vars.lastDateTimeOnTitleScreen = null;
    vars.isTitleScreenToNewSave = false;
    vars.isInventoryForcedOpenNeeded = false;
    vars.isInventoryForcedOpen = false;
    vars.isCanteenTimerTriggered = false;

    vars.splitDict = new Dictionary<string, bool>();
}

split
{
    /* ---- Testing logic below ---- 
    // if (vars.currentPlaceId != vars.oldPlaceId)
    // {
    //     print("level + place ids: " + vars.oldLevelId + "," + vars.oldPlaceId + " -> " + vars.currentLevelId + "," + vars.currentPlaceId);
    //     // return true;
    // }
       ---- Testing logic above ---- */

    // Crypt + Abbey (Devotees) splits
    if (vars.oldLevelId == 0 && vars.currentLevelId == 0)
    {
        /* Crypt splits */
        // Finish the 1st journal entry and exit the room.
        var firstJournal = vars.checkSplit(3, 4, "a1s_first_journal", "t1s_first_journal");
        // Crypt -> Abbey (finish the water locks puzzle and exit the room)
        var cryptExit = vars.checkSplit(5, 6, "a1s_crypt_exit", "t1s_crypt_exit");

        /* Abbey splits */
        // Finish hide and seek and enter the stealth room.
        var hideAndSeek = vars.checkSplit(9, 11, "a2s_hide_and_seek", "t2s_hide_and_seek");
        // Pick up the coin item by finishing the bed puzzle.
        var pickUpCoin = vars.isInventoryForcedOpen && vars.checkSplit(17, 17, "a2s_pick_up_coin", "t2s_pick_up_coin");
        // Enter the church.
        var enterChurch = vars.checkSplit(12, 21, "a2s_enter_church", "t2s_enter_church");
        // Pick up the lens item after getting the key from the jar and opening the door.
        var pickUpLens = vars.isInventoryForcedOpen && vars.checkSplit(23, 23, "a2s_pick_up_lens", "t2s_pick_up_lens");

        // True Ending - Devotee-Alchemist link 
        var devoteeAlchemistLink = old.terminalLinkUIProgress < 5 && current.terminalLinkUIProgress == 5 && vars.checkSplit(16, 16, "t7s_devo_alch", null);

        return firstJournal || cryptExit || hideAndSeek || pickUpCoin || enterChurch || pickUpLens || devoteeAlchemistLink;
    }

    // Abbey -> Fortress
    if (vars.oldLevelId == 0 && vars.currentLevelId == 1 && vars.checkSplit(null, null, "a2s_abbey_exit", "t2s_abbey_exit"))
    {
        return true;
    }

    // Fortress (Warriors) splits
    if (vars.oldLevelId == 1 && vars.currentLevelId == 1)
    {
        // Exit the room with the spear.
        var spearRoom = vars.checkSplit(7, 8, "a3s_spear_room", "t3s_spear_room");
        // Enter the first stealth room.
        var stealthStart = vars.checkSplit(9, 11, "a3s_stealth_start", "t3s_stealth_start");
        // Exit the stealth corridor.
        var stealthCorridor = vars.checkSplit(0, 12, "a3s_stealth_corridor", "t3s_stealth_corridor");
        // Exit the stealth storage room (has an elevator wtih 2 boxes).
        var stealthStorageRoom = vars.checkSplit(13, 14, "a3s_stealth_storage_room", "t3s_stealth_storage_room");
        // Exit the armory room after disguising as a guard.
        var armoryExit = vars.checkSplit(16, 14, "a3s_armory_exit", "t3s_armory_exit");

        // True Ending - Warrior-Alchemist link
        var warriorAlchemistLink = old.terminalLinkUIProgress < 5 && current.terminalLinkUIProgress == 5 && vars.checkSplit(21, 21, "t7s_warr_alch", null);

        return spearRoom || stealthStart || stealthCorridor || stealthStorageRoom || armoryExit || warriorAlchemistLink;
    }

    // Fortress -> Gardens.
    if (vars.oldLevelId == 1 && vars.currentLevelId == 2 && vars.checkSplit(null, null,"a3s_fortress_exit", "t3s_fortress_exit"))
    {
        return true;
    }

    // Gardens (Bards) splits    
    if (vars.oldLevelId == 2 && vars.currentLevelId == 2)
    {
        // Exit through the servant's door.
        var servantDoor = vars.checkSplit(2, 5, "a4s_servant_door", "t4s_servant_door");
        // Enter sewers.
        var enterSewers = vars.checkSplit(15, 11, "a4s_enter_sewers", null);
        // Get theatre ticket.
        var theatreTicket = vars.isInventoryForcedOpen && vars.checkSplit(17, 17, "t4s_theatre_ticket", null);
        // Watch the show.
        var theatreWatched = vars.checkSplit(23, 24, "t4s_theatre_watched", null);
        // Exit sewers.
        var exitSewers = vars.checkSplit(11, 15, "a4s_exit_sewers", "t4s_exit_sewers");
        // Pick up torch item at windmill.
        var pickUpTorch = vars.isInventoryForcedOpen && vars.checkSplit(18, 18, "a4s_pick_up_windmill_torch", "t4s_pick_up_windmill_torch");

        // True Ending - Devotee-Bard link
        var devoteeBardLink = old.terminalLinkUIProgress < 5 && current.terminalLinkUIProgress == 5 && vars.checkSplit(25, 25, "t7s_devo_bard", null);

        return servantDoor || enterSewers || theatreTicket || theatreWatched || exitSewers || pickUpTorch || devoteeBardLink;
    }

    /* Skipping Gardens -> Tunnels split, since we're considering the maze as part of Gardens */

    // Factory (Alchemists) splits (+ maze)
    if (vars.oldLevelId == 3 && vars.currentLevelId == 3)
    {
        // Exit the maze.
        var isMazeExitSplit = vars.oldPlaceId == 7 && vars.currentPlaceId == 8 && (settings["a4s_maze_exit"] || settings["t4s_maze_exit"]);
        // Escape the monster.
        var isEscapeMonsterSplit = vars.oldPlaceId == 13 && vars.currentPlaceId == 14 && (settings["a5s_escape_monster"] || settings["t5s_escape_monster"]);
        // Trigger the canteen timer (i.e. enter the canteen foyer for the 1st time).
        var isTriggerCanteenTimerSplit = vars.oldPlaceId == 31 && vars.currentPlaceId == 32 && !vars.isCanteenTimerTriggered && (settings["a5s_trigger_canteen_timer"] || settings["t5s_trigger_canteen_timer"]);
        // Pick up silverware item at canteen.
        var isPickUpSilverwareSplit = vars.currentPlaceId == 33 && vars.isInventoryForcedOpen && (settings["a5s_pick_up_silverware"] || settings["t5s_pick_up_silverware"]);
        // Pick up silver bar item after melting the silverware.
        var isPickUpSilverBarSplit = vars.currentPlaceId == 22 && vars.isInventoryForcedOpen && (settings["a5s_pick_up_silver_bar"] || settings["t5s_pick_up_silver_bar"]);

        // True Ending - Bards - Alchemists split
        var isBardAlchSplit = vars.currentPlaceId == 19 && old.terminalLinkUIProgress < 5 && current.terminalLinkUIProgress == 5 && settings["t7s_bard_alch"];

        // Set vars.isCanteenTimerTriggered so split isn't triggered again when entering the canteen.
        if (isTriggerCanteenTimerSplit)
        {
            vars.isCanteenTimerTriggered = true;
        }

        return isMazeExitSplit || isEscapeMonsterSplit || isTriggerCanteenTimerSplit || isPickUpSilverwareSplit || isPickUpSilverBarSplit || isBardAlchSplit;
    }

    // Factory -> Exile.
    if (vars.oldLevelId == 3 && vars.currentLevelId == 4 && (settings["a5s_factory_exit"] || settings["t5s_factory_exit"]))
    {
        return true;
    }

    // Exile (Anchorites) splits
    if (vars.oldLevelId == 4 && vars.currentLevelId == 4)
    {
        /* Exile splits */
        // Enter the Creator's room after entering the 3-glyph code in the keypad.
        var isExileNpcRoomSplit = vars.oldPlaceId == 15 && vars.currentPlaceId == 6 && (settings["a6s_exile_npc_room"] || settings["t6s_exile_npc_room"]);
        // Pick up Exile key.
        var isPickUpExileKeySplit = vars.currentPlaceId == 24 && vars.isInventoryForcedOpen && (settings["a6s_pick_up_exile_key"] || settings["t6s_pick_up_exile_key"]);
        // Final split (not optional) for Any% category. Fake tower split for True Ending category
        var isSadTowerSplit = vars.currentPlaceId == 2 && !current.canPlayerRun && !old.cursorOff && current.cursorOff && (settings["any_category"] || settings["t7s_fake_tower"]);
        // Final split (not optional) for True Ending category
        var isHappyTowerSplit = vars.currentPlaceId == 3 && !current.canPlayerRun && !old.cursorOff && current.cursorOff && settings["true_ending_category"];

        /* Laboratories True Ending splits */
        var isAbbeyLabSplit = vars.oldPlaceId == 9 && vars.currentPlaceId == 16 && settings["t7s_abbey_lab"];
        var isFortressLabSplit = vars.oldPlaceId == 9 && vars.currentPlaceId == 17 && settings["t7s_fortress_lab"];
        var isGardensLabSplit = vars.oldPlaceId == 9 && vars.currentPlaceId == 18 && settings["t7s_gardens_lab"];
        var isFactoryLabSplit = vars.oldPlaceId == 9 && vars.currentPlaceId == 19 && settings["t7s_factory_lab"];

        return isExileNpcRoomSplit || isPickUpExileKeySplit || isSadTowerSplit || isHappyTowerSplit || isAbbeyLabSplit || isFortressLabSplit || isGardensLabSplit || isFactoryLabSplit;
    }

    // Simulation splits
    if (vars.oldLevelId == 5 && vars.currentLevelId == 5)
    {
        var isTerminal1Split = vars.oldPlaceId == 4 && vars.currentPlaceId == 7 && settings["t8s_terminal_1"];
        var isTerminal2Split = vars.oldPlaceId == 11 && vars.currentPlaceId == 12 && settings["t8s_terminal_2"];
        var isTerminal3Split = vars.oldPlaceId == 13 && vars.currentPlaceId == 16 && settings["t8s_terminal_3"];

        return isTerminal1Split || isTerminal2Split || isTerminal3Split;
    }

    // Simuation end
    if (vars.oldLevelId == 5 && vars.currentLevelId == 4 && settings["t8s_exile_shutdown"])
    {
        return true;
    }
}
