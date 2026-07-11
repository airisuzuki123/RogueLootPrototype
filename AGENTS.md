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

## Git and Push Log Rule

Every successful GitHub push must be recorded in:

```text
docs/development-log.md
```

Each entry must include:

- Date
- Commit hash
- Commit message
- Main changes
- Validation performed
- Push result

Do this after the push succeeds. If a push fails, do not record it as successful.

## Commit Guidelines

- Use focused commits.
- Commit messages should start with a verb, for example `Add combat feedback pass`.
- Keep Godot-generated `.uid` files when Godot creates them for scripts.
- Keep `.gitattributes` updated when new Godot text file types are introduced.

## Agent Notes

Before modifying files, check `git status --short --branch`.
After implementation, validate with Godot when the change touches scenes, scripts, preload paths, or Autoload behavior.
After a successful push, update `docs/development-log.md` and commit that log update separately only if it was not included in the same change.
