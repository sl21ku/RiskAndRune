# MarkdownRogue Current Spec

Last updated: 2026-06-03

## Project Summary

`MarkdownRogue` is a Godot 4 prototype for a one-hand-friendly roguelite with markdown-style symbolic visuals. The intended final direction is an iOS-first action roguelite inspired by simple touch movement games, with risk/reward gambling mechanics based only on run-earned currency.

The current prototype focuses on proving this loop:

1. Move the player with one-hand style drag controls.
2. Auto-fire at nearby enemies.
3. Defeat enemies to earn run coins.
4. Touch the `$ BET` shrine.
5. Enter a gambling room and spend run coins on slots or blackjack.
6. Return to combat.
7. If HP reaches zero, retry the run from the game over screen.

The current stage loop also supports simple location travel:

1. Start in `FIELD`.
2. Touch `CAVE >` to enter `CAVE`.
3. Touch `VINE ^` to enter `HEAVEN`.
4. Use `< FIELD` or `DESCEND` to return to `FIELD`.

## Environment

- Engine: Godot `4.6.3.stable`
- Renderer: `Mobile`
- Script language: `GDScript`
- Project root: `/Users/IceTea/markdown-rogue`
- Main scene: `res://scenes/main.tscn`
- Development machine observed:
  - macOS `13.7.8`
  - Build `22H730`
  - CPU architecture `x86_64`
- Godot executable used by Codex for validation:
  - `/Users/IceTea/Downloads/Godot.app/Contents/MacOS/Godot`

## Current File Map

- `project.godot`
  - Sets the project name and main scene.
- `scenes/main.tscn`
  - Minimal scene containing the `Main` root node.
- `scripts/main.gd`
  - Creates the arena, camera, player, enemies, shrine, weapon shop, HUD, gambling UI, slot rules, blackjack rules, and game over/restart UI at runtime.
- `scripts/player.gd`
  - Handles drag/keyboard movement, enemy-seeking shot timing, forward shot timing, HP, and control enable/disable.
- `scripts/enemy.gd`
  - Handles enemy chase behavior, contact damage, and defeat signal.
- `scripts/bolt.gd`
  - Handles projectile movement and lifetime.
- `scripts/gamble_shrine.gd`
  - Detects player entry and signals transition to the slot room.
- `scripts/stage_portal.gd`
  - Detects player entry and signals transition to another stage.
- `scripts/weapon_shop.gd`
  - Detects player entry and signals transition to the weapon shop.

## Current Gameplay Details

### Combat Mode

- Player starts near the bottom of the arena.
- Enemies spawn near the upper half of the arena.
- Camera follows the player, so moving right/up/down/left reveals offscreen portals and stage space.
- Attacks are determined by owned weapons.
- Initial weapon: `TARGETER`, which fires toward the nearest enemy.
- Enemies chase the player.
- Enemy contact damages the player on a short cooldown.
- Defeating enemies grants `2` to `5` run coins.
- Clearing all enemies increases the wave and spawns a new wave.

### Weapon Shop

- The field contains `$ SHOP`.
- Touching `$ SHOP` opens the weapon shop UI.
- Enemies are paused while the shop is open.
- Existing bolts are removed when entering the shop.
- The prototype currently buys weapons with run coins.

Current weapons:

- `TARGETER`
  - Initial weapon.
  - Auto-aims at the nearest enemy.
- `BLASTER`
  - Cost: `10`
  - Fires a `>` projectile in the direction the player is facing.
- `SPLITTER`
  - Cost: `15`
  - Adds two angled shots to Targeter.
- `NOVA`
  - Cost: `20`
  - Fires an eight-way `*` burst on a cooldown.
- `REPEATER`
  - Cost: `25`
  - Adds a second Targeter shot.

Note: purchased weapons currently persist for the active debug session, including after `RETRY RUN`. This is useful for prototyping, but the final economy should separate run currency from permanent unlock currency.

### Shrine

- The shrine is represented by a stage-specific `$` label.
- Touching the shrine with the player enters the gambling room.
- The shrine ignores enemies by checking the `player` group.
- This is important because an earlier build let enemies trigger the slot room immediately after starting debug playback.

Stage-specific shrine games:

- `FIELD`: `$ SLOT`, with slot and blackjack tabs.
- `CAVE`: `$ POKER`, with cave poker only.
- `HEAVEN`: `$ RACE`, with angel race only.

### Stages

- `FIELD`
  - Background: dark green field tone.
  - Portals: `CAVE >`, `VINE ^`.
  - Shop: `$ SHOP`.
  - Gambling: slot / blackjack.
- `CAVE`
  - Background: dark cave tone.
  - Portals: `< FIELD`, `VINE ^`.
  - Gambling: cave poker.
- `HEAVEN`
  - Background: light gray-blue heaven tone.
  - Portal: `DESCEND`.
  - Gambling: angel race.

Changing stage:

- Clears current enemies and bolts.
- Updates arena title, background color, shrine label, and portals.
- Places player at `Vector2(0, 320)`.
- Spawns a fresh wave in the new stage.

### Gambling Room

- Entering the gambling room changes `mode` from `COMBAT` to `SLOT`.
- Player controls are disabled.
- Player and shrine are hidden.
- Enemies are hidden and their processing is disabled.
- Existing bolts are removed.
- The gambling UI appears on a `CanvasLayer`.
- The room displays current run coins and current bet.
- Bet can be changed with `-` and `+` buttons in `5` coin steps.
- `SLOT *` or `BLACKJACK *` marks the currently selected game.
- Spin/deal buttons are disabled when the player does not have enough run coins.
- Game switching is blocked while a blackjack hand is active.

#### Slot

Slot rules:

- Spin cost: current bet amount
- Symbols: `@`, `#`, `$`, `*`, `!`, `?`
- Two matching symbols: pays `2x` bet
- Three matching symbols: pays `6x` bet
- No match: pays `0`

#### Blackjack

Blackjack rules:

- Deal cost: current bet amount
- Player can `HIT` or `STAND`.
- Dealer draws until `17` or higher.
- Win pays `2x` bet.
- Blackjack pays `3x` bet.
- Push returns the bet.
- Bust or dealer win pays `0`.

#### Cave Poker

Poker rules:

- Draw cost: current bet amount
- Draws five ranks from `A`, `K`, `Q`, `J`, `10`, `9`, `8`.
- Pair returns bet.
- Two pair pays `2x` bet.
- Three of a kind pays `3x` bet.
- Full house pays `5x` bet.
- Four of a kind pays `8x` bet.
- Five of a kind pays `10x` bet.
- High card pays `0`.

This is a prototype poker-like draw game, not a full deck implementation yet.

#### Angel Race

Angel race rules:

- Race cost: current bet amount
- Pick `SERAPH`, `HALO`, or `FEATHER`.
- The winning angel is randomly selected.
- Correct pick pays `3x` bet.
- Incorrect pick pays `0`.

Returning:

- `RETURN` hides the slot UI.
- Combat resumes.
- Player is placed at `Vector2(0, 120)` to avoid immediate re-entry.
- Enemies are shown and re-enabled.

### Game Over And Restart

- HP reaching `0` changes `mode` to `GAME_OVER`.
- Player controls are disabled.
- Enemies are frozen.
- Existing bolts are removed.
- The game over UI shows reached wave and current run coins.
- `RETRY RUN` starts a new run without stopping the Godot debug session.
- Keyboard `R` also retries during desktop testing.

Restart resets:

- Run coins to `0`
- Wave to `1`
- Bet amount to `5`
- Player HP to `5`
- Player position to `Vector2(0, 360)`
- Enemies and bolts are cleared and a new wave spawns.

## Controls

- Touch/mouse drag: move player.
- `WASD` or arrow keys: move player during desktop testing.
- Auto-attack: no input required.
- Weapon shop:
  - Touch `$ SHOP`: open shop.
  - Weapon buttons: buy weapon if enough run coins.
  - `RETURN`: return to combat.
- Gambling room:
  - `-` / `+`: adjust bet amount.
  - `SLOT`: show slot controls.
  - `SPIN`: spend current bet and roll the slot.
  - `BLACKJACK`: show blackjack controls.
  - `DEAL`: spend current bet and start a blackjack hand.
  - `HIT`: draw one card.
  - `STAND`: let the dealer resolve the hand.
  - `DRAW`: spend current bet and play cave poker.
  - `SERAPH` / `HALO` / `FEATHER`: spend current bet and pick an angel race runner.
  - `RETURN`: return to combat.
- Stage travel:
  - `CAVE >`: enter cave stage.
  - `VINE ^`: enter heaven stage.
  - `< FIELD` / `DESCEND`: return to field.
- Game over:
  - `RETRY RUN`: restart the run.
  - `R`: restart the run during desktop testing.

## Economy And Compliance Direction

Keep these currencies separate:

- `Run coins`
  - Earned inside a run.
  - Can be spent on slot/gambling mechanics.
  - Should not be purchasable directly with real money.
- `Paid currency`
  - May be purchased through App Store in-app purchase.
  - Should be used for fixed-value non-gambling items such as skins, character unlocks, or battle pass style content.
  - Should not be wagered, multiplied, or lost through gambling mechanics.

This separation is intentional to reduce App Store and legal risk.

## Current Known Issues

- Most nodes are generated in `main.gd` at runtime. This is fast for prototyping but should be split into scenes later.
- Weapon purchases currently use run coins and persist for the debug session only.
- Camera follows player directly; later it should use tuned limits/dead zones for iOS feel.
- Gambling UI is functional but visually rough.
- Blackjack uses quick prototype rules and random rank draws rather than a real deck/shoe.
- Cave poker uses repeated rank draws rather than a real deck.
- Angel race has instant resolution and no animation yet.
- Stage layouts are prototype overlays using the same combat arena.
- There is no persistent save system yet.
- There is no title screen, pause menu, or settings screen yet.
- No audio has been added.
- The current symbolic assets are placeholders.
- No iOS export settings have been configured yet.

## Validation

Codex validated the current project with:

```sh
/Users/IceTea/Downloads/Godot.app/Contents/MacOS/Godot --headless --path /Users/IceTea/markdown-rogue --quit-after 2
```

The latest check completed without script/runtime errors.

## Next Suggested Tasks

1. Split `main.gd` runtime-created objects into reusable scenes.
2. Split stage data into resources or dictionaries instead of hard-coded branches.
3. Move weapon definitions into data/resources and add permanent unlock currency.
4. Tune camera dead zone, limits, and iOS touch feel.
5. Improve the slot room so reels animate instead of instantly resolving.
6. Improve blackjack presentation with card reveal timing and dealer animation.
7. Add angel race animation.
8. Add a simple reward choice after wave clear.
9. Add a minimal save file for meta progress.
10. Add iOS-safe screen sizing and touch-area checks.
