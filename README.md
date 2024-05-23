# How to use the autosplitter

1. Download `asl-help` from here: https://github.com/just-ero/asl-help/blob/main/lib/asl-help
2. Place `asl-help` in your livesplit application folder > Components
    - E.g. Documents\Applications\LiveSplit_1.8.26\Components
3. Place the .asl file anywhere you want, and then import it into Livesplit
    - Right-click > Edit Layout > plus button to add > Control > Scriptable Auto Splitter > Browse > select the .asl file
4. In the window, there should be settings in the "Advanced" section. You **must** select your game save slot for the autosplitter to work properly.
    - This will default to the 3rd save slot.

# How it works
## Start
The script expects you to be on the title screen, then select "New Game". The autosplitter will start once you start moving.

## Split
The script will split whenever the place id changes (e.g. when you enter a new room) as a test. If you want to disable the testing logic, follow the comments in the .asl script under the `split` block to disable the testing logic and enable the intended logic.

## Reset
The script will reset when you go back to the title screen.