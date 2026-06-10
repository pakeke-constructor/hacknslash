
<PROJECT>
Hack n stack is a videogame built for PC.
a combat hack n slash deckbuilder roguelike.
</PROJECT>

<gameplay>
- control a character in a top-down 2d world.
- fight off swarms of enemies (vampire-survivors/brotato style)
- use abilities: dash, blink, slash, and cast spells.
- buy upgrades and level-up.

See `GAME_DESIGN_DOC.md` for the more game details.
</gameplay>

<tech_stack>
Love2d, luaJIT. Custom libraries/modules all over.
</tech_stack>

<architecture>
- main.lua: entrypoint. All globals defined here.
- src/g.lua: main API, all the important/central functions live here
- src/modules/*: Extra services that are independent and standalone; could be used outside this game.
- src/modules/helper/helper.lua: standalone helper functions, super useful
- src/modules/richtext/*: richtext module, used for text rendering and text effects
- src/modules/objects/*: objects module, contains data structures: Grid, Enum, Heap, Partition, Set, Color, Class, and others
- src/modules/localization.lua: handles all localization.
- src/scenes/sceneManager.lua: manages scenes
- src/scenes/game_scene/game_scene.lua: Gameplay scene, contains an ECSWorld, does gameplay
- src/scenes/menu_scene/menu_scene.lua: Menu, title, anything "outside" of the game
- src/ecs/*: Entity-component-system stuff.
- src/ecs/systems/*: ECS Systems. (projectile, ent movement, pathing, etc)
- src/ecs/components.lua: All component type-definitions
- src/Run.lua: Represents a run. (can be serialized)
- src/consts.lua: Constants.
</architecture>

<reference-project>
In this repository, there is a reference project called `army_game`.
It is in the directory `army_game/**`.
This project is very different to hack-n-slash, but it uses a lot of the same tech, and a lot of the same ideas. To learn more about it, read it's CLAUDE.md.
<reference-project>

<localization>
Do NOT add text to entities, blessings, or UI without wrapping it in a `loc()` call.
Use `loc(txt, variables, context)` to translate text.
Example:
```lua
BUTTON = loc("Pole button %{n}", {n = 5}, {
  context = "As in, a button at the south pole"
})
```
loc MUST be called at load-time, before the draw/update loop begins.
</localization>

<IMPORTANT-INSTRUCTIONS>
- IN ALL INTERACTIONS, BE EXTREMELY CONCISE, EVEN IF IT MEANS GRAMMATICAL INCORRECTNESS.
- You are working with an experienced engineer. Be terse; don't over-explain.
- Simple code > "correct" code. No unnecessary error handling, no overengineering for the sake of "best practices".
- No complex one-liners, no deep nesting, no clever abstractions.
- If a feature needs >300 new lines, stop and ask how to simplify.
</IMPORTANT-INSTRUCTIONS>

