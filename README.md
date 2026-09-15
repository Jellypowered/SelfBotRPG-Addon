# SelfBot RPG Addon

A self-contained WotLK 3.3.5a control panel for the server-side
`mod-selfbot-rpg` module. It provides a dark, gold-accented tabbed UI for
starting and observing supported gathering, material, and fishing activities.
The required LibStub, LibDataBroker, CallbackHandler, and LibDBIcon libraries
are bundled; no separate addon dependency is required.

> The addon is a client control surface. The server module and stock playerbot
> systems remain authoritative for movement, combat, gathering, loot, fishing,
> configuration validation, and activity state.

## Install

1. Install and enable `mod-selfbot-rpg` on an AzerothCore WotLK realm.
2. Copy or symlink this directory as:
   ```text
   Interface/AddOns/SelfBotRPG
   ```
3. Confirm `SelfBotRPG.toc`, the `SBRPG_*.lua` files, and the bundled `Libs/`
   directory are directly inside that directory.
4. Enable **SelfBot RPG** on the character-select addon screen and log in.

No Ace3, PlayerbotManager, PBAltManager, or separately installed library addon
is needed.

## Use

- `/sbrpg` — toggle the main window.
- `/sbrpg material status` — open the window and request material status.
- `/sbrpgchat <command>` — manually send a `.sbrpg <command>` SAY message.
  This is an emergency/manual fallback only; the UI normally uses addon
  messages.
- **Minimap button:** left-click toggles the window; right-click opens
  Settings; drag to reposition. LibDBIcon preserves its position and migrates
  the previous launcher angle.
- **Tiny mode:** **Stop Current** uses the configured graceful return-home
  behavior; **Force Stop** immediately clears the activity when supported.

The main window has five tabs. History is newest-first and keeps its latest row highlighted:

| Tab | Purpose |
| --- | --- |
| Gathering | Select mining/herbalism node mode plus optional duration and exact-resource quantity goals. |
| Material | Select one server-catalog material, inspect indexed-source count, and set duration/quantity goals. |
| Fishing | Select a fish or fish the current zone, with pool/open-water options. |
| Settings | Stage validated configuration, including separate controller, loot, gather, route-progress, and chest timeout values, then Apply, Revert Unsaved, or Reset Defaults. |
| History | Read-only, persistent status history, capped at 100 newest entries. |

Controls remain disabled until the server advertises their capability. This is
intentional: an unavailable capability is not simulated by the addon. Activity
timing includes independent controls for exact loot handoff, gather claims,
route progress, chest loot, material-hotspot dwell/empty cooldown, danger
cooldown, and fishing-pool rediscovery.

## Server protocol

The addon preserves the existing `JLYRPG2` protocol. At login it sends `HELLO`,
receives server capabilities, and then requests only supported commands. Its
primary commands are `STATUS`, `STOP`, `SET_CONFIG`, `START`,
`START_MATERIAL`, `START_FISHING`, `MATERIAL_CATALOG`, `MATERIAL_SOURCES`, and
`MATERIAL_STATUS`.

The client never grants items or reputation, drives movement, resolves loot,
or bypasses server validation. If the UI says **Disconnected**, ensure the
server module is loaded and that the character is using the selfbot path which
owns the addon protocol.

## Saved data and migration

`SelfBotRPGDB` is account-wide. `SelfBotRPGMinimapDB` is a per-character
compatibility mirror used by the bundled minimap library; the account-wide
`SelfBotRPGDB.Minimap` table remains authoritative. On first load this release
migrates legacy:

- `Panel` position, gathering selection, material/fishing targets, and goals;
- `minimapPos` / `minimapAngle`;
- existing `Settings` values.

New sections are `Window`, `Gathering`, `Material`, `Fishing`, `Settings`,
`History`, and `Minimap`. History stores only timestamp, category, severity,
and short status text; it keeps at most 100 entries. Delete
`WTF/Account/.../SavedVariables/SelfBotRPG.lua` only if a full preference reset
is desired.

## Layout

```text
SBRPG_Core.lua       namespace, SavedVariables migration, slash commands
SBRPG_Data.lua       fallback catalogs, item presentation, plain-text filters
SBRPG_Theme.lua      shared dark/gold visual helpers
SBRPG_UIHelpers.lua  WotLK-safe widgets, tooltips, validation
SBRPG_History.lua    bounded persistent status sink
SBRPG_Protocol.lua   JLYRPG2 transport, parsing, capability gates
SBRPG_Window.lua     main frame, tab registration, footer, confirmation dialog
SBRPG_Minimap.lua    LibDBIcon launcher, persistence and legacy migration
SBRPG_Tab_*.lua      one module per initial tab
Libs/                bundled LibStub, CallbackHandler, LDB and LibDBIcon
```

Future Reputation and Questing tabs have no UI registration until server-side
capabilities and safety rules exist.

## Troubleshooting

- **Connected but a button is disabled:** the current server does not advertise
  that capability; update/enable the server module rather than forcing the UI.
- **Catalog is loading:** wait for the chunked `MATERIAL_CATALOG` response, then
  use the plain-text filter. The fallback catalog is display-only until the
  authoritative catalog arrives.
- **No indexed sources:** the server completed lookup but has no indexed source
  for that material on the current data set.
- **Settings rejected:** use the range printed by the validation error; server
  validation remains authoritative.
- **No messages arrive:** check the addon is enabled, reload the UI, then use
  `/sbrpg`. `/sbrpgchat status` is available only for manual diagnosis.

## Development checks

Run from this directory:

```bash
find . -name '*.lua' -print0 | xargs -0 -n1 luac -p
python3 tests/test_addon_layout.py
git diff --check
```

These checks verify syntax and static contracts only. They do **not** replace
live client/realm verification of frame behavior, protocol delivery, gathering,
material farming, fishing, settings application, history persistence, or
minimap drag behavior.
