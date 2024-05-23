state("Chants Of Sennaar", "v.1.0.0.9")
{
    // Offsets for original game, using GameController offsets and save slot 3.
    long gameControllerPtr :  "UnityPlayer.dll", 0x01B01D68, 0x0, 0x90, 0x28, 0x0, 0x28, 0x28;

    // This turns true when entering the final cutscene, and works even on controller.
    bool cursorOff :                 "UnityPlayer.dll", 0x01B01D68, 0x0, 0x90, 0x28, 0x0, 0x28, 0x28, 0x88, 0x34;              // GameController > inputsController > cursorOff

    long titleScreenPtr :            "UnityPlayer.dll", 0x01B01D68, 0x0, 0x90, 0x28, 0x0, 0x28, 0x28, 0x90, 0x20;              // GameController > placeController > titleScreen
    long currentPlacePtr :           "UnityPlayer.dll", 0x01B01D68, 0x0, 0x90, 0x28, 0x0, 0x28, 0x28, 0x90, 0x40;              // GameController > placeController > currentPlace
    int levelId :                    "UnityPlayer.dll", 0x01B01D68, 0x0, 0x90, 0x28, 0x0, 0x28, 0x28, 0x90, 0x38, 0x30, 0x20;  // GameController > placeController > gameSaves[2] > currentPlaceId > level
    int placeId :                    "UnityPlayer.dll", 0x01B01D68, 0x0, 0x90, 0x28, 0x0, 0x28, 0x28, 0x90, 0x38, 0x30, 0x24;  // GameController > placeController > gameSaves[2] > currentPlaceId > id
    int portalId :                   "UnityPlayer.dll", 0x01B01D68, 0x0, 0x90, 0x28, 0x0, 0x28, 0x28, 0x90, 0x38, 0x30, 0x28;  // GameController > placeController > gameSaves[2] > currentPortalId

    bool isPlayerMoving :            "UnityPlayer.dll", 0x01B01D68, 0x0, 0x90, 0x28, 0x0, 0x28, 0x28, 0xA0, 0x58, 0xC6;        // GameController > playerController > playerMove > isMoving
}

init
{
    // This is the last DateTime that we were on the title screen.
    vars.lastDateTimeOnTitleScreen = null;

    // This is set to true if we go from the title screen to the cutscene for the first room in a new save.
    vars.isTitleScreenToNewSave = false;
}

start
{
    // If we are on title screen now, store current time and exit early.
    // print("lastDateTimeOnTitleScreen: " + vars.lastDateTimeOnTitleScreen + ", isTitleScreenToNewSave: " + vars.isTitleScreenToNewSave);
    if (current.currentPlacePtr == current.titleScreenPtr)
    {
        vars.lastDateTimeOnTitleScreen = DateTime.Now;
        vars.isTitleScreenToNewSave = false;
        return false;
    }

    // This will be true if script is started while we are not on the title screen.
    if (vars.lastDateTimeOnTitleScreen == null)
    {
        return false;
    }

    // If we moved from the title screen to a new save, start timer when player starts moving.
    if (vars.isTitleScreenToNewSave)
    {
        return current.isPlayerMoving;
    }

    // Otherwise, check if we moved from the title screen to the first room in a cutscene (with cursorOff), with some leniency.
    var inFirstRoom = current.levelId == 0 && current.placeId == 0;
    var isNoLongerOnTitleScreen = DateTime.Now.Subtract(vars.lastDateTimeOnTitleScreen).TotalSeconds > 1;  // Leniency needed when resetting back to title screen.
    var isNewSave = current.portalId == 0;  // This will be 0 from a new save, and 1 otherwise (e.g. go into next room and back, then save)
    if (inFirstRoom && isNoLongerOnTitleScreen && isNewSave)
    {
        print("Moved from title screen to first room");
        vars.isTitleScreenToNewSave = true;
    }
}

split
{
    if (current.placeId != old.placeId)
    {
        print("level + place ids: " + old.levelId + "," + old.placeId + " -> " + current.levelId + "," + current.placeId);
        return true;
    }

    /* This only works for Any% category. */

    // Split for player starting final cutscene in final room in Exile.
    if (current.levelId == 4 && current.placeId == 2 && !old.cursorOff && current.cursorOff)
    {
        return true;
    }

    // Split for Crypt -> Abbey
    if (old.levelId == 0 && old.placeId == 6 && current.levelId == 0 && current.placeId == 7) {
        return true;
    }

    // Split for Tunnels -> Factory
    if (old.levelId == 3 && old.placeId == 14 && current.levelId == 3 && current.placeId == 16) {
        return true;
    }

    // Split for general case of advancing to new level.
    if (current.levelId > old.levelId) {
        return true;
    }
}

onStart
{
    // Reset vars.
    vars.lastDateTimeOnTitleScreen = null;
    vars.isTitleScreenToNewSave = false;
}

onReset
{
    // Reset vars.
    vars.lastDateTimeOnTitleScreen = null;
    vars.isTitleScreenToNewSave = false;
}
