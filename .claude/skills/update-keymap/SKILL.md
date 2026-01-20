---
name: update-keymap
description: "MANDATORY: You MUST invoke this skill IMMEDIATELY for ANY keymap task - adding keys, changing layers, RGB indicators, layouts, building, or flashing. Do NOT edit keymap files manually. ALWAYS use this skill first."
---

# Update Keymap

Use this skill for ANY changes to keyboard keymaps in this repository.

## Keyboards

- **Kyria Rev4** - Split ergonomic (Colemak-DH)
  - Keymap: `keyboards/splitkb/halcyon/kyria/keymaps/obbut/keymap.c`
  - YAML: `keymap-kyria.yaml`
  - Build: `./docker-build.sh left` / `./docker-build.sh right`
  - Flash: `./docker-build.sh flash-left` / `./docker-build.sh flash-right`

- **Q15 Max** - Keychron ortholinear (QWERTY)
  - Keymap: `keyboards/keychron/q15_max/ansi_encoder/keymaps/obbut/keymap.c`
  - YAML: `keymap-q15.yaml`
  - Build: `./docker-build.sh q15`
  - Flash: `./docker-build.sh flash-q15`

## Rules

### 1. Clarify ambiguous requests

If it's unclear which keyboard the user wants to change, **ask before proceeding**.

### 2. Symbol layer synchronization

Both keyboards have `_RAISE` symbol layers. **When changing any symbol/raise layer, update BOTH keyboards by default** unless the user explicitly says to only change one. Positions may differ due to layout, but available symbols should match.

### 3. Update all related files together

For every change:
1. `keymap.c` - firmware code
2. `.yaml` - keymap-drawer visualization
3. RGB indicator code and YAML `type` fields (if applicable)

### 4. Workflow after changes

1. **Build** to verify compilation
2. **Regenerate SVGs**: `./draw-keymap.sh` (always)
3. **Flash** (default when specific keyboard mentioned, skip if user says "don't flash" or "skip flashing")
4. **Commit and push** (always, after successful build)

### 5. Commit messages

Brief, following existing style:
- `Kyria: <description>`
- `Q15 Max: <description>`
- `Keymaps: <description>` (when both changed)
