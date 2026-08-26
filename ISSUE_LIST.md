# Effie OS - Test Build Issue Tracker & Action Plan

This document tracks observations, regressions, and tasks from test builds. Each issue includes diagnosis, updated findings, and actionable steps.

---

## Issue Summary Matrix

| ID | Component | Issue | Severity | Status |
|---|---|---|---|---|
| **ISSUE-01** | Theming / Boot | Effie Dark splash/login on install & live media | Medium | 📋 TODO (Filed for `effie-iso` pipeline) |
| **ISSUE-02** | Hyprland / Keybinds | `ALT + TAB` fails to summon Workspace Switcher | High | 🎯 Active Focus / In Progress |
| **ISSUE-03** | Workspace Switcher | Overlay closes on Enter/Click/NumKey without switching workspace | High | 🎯 Active Focus / In Progress |
| **ISSUE-04** | Workspace Switcher | Window app icons missing / fallback glyphs rendered | Medium | 🎯 Active Focus / In Progress |
| **ISSUE-05** | App Grid Plugin | Category pills navigation: overflow & navigation buttons | Low | ✅ Completed (Satisfactory) |

---

## Detailed Breakdown & Current Status

### 🎨 ISSUE-01: Effie Dark Theme Missing During Boot & Login
- **Current Status**: 📋 TODO (Disregarded for current sprint, filed for `effie-iso` review).
- **Findings & Actions**:
  - Boot logo colors were successfully updated in `default/plymouth/` and `default/sddm/omarchy/`.
  - The live installer ISO environment and bootloader graphics are generated within the `effie-iso` build pipeline. Further adjustments will be addressed when updating the ISO generation configuration.

---

### 🎯 Workspace Switcher Suite (ISSUE-02, ISSUE-03, ISSUE-04) — Current Focus

#### ⌨️ ISSUE-02: `ALT + TAB` Keybinding Interception
- **Observed Behavior**: `ALT + TAB` does not trigger the Workspace Switcher overlay in the running session.
- **Root Cause & Investigation**:
  - `default/hypr/bindings/tiling.lua` was updated with `ALT + TAB` bound to `omarchy.workspace-switcher`, but compositor session configs may need reload (`omarchy-refresh-config hypr/bindings/tiling.lua` / Hyprland config reload) or submap conflict resolution.
- **Next Steps**:
  - Verify keybinding registration directly with Hyprland binds (`hyprctl binds -j`) and test dedicated keybind dispatcher.

#### 🔢 ISSUE-03: Switching Regression (Closes Without Switching)
- **Observed Behavior**: Selecting a workspace or pressing Enter / Click / Number key closes the overlay but does not change the active Hyprland workspace.
- **Root Cause & Investigation**:
  - Investigate the layer-shell focus ungrab cycle and IPC execution sequence in Quickshell.
  - Test synchronous Hyprland IPC dispatch mechanisms to ensure workspace transition completes before overlay dismissal.

#### 🖼️ ISSUE-04: App Icons Missing in Workspace Indicators
- **Observed Behavior**: Running window indicators show the fallback utility glyph (`󰀻`) instead of the true application icon.
- **Root Cause & Investigation**:
  - Inspect Quickshell's `ToplevelManager` and `Hyprland.workspaces` toplevel objects to ensure correct `appId` / `initialClass` extraction and verify icon provider URLs (`file://` vs `image://icon/`).

---

### 📱 ISSUE-05: App Grid Category Navigation
- **Current Status**: ✅ Completed (Satisfactory).
- **Implemented Fix**:
  - Category pills are housed in a smooth horizontal `Flickable` with automatic scroll-into-view.
  - Added left (`‹`) and right (`›`) navigation arrow buttons that appear dynamically when categories overflow, allowing quick and intuitive mouse scrolling.
