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

    // Automatically detects the save slot - checks all variables and switches to checking only one when detects a change
    // 0 means no saveslot has been chosen
    vars.SaveSlotNumber = 0;
}

update
{
    // Determine save slot if we moved from spawnpoint to room 2 on that saveslot
    if (vars.SaveSlotNumber == 0)
    {
        if (old.gameSave1PortalId == 0 && old.gameSave1LevelId == 0 && old.gameSave1PlaceId == 0 && current.gameSave1LevelId == 0 && current.gameSave1PlaceId == 1)
        {  
            vars.SaveSlotNumber = 1;
        }
        else if (old.gameSave2PortalId == 0 && old.gameSave2LevelId == 0 && old.gameSave2PlaceId == 0 && current.gameSave2LevelId == 0 && current.gameSave2PlaceId == 1)
        {  
            vars.SaveSlotNumber = 2;
        }
        else if (old.gameSave3PortalId == 0 && old.gameSave3LevelId == 0 && old.gameSave3PlaceId == 0 && current.gameSave3LevelId == 0 && current.gameSave3PlaceId == 1)
        {  
            vars.SaveSlotNumber = 3;
        }
    }
    if (vars.SaveSlotNumber == 1)
    {
        vars.oldLevelId = old.gameSave1LevelId;
        vars.oldPlaceId = old.gameSave1PlaceId;
        vars.currentLevelId = current.gameSave1LevelId;
        vars.currentPlaceId = current.gameSave1PlaceId;
        vars.currentPortalId = current.gameSave1PortalId;
    }
    else if (vars.SaveSlotNumber == 2)
    {
        vars.oldLevelId = old.gameSave2LevelId;
        vars.oldPlaceId = old.gameSave2PlaceId;
        vars.currentLevelId = current.gameSave2LevelId;
        vars.currentPlaceId = current.gameSave2PlaceId;
        vars.currentPortalId = current.gameSave2PortalId;
    }
    else if (vars.SaveSlotNumber == 3)
    {
        vars.oldLevelId = old.gameSave3LevelId;
        vars.oldPlaceId = old.gameSave3PlaceId;
        vars.currentLevelId = current.gameSave3LevelId;
        vars.currentPlaceId = current.gameSave3PlaceId;
        vars.currentPortalId = current.gameSave3PortalId;
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
    var isNoLongerOnTitleScreen = DateTime.Now.Subtract(vars.lastDateTimeOnTitleScreen).TotalSeconds > 1;  // Leniency needed when resetting to title screen.
    var inCutscene = current.cursorOff;  // Cursor is off during a cutscene, even when using controller.
    if (isNoLongerOnTitleScreen && inCutscene)
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

    /* This only works for Any% category. */
    // Crypt + Abbey (Devotees) splits
    if (vars.oldLevelId == 0 && vars.currentLevelId == 0)
    {
        /* Crypt splits */
        // Finish the 1st journal entry and exit the room.
        var isFirstJournalSplit = vars.oldPlaceId == 3 && vars.currentPlaceId == 4 && settings["a1s_first_journal"];
        // Crypt -> Abbey (finish the water locks puzzle and exit the room)
        var isCryptExitSplit = vars.oldPlaceId == 5 && vars.currentPlaceId == 6 && settings["a1s_crypt_exit"];

        /* Abbey splits */
        // Finish hide and seek and enter the stealth room.
        var isHideAndSeekSplit = vars.oldPlaceId == 9 && vars.currentPlaceId == 11 && settings["a2s_hide_and_seek"];
        // Pick up the coin item by finishing the bed puzzle.
        var isPickUpCoinSplit = vars.currentPlaceId == 17 && vars.isInventoryForcedOpen && settings["a2s_pick_up_coin"];
        // Enter the church.
        var isEnterChurchSplit = vars.oldPlaceId == 12 && vars.currentPlaceId == 21 && settings["a2s_enter_church"];
        // Pick up the lens item after getting the key from the jar and opening the door.
        var isPickUpLensSplit = vars.currentPlaceId == 23 && vars.isInventoryForcedOpen && settings["a2s_pick_up_lens"];

        return isFirstJournalSplit || isCryptExitSplit || isHideAndSeekSplit || isPickUpCoinSplit || isEnterChurchSplit || isPickUpLensSplit;
    }

    // Abbey -> Fortress
    if (vars.oldLevelId == 0 && vars.currentLevelId == 1 && settings["a2s_abbey_exit"])
    {
        return true;
    }

    // Fortress (Warriors) splits
    if (vars.oldLevelId == 1 && vars.currentLevelId == 1)
    {
        // Exit the room with the spear.
        var isSpearRoomSplit = vars.oldPlaceId == 7 && vars.currentPlaceId == 8 && settings["a3s_spear_room"];
        // Enter the first stealth room.
        var isStealthStartSplit = vars.oldPlaceId == 9 && vars.currentPlaceId == 11 && settings["a3s_stealth_start"];
        // Exit the stealth corridor.
        var isStealthCorridorSplit = vars.oldPlaceId == 0 && vars.currentPlaceId == 12 && settings["a3s_stealth_corridor"];
        // Exit the stealth storage room (has an elevator wtih 2 boxes).
        var isStealthStorageRoomSplit = vars.oldPlaceId == 13 && vars.currentPlaceId == 14 && settings["a3s_stealth_storage_room"];
        // Exit the armory room after disguising as a guard.
        var isArmoryExitSplit = vars.oldPlaceId == 16 && vars.currentPlaceId == 14 && settings["a3s_armory_exit"];

        return isSpearRoomSplit || isStealthStartSplit || isStealthCorridorSplit || isStealthStorageRoomSplit || isArmoryExitSplit;
    }

    // Fortress -> Gardens.
    if (vars.oldLevelId == 1 && vars.currentLevelId == 2 && settings["a3s_fortress_exit"])
    {
        return true;
    }

    // Gardens (Bards) splits    
    if (vars.oldLevelId == 2 && vars.currentLevelId == 2)
    {
        // Exit through the servant's door.
        var isServantDoorSplit = vars.oldPlaceId == 2 && vars.currentPlaceId == 5 && settings["a4s_servant_door"];
        // Enter sewers.
        var isEnterSewersSplit = vars.oldPlaceId == 15 && vars.currentPlaceId == 11 && settings["a4s_enter_sewers"];
        // Exit sewers.
        var isExitSewersSplit = vars.oldPlaceId == 11 && vars.currentPlaceId == 15 && settings["a4s_exit_sewers"];
        // Pick up torch item at windmill.
        var isPickUpWindmillTorchSplit = vars.currentPlaceId == 18 && vars.isInventoryForcedOpen && settings["a4s_pick_up_windmill_torch"];

        return isServantDoorSplit || isEnterSewersSplit || isExitSewersSplit || isPickUpWindmillTorchSplit;
    }

    /* Skipping Gardens -> Tunnels split, since we're considering the maze as part of Gardens */

    // Factory (Alchemists) splits (+ maze)
    if (vars.oldLevelId == 3 && vars.currentLevelId == 3)
    {
        // Exit the maze.
        var isMazeExitSplit = vars.oldPlaceId == 7 && vars.currentPlaceId == 8 && settings["a4s_maze_exit"];
        // Escape the monster.
        var isEscapeMonsterSplit = vars.oldPlaceId == 13 && vars.currentPlaceId == 14 && settings["a5s_escape_monster"];
        // Trigger the canteen timer (i.e. enter the canteen foyer for the 1st time).
        var isTriggerCanteenTimerSplit = vars.oldPlaceId == 31 && vars.currentPlaceId == 32 && !vars.isCanteenTimerTriggered && settings["a5s_trigger_canteen_timer"];
        // Pick up silverware item at canteen.
        var isPickUpSilverwareSplit = vars.currentPlaceId == 33 && vars.isInventoryForcedOpen && settings["a5s_pick_up_silverware"];
        // Pick up silver bar item after melting the silverware.
        var isPickUpSilverBarSplit = vars.currentPlaceId == 22 && vars.isInventoryForcedOpen && settings["a5s_pick_up_silver_bar"];

        // Set vars.isCanteenTimerTriggered so split isn't triggered again when entering the canteen.
        if (isTriggerCanteenTimerSplit)
        {
            vars.isCanteenTimerTriggered = true;
        }

        return isMazeExitSplit || isEscapeMonsterSplit || isTriggerCanteenTimerSplit || isPickUpSilverwareSplit || isPickUpSilverBarSplit;
    }

    // Factory -> Exile.
    if (vars.oldLevelId == 3 && vars.currentLevelId == 4 && settings["a5s_factory_exit"])
    {
        return true;
    }

    // Exile (Anchorites) splits
    if (vars.oldLevelId == 4 && vars.currentLevelId == 4)
    {
        // Enter the Creator's room after entering the 3-glyph code in the keypad.
        var isExileNpcRoomSplit = vars.oldPlaceId == 15 && vars.currentPlaceId == 6 && settings["a6s_exile_npc_room"];
        // Pick up Exile key.
        var isPickUpExileKeySplit = vars.currentPlaceId == 24 && vars.isInventoryForcedOpen && settings["a6s_pick_up_exile_key"];
        // Final split for player starting cutscene in final room in Exile. Not optional.
        var isFinalCutsceneSplit = vars.currentPlaceId == 2 && !current.canPlayerRun && !old.cursorOff && current.cursorOff;

        return isExileNpcRoomSplit || isPickUpExileKeySplit || isFinalCutsceneSplit;
    }    
}
