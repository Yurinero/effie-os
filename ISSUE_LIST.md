# Effie OS - Test Build Issue Tracker & Action Plan

This document tracks observations, regressions, and tasks from test builds. Each issue includes diagnosis, updated findings, and actionable steps.

---

## Issue Summary Matrix

| ID | Component | Issue | Severity | Status |
|---|---|---|---|---|
| **ISSUE-01** | Theming / Boot | Effie Dark splash/login on install & live media | Medium | 📋 TODO (Filed for `effie-iso` pipeline) |
| **ISSUE-02** | Hyprland / Keybinds | `ALT + TAB` keybinding activation | High | ✅ Resolved (Verified in test build) |
| **ISSUE-03** | Workspace Switcher | Workspace switching via Number keys, Click, Return | High | ✅ Resolved (Verified in test build) |
| **ISSUE-04** | Workspace Switcher | Running window app icons missing (displays utility/gear fallback) | Medium | ✅ Resolved (Verified in test build) |
| **ISSUE-05** | App Grid Plugin | Category pills navigation: overflow & navigation buttons | Low | ✅ Completed (Satisfactory) |

---

## Detailed Breakdown & Current Status

### 🎨 ISSUE-01: Effie Dark Theme Missing During Boot & Login
- **Current Status**: 📋 TODO (Disregarded for current sprint, filed for `effie-iso` review).
- **Findings & Actions**:
  - Boot logo colors were successfully updated in `default/plymouth/` and `default/sddm/omarchy/`.
  - The live installer ISO environment and bootloader graphics are generated within the `effie-iso` build pipeline. Further adjustments will be addressed when updating the ISO generation configuration.

---

### ⌨️ ISSUE-02 & ISSUE-03: Workspace Switcher Navigation & Dispatch
- **Current Status**: ✅ Resolved (Verified in test build).
- **Verification Results**:
  - `ALT + TAB` / `ALT + SPACE` accurately summon the Workspace Switcher overlay.
  - Number keys (`1`–`9`, `0`), mouse clicks, and Return key are accurately consumed.
  - Hyprland workspace focus switches immediately upon confirmation.
  - Calling further empty workspaces extends the workspace row dynamically and accurately.

---

### 🖼️ ISSUE-04: Running Window App Icons in Workspace Switcher
- **Current Status**: ✅ Resolved (Verified in test build).
- **Verification Results**:
  - App icons correctly resolve and render across workspaces for all running applications.
  - Icon rows populate seamlessly even when multiple applications are running simultaneously on the same workspace.
  - Workspace switching remains fully functional with zero regressions.

---

### 📱 ISSUE-05: App Grid Category Navigation
- **Current Status**: ✅ Completed (Satisfactory).
- **Implemented Fix**:
  - Category pills are housed in a smooth horizontal `Flickable` with automatic scroll-into-view.
  - Added left (`‹`) and right (`›`) navigation arrow buttons that appear dynamically when categories overflow, allowing quick and intuitive mouse scrolling.
