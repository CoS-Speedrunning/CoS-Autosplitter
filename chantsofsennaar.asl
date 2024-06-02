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
}

update
{
    // Determine save slot based on setting, and populate vars with old and current level/place ids.
    if (settings["save_slot_1"] && !settings["save_slot_2"] && !settings["save_slot_3"])
    {
        vars.oldLevelId = old.gameSave1LevelId;
        vars.oldPlaceId = old.gameSave1PlaceId;
        vars.currentLevelId = current.gameSave1LevelId;
        vars.currentPlaceId = current.gameSave1PlaceId;
        vars.currentPortalId = current.gameSave1PortalId;
    }
    else if (!settings["save_slot_1"] && settings["save_slot_2"] && !settings["save_slot_3"])
    {
        vars.oldLevelId = old.gameSave2LevelId;
        vars.oldPlaceId = old.gameSave2PlaceId;
        vars.currentLevelId = current.gameSave2LevelId;
        vars.currentPlaceId = current.gameSave2PlaceId;
        vars.currentPortalId = current.gameSave2PortalId;
    }
    else if (!settings["save_slot_1"] && !settings["save_slot_2"] && settings["save_slot_3"])
    {
        vars.oldLevelId = old.gameSave3LevelId;
        vars.oldPlaceId = old.gameSave3PlaceId;
        vars.currentLevelId = current.gameSave3LevelId;
        vars.currentPlaceId = current.gameSave3PlaceId;
        vars.currentPortalId = current.gameSave3PortalId;
    }
    else
    {
        // If setting config is invalid, don't run autosplitter.
        print("Save slot config is invalid, autosplitter will not run.");
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

    // IMPORTANT!!! either inCutscene or currentPortalId causes the autosplitter not to start
}

onStart
{
    // Reset vars.
    vars.lastDateTimeOnTitleScreen = null;
    vars.isTitleScreenToNewSave = false;
    vars.isInventoryForcedOpenNeeded = false;
    vars.isInventoryForcedOpen = false;
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

    // Crypt splits
    if (vars.oldLevelId == 0 && vars.currentLevelId == 0 && vars.currentPlaceId <= 6 && settings["crypt_splits"])
    {
        // Complete the 1st journal entry and leave the room.
        var isFirstJournalSplit = vars.oldPlaceId == 3 && vars.currentPlaceId == 4 && settings["first_journal_split"];
        // Crypt -> Abbey
        var isCryptExitSplit = vars.oldPlaceId == 5 && vars.currentPlaceId == 6 && settings["crypt_exit_split"];

        return isFirstJournalSplit || isCryptExitSplit;
    }

    // Abbey (Devotees) splits
    if (vars.oldLevelId == 0 && settings["abbey_splits"])
    {
        // Abbey -> Fortress.
        if (vars.currentLevelId == 1 && settings["abbey_exit_split"])
        {
            return true;
        }

        // Exit early if current level is not Abbey to avoid duplicate check.
        if (vars.currentLevelId != 0)
        {
            return false;
        }

        // Finish hide and seek.
        var isHideAndSeekSplit = vars.oldPlaceId == 9 && vars.currentPlaceId == 11 && settings["hide_and_seek_split"];
        // Pick up coin item.
        var isPickUpCoinSplit = vars.currentPlaceId == 17 && vars.isInventoryForcedOpen && settings["pick_up_coin_split"];
        // Enter the church.
        var isEnterChurchSplit = vars.oldPlaceId == 12 && vars.currentPlaceId == 21 && settings["enter_church_split"];
        // Pick up lens item.
        var isPickUpLensSplit = vars.currentPlaceId == 23 && vars.isInventoryForcedOpen && settings["pick_up_lens_split"];

        return isHideAndSeekSplit || isPickUpCoinSplit || isEnterChurchSplit || isPickUpLensSplit;
    }

    // Fortress (Warriors) splits
    if (vars.oldLevelId == 1 && settings["fortress_splits"])
    {
        // Fortress -> Gardens.
        if (vars.currentLevelId == 2 && settings["fortress_exit_split"])
        {
            return true;
        }

        // Exit early if current level is not Fortress to avoid duplicate check.
        if (vars.currentLevelId != 1)
        {
            return false;
        }

        // Pick up spear item.
        var isSpearTerminalRoomSplit = vars.oldPlaceId == 7 && vars.currentPlaceId == 8 && settings["spear_terminal_room_split"];
        // Enter first stealth room.
        var isStealthStartSplit = vars.oldPlaceId == 9 && vars.currentPlaceId == 11 && settings["stealth_start_split"];
        // Exit stealth corridor room.
        var isStealthCorridorSplit = vars.oldPlaceId == 0 && vars.currentPlaceId == 12 && settings["stealth_corridor_split"];
        // Exit stealth storage room (with an elevator w/ 2 boxes).
        var isStealthStorageRoomSplit = vars.oldPlaceId == 13 && vars.currentPlaceId == 14 && settings["stealth_storage_room_split"];
        // Exit armory room, after disguising as a guard.
        var isArmoryExitSplit = vars.oldPlaceId == 16 && vars.currentPlaceId == 14 && settings["armory_exit_split"];

        return isSpearTerminalRoomSplit || isStealthStartSplit || isStealthCorridorSplit || isStealthStorageRoomSplit || isArmoryExitSplit;
    }

    // Gardens (Bards) splits    
    if (vars.oldLevelId == 2 && vars.currentLevelId == 2 && settings["gardens_splits"])
    {
        // Exit through door that servant opens.
        var isServantDoorSplit = vars.oldPlaceId == 2 && vars.currentPlaceId == 5 && settings["servant_door_split"];
        // Enter sewers.
        var isEnterSewersSplit = vars.oldPlaceId == 15 && vars.currentPlaceId == 11 && settings["enter_sewers_split"];
        // Exit sewers.
        var isExitSewersSplit = vars.oldPlaceId == 11 && vars.currentPlaceId == 15 && settings["exit_sewers_split"];
        // Pick up torch item at windmill.
        var isPickUpWindmillTorchSplit = vars.currentPlaceId == 18 && vars.isInventoryForcedOpen && settings["pick_up_windmill_torch_split"];

        return isServantDoorSplit || isEnterSewersSplit || isExitSewersSplit || isPickUpWindmillTorchSplit;
    }

    // Factory (Alchemists) splits (and Maze)
    if (vars.oldLevelId == 3)
    {
        // Exit the maze (considered part of the Gardens level).
        if (vars.oldPlaceId == 7 && vars.currentPlaceId == 8 && settings["gardens_splits"] && settings["maze_exit_split"])
        {
            return true;
        }

        // Factory -> Exile
        if (vars.currentLevelId == 4 && settings["factory_splits"] && settings["factory_exit_split"])
        {
            return true;
        }

        // Exit early if current level is not Factory to avoid duplicate check.
        if (vars.currentLevelId != 3 || !settings["factory_splits"]) // Moved factory splits check here to allow for maze split.
        {
            return false;
        }

        // Tunnels -> Factory
        var isTunnelExitSplit = vars.oldPlaceId == 14 && vars.currentPlaceId == 16 && settings["tunnels_exit_split"];
        // Pick up silverware item at canteen.
        var isPickUpSilverwareSplit = vars.currentPlaceId == 33 && vars.isInventoryForcedOpen && settings["pick_up_silverware_split"];
        // Pick up silver bar item after melting the silverware.
        var isPickUpSilverBarSplit = vars.currentPlaceId == 22 && vars.isInventoryForcedOpen && settings["pick_up_silver_bar"];

        return isTunnelExitSplit || isPickUpSilverwareSplit || isPickUpSilverBarSplit;
    }

    // Exile (Anchorites) splits
    if (vars.oldLevelId == 4 && vars.currentLevelId == 4)
    {   
        // Final split for player starting cutscene in final room in Exile. Not optional
        if (vars.currentPlaceId == 2 && !current.canPlayerRun && !old.cursorOff && current.cursorOff) {
            return true;
        }

        // Exit early if splits not selected
        if (!settings["exile_splits"])
        {
            return false;
        }
        // Enter the Creator's room after entering the 3-glyph code in the keypad.
        var isExileNpcRoomSplit = vars.oldPlaceId == 15 && vars.currentPlaceId == 6 && settings["exile_npc_room_split"];
        // Pick up Exile key.
        var isPickUpExileKeySplit = vars.currentPlaceId == 24 && vars.isInventoryForcedOpen && settings["pick_up_exile_key_split"];

        return isExileNpcRoomSplit || isPickUpExileKeySplit;
    }    
}
