# Development Changelog & Task Tracker

This document tracks all modifications, additions, deletions, and pending tasks for this development branch of Effie OS / Omarchy.

---

## 1. Activity Log

### [2026-08-26] Workspace Switcher Dispatch Reliability, Desktop Entry Icon Matching & Preview Polish
- **Author**: Yurinero & Antigravity (Google DeepMind)
- **Summary**: Resolved workspace switching dispatch by migrating to Hyprland's Lua focus dispatcher (`hl.dsp.focus`), integrated intelligent `.desktop` entry matching (`DesktopEntries.applications`) for reliable app icon resolution, normalized `file://` URL schemes, and expanded workspace preview card dimensions (`145×120px` tiles, `36×36px` icon badges) for enhanced visual clarity.
- **Modified Files**:
  - [`shell/plugins/workspace-switcher/WorkspaceSwitcher.qml`](file:///home/yurinero/Projects/effie-os/shell/plugins/workspace-switcher/WorkspaceSwitcher.qml): Implemented `findDesktopIcon`, Lua `hl.dsp.focus` dispatcher, `Util.fileUrl` resolution, and enlarged card geometry.
  - [`default/hypr/bindings/tiling.lua`](file:///home/yurinero/Projects/effie-os/default/hypr/bindings/tiling.lua): Bound `ALT + TAB` and `ALT + SHIFT + TAB` to `omarchy.workspace-switcher`.
  - [`test/shell.d/workspace-switcher-test.sh`](file:///home/yurinero/Projects/effie-os/test/shell.d/workspace-switcher-test.sh): Added `ALT + TAB` binding assertions.

### [2026-08-26] App Grid Category Overflow Fix & Navigation Arrows
- **Author**: Yurinero & Antigravity (Google DeepMind)
- **Summary**: Resolved category pill horizontal overflow in `omarchy.app-grid` by wrapping category buttons in a smooth horizontal `Flickable` and adding left/right navigation arrow buttons (`‹` / `›`) that appear dynamically when content overflows.
- **Modified Files**:
  - [`shell/plugins/app-grid/AppGrid.qml`](file:///home/yurinero/Projects/effie-os/shell/plugins/app-grid/AppGrid.qml): Replaced rigid `Row` with scrollable `Flickable` and dynamic left/right arrow step-scroll buttons.

### [2026-08-26] Game Development Category & Lazy Installers
- **Author**: Yurinero & Antigravity (Google DeepMind)
- **Summary**: Added a dedicated **Game Development** section across the desktop menu and Application Grid. Added official Arch package installer for Godot Engine and custom web app lazy installer/uninstaller for Itch.io.
- **Added Files**:
  - [`bin/omarchy-install-game-development-itch`](file:///home/yurinero/Projects/effie-os/bin/omarchy-install-game-development-itch): Lazy installer for Itch.io web app launcher and icon.
  - [`bin/omarchy-remove-game-development-itch`](file:///home/yurinero/Projects/effie-os/bin/omarchy-remove-game-development-itch): Uninstaller for Itch.io web app launcher.
- **Modified Files**:
  - [`default/omarchy/omarchy-menu.jsonc`](file:///home/yurinero/Projects/effie-os/default/omarchy/omarchy-menu.jsonc): Added `install.game-development` (Godot & Itch.io) and `remove.game-development`.
  - [`shell/plugins/app-grid/AppCategories.js`](file:///home/yurinero/Projects/effie-os/shell/plugins/app-grid/AppCategories.js): Added `game-development` category (``), keywords, and classification heuristics.
  - [`test/shell.d/app-grid-test.sh`](file:///home/yurinero/Projects/effie-os/test/shell.d/app-grid-test.sh) & [`test/shell.d/menu-test.sh`](file:///home/yurinero/Projects/effie-os/test/shell.d/menu-test.sh): Added test assertions.

### [2026-08-26] Effie Dark Default Theme & Plymouth/SDDM Boot Integration
- **Author**: Yurinero & Antigravity (Google DeepMind)
- **Summary**: Integrated "Effie Dark" (`#050516` background, `#E8AB76` foreground, `#8971a2` accent) as the default desktop, boot splash (Plymouth), and login manager (SDDM) theme. Shipped theme definitions, unlock assets, and setup hooks.
- **Added Files**:
  - `themes/effie-dark/`: Complete theme palette (`colors.toml`), lockscreen configuration (`shell.lock.toml`), unlock assets (`unlock.png`, `preview-unlock.png`), and editor definitions.
- **Modified Files**:
  - [`default/plymouth/omarchy.script`](file:///home/yurinero/Projects/effie-os/default/plymouth/omarchy.script): Updated default background color to `#050516`.
  - [`default/sddm/omarchy/Main.qml`](file:///home/yurinero/Projects/effie-os/default/sddm/omarchy/Main.qml): Updated default background color to `#050516`.
  - `default/plymouth/` & `default/sddm/omarchy/`: Updated logo and tinted UI assets with Effie Dark palette.
  - [`install/user/theme.sh`](file:///home/yurinero/Projects/effie-os/install/user/theme.sh) & [`install/login/sddm.sh`](file:///home/yurinero/Projects/effie-os/install/login/sddm.sh): Configured initial default theme seeding and Plymouth setup hooks.
  - [`migrations/1787481315.sh`](file:///home/yurinero/Projects/effie-os/migrations/1787481315.sh): Seeded initial default theme to Effie Dark.

### [2026-08-26] Superfile Theming Pipeline Integration
- **Author**: Yurinero & Antigravity (Google DeepMind)
- **Summary**: Added Superfile theme template (`superfile.toml.tpl`) to Omarchy's automated theming pipeline, preconfigured user configuration directory (`config/superfile/`), added active symlink hooks, and created versioned migration.
- **Added Files**:
  - [`default/themed/superfile.toml.tpl`](file:///home/yurinero/Projects/effie-os/default/themed/superfile.toml.tpl): Superfile TOML color template mapped to Omarchy palette tokens.
  - [`config/superfile/config.toml`](file:///home/yurinero/Projects/effie-os/config/superfile/config.toml): Default configuration referencing `theme = "omarchy"`.
  - [`migrations/1787706460.sh`](file:///home/yurinero/Projects/effie-os/migrations/1787706460.sh): User migration linking `~/.config/superfile/theme/omarchy.toml` to current theme.
- **Modified Files**:
  - [`install/user/theme.sh`](file:///home/yurinero/Projects/effie-os/install/user/theme.sh): Added Superfile theme directory and active symlink creation.
- **Author**: Yurinero & Antigravity (Google DeepMind)
- **Summary**: Enhanced the packaging pipeline (`packaging/build-packages.sh`) to automatically compile custom packages (`photogimp`, `photoinkscape`, `photokrita`) from external `effie-pkgs`, updated ISO profile auto-inclusion (`scripts/build-iso.sh`), added preinstall package definitions, and documented planned roadmap features in `README.md`.
- **Modified Files**:
  - [`packaging/build-packages.sh`](file:///home/yurinero/Projects/effie-os/packaging/build-packages.sh): Added `build_external_pkg` support for building packages from `../effie-pkgs/pkgbuilds/`.
  - [`scripts/build-iso.sh`](file:///home/yurinero/Projects/effie-os/scripts/build-iso.sh): Added dynamic inclusion of `install/omarchy-base.packages` to ISO package profile.
  - [`install/omarchy-base.packages`](file:///home/yurinero/Projects/effie-os/install/omarchy-base.packages): Added `photogimp`, `photoinkscape`, `photokrita`.
  - [`bin/omarchy-install-preinstalls`](file:///home/yurinero/Projects/effie-os/bin/omarchy-install-preinstalls) & [`bin/omarchy-remove-preinstalls`](file:///home/yurinero/Projects/effie-os/bin/omarchy-remove-preinstalls): Added new preinstalled package entries.
  - [`README.md`](file:///home/yurinero/Projects/effie-os/README.md): Added roadmap and planned additions.
- **Deleted Files**: None

### [2026-08-26] Workspace & Virtual Desktop Switcher Plugin
- **Author**: Antigravity Assistant & Development Team
- **Summary**: Implemented a floating macOS/Windows-style Workspace Switcher overlay (`omarchy.workspace-switcher`) displaying all active workspaces, focused indicator pills, and live application icon strips with keyboard cycling (`ALT + SPACE` / `SUPER + TAB` / Arrow keys / `1`..`9`) and mouse activation.
- **Added Files**:
  - [`shell/plugins/workspace-switcher/manifest.json`](file:///home/yurinero/Projects/effie-os/shell/plugins/workspace-switcher/manifest.json): Plugin manifest declaring `omarchy.workspace-switcher` overlay.
  - [`shell/plugins/workspace-switcher/WorkspaceSwitcher.qml`](file:///home/yurinero/Projects/effie-os/shell/plugins/workspace-switcher/WorkspaceSwitcher.qml): Graphical floating overlay with live Hyprland workspace cards and toplevel app icons.
  - [`test/shell.d/workspace-switcher-test.sh`](file:///home/yurinero/Projects/effie-os/test/shell.d/workspace-switcher-test.sh): Automated test suite for plugin registration, lifecycle, and keybindings.
- **Modified Files**:
  - [`default/hypr/bindings/tiling.lua`](file:///home/yurinero/Projects/effie-os/default/hypr/bindings/tiling.lua): Bound `ALT + SPACE` and `SUPER + TAB` to toggle `omarchy.workspace-switcher`.
- **Deleted Files**: None

### [2026-08-26] Installation Branding & Fastfetch ASCII Wordmark
- **Author**: Antigravity Assistant & Development Team
- **Summary**: Applied the "powered by Omarchy" subtitle branding specifically to the installer/login screens (`default/plymouth/logo.png`, `default/sddm/omarchy/logo.png`) in Effie green (`#a8cd76`) and rendered a pixel-aligned Unicode half-block ASCII version for `fastfetch` and the system about window (`logo.txt`, `icon.txt`).
- **Modified Files**:
  - [`default/plymouth/logo.png`](file:///home/yurinero/Projects/effie-os/default/plymouth/logo.png): Updated boot splash logo with subtitle.
  - [`default/sddm/omarchy/logo.png`](file:///home/yurinero/Projects/effie-os/default/sddm/omarchy/logo.png): Updated login screen logo with subtitle.
  - [`logo.txt`](file:///home/yurinero/Projects/effie-os/logo.txt) & [`icon.txt`](file:///home/yurinero/Projects/effie-os/icon.txt): Updated fastfetch and screensaver ASCII art.
- **Deleted Files**: None

### [2026-08-26] Kate Advanced Text Editor Lazy Installer
- **Author**: Antigravity Assistant & Development Team
- **Summary**: Added Kate as an on-demand lazy load editor option under **Install > Editor** executing `omarchy-install-and-launch Kate kate org.kde.kate` with floating terminal presentation and automatic launch on completion.
- **Modified Files**:
  - [`default/omarchy/omarchy-menu.jsonc`](file:///home/yurinero/Projects/effie-os/default/omarchy/omarchy-menu.jsonc): Added Kate to `install.editor`.
  - [`shell/plugins/app-grid/AppCategories.js`](file:///home/yurinero/Projects/effie-os/shell/plugins/app-grid/AppCategories.js): Added Kate & KWrite to development heuristics.
- **Deleted Files**: None

### [2026-08-26] JetBrains Toolbox Lazy Installer & Menu Integration
- **Author**: Antigravity Assistant & Development Team
- **Summary**: Implemented on-demand lazy installer for JetBrains Toolbox with local archive caching (`~/Downloads/jetbrains-toolbox-*.tar.gz`), automatic official download fallback, `.desktop` launcher creation, SVG icon registration, and menu integration under **Install > Editor** and **Install > Development**.
- **Added Files**:
  - [`bin/omarchy-install-jetbrains-toolbox`](file:///home/yurinero/Projects/effie-os/bin/omarchy-install-jetbrains-toolbox): Automated JetBrains Toolbox download, extraction, path linking, and launch script.
- **Modified Files**:
  - [`default/omarchy/omarchy-menu.jsonc`](file:///home/yurinero/Projects/effie-os/default/omarchy/omarchy-menu.jsonc): Added JetBrains Toolbox menu items under `install.editor` and `install.development`.
  - [`shell/plugins/app-grid/AppCategories.js`](file:///home/yurinero/Projects/effie-os/shell/plugins/app-grid/AppCategories.js): Added JetBrains ecosystem keywords to development categorization.
- **Deleted Files**: None

### [2026-08-26] Project Contributors & Co-Authorship Setup
- **Author**: Yurinero & Antigravity (Google DeepMind)
- **Summary**: Established official project co-authorship transparency: added `CONTRIBUTORS.md`, updated `README.md` acknowledgments, configured Git commit template with `Co-authored-by: Antigravity <antigravity@google.com>` trailer.
- **Added Files**:
  - [`CONTRIBUTORS.md`](file:///home/yurinero/Projects/effie-os/CONTRIBUTORS.md): Project contributor roll and authorship documentation.
- **Modified Files**:
  - [`README.md`](file:///home/yurinero/Projects/effie-os/README.md): Added Acknowledgments section.
- **Deleted Files**: None

### [2026-08-26] App Grid Categorization & WebApp XDG Metadata Fix
- **Author**: Antigravity Assistant & Development Team
- **Summary**: Added standard XDG `Categories=` metadata across all web application `.desktop` files, enhanced `AppCategories.js` URL/execution pattern matching for single-letter and web targets (`X`, `YouTube`, `Basecamp`, `Discord`), and updated test assertions.
- **Modified Files**:
  - `applications/*.desktop`: Added explicit XDG category classifications.
  - [`shell/plugins/app-grid/AppCategories.js`](file:///home/yurinero/Projects/effie-os/shell/plugins/app-grid/AppCategories.js): Added URL pattern recognition and explicit naming heuristics.
  - [`test/shell.d/app-grid-test.sh`](file:///home/yurinero/Projects/effie-os/test/shell.d/app-grid-test.sh): Added category tests for web apps.
- **Deleted Files**: None

### [2026-08-25] Traditional Application Viewer & Grid Launcher
- **Author**: Antigravity Assistant & Development Team
- **Summary**: Implemented a modern, graphical Application Viewer & Launcher overlay (`omarchy.app-grid`) in the Quickshell desktop environment with category filtering, real-time search, smooth keyboard navigation, top-bar launcher widget, and `SUPER + A` keybinding.
- **Added Files**:
  - [`shell/plugins/app-grid/manifest.json`](file:///home/yurinero/Projects/effie-os/shell/plugins/app-grid/manifest.json): Plugin manifest declaring `omarchy.app-grid` overlay and bar-widget entry points.
  - [`shell/plugins/app-grid/AppCategories.js`](file:///home/yurinero/Projects/effie-os/shell/plugins/app-grid/AppCategories.js): Category mapping, metadata categorization, search filtering, and alphabetical sorting logic.
  - [`shell/plugins/app-grid/AppGrid.qml`](file:///home/yurinero/Projects/effie-os/shell/plugins/app-grid/AppGrid.qml): Graphical grid viewer component with category pills, live search bar, rich application cards, and keyboard/mouse interaction.
  - [`shell/plugins/app-grid/BarWidget.qml`](file:///home/yurinero/Projects/effie-os/shell/plugins/app-grid/BarWidget.qml): Top-bar launcher button widget.
  - [`test/shell.d/app-grid-test.sh`](file:///home/yurinero/Projects/effie-os/test/shell.d/app-grid-test.sh): Automated test suite covering plugin registration, categorization, filtering, and sorting.
- **Modified Files**:
  - [`default/hypr/bindings/applications.lua`](file:///home/yurinero/Projects/effie-os/default/hypr/bindings/applications.lua): Bound `SUPER + A` to toggle `omarchy.app-grid`.
- **Deleted Files**: None

### [2026-08-25] Superfile TUI File Manager Integration
- **Author**: Antigravity Assistant & Development Team
- **Summary**: Added Superfile (`spf`) as a preinstalled base package and alternative terminal file manager, configured its `.desktop` entry, bundled its official SVG icon, mapped a quick access keybinding, and added a documentation link to its hotkey guide in the root menu.
- **Added Files**:
  - [`applications/Superfile.desktop`](file:///home/yurinero/Projects/effie-os/applications/Superfile.desktop): Desktop launcher entry for Superfile executing `xdg-terminal-exec --app-id=TUI.tile -e spf`.
  - [`applications/icons/superfile.svg`](file:///home/yurinero/Projects/effie-os/applications/icons/superfile.svg): Official vector app icon for Superfile.
- **Modified Files**:
  - [`install/omarchy-base.packages`](file:///home/yurinero/Projects/effie-os/install/omarchy-base.packages): Added `superfile` to base packages.
  - [`default/hypr/bindings/applications.lua`](file:///home/yurinero/Projects/effie-os/default/hypr/bindings/applications.lua): Bound `SUPER + SHIFT + ALT + F` to launch/focus Superfile.
  - [`default/omarchy/omarchy-menu.jsonc`](file:///home/yurinero/Projects/effie-os/default/omarchy/omarchy-menu.jsonc): Added `learn.superfile` entry linking to `https://superfile.dev/list/hotkey-list/`.
- **Deleted Files**: None

### [2026-08-25] Effie OS Branding & Logo Overhaul
- **Author**: Antigravity Assistant & Development Team
- **Summary**: Replaced the legacy Omarchy logo assets with the new Effie OS wordmark across vector, terminal ASCII art, default boot/login graphics, and all theme palettes.
- **Added Files**: None
- **Modified Files**:
  - [`logo.svg`](file:///home/yurinero/Projects/effie-os/logo.svg): Replaced root vector logo with the Effie wordmark SVG.
  - [`logo.txt`](file:///home/yurinero/Projects/effie-os/logo.txt): Replaced terminal ASCII art with pixel-aligned Unicode half-block art of the `effie` wordmark.
  - [`default/plymouth/logo.png`](file:///home/yurinero/Projects/effie-os/default/plymouth/logo.png): Updated default Plymouth boot splash logo in Effie green (`#a8cd76`).
  - [`default/sddm/omarchy/logo.png`](file:///home/yurinero/Projects/effie-os/default/sddm/omarchy/logo.png): Updated default SDDM login screen logo in Effie green (`#a8cd76`).
  - `themes/*/unlock.png`: Generated color-matched unlock logos for all 22 themes matching their respective `colors.toml` palette definitions.
  - `themes/*/preview-unlock.png`: Regenerated all 22 1920x1080 Plymouth switcher mockups to reflect the new Effie logo and centered composition.
- **Deleted Files**: None

### [2026-08-25] Branch Initialization & Mapping
- **Author**: Antigravity Assistant & Development Team
- **Summary**: Initialized new development branch `luna` branched from `quattro`. Explored repository architecture, packaging structure, build and ISO creation pipeline, user configuration seeding, manifest locations, and branding assets.
- **Added Files**:
  - [`REPO_MAP.md`](file:///home/yurinero/Projects/effie-os/REPO_MAP.md): Comprehensive repository architectural map, package breakdown, install/provisioning lifecycle, theming workflow, and extension points.
  - [`CHANGELOG_DEV.md`](file:///home/yurinero/Projects/effie-os/CHANGELOG_DEV.md): Development change log and active task tracking document.
- **Modified Files**: None
- **Deleted Files**: None

---

## 2. Inventory of Changes by Component

### Documentation & Architecture
| File | Status | Description |
|---|---|---|
| [`REPO_MAP.md`](file:///home/yurinero/Projects/effie-os/REPO_MAP.md) | Added | Full repository map and integration guide |
| [`CHANGELOG_DEV.md`](file:///home/yurinero/Projects/effie-os/CHANGELOG_DEV.md) | Added | Development change log and task tracker |

### Branding & Assets
| File | Status | Description |
|---|---|---|
| [`logo.svg`](file:///home/yurinero/Projects/effie-os/logo.svg) | Modified | Replaced root vector logo with Effie wordmark |
| [`logo.txt`](file:///home/yurinero/Projects/effie-os/logo.txt) | Modified | Replaced terminal ASCII art with Unicode half-block art |
| [`default/plymouth/logo.png`](file:///home/yurinero/Projects/effie-os/default/plymouth/logo.png) | Modified | Default Plymouth boot splash logo |
| [`default/sddm/omarchy/logo.png`](file:///home/yurinero/Projects/effie-os/default/sddm/omarchy/logo.png) | Modified | Default SDDM login screen logo |
| `themes/*/unlock.png` | Modified | Generated color-matched unlock logos for all 22 themes |
| `themes/*/preview-unlock.png` | Modified | Regenerated Plymouth switcher mockups for all 22 themes |
| [`applications/icons/superfile.svg`](file:///home/yurinero/Projects/effie-os/applications/icons/superfile.svg) | Added | Official Superfile vector app icon |

### Packages & Manifests
| File | Status | Description |
|---|---|---|
| [`install/omarchy-base.packages`](file:///home/yurinero/Projects/effie-os/install/omarchy-base.packages) | Modified | Added `superfile` package |

### System & User Configuration
*(No changes yet)*

### Desktop Shell & UI
| File | Status | Description |
|---|---|---|
| [`applications/Superfile.desktop`](file:///home/yurinero/Projects/effie-os/applications/Superfile.desktop) | Added | Desktop application launcher for Superfile |
| [`default/hypr/bindings/applications.lua`](file:///home/yurinero/Projects/effie-os/default/hypr/bindings/applications.lua) | Modified | Added `SUPER + A` for App Grid and `SUPER + SHIFT + ALT + F` for Superfile |
| [`default/omarchy/omarchy-menu.jsonc`](file:///home/yurinero/Projects/effie-os/default/omarchy/omarchy-menu.jsonc) | Modified | Added Superfile hotkeys guide link under Learn menu |
| [`shell/plugins/app-grid/manifest.json`](file:///home/yurinero/Projects/effie-os/shell/plugins/app-grid/manifest.json) | Added | Application Grid plugin manifest |
| [`shell/plugins/app-grid/AppCategories.js`](file:///home/yurinero/Projects/effie-os/shell/plugins/app-grid/AppCategories.js) | Added | Application categorization and search filter module |
| [`shell/plugins/app-grid/AppGrid.qml`](file:///home/yurinero/Projects/effie-os/shell/plugins/app-grid/AppGrid.qml) | Added | Graphical application launcher overlay |
| [`shell/plugins/app-grid/BarWidget.qml`](file:///home/yurinero/Projects/effie-os/shell/plugins/app-grid/BarWidget.qml) | Added | Top-bar launcher icon button widget |
| [`test/shell.d/app-grid-test.sh`](file:///home/yurinero/Projects/effie-os/test/shell.d/app-grid-test.sh) | Added | Automated test suite for App Grid plugin |

### CLI & Tooling
*(No changes yet)*

---

## 3. Pending & Planned Tasks

### Backlog
- [x] Update core branding and logo assets (SVG, ASCII art, Plymouth splash, SDDM, theme unlock logos).
- [x] Add Superfile terminal file manager (base package, desktop launcher, app icon, keybinding, hotkey documentation link).
- [x] Implement Traditional Application Viewer & Grid Launcher plugin (`omarchy.app-grid`, categories, search, top-bar button, `SUPER + A`).
- [ ] Define wallpaper sets and default background imagery for Effie OS.
- [ ] Review default desktop configurations in [`config/`](file:///home/yurinero/Projects/effie-os/config) for Effie OS specific presets.
- [ ] Review and adjust default themes in [`themes/`](file:///home/yurinero/Projects/effie-os/themes) and templates in [`default/themed/`](file:///home/yurinero/Projects/effie-os/default/themed).
- [ ] Verify test suite passes with `./test/all` (or `./test/cli` and `./test/shell`).

---

## 4. Maintenance Guidelines

When working on this branch:
1. **Atomic Updates**: Log new changes under the **Activity Log** section with date, modified components, and rationale.
2. **File Inventory**: Update the **Inventory of Changes by Component** table whenever files are created, modified, or deleted.
3. **Task Tracking**: Move items in **Pending & Planned Tasks** to completed (`[x]`) as features are implemented and tested.
4. **Style Consistency**: Use clickable markdown file links with `file:///` scheme, two-space indentation, and full lines without artificial wrapping.
