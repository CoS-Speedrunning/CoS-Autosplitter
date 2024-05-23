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

        vars.Helper["playerControllerPtr"] = mono.Make<ulong>("GameController", "staticInstance", "playerController");
        vars.Helper["isPlayerMoving"] = mono.Make<bool>("GameController", "staticInstance", "playerController", "playerMove", "isMoving");
        vars.Helper["canPlayerRun"] = mono.Make<bool>("GameController", "staticInstance", "playerController", "playerMove", "canRun");

        return true;
    });

    // Gets the last DateTime that player was on the title screen.
    vars.lastDateTimeOnTitleScreen = null;

    // Gets whether the player went from the title screen to the first cutscene.
    vars.isTitleScreenToNewSave = false;
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
        return true;
    }
    else if (!settings["save_slot_1"] && settings["save_slot_2"] && !settings["save_slot_3"])
    {
        vars.oldLevelId = old.gameSave2LevelId;
        vars.oldPlaceId = old.gameSave2PlaceId;
        vars.currentLevelId = current.gameSave2LevelId;
        vars.currentPlaceId = current.gameSave2PlaceId;
        vars.currentPortalId = current.gameSave2PortalId;
        return true;
    }
    else if (!settings["save_slot_1"] && !settings["save_slot_2"] && settings["save_slot_3"])
    {
        vars.oldLevelId = old.gameSave3LevelId;
        vars.oldPlaceId = old.gameSave3PlaceId;
        vars.currentLevelId = current.gameSave3LevelId;
        vars.currentPlaceId = current.gameSave3PlaceId;
        vars.currentPortalId = current.gameSave3PortalId;
        return true;
    }

    // If setting config is invalid, don't run autosplitter.
    return false;
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
        print("Moved from title screen to first room");
        vars.isTitleScreenToNewSave = true;
    }
}

onStart
{
    // Reset vars.
    vars.lastDateTimeOnTitleScreen = null;
    vars.isTitleScreenToNewSave = false;
}

split
{
    /* ---- Testing logic below ---- */
    // if (vars.currentPlaceId != vars.oldPlaceId)
    // {
    //     print("level + place ids: " + vars.oldLevelId + "," + vars.oldPlaceId + " -> " + vars.currentLevelId + "," + vars.currentPlaceId);
    //     return true;
    // }
    /* ---- Testing logic above ---- */

    /* This only works for Any% category. */

    /* ---- Real logic below ---- */
    // Split for player starting final cutscene in final room in Exile.
    if (vars.currentLevelId == 4 && vars.currentPlaceId == 2 && !current.canPlayerRun && !old.cursorOff && current.cursorOff)
    {
        return true;
    }

    // Split for Crypt -> Abbey
    if (vars.oldLevelId == 0 && vars.oldPlaceId == 6 && vars.currentLevelId == 0 && vars.currentPlaceId == 7)
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
