# Development Log

This file records successful GitHub pushes for the project.

## 2026-07-12 - Add inventory slot filters

- Added backpack filter buttons for all equipment, weapons, armor, and accessories.
- Kept backpack sorting unchanged while making the visible list and selection respect the active filter.
- Updated empty-state text for filtered backpack views.
- Updated README and design notes with the current backpack filtering behavior.
- Validation: ran `git diff --check` and Godot 4.6.1 headless for 5 seconds outside the sandbox with no script errors before committing.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - Add weapon form upgrade specializations

- Added upgrade choices that can appear based on the currently equipped weapon form.
- Added focused, scatter, piercing, and burst specialization effects for damage, projectile count, pierce, and explosion radius.
- Kept specialization effects fixed after selection so later weapon swaps do not remove already-earned upgrades.
- Updated README and design notes with the current upgrade and weapon-form linkage.
- Validation: ran `git diff --check` and Godot 4.6.1 headless for 5 seconds outside the sandbox with no script errors before committing.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - Add sustain and gold affixes

- Added life-steal and gold-gain equipment affixes with slot-specific roll pools.
- Added player life-steal handling for projectile and explosion hits.
- Added player gold-gain handling for gold pickups and equipment salvage rewards.
- Updated equipment scoring, comparison summaries, and recommendation text to account for the new affixes.
- Updated README and design notes with the current sustain and economy affix behavior.
- Validation: ran `git diff --check` and Godot 4.6.1 headless for 5 seconds outside the sandbox; first Godot run caught a type inference error in the new life-steal calculation, second run passed after fixing it.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - Add multi-slot equipment

- Added weapon, armor, and accessory equipment slots with slot-specific affix pools.
- Changed equipment drops to roll across the supported slot types instead of only weapons.
- Updated equipped state to track one item per slot and return replaced items to the backpack.
- Updated player equipment application so only weapon replacements change weapon form while all slots can apply affix stats.
- Updated the backpack and HUD to show the full loadout and compare selected equipment against the currently equipped item in the same slot.
- Updated README and design notes with the current multi-slot equipment flow.
- Validation: ran `git diff --check` and Godot 4.6.1 headless for 5 seconds outside the sandbox with no script errors before committing.
- Push result: first push attempt failed due to connection reset; second attempt pushed `main` to `origin/main` successfully.

## 2026-07-12 - Improve inventory readability

- Added recommendation text for selected backpack equipment.
- Improved backpack list entries with rarity color, form, level, score, and score delta.
- Reworked backpack details to show current and selected weapons side by side with a focused change summary.
- Added `Esc` as a backpack close shortcut.
- Updated README and design notes with the improved backpack interaction flow.
- Validation: ran Godot 4.6.1 headless for 5 seconds outside the sandbox with no script errors before committing.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - Add inventory equipment flow

- Changed weapon pickup so equipment goes into a backpack instead of pausing immediately.
- Added a backpack panel opened with `B`; combat pauses only while the backpack is open.
- Added backpack sorting by rarity, equipment level, and score.
- Added backpack equipment and salvage actions, returning the old equipped weapon to the backpack when replaced.
- Added equipment level display and updated README/design notes for the new pickup flow.
- Updated agent notes to require validation before commits.
- Validation: ran Godot 4.6.1 headless for 5 seconds outside the sandbox with no script errors before committing.
- Push result: first push attempt timed out; second attempt pushed `main` to `origin/main` successfully.

## 2026-07-12 - Tune equipment economy

- Added rarity-based salvage values that also scale with equipment score.
- Centralized salvage value calculation in `EquipmentFactory`.
- Added level-scaled weapon drop chance and gold drop amount tuning.
- Updated README and design notes with the current drop and economy rules.
- Validation: ran Godot 4.6.1 headless for 5 seconds outside the sandbox with no script errors before committing.
- Push result: pushed `main` to `origin/main` successfully.

## 2026-07-12 - Add equipment comparison summary

- Added a core-change summary to weapon comparison, including form, score, damage, projectile count, pierce, burst radius, attack speed, critical chance, movement speed, and max health deltas.
- Updated the equipment pickup panel to show the richer comparison summary.
- Updated README and design notes with the improved comparison flow.
- Validation: ran Godot 4.6.1 headless for 5 seconds outside the sandbox with no script errors before committing.
- Push result: pushed `main` to `origin/main` successfully.

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
