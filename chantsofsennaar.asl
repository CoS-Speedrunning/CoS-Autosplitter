state("Chants Of Sennaar", "v.1.0.0.9")
{
}

startup
{
    settings.Add("game_save_slot", true, "[Required] Game save slot");
    settings.SetToolTip("game_save_slot", "[Required] The save slot that will be used for speedruns. Your level/place ids are determined from the save data.");

    settings.CurrentDefaultParent = "game_save_slot";
    settings.Add("save_slot_1", false, "Save slot 1");
    settings.Add("save_slot_2", false, "Save slot 2");
    settings.Add("save_slot_3", true, "Save slot 3");

    settings.CurrentDefaultParent = null;
    settings.Add("abbey_splits", true, "Abbey splits");

    settings.CurrentDefaultParent = "abbey_splits";
    settings.Add("crypt_split", true, "Crypt");
    settings.Add("hide_and_seek_split", true, "Hide and seek");
    settings.Add("bed_puzzle_split", true, "Bed puzzle");
    settings.Add("lens_split", true, "Lens");

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
        print("Save slot config is invalid, autosplitter will not run.")
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
    if (vars.currentPlaceId != vars.oldPlaceId)
    {
        print("level + place ids: " + vars.oldLevelId + "," + vars.oldPlaceId + " -> " + vars.currentLevelId + "," + vars.currentPlaceId);
        // return true;
    }
    /* ---- Testing logic above ---- */

    /* ---- Real logic below ---- */
    /* This only works for Any% category. */

    // Crypt + Abbey splits
    if (vars.oldLevelId == 0)
    {
        // Abbey -> Fortress.
        if (vars.currentLevelId == 1 && settings["abbey_splits"])
        {
            return true;
        }

        // Exit early if current level is not Crypt + Abbey to avoid duplicate check.
        if (vars.currentLevelId != 0)
        {
            return false;
        }

        // Crypt -> Abbey.
        var isCryptSplit = vars.oldPlaceId == 5 && vars.currentPlaceId == 6 && settings["crypt_split"];
        // Finish hide and seek.
        var isHideAndSeekSplit = vars.oldPlaceId == 9 && vars.currentPlaceId == 11 && settings["hide_and_seek_split"];
        // Finish bed puzzle by picking up coin item.
        var isBedPuzzleSplit = vars.currentPlaceId == 17 && vars.isInventoryForcedOpen && settings["bed_puzzle_split"];
        // Pick up lens item.
        var isLensSplit = vars.currentPlaceId == 23 && vars.isInventoryForcedOpen && settings["lens_split"];

        return isCryptSplit || isHideAndSeekSplit || isBedPuzzleSplit || isLensSplit;
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
