# MarkdownRogue

Godot 4で作っている、片手操作向けのマークダウン風ローグライト試作です。

## Current Environment

- Project path: `/Users/IceTea/markdown-rogue`
- Engine: Godot `4.6.3.stable`
- Renderer: `Mobile`
- Language: `GDScript`
- Development Mac: macOS `13.7.8` / Intel `x86_64`
- Local Godot app used for checks: `/Users/IceTea/Downloads/Godot.app`

## Run

Open this folder in Godot and press Play.

Main scene:

```text
res://scenes/main.tscn
```

The project can also be checked headlessly:

```sh
/Users/IceTea/Downloads/Godot.app/Contents/MacOS/Godot --headless --path /Users/IceTea/markdown-rogue --quit-after 2
```

## Controls

- Move: drag with mouse/touch, or use `WASD` / arrow keys.
- Attack: automatic.
- Camera: follows the player, so moving toward screen edges reveals more of the stage.
- Weapon shop: touch `$ SHOP` in the field.
- Gamble room: touch the `$ BET` shrine with the player.
- Bet amount: use `-` / `+`.
- Slot spin: press `SPIN`.
- Blackjack: switch to `BLACKJACK`, then use `DEAL`, `HIT`, and `STAND`.
- Stage travel: touch `CAVE >`, `VINE ^`, `< FIELD`, or `DESCEND` portals.
- Cave gambling: touch `$ POKER`, then press `DRAW`.
- Heaven gambling: touch `$ RACE`, then pick `SERAPH`, `HALO`, or `FEATHER`.
- Return to combat: press `RETURN`.
- Game over: press `RETRY RUN`, or press `R` on keyboard during desktop testing.

## Current Prototype

- `@`: player
- `x`: enemy
- `-`: auto-fired projectile
- `>`: forward projectile fired in the direction the player is facing
- `$ BET`: shrine that opens the slot room
- `$ SHOP`: field weapon shop
- `CAVE >`: portal to cave stage
- `VINE ^`: portal to heaven stage
- `< FIELD` / `DESCEND`: portals back to field
- Run coins: earned by defeating enemies
- Initial weapon: `TARGETER`, auto-aims at the nearest enemy.
- Purchasable weapons:
- `BLASTER`: forward shot in the direction `@` is facing.
- `SPLITTER`: adds two angled shots to Targeter.
- `NOVA`: eight-way burst on a cooldown.
- `REPEATER`: doubles the Targeter shot.
- Gambling room shows current run coins and current bet
- Slot payout: `2x` bet for two matching symbols, `6x` bet for three matching symbols
- Blackjack payout: `2x` bet for a win, `3x` bet for blackjack, bet returned on push
- Cave poker payout: pair returns bet, two pair `2x`, three of a kind `3x`, full house `5x`, four of a kind `8x`, five of a kind `10x`
- Angel race payout: chosen angel wins for `3x`
- Game over screen: shows reached wave/run coins and can restart the run without stopping Godot.

## Notes

- The current assets are intentionally symbolic/markdown-like placeholders.
- Paid currency must stay separate from run coins. Run coins can be used for gambling; paid currency should not.
- The shrine only reacts to nodes in the `player` group. This prevents enemies from triggering the slot room.
- See [docs/current_spec.md](docs/current_spec.md) for the current handoff/spec notes.
