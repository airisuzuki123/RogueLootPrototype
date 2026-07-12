# Development Log

This file records successful GitHub pushes for the project.

## 2026-07-12 - Add form-linked affixes

- Added weapon affixes for extra projectiles, pierce, and explosion radius.
- Added player stat handling so affix bonuses stack with weapon forms and upgrade projectile count.
- Added explosion-radius affix behavior that creates small burst damage on non-burst weapons and strengthens burst staffs.
- Updated README and design notes with the expanded stage 2 affix set.
- Validation: ran Godot 4.6.1 headless for 5 seconds outside the sandbox with no script errors.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - Add weapon forms

- Added weapon forms for focused, scatter, piercing, and burst staffs.
- Added form descriptions to weapon comparison text and included form value in equipment score.
- Added player shooting support for form-based projectile count, spread, damage multiplier, pierce, and explosion damage.
- Added projectile piercing and small-area burst damage behavior.
- Updated README and design notes with the current weapon forms.
- Validation: ran Godot 4.6.1 headless for 5 seconds outside the sandbox with no script errors after fixing one type inference warning.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - Add mobility and critical affixes

- Added weapon affixes for movement speed and critical chance.
- Added player equipment stat application and removal for the new affixes.
- Added critical projectile damage rolls with stronger hit burst and damage color feedback.
- Updated README and design notes with the expanded affix set.
- Validation: ran Godot 4.6.1 headless for 5 seconds outside the sandbox with no script errors.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - Add equipment comparison choice

- Added a weapon pickup comparison flow that pauses combat before replacing equipment.
- Added current/new weapon comparison text with score and score delta.
- Added choices to equip the new weapon or keep the current weapon and salvage the new one for gold.
- Updated gameplay pause checks so enemies and projectiles stop during equipment choices.
- Updated README and design notes with the current equipment pickup flow.
- Validation: ran Godot 4.6.1 headless for 5 seconds outside the sandbox with no script errors; sandboxed Godot runs crashed at engine startup before validation.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - Add enemy archetypes

- Added enemy archetypes: normal, fast runner, tank, and ranged attacker.
- Added enemy projectile scene and script for ranged enemies.
- Added weighted enemy spawning with level-based unlocks.
- Updated README and design notes with the current enemy ecology.
- Validation: ran Godot 4.6.1 headless for 6 seconds with no script errors.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - Localize in-game text to Chinese

- Added a repository rule that all player-facing in-game text must use Simplified Chinese by default.
- Localized HUD labels, operation hints, upgrade titles/descriptions, pickup messages, equipment names, rarity names, affix labels, and game-over text.
- Kept internal ids, file names, signal names, and variable names in English.
- Validation: ran Godot 4.6.1 headless for 5 seconds with no script errors.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - Add enemy health bars

- Added enemy health bars that appear after enemies take damage.
- Updated enemy scene with a lightweight ProgressBar and health fill style.
- Updated enemy script to sync health bar max/value/visibility after damage.
- Updated README and design notes to reflect enemy health bar feedback.
- Validation: ran Godot 4.6.1 headless for 5 seconds with no script errors.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - 41d4209 - Tune combat feel and pacing

- Added projectile knockback against enemies.
- Added player knockback when hit by enemies.
- Added knockback recovery tuning for both player and enemies.
- Tuned enemy spawn distance and spawn interval scaling by player level.
- Added basic HUD control hint for playtesting.
- Updated README and design notes with current combat feedback and playtest focus points.
- Validation: ran Godot 4.6.1 headless for 5 seconds with no script errors.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - b1c8f0f - Add development push log

- Replaced the repository agent guide with a stable ASCII/English version to avoid terminal encoding issues.
- Added `docs/development-log.md` as the canonical record of successful GitHub pushes.
- Added the rule that every successful push must record commit hash, changes, validation, and push result.
- Backfilled previous successful push entries from local Git history and prior validation results.
- Validation: ran Godot 4.6.1 headless for 3 seconds with no script errors.
- Push result: first push attempt failed due to connection reset; second attempt pushed `main` to `origin/main` successfully.

## 2026-07-12 - a7afb46 - Add combat feedback pass

- Added player hit invulnerability and flicker feedback.
- Added damage numbers for player and enemy damage events.
- Added hit burst effects for projectile impact, player damage, enemy damage, and enemy death.
- Added reusable combat feedback scripts and effect scenes.
- Validation: ran Godot 4.6.1 headless for 5 seconds with no script errors.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - cc04764 - Constrain player to screen bounds

- Added screen boundary clamping to player movement.
- Updated project metadata to Godot 4.6 after opening the project in the editor.
- Added Godot script `.uid` files generated by the editor.
- Updated `.gitattributes` for `.gd.uid` files.
- Validation: ran Godot 4.6.1 headless for 3 seconds with no script errors.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - 3c1257a - Add basic equipment drops

- Added random weapon generation with Common, Magic, and Rare rarities.
- Added damage, max HP, and attack speed affixes.
- Added equipment pickup and automatic weapon equip behavior.
- Updated HUD to show current weapon and latest pickup message.
- Validation: ran Godot 4.6.1 headless for 5 seconds; fixed missing `EquipmentFactory` preload; second validation passed.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - 91004d0 - Add playable roguelite loop

- Added HUD for HP, level, XP, gold, and kills.
- Added enemy contact damage.
- Added XP gain and level-up choices.
- Added run-over state and simple end-of-run summary.
- Validation: ran Godot 4.6.1 headless for 3 seconds with no script errors.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - ffe4479 - Add repository line ending rules

- Added `.gitattributes` to enforce stable line endings for Godot text assets, scripts, docs, and binary assets.
- Validation: checked Git attributes for Godot and Markdown files.
- Push result: pushed as part of the repository history.

## 2026-07-12 - 24c1cc6 - Initial Godot rogueloot prototype

- Created the initial Godot project skeleton.
- Added player movement, enemy spawning, auto attack, projectile, loot drop, README, design notes, and repository guidelines.
- Validation: basic file and project structure inspection.
- Push result: pushed as part of the initial GitHub setup.
