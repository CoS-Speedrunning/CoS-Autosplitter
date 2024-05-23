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

startup
{
    settings.Add("game_save_slot", true, "[Required] Game save slot for speedruns");
    settings.CurrentDefaultParent = "game_save_slot";
    settings.Add("save_slot_1", false, "Use save slot 1");
    settings.Add("save_slot_2", false, "Use save slot 2");
    settings.Add("save_slot_3", true, "Use save slot 3");

    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
    vars.Helper.GameName = "Chants of Sennaar";
    vars.Helper.LoadSceneManager = true;
}

// This block only runs if the timer is not running.
start
{
    var inFirstRoom = current.levelId == 0 && current.placeId == 0;
    var isNewSave = current.portalId == 0;  // This will be 0 from a new save, and 1 otherwise (e.g. going into next room and back, then save)
    return inFirstRoom && isNewSave && current.isPlayerMoving;
}

// This block only runs if the timer is running or paused.
reset
{
    return current.currentPlacePtr == current.titleScreenPtr;
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
