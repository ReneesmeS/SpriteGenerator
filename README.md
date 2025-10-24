# Sprite Generator Deluxe

Enhanced Godot 4 pixel-sprite generator derived from the original MIT-licensed project by Deep-Fold. This fork adds palette customization, sprite-sheet exporting, responsive UI scaling, and quality-of-life fixes for HTML5 builds.

## ✨ Features

- **Procedural sprites** driven by cellular automata with symmetry controls and adjustable map size.
- **Rich palette customization** – choose from warm/cool/pastel/monochrome presets, tweak hue shift, saturation, and brightness, and lock palettes to seeds for reproducible looks.
- **One-click exports** – grab a single PNG or generate a sprite strip with multiple animation phases.
- **Responsive interface** that centers the preview and scales cleanly on large monitors.
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
- **Hue Shift**: adjust hue in degrees.
- **Saturation / Brightness**: fine-tune intensity/values (percent sliders).
- **Seed linked**: lock palette generation to the current sprite seed for consistent results.

### Exporting for Web

1. Install Godot web export templates (`Editor → Manage Export Templates`).
2. Add a **Web** preset in `Project → Export`, keeping the default HTML shell.
3. Export – Godot will produce an `index.html`, `.wasm`, and `.pck` in your chosen folder.
4. Serve locally for testing:

   ```bash
   cd export/web
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
```

## 📝 License & attribution

- Original code & assets © Deep-Fold, released under the MIT License (see `LICENSE`).
- Add your name/company to commits or README if you distribute custom builds.

Enjoy generating endless sprites! Feel free to open issues or PRs with new palette ideas or export workflows.
