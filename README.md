# Lingua

Create your own languages, write coded books, and share dictionaries
with other players.

## Features

- **Create languages** — each language gets a unique random alphabet.
- **Encode / decode text** — via chat commands or a GUI editor.
- **Coded books** — write a book in any language you know; other players
  see it encoded until they learn the language.
- **Dictionaries** — share a language with another player (permanent or
  one-time).
- **Multi-mode bookshelf** — a bookshelf with three modes:
  - **Normal** — store and take items.
  - **Copy** — hand out copies of filled books or bound dictionaries.
  - **Locked** — only the owner can take or put items.
- **Anti-duplication** — copies cannot be copied again, edited, or used
  in crafting.

## Requirements

- Luanti (Minetest) 5.x
- `default` (Minetest Game)

## Installation

1. Copy the `lingua` folder into your `mods/` directory.
2. Enable the mod in your world settings.
3. Optional: set `lingua_max_languages_per_player` in `minetest.conf`
   (default `3`, `0` = no limit).

## Quick start

1. Open the GUI with `/lingua gui`.
2. In the **Languages** tab, enter a name and click **Create**.
3. In the **Editor** tab, type text and click **Encode →**.
4. Craft an **Unknown Book** (4 paper + 1 book) and write in it.
5. Craft a **Dictionary** (3 paper + 1 book) and bind it with
   `/lingua bind <name>` while holding it.
6. Give the dictionary to another player — they can now read your
   messages.

## Commands

| Command | Description |
|---|---|
| `/lingua gui` | Open the GUI editor |
| `/lingua create <name> [secret]` | Create a language |
| `/lingua list` | List all languages |
| `/lingua info <name>` | Info about a language |
| `/lingua encode <name> <text>` | Encode text |
| `/lingua decode <name> <text>` | Decode text |
| `/lingua wrap <name> <text>` | Encode + wrap in markers |
| `/lingua decode_all <text>` | Decode all markers in text |
| `/lingua bind <name>` | Bind held dictionary |
| `/lingua bind_once <name>` | Bind held one-time dictionary |
| `/lingua forget <name>` | Forget a language |
| `/lingua delete <name>` | Delete (author or admin) |

## Crafting

- **Unknown Book** — 4 paper + 1 book
- **Dictionary** — 3 paper + 1 book
- **One-time Dictionary** — 1 paper + 1 book
- **Bookshelf** — 1 bookshelf + 1 paper

## Privileges

- `lingua_admin` — create unlimited languages, delete any language.

## License

GPL-3.0-or-later. See `LICENSE`.