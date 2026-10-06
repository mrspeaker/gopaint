# gopaint

A Godot editor addon for creating and editing 2D image assets and animations.
Other Godot users install it into their own projects to edit those projects' assets.

This repository is a Godot project used for development. Only `addons/gopaint/` ships to users.

## Layout

- `addons/gopaint/`: the addon that ships.
  - `plugin.cfg`, `plugin.gd`: the EditorPlugin. Adds a "GoPaint" main screen tab and opens selected `Texture2D` assets.
  - `core/`: pixel operations on `Image` objects (for example `image_ops.gd`). No editor APIs, so tests run headless.
  - `ui/`: editor UI (for example `main_screen.gd`, the canvas).
- `addons/gdUnit4/`: the test framework (v6.2.1). Not shipped.
- `test/`: gdUnit4 test suites. The folder structure follows `addons/gopaint/`, for example `test/core/image_ops_test.gd`.
- `.github/workflows/tests.yml`: CI on Godot 4.5, 4.6 and 4.7.
- `.gitattributes`: uses `export-ignore` to keep everything except `addons/gopaint/` out of Asset Library downloads.

## Commands

- Run all tests: `./run_tests.sh`. Set `GODOT_BIN` to use a different Godot binary.
- Run one suite: `./run_tests.sh -a res://test/core/image_ops_test.gd`
- Check that the editor loads the plugin without script errors: `godot --headless --editor --path . --quit`
- Open the editor with output in the terminal: `godot --editor --path . --verbose`

Each test run prints `Unable to connect to host '127.0.0.1:0'`. The gdUnit4 runner causes this, and it is not a failure.

## Conventions

- Support Godot 4.5 and newer. Do not use APIs added after 4.5 unless CI is updated.
- Do not use `class_name` in the addon. Global class names can clash with classes in users' projects. Load scripts with `preload("res://addons/gopaint/...")`.
- Every script in `addons/gopaint/` needs `@tool`, because it runs inside the editor.
- Keep pixel logic in `core/` and test it there. UI code in `ui/` calls into `core/`.
- The addon must not depend on any file outside `addons/gopaint/`.
- `_exit_tree()` in `plugin.gd` must remove every control the plugin adds. Test this by turning the plugin off and on in Project Settings → Plugins.
- Tests run with `--ignoreHeadlessMode`, so input events do not work in tests. Tests that need mouse input need a non-headless run.
- Use tabs for indentation in GDScript, the Godot default.

## Status

- The canvas shows the selected texture. A click flood-fills an in-memory copy of the image.
- Not done yet: saving to disk, undo/redo with `EditorUndoRedoManager`, layers, animation (`SpriteFrames`).
- When saving is added, call `EditorInterface.get_resource_filesystem().update_file()` or `reimport_files()` after `Image.save_png()`, so Godot sees the change.
