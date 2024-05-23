state("Chants Of Sennaar", "v.1.0.0.9")
{
}

startup
{
    settings.Add("game_save_slot", true, "[Required] Game save slot");
    settings.SetToolTip("game_save_slot", "[Required] The save slot that will be used for speedruns. Your level/place ids are determined from the save data.");

    // Settings for game save slots.
    settings.CurrentDefaultParent = "game_save_slot";
    settings.Add("save_slot_1", false, "Save slot 1");
    settings.Add("save_slot_2", false, "Save slot 2");
    settings.Add("save_slot_3", true, "Save slot 3");

    // Settings for Crypt level splits.
    settings.CurrentDefaultParent = null;
    settings.Add("crypt_splits", true, "Crypt splits");

    settings.CurrentDefaultParent = "crypt_splits";
    settings.Add("first_journal_split", true, "First journal");

    // Settings for Abbey (Devotees) level splits 
    settings.CurrentDefaultParent = null;
    settings.Add("abbey_splits", true, "Abbey (Devotees) splits");

    settings.CurrentDefaultParent = "abbey_splits";
    settings.Add("hide_and_seek_split", true, "Finish hide and seek");
    settings.Add("pick_up_coin_split", true, "Pick up coin item");
    settings.Add("pick_up_lens_split", true, "Pick up lens item");

    // Settings for Fortress (Warriors) level splits
    settings.CurrentDefaultParent = null;
    settings.Add("fortress_splits", true, "Fortress (Warriors) splits");

    settings.CurrentDefaultParent = "fortress_splits";
    settings.Add("stealth_start_split", true, "Start stealth section");
    settings.Add("stealth_corridor_split", true, "Exit stealth corridor");
    settings.Add("stealth_box_elevator_split", true, "Exit stealth reserve room");
    settings.Add("dress_up_split", true, "Exit armory room");

    // Settings for Gardens (Bards) level splits
    settings.CurrentDefaultParent = null;
    settings.Add("gardens_splits", true, "Gardens (Bards) splits");

    settings.CurrentDefaultParent = "gardens_splits";
    settings.Add("servant_door_split", true, "Exit servant door");
    settings.Add("enter_sewers_split", true, "Enter sewers");
    settings.Add("exit_sewers_split", true, "Exit sewers");
    settings.Add("pick_up_windmill_torch_split", true, "Pick up torch item");

    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Chants of Sennaar";
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

        vars.Helper["isPlayerMoving"] = mono.Make<bool>("GameController", "staticInstance", "playerController", "playerMove", "isMoving");
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
        // Start timer when player starts moving.
        return current.isPlayerMoving;
    }

    // Otherwise, check if player moved from title screen to first room's intro cutscene.
    var isFreshFirstRoom = vars.currentLevelId == 0 && vars.currentPlaceId == 0 && vars.currentPortalId == 0;  // Portal id is 0 from a new save, and 1 otherwise (e.g. go into next room and back, then save).
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
}

split
{
    /* ---- Testing logic below ---- */
    // if (vars.currentPlaceId != vars.oldPlaceId)
    // {
    //     print("level + place ids: " + vars.oldLevelId + "," + vars.oldPlaceId + " -> " + vars.currentLevelId + "," + vars.currentPlaceId);
    //     // return true;
    // }
    /* ---- Testing logic above ---- */

    /* ---- Real logic below ---- */
    /* This only works for Any% category. */

    // Crypt splits
    if (vars.oldLevelId == 0 && vars.currentLevelId == 0 && vars.currentPlaceId <= 6 && settings["crypt_splits"])
    {
        var isFirstJournalSplit = vars.oldPlaceId == 3 && vars.currentPlaceId == 4;
        var isCryptExit = vars.oldPlaceId == 5 && vars.currentPlaceId == 6;

        return isFirstJournalSplit || isCryptExit;
    }

    // Abbey (Devotees) splits
    if (vars.oldLevelId == 0 && settings["abbey_splits"])
    {
        // Abbey -> Fortress.
        if (vars.currentLevelId == 1)
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
        // Pick up lens item.
        var isPickUpLensSplit = vars.currentPlaceId == 23 && vars.isInventoryForcedOpen && settings["pick_up_lens_split"];

        return isHideAndSeekSplit || isPickUpCoinSplit || isPickUpLensSplit;
    }

    // Fortress (Warriors) splits
    if (vars.oldLevelId == 1 && settings["fortress_splits"])
    {
        // Fortress -> Gardens.
        if (vars.currentLevelId == 2)
        {
            return true;
        }

        // Exit early if current level is not Fortress to avoid duplicate check.
        if (vars.currentLevelId != 1)
        {
            return false;
        }

        // Enter first stealth room.
        var isStealthStartSplit = vars.oldPlaceId == 9 && vars.currentPlaceId == 11 && settings["stealth_start_split"];
        // Exit stealth corridor room.
        var isStealthCorridorSplit = vars.oldPlaceId == 0 && vars.currentPlaceId == 12 && settings["stealth_corridor_split"];
        // Exit stealth box elevator room.
        var isStealthBoxElevatorSplit = vars.oldPlaceId == 13 && vars.currentPlaceId == 14 && settings["stealth_box_elevator_split"];
        // Exit dress up room.
        var isDressUpSplit = vars.oldPlaceId == 16 && vars.currentPlaceId == 14 && settings["dress_up_split"];

        return isStealthStartSplit || isStealthCorridorSplit || isStealthBoxElevatorSplit || isDressUpSplit;
    }

    // Gardens (Bards) splits
    if (vars.oldLevelId == 2 && settings["gardens_splits"])
    {
        // Gardens -> Tunnels.
        if (vars.currentLevelId == 3)
        {
            return true;
        }

        // Exit early if current level is not Gardens to avoid duplicate check.
        if (vars.currentLevelId != 2)
        {
            return false;
        }

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

    // Split for player starting final cutscene in final room in Exile.
    if (vars.currentLevelId == 4 && vars.currentPlaceId == 2 && !current.canPlayerRun && !old.cursorOff && current.cursorOff)
    {
        return true;
    }

    // Split for Tunnels -> Factory
    if (vars.oldLevelId == 3 && vars.oldPlaceId == 14 && vars.currentLevelId == 3 && vars.currentPlaceId == 16)
    {
        return true;
    }

    // Split for general case of advancing to new level.
    if (vars.currentLevelId > vars.oldLevelId)
    {
        return true;
    }
    /* ---- Real logic above ---- */
}
