

# PROJECT: "Hack n Stack":
a combat hack n slash deckbuilder roguelike.

TLDR:
- control a character in a top-down 2d world.
- fight off swarms of enemies (vampire-survivors/brotato style)
- use abilities: dash, blink, slash, and cast spells.
- buy upgrades and level-up.

See `GAME_DESIGN_DOC.md` for the more game details.


## Tech stack:
Love2d, luaJIT. Custom libraries/modules all over.

## Architecture / Details:
The game can be started in 1 of 2 modes: "Menu", or "Gameplay".
Menu-mode: choose character, change settings, start run.
Gameplay-mode: play the actual game.

When starting a run, the lua-state is fully reset via `love.event.quit("restart")`.
This ensures that during the run, we can have whatever variables we want ANYWHERE, and it's guaranteed not to cause stateful-issues with future runs.


## Current details:
This project has only just started; barely any code exists.
However, there's an older, different project in this repository: "Army-game", (folder `armygame/**`) which contains a TONNE of useful systems and code.
There is a LOT of code/files in there, so don't look through them all.

Look at `armygame/CLAUDE.md` to understand more about the architecture of army-game.


## YOUR TASK, AS A CODING AGENT:
You'll be asked to bring over common systems from army-game, and you'll be expected to use your own judgement to determine what needs to be brought over, and what doesn't.

If possible use `bash` copy tool to move files, as opposed to read_file/write_file, since it's much more token efficient.

Do NOT use `bash` tool to check syntax-errors, run lua, because it will not work.


