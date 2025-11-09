# OpenIsopix
An open project for 2d isometric pixel-art games.

## Bounty status

<a href="https://www.boss.dev/issue/github/I_kwDOQSBVes7W1sRk"><img src="https://img.shields.io/endpoint.svg?url=https://api.boss.dev/badge/bounty%3Fgid%3Dboss%2F8vnvls9r0m40gcz984rt955" /></a>

<details>
<summary>Instructions / more info</summary>

> You may claim a bounty by closing the issue linked above with a PR that meets the goals/requirements below.

Choose one of the platforms below to claim the bounty:

- [Boss.dev](https://www.boss.dev/issue/github/I_kwDOQSBVes7W1sRk)
- [IssueHunt](https://oss.issuehunt.io/r/OpenSword/OpenIsopix/issues/1)
- [Gitpay](https://gitpay.me/#/task/1312): send me a bounty suggestion at the e-mail `gustavospgondim@gmail.com` using the announced price at Boss.dev/IssueHunt as reference

</details>

## Goals / requirements

A reality system using Godot Engine with the following features:

- [ ] Isometric tilemap rendering _`(in. AoE2, RollerCoaster, SimCity 2000)`_
- [ ] Pixel-art style graphics _`(in. Stardew Valley, Terraria)`_
- [ ] Block-based world, clustered in 16x16 chunks, with 2 heights (0.5 and 1.0 block height) _`(in. Minecraft)`_
- [ ] Different Point of Views (POV), supporting:
  - [ ] Heading/rotation (NSWE)
  - [ ] Zoom in/out
  - [ ] Pitch/tilt in 4 levels: low (closer to the ground), normal, high (closer to top-down), top-down _`(in. Final Fantasy Tactics)`_
- [ ] Smooth scrolling and POV movement
- [ ] Lighting system with different environmental lighting levels _`(in. Stardew Valley)`_
- [ ] Map revelation/fog support _`(in. AoE2, Warcraft 3)`_
- [ ] Blocks as entities with attributes that affect their rendering and behavior:
  - [ ] Behavior flags: solid/non-solid, opaque/non-opaque, climbable/non-climbable, etc.
  - [ ] Visual attributes: animation, light emission, etc.
  - [ ] Numeric attributes: HP, material, etc.
  - [ ] Interaction attributes: on-click, on-walk-over, etc.
- [ ] Basic world interaction:
  - [ ] Selecting and highlighting blocks under the cursor
  - [ ] Adding/removing/modifying blocks
  - [ ] Querying block attributes
  - [ ] Chunk management: loading/unloading chunks
- [ ] Mouse and controller support

_*Legend: `(in.)` Inspiration_

## Rules

- It MUST have an API that supports interacting with the world regardless of any user interface, including:
  - Adding/removing/modifying blocks
  - Querying block attributes
  - Handling events (e.g., block updates, lighting changes)
- It MAY have a basic user interface only for demonstration purposes, but the core functionality MUST be decoupled from any specific UI implementation.
- It MUST not depend on any specific game logic or assets; it should allow for easy creation of new blocks and behaviors.
- It SHOULD be made with extensibility in mind, specifically to allow for future features that are not in the requirements, like:
  - Player/NPC entities with movement and interaction
  - Automatic generation or manual building of worlds
  - In-game user interfaces (HUD, inventory, menus, chat, etc.)
  - Global/biome-specific environmental effects (weather, seasons, day/night cycle, etc.)
- It SHOULD be optimized for performance, especially regarding rendering and chunk management.
- It SHOULD be compatible with different platforms supported by Godot Engine (PC, mobile, web, etc.).
