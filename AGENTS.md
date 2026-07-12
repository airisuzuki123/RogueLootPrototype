# Repository Guidelines

## Project Structure

This is a Godot 4.6 roguelite loot prototype.

- `scenes/` stores Godot scenes.
- `scripts/core/` stores global managers and shared gameplay systems.
- `scripts/entities/` stores player, enemy, projectile, and combat entity logic.
- `scripts/items/` stores loot, equipment, and item generation logic.
- `scripts/effects/` stores lightweight combat feedback scripts.
- `docs/` stores design notes, reference analysis, and development logs.

Keep gameplay systems small and explicit. Avoid mixing combat, UI, loot, and save/progression logic in the same script unless the feature is still a temporary prototype.

## Development and Validation

Open the project with Godot 4.6.x:

- Project file: `project.godot`
- Main scene: `scenes/main.tscn`

Command-line validation on this machine:

```powershell
& "C:\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe" --headless --path "D:\CODEX\RogueLootPrototype" --quit-after 5
```

Use this validation after gameplay script changes when possible.

## Coding Style

- Use GDScript with Godot default indentation.
- Use snake_case for file names, functions, variables, and scene paths.
- Use PascalCase for node names and class names where Godot convention expects it.
- Prefer data dictionaries only for prototype-stage content; promote them to Resources or typed scripts when the structure stabilizes.

## In-Game Text Language

All player-facing in-game text must be Simplified Chinese by default. This includes HUD labels, upgrade names/descriptions, equipment names, rarity names, affix labels, pickup messages, game-over text, button labels, tutorial text, and combat prompts.

Internal ids, file names, signal names, variable names, and commit messages may remain English.

## Git and Push Log Rule

Record successful GitHub pushes for substantive work in:

```text
docs/development-log.md
```

Record gameplay, system, content, validation, tooling, or documentation changes that materially affect the project. Do not create recursive log-only entries.

Each recorded entry should include:

- Date
- Commit message
- Main changes
- Validation performed
- Push result

When the log update is included in the same commit as the substantive change, do not try to record that commit's own hash inside the same commit. This changes the commit content and therefore changes the hash. In that case, record the commit message in the log and report the final hash in the assistant's final response after the push succeeds.

Preferred workflow:

1. Implement the change.
2. Validate it.
3. Update `docs/development-log.md` in the same commit, before pushing.
4. Push once.

If a push fails, do not record it as successful. If a retry succeeds, note the failed attempt inside the same substantive entry.

Do not add development-log entries for commits whose only purpose is updating `docs/development-log.md` or generated `.uid` bookkeeping.

## Commit Guidelines

- Use focused commits.
- Commit messages should start with a verb, for example `Add combat feedback pass`.
- Keep Godot-generated `.uid` files when Godot creates them for scripts.
- Keep `.gitattributes` updated when new Godot text file types are introduced.

## Agent Notes

Before modifying files, check `git status --short --branch`.
Before committing, validate the commit contents. For Godot gameplay, scene, script, preload path, or Autoload changes, run the project headless validation and commit only after it passes.
For future work, include the development-log update in the same commit as the substantive change whenever practical. Avoid separate log-only commits unless correcting a mistake in the log.
