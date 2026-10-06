# gopaint

A Godot editor addon for creating and editing 2D image assets and animations.
Other Godot users install it into their own projects to edit those projects' assets.

This repository is a Godot project used for development. Only `addons/gopaint/` ships to users.

## Layout

- `addons/gopaint/`: the addon that ships.
  - `plugin.cfg`, `plugin.gd`: the EditorPlugin. Adds a "GoPaint" main screen tab and opens selected `Texture2D` assets.
  - `core/`: no editor APIs, so tests run headless.
    - `image_ops.gd`: flood fill, brush stamp, line and rectangle drawing.
    - `history.gd`: undo and redo, stored as full image copies.
  - `ui/`: editor UI. The layout follows the GameMaker image editor.
    - `main_screen.gd`: toolbar at the top (new, save, undo, redo, zoom, grid), tool panel on the left, canvas on the right.
    - `tool_panel.gd`: tool buttons, brush size, colors for the left and right mouse buttons, palette.
    - `canvas_view.gd`: draws the image, checkerboard and grid. Turns mouse input into tool actions.
    - `new_image_dialog.gd`: `FileDialog` for a new PNG's path, with width and height fields.
- `addons/gdUnit4/`: the test framework (v6.2.1). Not shipped.
- `test/`: gdUnit4 test suites. The folder structure follows `addons/gopaint/`, for example `test/core/image_ops_test.gd`.
- `samples/`: test images for manual testing in the editor. Not shipped.
  - `quadrants_16.png`: four solid areas with a border.
  - `ring_32.png`: circle outline on a transparent background.
  - `checker_64.png`: 8 x 8 squares. Checks that fills do not cross diagonals.
  - `gradient_64.png`: every pixel has a different color.
  - `large_512.png`: large areas. Checks fill speed.
  - `bounce_strip_4x16.png`: four 16 x 16 animation frames in one strip.
  - `flying.png`: 256 x 64 RGBA image.
- `.github/workflows/tests.yml`: CI on Godot 4.5, 4.6 and 4.7.
- `.gitattributes`: uses `export-ignore` to keep everything except `addons/gopaint/` out of Asset Library downloads. Add new top-level files and folders to it.

## Commands

- Run all tests: `./run_tests.sh`. Set `GODOT_BIN` to use a different Godot binary.
- Run one suite: `./run_tests.sh -a res://test/core/image_ops_test.gd`
- Check that the editor loads the plugin without script errors: `godot --headless --editor --path . --quit`
- Open the editor with output in the terminal: `godot --editor --path . --verbose`

Each test run prints `Unable to connect to host '127.0.0.1:0'`. The gdUnit4 runner causes this, and it is not a failure.

To check the UI visually without the editor, write a `SceneTree` script outside the repo that adds `MainScreen.new()` to `root`, waits a few frames, and saves `root.get_texture().get_image()` as a PNG. Run it without `--headless`: `godot --path . --script /path/to/shot.gd`. Editor icons are not available there, so buttons show text.

## Conventions

- Support Godot 4.5 and newer. Do not use APIs added after 4.5 unless CI is updated.
- Do not use `class_name` in the addon. Global class names can clash with classes in users' projects. Load scripts with `preload("res://addons/gopaint/...")`.
- Every script in `addons/gopaint/` needs `@tool`, because it runs inside the editor.
- Keep pixel logic in `core/` and test it there. UI code in `ui/` calls into `core/`.
- The addon must not depend on any file outside `addons/gopaint/`.
- `_exit_tree()` in `plugin.gd` must remove every control the plugin adds. Test this by turning the plugin off and on in Project Settings → Plugins.
- Tests run with `--ignoreHeadlessMode`, so real input events do not work. To test input, create events and pass them to `_gui_input()`, as in `test/ui/canvas_view_test.gd`.
- UI code uses editor icons through `get_theme_icon(name, "EditorIcons")`, with a text fallback. Do not call `EditorInterface` in `ui/`, so UI tests run without the editor.
- Build UI in code in `_init()`. There are no `.tscn` scenes.
- `ui/` sends signals (for example `saved`) and `plugin.gd` makes the `EditorInterface` calls.
- Editor icon names checked to exist: `New`, `Save`, `Undo`, `Redo`, `Grid`, `Edit`, `Eraser`, `Bucket`, `ColorPick`, `Line`, `Rectangle`. No zoom icons were found, so zoom buttons use text.
- Tests that write files use `user://` and delete the files in `after_test()`.
- Commit the `.uid` and `.import` files that Godot creates.
- Use tabs for indentation in GDScript, the Godot default.

## Status

- Tools: pencil, eraser, fill, color picker, line, rectangle (outline or filled). Each mouse button has its own color.
- Drawing replaces pixels, including alpha. It does not blend. Images are converted to RGBA8 when opened.
- Selecting the open file again keeps unsaved edits. Selecting a different file or creating a new one discards them without a warning.
- New creates a blank transparent PNG (default 64 x 64) and opens it.
- Saving writes the PNG. `plugin.gd` then reimports it, or runs a filesystem scan for a new file, so Godot sees the change.
- Undo and redo use GoPaint's own history and toolbar buttons. Ctrl+Z goes to the editor's history, not GoPaint's.
- Not tried by hand in the editor yet: editor icons, the color picker popup, saving, and the scan that adds a new file to the FileSystem dock.
- Not done yet: keyboard shortcuts, `EditorUndoRedoManager`, resizing, a warning before unsaved changes are replaced, layers, animation frames (`SpriteFrames`).
