# Sprite Generator Deluxe

Enhanced Godot 4 pixel-sprite generator derived from the original MIT-licensed project by Deep-Fold. This fork adds palette customization, sprite-sheet exporting, responsive UI scaling, and quality-of-life fixes for HTML5 builds.

## ✨ Features

- **Procedural sprites** driven by cellular automata with symmetry controls and adjustable map size.
- **Rich palette customization** – choose from warm/cool/pastel/monochrome presets, tweak hue shift, saturation, and brightness, and lock palettes to seeds for reproducible looks.
- **Custom palettes** – load a palette file or paste hex codes/CSV/GIMP `.gpl` rows to drive sprite colors directly.
- **One-click exports** – grab a single PNG or generate a sprite strip with multiple animation phases.
- **Responsive interface** that centers the preview, scales on large monitors, and auto-stacks the settings panel on narrow windows.
- **HTML5-ready downloads** thanks to the bundled `HTML5FileExchange` plugin.

## 🚀 Getting started

### Requirements

- [Godot 4.2+](https://godotengine.org/) Standard or Mono edition.
- Export templates installed if you plan to build for Web.

### Run locally

1. Install Godot 4 and launch the editor.
2. Open this project folder via `Project Manager → Import`.
3. Run the main scene (`GUI/GUI.tscn`) or press <kbd>F5</kbd> to launch the generator.
4. Use the settings panel to tweak size, symmetry, outline, palette, and frame count.

### Controls

| Action | Input |
| --- | --- |
| Generate new sprite | `→` arrow / Click **Next** button |
| Go back to previous sprite | `←` arrow / Click **Previous** button |
| Toggle outline | Outline button |
| Export PNG | **Export PNG** button |
| Export sprite sheet | **Export Sprite Sheet** button |

### Palette controls

- **Colors**: number of distinct colors used in the scheme.
- **Palette**: select base mood (Random/Warm/Cool/Pastel/Monochrome).
- **Palette source**: view whether you're using the procedural generator or a custom upload; access **Load File**, **Paste**, or **Clear** controls.
- **Hue Shift**: adjust hue in degrees.
- **Saturation / Brightness**: fine-tune intensity/values (percent sliders).
- **Seed linked**: lock palette generation to the current sprite seed for consistent results.

### Importing a custom palette

You can override the procedural palette at any time:

1. Click **Load File** to choose a palette document (`.pal`, `.txt`, `.json`, `.gpl`, `.hex`). The parser accepts:
   - Hex colors with or without the `#` prefix (`#ff7700`, `ff7700ff`).
   - Comma/space separated RGB(A) values (`255,120,64`, `0.4 0.8 0.2 1`).
   - GIMP palette (`.gpl`) rows (`255 0 0 Red`).
2. Or click **Paste** to drop raw text (one color per line, comma, or space).
3. Press **Clear** to return to the generator controls. While a custom palette is active the mood/hue/saturation sliders are disabled so your uploaded colors stay untouched.

> **Note:** In the HTML5 export, browser sandboxes prevent direct file access, so use **Paste** to bring in palettes.

### Exporting for Web

1. Install Godot web export templates (`Editor → Manage Export Templates`).
2. Add a **Web** preset in `Project → Export`, keeping the default HTML shell.
3. Export – Godot will produce an `index.html`, `.wasm`, and `.pck`. A common pattern is `build/web/index.html`, which keeps generated bundles out of version control.
4. Serve locally for testing:

   ```bash
   cd build/web
   python3 -m http.server 8080
   ```

   Open `http://localhost:8080/` in a browser; the download buttons will trigger the HTML5 file exchange dialog.

### Deploying online

- Upload the web export bundle to GitHub Pages, itch.io, Netlify, or any static host.
- Ensure all files (HTML, WASM, PCK) stay together in the site root.

## 🧩 Repository structure

```
Generator/       # Core generation scripts (maps, colors, grouping, etc.)
GUI/             # UI scene, theme, textures, and controls
addons/          # HTML5 file exchange plugin for web downloads
export_presets/  # (Optional) export configuration files
build/           # (Ignored) optional folder for exported builds
```

## 🛠️ Troubleshooting

- **`godot4` command not found on macOS** – Godot’s GUI bundle isn’t on the system `PATH` by default. Either launch the editor directly from `/Applications`, or expose the CLI with a symlink:

   ```bash
   sudo ln -s /Applications/Godot.app/Contents/MacOS/Godot /usr/local/bin/godot4
   ```

   Adjust the path if you keep the app elsewhere (e.g., inside `~/Applications`). Once the link exists you can run `godot4 --version` or export from the terminal.

## 📝 License & attribution

- Original code & assets © Deep-Fold, released under the MIT License (see `LICENSE`).
- Add your name/company to commits or README if you distribute custom builds.

Enjoy generating endless sprites! Feel free to open issues or PRs with new palette ideas or export workflows.
